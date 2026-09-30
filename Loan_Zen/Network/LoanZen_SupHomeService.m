#import "LoanZen_SupHomeService.h"
#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_HTTPClient.h"
#import "LoanZen_CredentialStore.h"
#import "LoanZen_APIConfig.h"
#import "LoanZen_AppConfigStore.h"

static NSDictionary *_lzLastSupHomeResponse;

@implementation LoanZen_SupHomeStore

+ (NSDictionary *)LZ_lastResponse { return _lzLastSupHomeResponse; }
+ (void)LZ_applyResponse:(NSDictionary *)response { _lzLastSupHomeResponse = response; }
+ (void)LZ_clear { _lzLastSupHomeResponse = nil; }

@end

@implementation LoanZen_SupHomeService

+ (void)LZ_refreshIfLoggedInWithShowLoading:(BOOL)showLoading
                                completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    if (LoanZen_CredentialStore.token.length == 0 || !LoanZen_APIConfig.hasSigningProfile) {
        if (completion) completion(nil, nil);
        return;
    }
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/user/suphome" dataParams:@{} showLoading:showLoading completion:^(NSDictionary *json, NSError *error) {
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        NSDictionary *data = [json[LZAPIResponseData] isKindOfClass:[NSDictionary class]] ? json[LZAPIResponseData] : nil;
        [LoanZen_SupHomeStore LZ_applyResponse:data];
        [LoanZen_AppConfigStore LZ_applySuphomeData:data];
        if (completion) completion(data, nil);
    }];
}

@end
