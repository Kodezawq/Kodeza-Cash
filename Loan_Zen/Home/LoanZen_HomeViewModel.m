#import "LoanZen_HomeViewModel.h"
#import "LoanZen_SupHomeService.h"
#import "LoanZen_SupHomeParser.h"
#import "LoanZen_ProductService.h"
#import "LoanZen_UserService.h"
#import "LoanZen_CredentialStore.h"
#import "LoanZen_SessionStore.h"
#import "LoanZen_CheckInStore.h"
#import "LoanZen_RejectH5Navigator.h"

static const NSInteger kLZUnknownUserStatus = NSIntegerMax;

@interface LoanZen_HomeViewModel ()
@property (nonatomic, copy, readwrite) NSString *welcomeText;
@property (nonatomic, copy, readwrite) NSString *kycHint;
@property (nonatomic, copy, readwrite) NSArray<NSDictionary *> *products;
@property (nonatomic, assign, readwrite) NSInteger userStatus;
@property (nonatomic, copy, readwrite, nullable) NSString *withdrawalOrderId;
@property (nonatomic, assign, readwrite) BOOL kycJumpEnabled;
@property (nonatomic, assign, readwrite) BOOL pendingKyc;
@property (nonatomic, assign, readwrite) BOOL hideCenterAndApply;
@property (nonatomic, assign, readwrite) NSInteger checkInCompletedDays;
@property (nonatomic, assign, readwrite) BOOL hasCheckedInToday;
@end

@implementation LoanZen_HomeViewModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _welcomeText = @"";
        _kycHint = @"";
        _products = @[];
        _userStatus = kLZUnknownUserStatus;
    }
    return self;
}

- (void)LZ_loadHomeData {
    [self LZ_refreshWithLoading:NO];
}

- (void)LZ_showGuestHome {
    [self LZ_applyGuestState];
}

- (void)LZ_applyGuestState {
    self.userStatus = 10;
    self.withdrawalOrderId = nil;
    // 对齐 LoanBase：未登录不显示消息框箭头、不可点跳转
    self.kycJumpEnabled = NO;
    self.pendingKyc = YES;
    self.hideCenterAndApply = NO;
    self.products = @[];
    self.kycHint = @"Please submit your KYC certification information for review.";
    self.welcomeText = [self LZ_appDisplayName];
    [self LZ_refreshCheckInState];
    [self LZ_notifyStateChanged];
}

- (void)LZ_refreshCheckInState {
    if (LoanZen_CredentialStore.token.length == 0) {
        self.checkInCompletedDays = 0;
        self.hasCheckedInToday = NO;
        return;
    }
    self.checkInCompletedDays = [LoanZen_CheckInStore LZ_completedDays];
    self.hasCheckedInToday = [LoanZen_CheckInStore LZ_hasCheckedInToday];
}

- (BOOL)LZ_performCheckIn {
    if (LoanZen_CredentialStore.token.length == 0) return NO;
    BOOL success = [LoanZen_CheckInStore LZ_checkInTodayIfNeeded];
    [self LZ_refreshCheckInState];
    [self LZ_notifyStateChanged];
    return success;
}

- (void)LZ_applySuphome:(NSDictionary *)data {
    self.userStatus = [LoanZen_SupHomeParser LZ_userStatusFromData:data];
    self.withdrawalOrderId = [LoanZen_SupHomeParser LZ_withdrawalOrderIdFromData:data];
    if (self.userStatus == 51) {
        self.kycJumpEnabled = [LoanZen_RejectH5Navigator LZ_hasURL];
    } else {
        self.kycJumpEnabled = [LoanZen_SupHomeParser LZ_canJumpByUserStatus:self.userStatus];
    }
    self.pendingKyc = (self.userStatus == 10);
    self.hideCenterAndApply = (self.userStatus != kLZUnknownUserStatus && self.userStatus != 10);
    self.welcomeText = [self LZ_resolvedWelcomeNameFromSuphome:data];

    NSString *prompt = [LoanZen_SupHomeParser LZ_promptCopyFromData:data];
    if (prompt.length > 0) {
        self.kycHint = prompt;
    } else if (self.pendingKyc) {
        self.kycHint = @"Please submit your KYC certification information for review";
    } else {
        self.kycHint = @"";
    }
}

- (NSString *)LZ_appDisplayName {
    NSString *name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (name.length == 0) name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    return name.length > 0 ? name : @"Kodeza Cash";
}

- (NSString *)LZ_resolvedWelcomeNameFromSuphome:(NSDictionary *)data {
    NSString *name = [LoanZen_SupHomeParser LZ_displayNameFromData:data];
    if (name.length == 0) name = LoanZen_SessionStore.shared.userName;
    NSString *trimmed = [name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    // 无名称或占位文案时回退 APP 名称（对齐 Me 页）
    if (trimmed.length == 0 || [trimmed isEqualToString:@"User name"]) {
        return [self LZ_appDisplayName];
    }
    return trimmed;
}

- (void)LZ_reloadProductsAfterSuphome:(NSDictionary *)data {
    if (self.pendingKyc) {
        self.products = @[];
        [self LZ_notifyStateChanged];
        return;
    }
    [LoanZen_ProductService LZ_fetchProductListWithCompletion:^(NSArray<NSDictionary *> *list, NSError *error) {
        if (list.count > 0) {
            self.products = list;
        } else {
            NSArray *embedded = [data[@"productList"] isKindOfClass:[NSArray class]] ? data[@"productList"] : nil;
            if (embedded.count > 0) {
                NSMutableArray *mapped = [NSMutableArray array];
                for (NSDictionary *item in embedded) {
                    [mapped addObject:[LoanZen_ProductService LZ_mapProductItem:item]];
                }
                self.products = mapped;
            } else {
                self.products = @[];
            }
        }
        [self LZ_notifyStateChanged];
    }];
}

- (void)LZ_reloadFromCachedSuphome {
    if (LoanZen_CredentialStore.token.length == 0) {
        [self LZ_applyGuestState];
        return;
    }
    [self LZ_refreshCheckInState];
    NSDictionary *data = [LoanZen_SupHomeStore LZ_lastResponse];
    if (![data isKindOfClass:[NSDictionary class]]) {
        [self LZ_refreshWithLoading:NO];
        return;
    }
    [self LZ_applySuphome:data];
    [self LZ_reloadProductsAfterSuphome:data];
}

- (void)LZ_refreshWithLoading:(BOOL)loading {
    if (LoanZen_CredentialStore.token.length == 0) {
        [self LZ_applyGuestState];
        return;
    }
    [self LZ_refreshCheckInState];
    [LoanZen_UserService LZ_fetchUserInfoWithCompletion:^(NSDictionary *user, NSError *error) {
        if (!error) {
            self.welcomeText = [self LZ_resolvedWelcomeNameFromSuphome:nil];
            [self LZ_notifyStateChanged];
        }
    }];
    [LoanZen_SupHomeService LZ_refreshIfLoggedInWithShowLoading:loading completion:^(NSDictionary *data, NSError *error) {
        if (!data) {
            // 对齐 LoanBase：接口失败时隐藏消息框箭头
            self.kycJumpEnabled = NO;
            [self LZ_notifyStateChanged];
            return;
        }
        [self LZ_applySuphome:data];
        [self LZ_reloadProductsAfterSuphome:data];
    }];
}

@end
