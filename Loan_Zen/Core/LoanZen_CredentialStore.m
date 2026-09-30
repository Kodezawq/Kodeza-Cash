#import "LoanZen_CredentialStore.h"

static NSString * const kLZTokenKey = @"LoanZen_CredentialStore.token";
static NSString * const kLZUserIdKey = @"LoanZen_CredentialStore.userId";
static NSString * const kLZMobileKey = @"LoanZen_CredentialStore.mobile";

@implementation LoanZen_CredentialStore

+ (NSString *)token {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kLZTokenKey] ?: @"";
}

+ (void)setToken:(NSString *)token {
    [[NSUserDefaults standardUserDefaults] setObject:token ?: @"" forKey:kLZTokenKey];
}

+ (NSString *)userId {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kLZUserIdKey] ?: @"";
}

+ (void)setUserId:(NSString *)userId {
    [[NSUserDefaults standardUserDefaults] setObject:userId ?: @"" forKey:kLZUserIdKey];
}

+ (NSString *)mobileDigits {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kLZMobileKey] ?: @"";
}

+ (void)setMobileDigits:(NSString *)mobileDigits {
    [[NSUserDefaults standardUserDefaults] setObject:mobileDigits ?: @"" forKey:kLZMobileKey];
}

+ (void)LZ_clearAuth {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kLZTokenKey];
    [defaults removeObjectForKey:kLZUserIdKey];
    [defaults removeObjectForKey:kLZMobileKey];
}

@end
