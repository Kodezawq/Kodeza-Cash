#import "LoanZen_MainTabController.h"
#import "LoanZen_BottomBarView.h"
#import "LoanZen_LoginGatekeeper.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_HomeViewController.h"
#import "LoanZen_OrdersViewController.h"
#import "LoanZen_EMIViewController.h"
#import "LoanZen_MeViewController.h"
#import "LoanZen_Notifications.h"
#import "LoanZen_AppConfigRefresher.h"
@import Masonry;

@interface LoanZen_MainTabController ()
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) LoanZen_BottomBarView *bottomBar;
@property (nonatomic, strong) NSArray<UINavigationController *> *navigations;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, strong) MASConstraint *contentBottomToBar;
@property (nonatomic, strong) MASConstraint *contentBottomToSuperview;
@property (nonatomic, strong) id logoutObserver;
@property (nonatomic, weak) UIView *overlayOrderSubmitMaskView;
@end

@implementation LoanZen_MainTabController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [LoanZen_Color background];
    [LoanZen_AppConfigRefresher LZ_refreshIfPossible];

    self.contentView = [[UIView alloc] init];
    self.bottomBar = [[LoanZen_BottomBarView alloc] init];
    [self.view addSubview:self.contentView];
    [self.view addSubview:self.bottomBar];

    [self.bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view).inset(LZ_SizePageInset);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        make.height.mas_equalTo(LZ_SizeBottomBarHeight);
    }];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        self.contentBottomToBar = make.bottom.equalTo(self.bottomBar.mas_top);
        self.contentBottomToSuperview = make.bottom.equalTo(self.view);
    }];
    [self.contentBottomToSuperview deactivate];

    UINavigationController *loan = [[UINavigationController alloc] initWithRootViewController:[[LoanZen_HomeViewController alloc] init]];
    UINavigationController *orders = [[UINavigationController alloc] initWithRootViewController:[[LoanZen_OrdersViewController alloc] init]];
    UINavigationController *emi = [[UINavigationController alloc] initWithRootViewController:[[LoanZen_EMIViewController alloc] init]];
    UINavigationController *me = [[UINavigationController alloc] initWithRootViewController:[[LoanZen_MeViewController alloc] init]];
    self.navigations = @[loan, orders, emi, me];
    self.selectedIndex = 0;

    for (UINavigationController *nav in self.navigations) {
        nav.delegate = self;
        [self addChildViewController:nav];
        [self.contentView addSubview:nav.view];
        [nav.view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView);
        }];
        [nav didMoveToParentViewController:self];
        nav.view.hidden = YES;
    }
    loan.view.hidden = NO;

    __weak typeof(self) weakSelf = self;
    self.bottomBar.onSelectTab = ^(LoanZen_BottomTab tab) {
        [weakSelf LZ_handleBottomTab:tab];
    };

    __weak typeof(self) weakSelfForLogout = self;
    self.logoutObserver = [NSNotificationCenter.defaultCenter addObserverForName:LZ_NotificationLogoutDidFinish object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
        [weakSelfForLogout LZ_switchToHomeTab];
    }];
}

- (void)dealloc {
    if (self.logoutObserver) {
        [NSNotificationCenter.defaultCenter removeObserver:self.logoutObserver];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.view bringSubviewToFront:self.bottomBar];
    if (self.overlayOrderSubmitMaskView && !self.overlayOrderSubmitMaskView.hidden) {
        [self.view bringSubviewToFront:self.overlayOrderSubmitMaskView];
    }
}

