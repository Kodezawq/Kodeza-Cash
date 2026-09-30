#import "LoanZen_LoginViewController.h"
#import "LoanZen_LoginRootView.h"
#import "LoanZen_LoginViewModel.h"
#import "LoanZen_HUD.h"
#import "LoanZen_BuryReporter.h"
#import "LoanZen_WebDocumentViewController.h"
#import "LoanZen_AppRouter.h"
#import "LoanZen_Notifications.h"
#import "LoanZen_AppConfigRefresher.h"
#import "LoanZen_AppConfigStore.h"

@interface LoanZen_LoginViewController () <LoanZen_LoginRootViewDelegate>
@property (nonatomic, strong) LoanZen_LoginRootView *rootView;
@property (nonatomic, strong) LoanZen_LoginViewModel *loginViewModel;
@property (nonatomic, strong) id loginSuccessObserver;
@end

@implementation LoanZen_LoginViewController

- (void)loadView {
    self.rootView = [[LoanZen_LoginRootView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.view = self.rootView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.loginViewModel = [[LoanZen_LoginViewModel alloc] init];
    self.viewModel = self.loginViewModel;
    [self LZ_bindViewModel];
    self.rootView.delegate = self;
    __weak typeof(self) weakSelf = self;
    self.rootView.onTapPrivacyPolicy = ^{
        [weakSelf LZ_openDocumentWithTitle:@"Privacy Policy" url:[LoanZen_AppConfigStore LZ_resolvedPrivacyPolicyURL]];
    };
    self.rootView.onTapServiceAgreement = ^{
        [weakSelf LZ_openDocumentWithTitle:@"Service Agreement" url:[LoanZen_AppConfigStore LZ_resolvedServiceAgreementURL]];
    };
    [LoanZen_AppConfigRefresher LZ_refreshIfPossible];

    self.loginSuccessObserver = [NSNotificationCenter.defaultCenter addObserverForName:LZ_NotificationLoginDidSucceed object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
        if (weakSelf.presentingViewController) {
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
            return;
        }
        [LoanZen_AppRouter LZ_showMainInterfaceInWindow:weakSelf.view.window];
    }];
}

- (void)dealloc {
    if (self.loginSuccessObserver) {
        [NSNotificationCenter.defaultCenter removeObserver:self.loginSuccessObserver];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)LZ_openDocumentWithTitle:(NSString *)title url:(NSString *)url {
    if (url.length == 0) {
        [LoanZen_HUD LZ_showError:@"Document link is not available yet. Please try again later."];
        return;
    }
    [self.navigationController pushViewController:[[LoanZen_WebDocumentViewController alloc] initWithURLString:url title:title] animated:YES];
}

- (void)LZ_onViewModelStateChanged {
    [self.rootView LZ_setAgreementAccepted:self.loginViewModel.agreementAccepted];
    [self.rootView LZ_updateOTPButtonWithRemaining:self.loginViewModel.otpRemainingSeconds
                                     completedOnce:self.loginViewModel.otpHasCompletedOnce];
}

- (void)LZ_onViewModelError:(NSString *)message {
    [LoanZen_HUD LZ_showError:message];
}

- (void)LZ_onViewModelSuccess:(NSString *)message {
    [LoanZen_HUD LZ_showSuccess:message];
}

#pragma mark - LoanZen_LoginRootViewDelegate

- (void)LZ_loginRootViewDidTapGetOTP:(UIView *)view {
    [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventClickSendOTP];
    [self.loginViewModel LZ_requestOTPWithMobile:self.rootView.mobileField.text ?: @""];
}

- (void)LZ_loginRootViewDidTapSignIn:(UIView *)view {
    [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventClickLogin];
    [self.loginViewModel LZ_setAgreementAccepted:self.rootView.agreementAccepted];
    [self.loginViewModel LZ_signInWithMobile:self.rootView.mobileField.text ?: @"" otp:self.rootView.otpField.text ?: @""];
}

@end
