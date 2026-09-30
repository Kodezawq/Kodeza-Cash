#import "LoanZen_EMIViewController.h"
#import "LoanZen_EMIRootView.h"
#import "LoanZen_EMIViewModel.h"
#import "LoanZen_EMIResultViewController.h"
#import "LoanZen_LoginGatekeeper.h"

@interface LoanZen_EMIViewController () <LoanZen_EMIRootViewDelegate>
@property (nonatomic, strong) LoanZen_EMIRootView *rootView;
@property (nonatomic, strong) LoanZen_EMIViewModel *emiViewModel;
@end

@implementation LoanZen_EMIViewController

- (void)loadView {
    self.rootView = [[LoanZen_EMIRootView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.view = self.rootView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.emiViewModel = [[LoanZen_EMIViewModel alloc] init];
    self.viewModel = self.emiViewModel;
    [self LZ_bindViewModel];
    self.rootView.delegate = self;
    [self.rootView LZ_renderAmount:self.emiViewModel.amount years:self.emiViewModel.years rate:self.emiViewModel.rate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)LZ_onViewModelStateChanged {
    [self.rootView LZ_renderAmount:self.emiViewModel.amount years:self.emiViewModel.years rate:self.emiViewModel.rate];
}

#pragma mark - LoanZen_EMIRootViewDelegate

- (void)LZ_emiRootView:(LoanZen_EMIRootView *)view didChangeAmount:(double)amount years:(NSInteger)years rate:(double)rate {
    self.emiViewModel.amount = amount;
    self.emiViewModel.years = years;
    self.emiViewModel.rate = rate;
}

- (void)LZ_emiRootViewDidSubmit:(LoanZen_EMIRootView *)view {
    if ([LoanZen_LoginGatekeeper LZ_requireLoginIfNeededFrom:self]) return;
    LoanZen_EMIResult *result = [self.emiViewModel LZ_submitResult];
    if (!result) return;
    [self.navigationController pushViewController:[[LoanZen_EMIResultViewController alloc] initWithResult:result] animated:YES];
}

@end