- (void)LZ_setOverlayOrderSubmitMask:(UIView *)maskView {
    if (self.overlayOrderSubmitMaskView == maskView) {
        if (!maskView) {
            [self.overlayOrderSubmitMaskView removeFromSuperview];
            self.overlayOrderSubmitMaskView = nil;
        }
        return;
    }
    [self.overlayOrderSubmitMaskView removeFromSuperview];
    self.overlayOrderSubmitMaskView = maskView;
    if (!maskView) return;
    if (maskView.superview != self.view) {
        [maskView removeFromSuperview];
        [self.view addSubview:maskView];
    }
    [maskView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    maskView.hidden = NO;
    [self.view bringSubviewToFront:maskView];
}

- (NSInteger)LZ_indexForTab:(LoanZen_BottomTab)tab {
    switch (tab) {
        case LoanZen_BottomTabLoan: return 0;
        case LoanZen_BottomTabOrder: return 1;
        case LoanZen_BottomTabEMI: return 2;
        case LoanZen_BottomTabMe: return 3;
    }
    return 0;
}

- (void)LZ_handleBottomTab:(LoanZen_BottomTab)tab {
    if ([LoanZen_LoginGatekeeper LZ_requireLoginIfNeededFrom:self]) return;
    NSInteger idx = [self LZ_indexForTab:tab];
    if (idx == self.selectedIndex) return;
    self.navigations[self.selectedIndex].view.hidden = YES;
    self.selectedIndex = idx;
    self.navigations[idx].view.hidden = NO;
    [self LZ_refreshBottomBarVisibility];
    if (idx == 0) {
        [self LZ_refreshHomeIfVisible];
    }
}

- (void)LZ_switchToHomeTab {
    if (self.selectedIndex != 0) {
        self.navigations[self.selectedIndex].view.hidden = YES;
        self.selectedIndex = 0;
        self.navigations[0].view.hidden = NO;
    }
    self.bottomBar.selectedTab = LoanZen_BottomTabLoan;
    [self LZ_refreshBottomBarVisibility];
    [self LZ_refreshHomeIfVisible];
}

- (void)LZ_refreshHomeIfVisible {
    UINavigationController *homeNav = self.navigations.firstObject;
    UIViewController *root = homeNav.viewControllers.firstObject;
    if ([root isKindOfClass:[LoanZen_HomeViewController class]]) {
        [(LoanZen_HomeViewController *)root LZ_refreshOnTabSelected];
    }
}

- (void)LZ_switchToOrderTabWithRequestStatus:(NSInteger)requestStatus {
    NSInteger orderTabIndex = [self LZ_indexForTab:LoanZen_BottomTabOrder];
    UINavigationController *ordersNav = self.navigations[orderTabIndex];
    if (ordersNav.viewControllers.count > 1) {
        [ordersNav popToRootViewControllerAnimated:NO];
    }
    
    if (self.selectedIndex != orderTabIndex) {
        self.navigations[self.selectedIndex].view.hidden = YES;
        self.selectedIndex = orderTabIndex;
        ordersNav.view.hidden = NO;
    }
    self.bottomBar.selectedTab = LoanZen_BottomTabOrder;
    [self LZ_refreshBottomBarVisibility];

    UIViewController *root = ordersNav.viewControllers.firstObject;
    if ([root isKindOfClass:[LoanZen_OrdersViewController class]]) {
        [(LoanZen_OrdersViewController *)root LZ_switchToTabWithRequestStatus:requestStatus];
    }
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (navigationController != self.navigations[self.selectedIndex]) return;
    BOOL hide = viewController != navigationController.viewControllers.firstObject;
    [UIView performWithoutAnimation:^{
        [self LZ_updateBottomBarHidden:hide];
        [self.view layoutIfNeeded];
    }];
}

- (void)LZ_refreshBottomBarIfNeeded {
    [self LZ_refreshBottomBarVisibility];
}

- (void)LZ_refreshBottomBarVisibility {
    UINavigationController *nav = self.navigations[self.selectedIndex];
    UIViewController *top = nav.viewControllers.lastObject ?: nav.viewControllers.firstObject;
    BOOL hide = top && top != nav.viewControllers.firstObject;
    [self LZ_updateBottomBarHidden:hide];
}

- (void)LZ_updateBottomBarHidden:(BOOL)hide {
    self.bottomBar.hidden = hide;
    if (hide) {
        [self.contentBottomToBar deactivate];
        [self.contentBottomToSuperview activate];
    } else {
        [self.contentBottomToSuperview deactivate];
        [self.contentBottomToBar activate];
    }
}

@end
