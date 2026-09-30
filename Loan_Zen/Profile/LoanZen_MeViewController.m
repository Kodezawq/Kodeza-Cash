#import "LoanZen_MeViewController.h"
#import "LoanZen_MeRootView.h"
#import "LoanZen_MeViewModel.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_PopupHelper.h"
#import "LoanZen_AppConfigStore.h"
#import "LoanZen_BankListViewController.h"
#import "LoanZen_ContactUsViewController.h"
#import "LoanZen_FeedbackViewController.h"
#import "LoanZen_RepaymentViewController.h"
#import "LoanZen_AboutViewController.h"
#import "LoanZen_OfficialWebsiteViewController.h"
#import "LoanZen_WebDocumentViewController.h"

@interface LoanZen_MeViewController () <LoanZen_MeRootViewDelegate>
@property (nonatomic, strong) LoanZen_MeRootView *rootView;
@property (nonatomic, strong) LoanZen_MeViewModel *meViewModel;
@end

@implementation LoanZen_MeViewController

- (void)loadView {
    self.rootView = [[LoanZen_MeRootView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.view = self.rootView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    self.meViewModel = [[LoanZen_MeViewModel alloc] init];
    self.viewModel = self.meViewModel;
    self.rootView.delegate = self;
    [self LZ_bindViewModel];
    [self.meViewModel LZ_loadProfile];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.meViewModel LZ_refreshUserInfo];
}

- (void)LZ_onViewModelStateChanged {
    [self.rootView LZ_renderWithName:self.meViewModel.userName
                               phone:self.meViewModel.mobileDisplay
                           menuItems:self.meViewModel.menuItems];
}

#pragma mark - LoanZen_MeRootViewDelegate

- (void)LZ_meRootViewDidTapBankAccount:(UIView *)view {
    [self.navigationController pushViewController:[[LoanZen_BankListViewController alloc] init] animated:YES];
}

- (void)LZ_meRootView:(UIView *)view didSelectMenuAction:(NSString *)actionKey {
    UIViewController *vc = nil;
    if ([actionKey isEqualToString:@"contact"]) vc = [[LoanZen_ContactUsViewController alloc] init];
    else if ([actionKey isEqualToString:@"feedback"]) vc = [[LoanZen_FeedbackViewController alloc] init];
    else if ([actionKey isEqualToString:@"repayment"]) vc = [[LoanZen_RepaymentViewController alloc] init];
    else if ([actionKey isEqualToString:@"about"]) vc = [[LoanZen_AboutViewController alloc] init];
    else if ([actionKey isEqualToString:@"privacy"]) {
        vc = [[LoanZen_WebDocumentViewController alloc] initWithURLString:[LoanZen_AppConfigStore LZ_resolvedPrivacyPolicyURL] title:@"Privacy policy"];
    } else if ([actionKey isEqualToString:@"terms"]) {
        vc = [[LoanZen_WebDocumentViewController alloc] initWithURLString:[LoanZen_AppConfigStore LZ_resolvedTermsURL] title:@"Terms of the loan"];
    } else if ([actionKey isEqualToString:@"website"]) {
        vc = [[LoanZen_OfficialWebsiteViewController alloc] init];
    }
    if (vc) [self.navigationController pushViewController:vc animated:YES];
}

- (void)LZ_meRootViewDidTapSignOut:(UIView *)view {
    [LoanZen_PopupHelper LZ_showConfirmOn:self
                                    title:@"Sign out"
                                  message:@"Do you want to sign out of your Kodeza Cash account?"
                             confirmTitle:@"Confirm"
                              cancelTitle:@"Cancel"
                                 iconName:@"lz_tk_tc"
                                onConfirm:^{
        [self.meViewModel LZ_logout];
    }];
}

@end
