#import "LoanZen_ProductService.h"
#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_HTTPClient.h"
#import "LoanZen_HUD.h"
#import "LoanZen_DeviceIdentity.h"

@implementation LoanZen_ProductService

+ (NSString *)LZ_stringFromItem:(NSDictionary *)item keys:(NSArray<NSString *> *)keys {
    for (NSString *key in keys) {
        id value = item[key];
        if ([value isKindOfClass:[NSString class]]) {
            NSString *text = [(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (text.length > 0) return text;
        } else if ([value isKindOfClass:[NSNumber class]]) {
            return [(NSNumber *)value stringValue];
        }
    }
    return @"";
}

+ (NSString *)LZ_formatAmount:(NSString *)rawValue {
    NSString *raw = [rawValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (raw.length == 0) return @"";
    if ([raw containsString:@"₱"]) return raw;
    NSCharacterSet *nonDigits = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789."] invertedSet];
    NSString *cleaned = [[raw componentsSeparatedByCharactersInSet:nonDigits] componentsJoinedByString:@""];
    if (cleaned.length == 0) return [NSString stringWithFormat:@"₱%@", raw];
    double number = cleaned.doubleValue;
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.maximumFractionDigits = 0;
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_PH"];
    NSString *formatted = [formatter stringFromNumber:@(number)];
    return formatted.length > 0 ? [NSString stringWithFormat:@"₱%@", formatted] : [NSString stringWithFormat:@"₱%@", raw];
}

+ (NSString *)LZ_quotaRangeTextWithLow:(NSString *)low high:(NSString *)high {
    NSString *lowText = [self LZ_formatAmount:low];
    NSString *highText = [self LZ_formatAmount:high];
    if (lowText.length > 0 && highText.length > 0) {
        return [NSString stringWithFormat:@"%@ ~ %@", lowText, highText];
    }
    if (lowText.length > 0) return [NSString stringWithFormat:@"From %@", lowText];
    if (highText.length > 0) return [NSString stringWithFormat:@"Up to %@", highText];
    return @"—";
}

+ (NSString *)LZ_interestRateText:(NSString *)rawValue {
    NSString *raw = [rawValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (raw.length == 0) return @"—";
    if ([raw containsString:@"%"]) return raw;
    NSCharacterSet *nonDigits = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789.-"] invertedSet];
    NSString *cleaned = [[raw componentsSeparatedByCharactersInSet:nonDigits] componentsJoinedByString:@""];
    if (cleaned.length == 0) return [NSString stringWithFormat:@"%@%%", raw];
    double number = cleaned.doubleValue;
    double percentage = number <= 1.0 ? number * 100.0 : number;
    return [NSString stringWithFormat:@"%.2f%%", percentage];
}

+ (void)LZ_fetchProductTermWithProductId:(NSString *)productId completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    [self LZ_fetchProductTermEnvelopeWithProductId:productId showLoading:YES completion:^(NSDictionary *json, NSError *error) {
        if (error) { completion(nil, error); return; }
        completion([json[LZAPIResponseData] isKindOfClass:[NSDictionary class]] ? json[LZAPIResponseData] : nil, nil);
    }];
}

+ (void)LZ_fetchProductTermEnvelopeWithProductId:(NSString *)productId showLoading:(BOOL)showLoading completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSDictionary *data = @{@"productId": productId ?: @""};
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/product/termV3" dataParams:data showLoading:showLoading completion:completion];
}

+ (NSDictionary *)LZ_mapProductItem:(NSDictionary *)item {
    NSString *low = [self LZ_stringFromItem:item keys:@[LZAPIFieldLowAmount, @"lowamount"]];
    NSString *high = [self LZ_stringFromItem:item keys:@[LZAPIFieldHighAmount, @"highamount"]];
    NSString *amount = [self LZ_quotaRangeTextWithLow:low high:high];
    NSString *interestRate = [self LZ_interestRateText:[self LZ_stringFromItem:item keys:@[LZAPIFieldLowestLoanInterestRate, @"lowestloaninterestrate"]]];
    NSString *name = [self LZ_stringFromItem:item keys:@[LZAPIFieldProductName, @"productname"]];
    NSString *term = [self LZ_stringFromItem:item keys:@[LZAPIFieldHighestTerm, @"highestterm", LZAPIFieldShowTerm]];
    return @{
        @"name": name.length > 0 ? name : @"Loan",
        @"amount": amount,
        @"quotaRange": amount,
        @"interestRate": interestRate,
        @"term": term.length > 0 ? term : @"—",
        @"productId": [self LZ_stringFromItem:item keys:@[LZAPIFieldProductId, @"productid"]],
        @"productLogo": [self LZ_stringFromItem:item keys:@[LZAPIFieldProductLogo, @"productlogo"]],
    };
}

+ (void)LZ_fetchProductListWithCompletion:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion {
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/product/list" dataParams:@{} showLoading:NO completion:^(NSDictionary *json, NSError *error) {
        if (error) { completion(nil, error); return; }
        id data = json[LZAPIResponseData];
        NSArray *list = nil;
        if ([data isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dict = (NSDictionary *)data;
            list = [dict[LZAPIFieldProductInfoList] isKindOfClass:[NSArray class]] ? dict[LZAPIFieldProductInfoList] :
                   [dict[@"productList"] isKindOfClass:[NSArray class]] ? dict[@"productList"] : nil;
        } else if ([data isKindOfClass:[NSArray class]]) {
            list = (NSArray *)data;
        }
        NSMutableArray *mapped = [NSMutableArray array];
        for (NSDictionary *item in list ?: @[]) {
            if ([item isKindOfClass:[NSDictionary class]]) [mapped addObject:[self LZ_mapProductItem:item]];
        }
        completion(mapped.copy, nil);
    }];
}

+ (void)LZ_fetchProductStateWithProductId:(NSString *)productId completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    if (productId.length > 0) data[@"productId"] = productId;
    // 对齐 LoanEase LEProductStatePayload.signatureFieldNames = []：productId 仅请求体、不参与签名。
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/product/state"
                             signParams:@{}
                             dataParams:data
                            showLoading:NO
                             completion:^(NSDictionary *json, NSError *error) {
        if (error) { completion(nil, error); return; }
        completion([json[LZAPIResponseData] isKindOfClass:[NSDictionary class]] ? json[LZAPIResponseData] : nil, nil);
    }];
}

