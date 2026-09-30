#import "LoanZen_HomeViewController.h"
#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_HomeRootView.h"
#import "LoanZen_HomeViewModel.h"
#import "LoanZen_HUD.h"
#import "LoanZen_LoginGatekeeper.h"
#import "LoanZen_KYCFourFlowNavigator.h"
#import "LoanZen_LoanConfirmationViewController.h"
#import "LoanZen_BuryReporter.h"
#import "LoanZen_AdjustUserInfoSync.h"
#import "LoanZen_Notifications.h"
#import "LoanZen_ProductService.h"
#import "LoanZen_TermBusinessHelper.h"
#import "LoanZen_RejectH5Navigator.h"
#import "LoanZen_SupHomeService.h"
#import "LoanZen_SupHomeParser.h"
#import "LoanZen_SessionStore.h"
#import "LoanZen_OrderSubmitMaskView.h"
#import "LoanZen_MainTabController.h"
#import "LoanZen_NetworkPermissionMonitor.h"
#import "LoanZen_DeviceIdentity.h"
@import Masonry;

@interface LoanZen_HomeViewController () <LoanZen_HomeRootViewDelegate>
@property (nonatomic, strong) LoanZen_HomeRootView *rootView;
@property (nonatomic, strong) LoanZen_HomeViewModel *homeViewModel;
@property (nonatomic, strong) LoanZen_OrderSubmitMaskView *orderSubmitMaskView;
@property (nonatomic, assign) BOOL didShowPendingWithdrawalPopupThisAppear;
@property (nonatomic, assign) BOOL networkPermissionGranted;
@property (nonatomic, strong) id homeRefreshObserver;
@property (nonatomic, strong) id loginSuccessObserver;
@property (nonatomic, strong) id logoutObserver;
@property (nonatomic, strong) id appDidBecomeActiveObserver;
@end

@implementation LoanZen_HomeViewController

- (void)loadView {
    self.rootView = [[LoanZen_HomeRootView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.view = self.rootView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.homeViewModel = [[LoanZen_HomeViewModel alloc] init];
    self.viewModel = self.homeViewModel;
    [self LZ_bindViewModel];
    self.rootView.delegate = self;
    [self LZ_setupOrderSubmitMaskIfNeeded];

    __weak typeof(self) weakSelf = self;
    [LoanZen_NetworkPermissionMonitor LZ_whenNetworkAvailable:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.networkPermissionGranted = YES;
        [self LZ_tryStartIDFAFlowIfNeededWithRetryCount:5];
    }];
    self.homeRefreshObserver = [NSNotificationCenter.defaultCenter addObserverForName:LZ_NotificationHomeShouldRefresh object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
        if (!LoanZen_SessionStore.shared.isLoggedIn) {
            [weakSelf.homeViewModel LZ_showGuestHome];
            return;
        }
        if ([note.userInfo[LZ_NotificationUserInfoSuphomePrefetched] boolValue]) {
            [weakSelf.homeViewModel LZ_reloadFromCachedSuphome];
        } else {
            [weakSelf.homeViewModel LZ_refreshWithLoading:NO];
        }
    }];
    self.loginSuccessObserver = [NSNotificationCenter.defaultCenter addObserverForName:LZ_NotificationLoginDidSucceed object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
        (void)note;
        [weakSelf.homeViewModel LZ_refreshWithLoading:YES];
        [LoanZen_AdjustUserInfoSync LZ_scheduleUserInfoReport];
    }];
    self.appDidBecomeActiveObserver = [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
        (void)note;
        [weakSelf LZ_tryStartIDFAFlowIfNeededWithRetryCount:5];
    }];
    self.logoutObserver = [NSNotificationCenter.defaultCenter addObserverForName:LZ_NotificationLogoutDidFinish object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
        (void)note;
        [weakSelf.homeViewModel LZ_showGuestHome];
    }];
}

