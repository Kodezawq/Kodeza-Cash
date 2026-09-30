#import "LoanZen_MeViewModel.h"
#import "LoanZen_SessionStore.h"
#import "LoanZen_SupHomeParser.h"
#import "LoanZen_Notifications.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_AuthService.h"
#import "LoanZen_SupHomeService.h"
#import "LoanZen_UserService.h"

@interface LoanZen_MeViewModel ()
@property (nonatomic, copy, readwrite) NSString *userName;
@property (nonatomic, copy, readwrite) NSString *mobileDisplay;
@property (nonatomic, copy, readwrite) NSArray<NSDictionary *> *menuItems;
@end

@implementation LoanZen_MeViewModel

- (NSString *)LZ_appDisplayName {
    NSString *name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (name.length == 0) name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    return name.length > 0 ? name : @"Kodeza Cash";
}

- (NSString *)LZ_resolvedDisplayName:(NSString *)raw {
    NSString *trimmed = [raw stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmed.length == 0 || [trimmed isEqualToString:@"User name"]) {
        return [self LZ_appDisplayName];
    }
    return trimmed;
}

- (void)LZ_loadProfile {
    self.mobileDisplay = LoanZen_SessionStore.shared.mobileDisplay;
    self.userName = [self LZ_resolvedDisplayName:LoanZen_SessionStore.shared.userName];
    self.menuItems = [self LZ_buildMenuItems];
    [self LZ_notifyStateChanged];
}

- (void)LZ_refreshUserInfo {
    if (!LoanZen_SessionStore.shared.isLoggedIn) {
        [self LZ_loadProfile];
        return;
    }
    [LoanZen_UserService LZ_fetchUserInfoWithCompletion:^(NSDictionary *user, NSError *error) {
        if (!error && [user isKindOfClass:[NSDictionary class]]) {
            NSString *name = [LoanZen_SupHomeParser LZ_displayNameFromUserInfo:user];
            self.userName = [self LZ_resolvedDisplayName:name];
            [LoanZen_SessionStore.shared LZ_applyUserInfo:user];
            NSString *phone = [LoanZen_SupHomeParser LZ_displayPhoneFromUserInfo:user];
            if (phone.length > 0) self.mobileDisplay = [self LZ_formatPhone:phone];
        } else {
            self.userName = [self LZ_resolvedDisplayName:LoanZen_SessionStore.shared.userName];
        }
        [self LZ_notifyStateChanged];
    }];
}

- (NSArray<NSDictionary *> *)LZ_buildMenuItems {
    return @[
        @{@"title": @"Contact Us", @"icon": [LoanZen_Asset meContact], @"action": @"contact"},
        @{@"title": @"Privacy policy", @"icon": [LoanZen_Asset mePrivacy], @"action": @"privacy"},
        @{@"title": @"Terms of the loan", @"icon": [LoanZen_Asset meTerms], @"action": @"terms"},
        @{@"title": @"Feedback", @"icon": [LoanZen_Asset meFeedback], @"action": @"feedback"},
        @{@"title": @"Repayment Instructions", @"icon": [LoanZen_Asset meRepayment], @"action": @"repayment"},
        @{@"title": @"Official Website", @"icon": [LoanZen_Asset meWebsite], @"action": @"website"},
        @{@"title": @"About", @"icon": [LoanZen_Asset meAbout], @"action": @"about"},
    ];
}

- (NSString *)LZ_formatPhone:(NSString *)raw {
    NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSArray *parts = [raw componentsSeparatedByCharactersInSet:nonDigits];
    NSMutableString *clean = [NSMutableString string];
    for (NSString *part in parts) [clean appendString:part];
    if (clean.length == 0) return LoanZen_SessionStore.shared.mobileDisplay;
    if ([clean hasPrefix:@"63"] && clean.length > 2) clean = [clean substringFromIndex:2];
    else if ([clean hasPrefix:@"0"] && clean.length > 1) clean = [clean substringFromIndex:1];
    return [NSString stringWithFormat:@"+63 %@", clean];
}

- (void)LZ_logout {
    [LoanZen_AuthService LZ_logoutWithCompletion:^(NSError *error) {
        if (error) return;
        [LoanZen_SessionStore.shared LZ_clearSession];
        [LoanZen_SupHomeStore LZ_clear];
        [self LZ_loadProfile];
        [[NSNotificationCenter defaultCenter] postNotificationName:LZ_NotificationLogoutDidFinish object:nil];
    }];
}

@end
