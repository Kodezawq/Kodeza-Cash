#import "LoanZen_SessionStore.h"
#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_CredentialStore.h"
#import "LoanZen_LoginResult.h"
#import "LoanZen_SupHomeParser.h"

@interface LoanZen_SessionStore ()
@property (nonatomic, assign, readwrite) BOOL isLoggedIn;
@property (nonatomic, copy, readwrite) NSString *mobileDisplay;
@property (nonatomic, copy, readwrite) NSString *userName;
@property (nonatomic, copy, readwrite) NSString *appUserType;
@end

@implementation LoanZen_SessionStore

+ (LoanZen_SessionStore *)shared {
    static LoanZen_SessionStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[LoanZen_SessionStore alloc] init];
        store.userName = @"User name";
        store.appUserType = @"";
        [store LZ_reloadFromStore];
    });
    return store;
}

- (void)LZ_reloadFromStore {
    if (LoanZen_CredentialStore.token.length == 0) {
        self.isLoggedIn = NO;
        self.mobileDisplay = @"+63";
        return;
    }
    self.isLoggedIn = YES;
    NSString *digits = LoanZen_CredentialStore.mobileDigits;
    self.mobileDisplay = digits.length > 0 ? [self LZ_formatPHMobile:digits] : @"+63";
}

- (void)LZ_applyLoginWithToken:(NSString *)token userId:(NSString *)userId mobileDigits:(NSString *)mobileDigits {
    LoanZen_CredentialStore.token = token;
    if (userId.length > 0) LoanZen_CredentialStore.userId = userId;
    LoanZen_CredentialStore.mobileDigits = mobileDigits;
    self.isLoggedIn = YES;
    self.mobileDisplay = [self LZ_formatPHMobile:mobileDigits];
}

- (void)LZ_applyLoginResult:(LoanZen_LoginResult *)result fallbackMobileDigits:(NSString *)fallbackMobileDigits {
    NSString *mobile = result.mobile.length > 0 ? result.mobile : fallbackMobileDigits;
    [self LZ_applyLoginWithToken:result.token userId:result.userId mobileDigits:mobile];
}

- (void)LZ_applyDemoLoginWithMobileDigits:(NSString *)mobileDigits {
    self.isLoggedIn = YES;
    self.mobileDisplay = [self LZ_formatPHMobile:mobileDigits];
}

- (void)LZ_clearSession {
    [LoanZen_CredentialStore LZ_clearAuth];
    self.isLoggedIn = NO;
    self.mobileDisplay = @"+63 8888888888";
    self.userName = @"User name";
    self.appUserType = @"";
}

- (void)LZ_applyUserInfo:(NSDictionary *)userInfo {
    if (![userInfo isKindOfClass:[NSDictionary class]]) return;
    NSString *name = [LoanZen_SupHomeParser LZ_displayNameFromUserInfo:userInfo];
    if (name.length > 0) self.userName = name;
    id userType = userInfo[LZAPIFieldAppUserType] ?: userInfo[@"app_user_type"];
    if ([userType isKindOfClass:[NSString class]] && [(NSString *)userType length] > 0) {
        self.appUserType = (NSString *)userType;
    } else if ([userType isKindOfClass:[NSNumber class]]) {
        self.appUserType = [(NSNumber *)userType stringValue];
    }
}

- (NSString *)LZ_formatPHMobile:(NSString *)digits {
    NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSArray *parts = [digits componentsSeparatedByCharactersInSet:nonDigits];
    NSMutableString *clean = [NSMutableString string];
    for (NSString *p in parts) [clean appendString:p];
    if (clean.length == 0) return @"+63";
    return [NSString stringWithFormat:@"+63 %@", clean];
}

@end