- (void)dealloc {
    if (self.homeRefreshObserver) {
        [NSNotificationCenter.defaultCenter removeObserver:self.homeRefreshObserver];
    }
    if (self.loginSuccessObserver) {
        [NSNotificationCenter.defaultCenter removeObserver:self.loginSuccessObserver];
    }
    if (self.logoutObserver) {
        [NSNotificationCenter.defaultCenter removeObserver:self.logoutObserver];
    }
    if (self.appDidBecomeActiveObserver) {
        [NSNotificationCenter.defaultCenter removeObserver:self.appDidBecomeActiveObserver];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.didShowPendingWithdrawalPopupThisAppear = NO;
    [self LZ_refreshOnTabSelected];
}

- (void)LZ_refreshOnTabSelected {
    if (!LoanZen_SessionStore.shared.isLoggedIn) {
        [self.homeViewModel LZ_showGuestHome];
        return;
    }
    [self.homeViewModel LZ_refreshWithLoading:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self LZ_tryStartIDFAFlowIfNeededWithRetryCount:5];
    if (!LoanZen_SessionStore.shared.isLoggedIn) return;
    [LoanZen_AdjustUserInfoSync LZ_scheduleUserInfoReport];
}

- (void)LZ_tryStartIDFAFlowIfNeededWithRetryCount:(NSInteger)retriesLeft {
    if (!self.networkPermissionGranted) return;
    if (retriesLeft <= 0) return;
    if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive) return;

    if (![LoanZen_DeviceIdentity LZ_needsIDFAAuthorizationPrompt]) {
        if (LoanZen_SessionStore.shared.isLoggedIn) {
            [LoanZen_AdjustUserInfoSync LZ_scheduleUserInfoReport];
        }
        return;
    }

    __weak typeof(self) weakSelf = self;
    [LoanZen_DeviceIdentity LZ_requestIDFAAuthorizationIfNeededWithCompletion:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if ([LoanZen_DeviceIdentity LZ_needsIDFAAuthorizationPrompt]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self LZ_tryStartIDFAFlowIfNeededWithRetryCount:retriesLeft - 1];
            });
            return;
        }
        if (LoanZen_SessionStore.shared.isLoggedIn) {
            [LoanZen_AdjustUserInfoSync LZ_scheduleUserInfoReport];
        }
    }];
}

- (void)LZ_onViewModelStateChanged {
    [self.rootView LZ_renderWithWelcome:self.homeViewModel.welcomeText
                                kycHint:self.homeViewModel.kycHint
                               products:self.homeViewModel.products
                         kycJumpEnabled:self.homeViewModel.kycJumpEnabled
                              pendingKyc:self.homeViewModel.pendingKyc
                      hideCenterAndApply:self.homeViewModel.hideCenterAndApply
                    checkInCompletedDays:self.homeViewModel.checkInCompletedDays
                       hasCheckedInToday:self.homeViewModel.hasCheckedInToday];
    [self LZ_maybeShowPendingWithdrawalPopupIfNeeded];
}

- (void)LZ_maybeShowPendingWithdrawalPopupIfNeeded {
    if (self.didShowPendingWithdrawalPopupThisAppear) return;
    if (self.homeViewModel.userStatus != 32) return;
    NSString *orderId = self.homeViewModel.withdrawalOrderId;
    if (orderId.length == 0) return;
    self.didShowPendingWithdrawalPopupThisAppear = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.presentedViewController) return;
        [LoanZen_TermBusinessHelper LZ_presentPendingWithdrawalFrom:self productId:nil orderId:orderId];
    });
}

#pragma mark - Order submit mask

- (void)LZ_setupOrderSubmitMaskIfNeeded {
    self.orderSubmitMaskView = [[LoanZen_OrderSubmitMaskView alloc] init];
    self.orderSubmitMaskView.hidden = YES;
}

- (LoanZen_OrderSubmitMaskView *)LZ_orderSubmitMaskView {
    if (!self.orderSubmitMaskView) {
        [self LZ_setupOrderSubmitMaskIfNeeded];
    }
    return self.orderSubmitMaskView;
}

- (LoanZen_MainTabController *)LZ_mainTabController {
    UIResponder *responder = self.nextResponder;
    while (responder) {
        if ([responder isKindOfClass:[LoanZen_MainTabController class]]) {
            return (LoanZen_MainTabController *)responder;
        }
        responder = responder.nextResponder;
    }
    return nil;
}

- (void)LZ_showOrderSubmitMask {
    LoanZen_OrderSubmitMaskView *mask = [self LZ_orderSubmitMaskView];
    mask.hidden = NO;
    LoanZen_MainTabController *tab = [self LZ_mainTabController];
    if (tab) {
        [tab LZ_setOverlayOrderSubmitMask:mask];
        return;
    }
    if (mask.superview != self.view) {
        [mask removeFromSuperview];
        [self.view addSubview:mask];
    }
    [mask mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self.view bringSubviewToFront:mask];
}

