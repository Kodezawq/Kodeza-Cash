#import "LoanZen_BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_FaceLivenessCaptureViewController : LoanZen_BaseViewController
- (instancetype)initWithOnConfirmed:(void (^)(NSString *base64, UIImage *preview))onConfirmed;
@end

NS_ASSUME_NONNULL_END
