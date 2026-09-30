#import "LoanZen_AdjustManager.h"
#import "LoanZen_APIConfig.h"

#if __has_include(<AdjustSdk/AdjustSdk.h>)
@import AdjustSdk;
#define LZ_HAS_ADJUST 1
#else
#define LZ_HAS_ADJUST 0
#endif

@implementation LoanZen_AdjustManager

+ (void)LZ_configureIfNeeded {
#if LZ_HAS_ADJUST
    NSString *token = [LoanZen_APIConfig.adjustAppToken stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (token.length == 0) {
        NSLog(@"[LoanZen Adjust] adjustAppToken is empty, SDK skipped");
        return;
    }
#if DEBUG
    NSString *environment = ADJEnvironmentSandbox;
#else
    NSString *environment = ADJEnvironmentProduction;
#endif
    ADJConfig *config = [[ADJConfig alloc] initWithAppToken:token environment:environment];
    config.logLevel = ADJLogLevelWarn;
    [Adjust initSdk:config];
    NSLog(@"[LoanZen Adjust] SDK initialized (token=%@, env=%@)", token, environment);
#endif
}

+ (void)LZ_fetchAdid:(void (^)(NSString * _Nullable))completion {
#if LZ_HAS_ADJUST
    if ([LoanZen_APIConfig.adjustAppToken stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length == 0) {
        NSLog(@"[LoanZen Adjust] fetch adid skipped: adjustAppToken empty");
        if (completion) completion(nil);
        return;
    }
    [Adjust adidWithCompletionHandler:^(NSString * _Nullable adid) {
        NSString *trimmed = [adid stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (completion) completion(trimmed.length > 0 ? trimmed : nil);
    }];
#else
    NSLog(@"[LoanZen Adjust] fetch adid skipped: Adjust SDK not linked");
    if (completion) completion(nil);
#endif
}

@end
