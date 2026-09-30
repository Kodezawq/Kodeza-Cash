#import "LoanZen_BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class LoanZen_OrderSubmitMaskView;

@interface LoanZen_HomeViewController : LoanZen_BaseViewController

- (LoanZen_OrderSubmitMaskView *)LZ_orderSubmitMaskView;
- (void)LZ_showOrderSubmitMask;
- (void)LZ_hideOrderSubmitMask;
/// TabBar 切到首页时刷新首页接口（custom tab 用 hidden，不会走 viewWillAppear）
- (void)LZ_refreshOnTabSelected;

@end

NS_ASSUME_NONNULL_END
