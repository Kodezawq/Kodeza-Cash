#import "LoanZen_AppConfigRefresher.h"
#import "LoanZen_AuthService.h"
#import "LoanZen_APIConfig.h"

@implementation LoanZen_AppConfigRefresher

+ (void)LZ_refreshIfPossible {
    [self LZ_refreshIfPossibleWithCompletion:nil];
}

+ (void)LZ_refreshIfPossibleWithCompletion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    if (!LoanZen_APIConfig.hasSigningProfile) {
        if (completion) completion(nil, nil);
        return;
    }
    if ([LoanZen_APIConfig LZ_normalizedBaseURLString].length == 0) {
        if (completion) completion(nil, nil);
        return;
    }
    [LoanZen_AuthService LZ_fetchAppConfigWithCompletion:completion];
}

@end
