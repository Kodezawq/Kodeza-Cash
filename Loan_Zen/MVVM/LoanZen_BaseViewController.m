#import "LoanZen_BaseViewController.h"

@implementation LoanZen_BaseViewController

- (void)LZ_bindViewModel {
    __weak typeof(self) weakSelf = self;
    self.viewModel.onStateChanged = ^{
        [weakSelf LZ_onViewModelStateChanged];
    };
    self.viewModel.onErrorMessage = ^(NSString *message) {
        [weakSelf LZ_onViewModelError:message];
    };
    self.viewModel.onSuccessMessage = ^(NSString *message) {
        [weakSelf LZ_onViewModelSuccess:message];
    };
}

- (void)LZ_onViewModelStateChanged {}
- (void)LZ_onViewModelError:(NSString *)message {}
- (void)LZ_onViewModelSuccess:(NSString *)message {}

@end