- (void)LZ_hideOrderSubmitMask {
    self.orderSubmitMaskView.hidden = YES;
    LoanZen_MainTabController *tab = [self LZ_mainTabController];
    if (tab) {
        [tab LZ_setOverlayOrderSubmitMask:nil];
    }
}

#pragma mark - LoanZen_HomeRootViewDelegate

- (void)LZ_homeRootViewDidTapApply:(UIView *)view {
    if ([LoanZen_LoginGatekeeper LZ_requireLoginIfNeededFrom:self]) return;
    [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventClickHomePageButton];
    [self LZ_startKYCFlow];
}

- (void)LZ_homeRootViewDidTapCheckIn:(UIView *)view {
    if ([LoanZen_LoginGatekeeper LZ_requireLoginIfNeededFrom:self]) return;
    if (self.homeViewModel.hasCheckedInToday) {
        [LoanZen_HUD LZ_showError:@"You have already checked in today."];
        return;
    }
    if ([self.homeViewModel LZ_performCheckIn]) {
        [LoanZen_HUD LZ_showSuccess:@"Check-in successful"];
    }
}

- (void)LZ_homeRootViewDidTapKYC:(UIView *)view {
    if ([LoanZen_LoginGatekeeper LZ_requireLoginIfNeededFrom:self]) return;
    if (!self.homeViewModel.kycJumpEnabled) return;
    [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventClickHomePageButton];
    __weak typeof(self) weakSelf = self;
    [LoanZen_SupHomeService LZ_refreshIfLoggedInWithShowLoading:NO completion:^(NSDictionary *data, NSError *error) {
        __strong typeof(self) self = weakSelf;
        if (!self) return;
        NSDictionary *snapshot = data ?: [LoanZen_SupHomeStore LZ_lastResponse];
        NSInteger status = [LoanZen_SupHomeParser LZ_userStatusFromData:snapshot];
        if (status == NSIntegerMax) status = self.homeViewModel.userStatus;
        if (status == 51) {
            if ([LoanZen_RejectH5Navigator LZ_hasURL]) {
                [LoanZen_RejectH5Navigator LZ_openFrom:self message:nil];
            }
            return;
        }
        if (![LoanZen_SupHomeParser LZ_canJumpByUserStatus:status]) return;
        [self LZ_navigateByUserStatus:status];
    }];
}

- (void)LZ_homeRootView:(UIView *)view didSelectProductAtIndex:(NSInteger)index {
    if ([LoanZen_LoginGatekeeper LZ_requireLoginIfNeededFrom:self]) return;
    if (index >= self.homeViewModel.products.count) return;
    NSString *productId = self.homeViewModel.products[index][@"productId"];
    if (productId.length == 0) {
        [self LZ_startKYCFlow];
        return;
    }
    [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventClickHomePageButton];
    [LoanZen_ProductService LZ_fetchProductTermEnvelopeWithProductId:productId showLoading:YES completion:^(NSDictionary *json, NSError *error) {
        if (error) {
            [LoanZen_HUD LZ_showError:error.localizedDescription];
            return;
        }
        BOOL handled = [LoanZen_TermBusinessHelper LZ_handleTermResponse:json controller:self productId:productId onSuccess:^(NSDictionary *termData) {
            LoanZen_LoanConfirmationViewController *vc = [[LoanZen_LoanConfirmationViewController alloc] initWithProductId:productId];
            [self.navigationController pushViewController:vc animated:YES];
        }];
        if (!handled) {
            NSString *msg = json[@"message"] ?: json[LZAPIResponseResultMsg];
            if (msg.length > 0) {
                [LoanZen_HUD LZ_showError:msg];
            }
        }
    }];
}

#pragma mark - Navigation

- (void)LZ_startKYCFlow {
    [LoanZen_KYCFourFlowNavigator LZ_enterFlowFrom:self animated:YES];
}

- (void)LZ_navigateByUserStatus:(NSInteger)userStatus {
    switch (userStatus) {
        case 80:
        case 81:
            [LoanZen_TermBusinessHelper LZ_navigateToOrdersWithRequestStatus:20 from:self];
            break;
        case 30:
        case 32:
        case 41:
            [LoanZen_TermBusinessHelper LZ_navigateToOrdersWithRequestStatus:10 from:self];
            break;
        case 10:
            [self LZ_startKYCFlow];
            break;
        case 51:
            [LoanZen_RejectH5Navigator LZ_openFrom:self message:nil];
            break;
        default:
            break;
    }
}

@end
