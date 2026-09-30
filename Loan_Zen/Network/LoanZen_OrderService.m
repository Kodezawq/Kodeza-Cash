#import "LoanZen_OrderService.h"
#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_HTTPClient.h"
#import "LoanZen_CredentialStore.h"
#import <UIKit/UIKit.h>

@implementation LoanZen_OrderService

+ (void)LZ_fetchOrderListWithStatus:(NSInteger)orderStatus
                        showLoading:(BOOL)showLoading
                         completion:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion {
    if (LoanZen_CredentialStore.token.length == 0) { completion(@[], nil); return; }
    NSDictionary *data = @{@"orderStatus": @(orderStatus)};
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/order/list"
                             signParams:@{}
                             dataParams:data
                            showLoading:showLoading
                             completion:^(NSDictionary *json, NSError *error) {
        if (error) { completion(nil, error); return; }
        NSDictionary *payload = json[LZAPIResponseData];
        NSArray *list = [payload[LZAPIFieldOrderList] isKindOfClass:[NSArray class]] ? payload[LZAPIFieldOrderList] : @[];
        completion(list, nil);
    }];
}

+ (void)LZ_fetchOrderDetailWithOrderId:(NSString *)orderId productId:(nullable NSString *)productId completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSMutableDictionary *data = [@{@"orderId": orderId ?: @"", @"appType": @"DC"} mutableCopy];
    if (productId.length > 0) data[@"productId"] = productId;
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/order/detailV2"
                             signParams:@{@"orderId": orderId ?: @""}
                             dataParams:data
                            showLoading:YES
                             completion:^(NSDictionary *json, NSError *error) {
        if (error) { completion(nil, error); return; }
        completion([json[LZAPIResponseData] isKindOfClass:[NSDictionary class]] ? json[LZAPIResponseData] : nil, nil);
    }];
}

+ (void)LZ_repayConnectWithOrderId:(NSString *)orderId
                 payAccountNumber:(NSString *)payAccountNumber
                       completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    NSMutableDictionary *data = [@{
        @"orderId": orderId ?: @"",
        @"periodNoList": @[@1],
    } mutableCopy];
    NSString *account = [self LZ_normalizedPayAccountNumber:payAccountNumber];
    if (account.length > 0) data[@"payAccountNumber"] = account;
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/order/repay/connect"
                             signParams:@{@"orderId": orderId ?: @""}
                             dataParams:data
                            showLoading:YES
                             completion:^(NSDictionary *json, NSError *error) {
        if (error) { completion(nil, error); return; }
        NSDictionary *payload = [json[LZAPIResponseData] isKindOfClass:[NSDictionary class]] ? json[LZAPIResponseData] : nil;
        completion([self LZ_repayLinkFromResponseData:payload], nil);
    }];
}

+ (void)LZ_fetchWithdrawalDetailWithOrderId:(NSString *)orderId productId:(NSString *)productId completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSMutableDictionary *data = [@{@"orderId": orderId ?: @""} mutableCopy];
    if (productId.length > 0) data[@"productId"] = productId;
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/order/withdrawn/detail"
                             signParams:@{@"orderId": orderId ?: @""}
                             dataParams:data
                            showLoading:YES
                             completion:^(NSDictionary *json, NSError *error) {
        if (error) { completion(nil, error); return; }
        completion([json[LZAPIResponseData] isKindOfClass:[NSDictionary class]] ? json[LZAPIResponseData] : nil, nil);
    }];
}

+ (void)LZ_applyWithdrawalWithOrderId:(NSString *)orderId loanAmount:(NSString *)loanAmount loanTerm:(NSString *)loanTerm completion:(void (^)(NSError * _Nullable))completion {
    NSMutableDictionary *data = [@{@"orderId": orderId ?: @""} mutableCopy];
    if (loanAmount.length > 0) data[@"loanAmount"] = loanAmount;
    if (loanTerm.length > 0) data[@"loanTerm"] = loanTerm;
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/order/apply/withdrawal"
                             signParams:@{@"orderId": orderId ?: @""}
                             dataParams:data
                            showLoading:YES
                             completion:^(NSDictionary *json, NSError *error) {
        completion(error);
    }];
}

+ (void)LZ_repayExtensionWithOrderId:(NSString *)orderId
                    payAccountNumber:(NSString *)payAccountNumber
                          completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    // 对齐 CMD CMRepayExtensionData：orderId + periodNoList[1] + payAccountNumber，签名仅 orderId
    NSMutableDictionary *data = [@{
        @"orderId": orderId ?: @"",
        @"periodNoList": @[@1],
    } mutableCopy];
    NSString *account = [self LZ_normalizedPayAccountNumber:payAccountNumber];
    if (account.length > 0) data[@"payAccountNumber"] = account;
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/order/repay/extension"
                             signParams:@{@"orderId": orderId ?: @""}
                             dataParams:data
                            showLoading:YES
                             completion:^(NSDictionary *json, NSError *error) {
        if (error) { completion(nil, error); return; }
        NSDictionary *payload = [json[LZAPIResponseData] isKindOfClass:[NSDictionary class]] ? json[LZAPIResponseData] : nil;
        completion([self LZ_repayLinkFromResponseData:payload], nil);
    }];
}

+ (NSString *)LZ_normalizedPayAccountNumber:(NSString *)raw {
    NSString *value = raw ?: @"";
    value = [value stringByReplacingOccurrencesOfString:@" " withString:@""];
    return [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

+ (NSString *)LZ_repayLinkFromResponseData:(NSDictionary *)data {
    if (![data isKindOfClass:[NSDictionary class]]) return nil;
    id connect = data[LZAPIFieldConnect];
    if ([connect isKindOfClass:[NSString class]] && [(NSString *)connect length] > 0) return connect;
    id connectUrl = data[@"connectUrl"];
    if ([connectUrl isKindOfClass:[NSString class]] && [(NSString *)connectUrl length] > 0) return connectUrl;
    id repayUrl = data[@"repayUrl"];
    if ([repayUrl isKindOfClass:[NSString class]] && [(NSString *)repayUrl length] > 0) return repayUrl;
    return nil;
}

@end