+ (void)LZ_submitOrderWithProductId:(NSString *)productId loanAmount:(NSString *)amount showTerm:(NSString *)showTerm bankCardBindId:(NSString *)bindId longitude:(NSString *)longitude latitude:(NSString *)latitude completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    [self LZ_submitOrderWithProductId:productId loanAmount:amount showTerm:showTerm bankCardBindId:bindId longitude:longitude latitude:latitude showLoading:YES completion:completion];
}

+ (void)LZ_submitOrderWithProductId:(NSString *)productId loanAmount:(NSString *)amount showTerm:(NSString *)showTerm bankCardBindId:(NSString *)bindId longitude:(NSString *)longitude latitude:(NSString *)latitude showLoading:(BOOL)showLoading completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSMutableDictionary *data = [@{
        @"productId": productId ?: @"",
        @"loanAmount": amount ?: @"",
        @"longitude": longitude.length > 0 ? longitude : @"-360",
        @"latitude": latitude.length > 0 ? latitude : @"-360",
        @"imei": [LoanZen_DeviceIdentity LZ_imei],
        @"serialNo": [LoanZen_DeviceIdentity LZ_serialNo],
        @"showTerm": showTerm ?: @"",
    } mutableCopy];
    if (bindId.length > 0) data[@"bankCardBindId"] = bindId;
    NSDictionary *sign = @{
        @"productId": productId ?: @"",
        @"loanAmount": amount ?: @"",
        @"longitude": data[@"longitude"],
        @"latitude": data[@"latitude"],
        @"imei": data[@"imei"],
        @"serialNo": data[@"serialNo"],
    };
    // 对齐 LoanEase LEOrderSubmitPayload：bankCardBindId / showTerm 不参与签名。
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/order/userSubmitV3"
                             signParams:sign
                             dataParams:data
                            showLoading:showLoading
                             completion:^(NSDictionary *json, NSError *error) {
        if (error) { completion(nil, error); return; }
        completion([json[LZAPIResponseData] isKindOfClass:[NSDictionary class]] ? json[LZAPIResponseData] : nil, nil);
    }];
}

@end
