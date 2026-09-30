#import "LoanZen_KYCFourService.h"
#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_HTTPClient.h"
#import "LoanZen_CredentialStore.h"
#import "LoanZen_KYCFourFlowStore.h"
#import "LoanZen_KYCFourFlowNavigator.h"

@implementation LoanZen_KYCFourService

+ (NSArray<NSDictionary *> *)LZ_regionPairsFromList:(NSArray *)list key:(NSString *)listKey {
    id raw = list;
    if (listKey.length > 0 && [list isKindOfClass:[NSDictionary class]]) {
        raw = ((NSDictionary *)list)[listKey];
    }
    if (![raw isKindOfClass:[NSArray class]]) return @[];
    NSMutableArray<NSDictionary *> *pairs = [NSMutableArray array];
    for (NSDictionary *option in (NSArray *)raw) {
        if (![option isKindOfClass:[NSDictionary class]]) continue;
        NSString *label = [option[LZAPIFieldLabel] isKindOfClass:[NSString class]] ? [option[LZAPIFieldLabel] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] : @"";
        if (label.length == 0 && [option[@"label"] isKindOfClass:[NSString class]]) {
            label = [(NSString *)option[@"label"] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        }
        NSString *value = [option[LZAPIFieldKey] isKindOfClass:[NSString class]] ? [option[LZAPIFieldKey] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] : @"";
        if (value.length == 0 && [option[@"key"] isKindOfClass:[NSString class]]) {
            value = [(NSString *)option[@"key"] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        }
        if (label.length == 0 || value.length == 0) continue;
        NSInteger sort = 0;
        if ([option[LZAPIFieldSort] respondsToSelector:@selector(integerValue)]) {
            sort = [option[LZAPIFieldSort] integerValue];
        } else if ([option[@"sort"] respondsToSelector:@selector(integerValue)]) {
            sort = [option[@"sort"] integerValue];
        }
        [pairs addObject:@{ @"label": label, @"value": value, LZAPIFieldSort: @(sort) }];
    }
    [pairs sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        return [a[LZAPIFieldSort] compare:b[LZAPIFieldSort]];
    }];
    return pairs.copy;
}

+ (NSNumber *)LZ_stepNumberFromStatusData:(NSDictionary *)data {
    if (![data isKindOfClass:[NSDictionary class]]) return nil;
    NSDictionary *echo = [data[LZAPIFieldEchoMap] isKindOfClass:[NSDictionary class]] ? data[LZAPIFieldEchoMap] : nil;
    id raw = echo[@"willExecuteStepNumber"] ?: data[@"willExecuteStepNumber"];
    if ([raw isKindOfClass:[NSNumber class]]) return raw;
    if ([raw isKindOfClass:[NSString class]]) {
        NSString *trimmed = [(NSString *)raw stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        return trimmed.length > 0 ? @([trimmed integerValue]) : nil;
    }
    return nil;
}

+ (void)LZ_fetchFourStatusWithLoading:(BOOL)showLoading completion:(void (^)(NSNumber * _Nullable, NSError * _Nullable))completion {
    if (LoanZen_CredentialStore.token.length == 0) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"LoanZen_KYCFourService" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Not logged in"}]);
        }
        return;
    }
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/kyc/four/status"
                             signParams:@{}
                             dataParams:@{}
                            showLoading:showLoading
                             completion:^(NSDictionary *json, NSError *error) {
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        NSDictionary *data = [json[LZAPIResponseData] isKindOfClass:[NSDictionary class]] ? json[LZAPIResponseData] : nil;
        NSNumber *step = [self LZ_stepNumberFromStatusData:data];
        if (step) [LoanZen_KYCFourFlowStore.shared LZ_applyStatusStep:step.integerValue];
        if (completion) completion(step, nil);
    }];
}

+ (void)LZ_fetchSearchItemsForStep:(NSInteger)step showLoading:(BOOL)showLoading completion:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion {
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/kyc/four/search-iterm"
                             signParams:@{}
                             dataParams:@{}
                            showLoading:showLoading
                             completion:^(NSDictionary *json, NSError *error) {
        if (error) {
            if (step != 4) [LoanZen_KYCFourFlowStore.shared LZ_applyStageKycId:nil];
            if (completion) completion(nil, error);
            return;
        }
        NSDictionary *data = [json[LZAPIResponseData] isKindOfClass:[NSDictionary class]] ? json[LZAPIResponseData] : nil;
        NSArray<NSDictionary *> *list = @[];
        id rawList = data[LZAPIFieldKycItemList];
        if ([rawList isKindOfClass:[NSArray class]]) {
            list = (NSArray<NSDictionary *> *)rawList;
        }
        [LoanZen_KYCFourFlowStore.shared LZ_applySearchItems:list];
        [LoanZen_KYCFourFlowNavigator LZ_applyStageKycIdFromSearchItems:step list:list];
        if (completion) completion(list, nil);
    }];
}

+ (void)LZ_fetchSearchItemsForStep:(NSInteger)step completion:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion {
    [self LZ_fetchSearchItemsForStep:step showLoading:YES completion:completion];
}

+ (void)LZ_fetchSearchItemsWithCompletion:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion {
    NSInteger step = LoanZen_KYCFourFlowStore.shared.currentStepNumber.integerValue;
    if (step < 1 || step > 4) step = 1;
    [self LZ_fetchSearchItemsForStep:step completion:completion];
}

+ (void)LZ_fetchProvinceListWithCountryId:(NSString *)countryId completion:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion {
    NSDictionary *payload = @{ @"countryId": countryId ?: @"" };
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/sys/province"
                             signParams:payload
                             dataParams:payload
                            showLoading:YES
                             completion:^(NSDictionary *json, NSError *error) {
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        NSDictionary *data = [json[LZAPIResponseData] isKindOfClass:[NSDictionary class]] ? json[LZAPIResponseData] : nil;
        if (completion) completion([self LZ_regionPairsFromList:data key:LZAPIFieldProvinceList], nil);
    }];
}

+ (void)LZ_fetchCityListWithCountryId:(NSString *)countryId provinceId:(NSString *)provinceId completion:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion {
    NSDictionary *payload = @{ @"countryId": countryId ?: @"", @"provinceId": provinceId ?: @"" };
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/sys/city"
                             signParams:payload
                             dataParams:payload
                            showLoading:YES
                             completion:^(NSDictionary *json, NSError *error) {
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        NSDictionary *data = [json[LZAPIResponseData] isKindOfClass:[NSDictionary class]] ? json[LZAPIResponseData] : nil;
        if (completion) completion([self LZ_regionPairsFromList:data key:@"cityList"], nil);
    }];
}

+ (NSString *)LZ_pathForStep:(NSInteger)step {
    switch (step) {
        case 1: return @"/app/v3/kyc/four/personal";
        case 2: return @"/app/v3/kyc/four/work";
        case 3: return @"/app/v3/kyc/four/contact";
        case 4: return @"/app/v3/kyc/four/liveness";
        default: return @"/app/v3/kyc/four/personal";
    }
}

+ (void)LZ_submitStep:(NSInteger)step fields:(NSDictionary *)fields completion:(void (^)(NSError * _Nullable))completion {
    [LoanZen_HTTPClient LZ_postWithPath:[self LZ_pathForStep:step]
                             signParams:@{}
                             dataParams:fields ?: @{}
                            showLoading:YES
                             completion:^(NSDictionary *json, NSError *error) {
        if (completion) completion(error);
    }];
}

@end
