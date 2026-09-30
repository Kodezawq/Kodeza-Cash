#import "LoanZen_PayAccountService.h"
#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_HTTPClient.h"

@implementation LoanZen_PayAccountService

+ (void)LZ_fetchPayAccountList:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion {
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/payAccountInfo/list" dataParams:@{} showLoading:NO completion:^(NSDictionary *json, NSError *error) {
        if (error) { completion(nil, error); return; }
        NSDictionary *data = [json[LZAPIResponseData] isKindOfClass:[NSDictionary class]] ? json[LZAPIResponseData] : nil;
        NSArray *list = [data[@"payAccountInfoList"] isKindOfClass:[NSArray class]] ? data[@"payAccountInfoList"] : @[];
        completion(list, nil);
    }];
}

+ (void)LZ_fetchPayAccountItemList:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion {
    [self LZ_fetchPayAccountItemListWithShowLoading:NO completion:completion];
}

+ (void)LZ_fetchPayAccountItemListWithShowLoading:(BOOL)showLoading completion:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion {
    
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/payAccountInfo/payAccountItemList" dataParams:@{} showLoading:showLoading completion:^(NSDictionary *json, NSError *error) {
        if (error) { completion(nil, error); return; }
        NSDictionary *data = [json[LZAPIResponseData] isKindOfClass:[NSDictionary class]] ? json[LZAPIResponseData] : nil;
        NSArray *list = [data[@"payAccountInfoItemDtoList"] isKindOfClass:[NSArray class]] ? data[@"payAccountInfoItemDtoList"] : @[];
        completion(list, nil);
    }];
    
}

+ (void)LZ_fetchBankList:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion {
    [self LZ_fetchBankListWithShowLoading:NO completion:completion];
}

+ (void)LZ_fetchBankListWithShowLoading:(BOOL)showLoading completion:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion {
    
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/sys/bank" dataParams:@{} showLoading:showLoading completion:^(NSDictionary *json, NSError *error) {
        if (error) { completion(nil, error); return; }
        NSDictionary *data = [json[LZAPIResponseData] isKindOfClass:[NSDictionary class]] ? json[LZAPIResponseData] : nil;
        NSArray *list = [data[LZAPIFieldBankList] isKindOfClass:[NSArray class]] ? data[LZAPIFieldBankList] : @[];
        completion(list, nil);
    }];
}

+ (void)LZ_fetchWalletList:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion {
    [self LZ_fetchWalletListWithShowLoading:NO completion:completion];
}

+ (void)LZ_fetchWalletListWithShowLoading:(BOOL)showLoading completion:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion {
    
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/sys/wallet" dataParams:@{} showLoading:showLoading completion:^(NSDictionary *json, NSError *error) {
        if (error) { completion(nil, error); return; }
        NSDictionary *data = [json[LZAPIResponseData] isKindOfClass:[NSDictionary class]] ? json[LZAPIResponseData] : nil;
        NSArray *list = [data[LZAPIFieldWalletList] isKindOfClass:[NSArray class]] ? data[LZAPIFieldWalletList] : @[];
        completion(list, nil);
    }];
}

+ (void)LZ_updatePayAccountWithRecordId:(NSString *)recordId defaultFlag:(NSString *)defaultFlag commits:(NSArray<NSDictionary *> *)commits completion:(void (^)(NSError * _Nullable))completion {
    
    NSDictionary *data = @{@"recordId": recordId ?: @"", @"defaultFlag": defaultFlag ?: @"1", @"kycCommitItemList": commits ?: @[]};
    
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/payAccountInfo/update"
                             signParams:@{}
                             dataParams:data
                            showLoading:YES
                             completion:^(NSDictionary *json, NSError *error) {
        completion(error);
        
    }];
}

+ (void)LZ_savePayAccountWithDefaultFlag:(NSString *)defaultFlag commits:(NSArray<NSDictionary *> *)commits completion:(void (^)(NSError * _Nullable))completion {
    NSDictionary *data = @{@"defaultFlag": defaultFlag ?: @"1", @"kycCommitItemList": commits ?: @[]};
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/payAccountInfo/save"
                             signParams:@{}
                             dataParams:data
                            showLoading:YES
                             completion:^(NSDictionary *json, NSError *error) {
        completion(error);
    }];
}

@end
