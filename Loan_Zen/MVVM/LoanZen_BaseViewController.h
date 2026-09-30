#import <UIKit/UIKit.h>
#import "LoanZen_ViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_BaseViewController : UIViewController

@property (nonatomic, strong, nullable) LoanZen_ViewModel *viewModel;

- (void)LZ_bindViewModel;

@end

NS_ASSUME_NONNULL_END
