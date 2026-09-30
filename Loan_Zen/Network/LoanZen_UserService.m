#import "LoanZen_UserService.h"
#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_HTTPClient.h"
#import "LoanZen_SessionStore.h"
#import "LoanZen_JSONParser.h"

@implementation LoanZen_UserService

+ (void)LZ_uploadUserInfoWithAdid:(NSString *)adid completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    if (adid.length > 0) data[@"adid"] = adid;
    // 对齐 LoanEase LEUserInfoPayload.signatureFieldNames = []：data 字段不参与签名。
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/user/info"
                             signParams:@{}
                             dataParams:data
                            showLoading:NO
                             completion:^(NSDictionary *json, NSError *error) {
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        NSInteger code = [LoanZen_JSONParser LZ_businessCodeFromResponseJSON:json];
        BOOL success = [json[LZAPIResponseSuccess] boolValue] || code == 200;
        if (!success) {
            NSString *message = [LoanZen_JSONParser LZ_messageFromResponseJSON:json] ?: @"user/info request failed";
            if (completion) {
                completion(nil, [NSError errorWithDomain:@"LoanZen_UserService"
                                                     code:code
                                                 userInfo:@{NSLocalizedDescriptionKey: message}]);
            }
            return;
        }
        NSDictionary *user = [json[LZAPIResponseData] isKindOfClass:[NSDictionary class]] ? json[LZAPIResponseData] : nil;
        [LoanZen_SessionStore.shared LZ_applyUserInfo:user];
        if (completion) completion(user, nil);
    }];
}

+ (void)LZ_fetchUserInfoWithCompletion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    [self LZ_uploadUserInfoWithAdid:nil completion:completion];
}

@end
