#import "LoanZen_AuthService.h"
#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_HTTPClient.h"
#import "LoanZen_DeviceIdentity.h"
#import "LoanZen_AppConfigStore.h"
#import "LoanZen_JSONParser.h"
#import "LoanZen_LoginResult.h"

static void LZ_logAppConfigResponseJSON(id object) {
    if (!object) {
        NSLog(@"[LoanZen AppConfig] /app/v3/app/config response: (nil)");
        return;
    }
    if (![NSJSONSerialization isValidJSONObject:object]) {
        NSLog(@"[LoanZen AppConfig] /app/v3/app/config response: %@", object);
        return;
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:nil];
    if (jsonData.length > 0) {
        NSLog(@"[LoanZen AppConfig] /app/v3/app/config response:\n%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
        return;
    }
    NSLog(@"[LoanZen AppConfig] /app/v3/app/config response: %@", object);
}

@implementation LoanZen_AuthService

+ (void)LZ_sendOTPWithMobileDigits:(NSString *)mobileDigits completion:(void (^)(NSError * _Nullable))completion {
    NSDictionary *data = @{@"mobile": mobileDigits ?: @"", @"verifyType": @1};
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/sms/sendVerifySms" dataParams:data showLoading:YES completion:^(NSDictionary *json, NSError *error) {
        if (completion) completion(error);
    }];
}

+ (void)LZ_registerOrLoginWithMobileDigits:(NSString *)mobileDigits
                                verifyCode:(NSString *)verifyCode
                                completion:(void (^)(LoanZen_LoginResult * _Nullable, NSError * _Nullable))completion {
    NSDictionary *data = @{
        @"mobile": mobileDigits ?: @"",
        @"verifyCode": verifyCode ?: @"",
        @"longitude": @"-360",
        @"latitude": @"-360",
        @"imei": [LoanZen_DeviceIdentity LZ_imei],
        @"serialNo": [LoanZen_DeviceIdentity LZ_serialNo]
    };
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/auth/registerOrLogin" dataParams:data showLoading:YES completion:^(NSDictionary *json, NSError *error) {
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        NSError *parseError = nil;
        LoanZen_LoginResult *result = [LoanZen_JSONParser LZ_modelFromResponseJSON:json
                                                                        modelClass:[LoanZen_LoginResult class]
                                                                             error:&parseError];
        if (completion) completion(result, parseError);
    }];
}

+ (void)LZ_fetchAppConfigWithCompletion:(void (^ _Nullable)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/app/config" dataParams:@{} showLoading:NO completion:^(NSDictionary *json, NSError *error) {
        if (error) {
            NSLog(@"[LoanZen AppConfig] /app/v3/app/config error: %@", error);
            if (completion) completion(nil, error);
            return;
        }
        LZ_logAppConfigResponseJSON(json);
        NSDictionary *data = [json[LZAPIResponseData] isKindOfClass:[NSDictionary class]] ? json[LZAPIResponseData] : nil;
        [LoanZen_AppConfigStore LZ_applyAppConfig:data];
        if (completion) completion(data, nil);
    }];
}

+ (void)LZ_logoutWithCompletion:(void (^)(NSError * _Nullable))completion {
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/auth/logout" dataParams:@{} showLoading:YES completion:^(NSDictionary *json, NSError *error) {
        if (completion) completion(error);
    }];
}

+ (void)LZ_closeAccountWithCompletion:(void (^)(NSError * _Nullable))completion {
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/auth/close" dataParams:@{} showLoading:YES completion:^(NSDictionary *json, NSError *error) {
        if (completion) completion(error);
    }];
}

@end
