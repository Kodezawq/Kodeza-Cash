#import "LoanZen_BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

/// 拒量推荐 H5（对齐 LoanEase `LERejectH5WebViewController`，UI 用 Loan_Zen Scaffold）
@interface LoanZen_RejectH5ViewController : LoanZen_BaseViewController

- (instancetype)initWithURL:(NSURL *)url NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
