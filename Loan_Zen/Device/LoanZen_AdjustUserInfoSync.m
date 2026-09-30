#import "LoanZen_AdjustUserInfoSync.h"
#import "LoanZen_AdjustManager.h"
#import "LoanZen_UserService.h"
#import "LoanZen_SessionStore.h"

@implementation LoanZen_AdjustUserInfoSync

+ (void)LZ_scheduleUserInfoReport {
    if (!LoanZen_SessionStore.shared.isLoggedIn) {
        NSLog(@"[LoanZen Adjust] skip adid upload: user not logged in");
        return;
    }
    NSLog(@"[LoanZen Adjust] start resolving adid...");
    [self LZ_resolveAdid:^(NSString *adid, BOOL fromRetry) {
        if (adid.length == 0) {
            NSLog(@"[LoanZen Adjust] adid fetch result: EMPTY (retryUsed=%@), skip /user/info upload",
                  fromRetry ? @"YES" : @"NO");
            return;
        }
        NSLog(@"[LoanZen Adjust] adid fetch result: OK value=%@ (retryUsed=%@)",
              adid, fromRetry ? @"YES" : @"NO");
        NSLog(@"[LoanZen Adjust] uploading adid via /app/v3/user/info...");
        [LoanZen_UserService LZ_uploadUserInfoWithAdid:adid completion:^(NSDictionary *user, NSError *error) {
            if (error) {
                NSLog(@"[LoanZen Adjust] adid upload result: FAILED error=%@", error.localizedDescription ?: error);
                return;
            }
            NSLog(@"[LoanZen Adjust] adid upload result: SUCCESS userInfoUpdated=%@",
                  user ? @"YES" : @"NO");
        }];
    }];
}

+ (void)LZ_resolveAdid:(void (^)(NSString *adid, BOOL fromRetry))completion {
    [LoanZen_AdjustManager LZ_fetchAdid:^(NSString *adid) {
        if (adid.length > 0) {
            NSLog(@"[LoanZen Adjust] adid first fetch: %@", adid);
            completion(adid, NO);
            return;
        }
        NSLog(@"[LoanZen Adjust] adid first fetch: empty, retry after 1s");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [LoanZen_AdjustManager LZ_fetchAdid:^(NSString *retry) {
                NSString *resolved = retry ?: @"";
                if (resolved.length > 0) {
                    NSLog(@"[LoanZen Adjust] adid retry fetch: %@", resolved);
                } else {
                    NSLog(@"[LoanZen Adjust] adid retry fetch: empty");
                }
                completion(resolved, YES);
            }];
        });
    }];
}

@end
