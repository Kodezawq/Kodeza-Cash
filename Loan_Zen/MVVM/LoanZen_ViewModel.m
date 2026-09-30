#import "LoanZen_ViewModel.h"

@implementation LoanZen_ViewModel

- (void)LZ_notifyStateChanged {
    if (self.onStateChanged) self.onStateChanged();
}

- (void)LZ_notifyError:(NSString *)message {
    if (self.onErrorMessage) self.onErrorMessage(message);
}

- (void)LZ_notifySuccess:(NSString *)message {
    if (self.onSuccessMessage) self.onSuccessMessage(message);
}

@end
