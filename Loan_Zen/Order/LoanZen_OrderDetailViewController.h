#import "LoanZen_BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class LoanZen_OrderSubmitMaskView;

@interface LoanZen_OrderDetailViewController : LoanZen_BaseViewController
- (instancetype)initWithOrderId:(NSString *)orderId productId:(nullable NSString *)productId;
/// HopeLoan `orderType == 1`：6230003 / 待提现场景直接拉提现详情。
- (instancetype)initWithOrderId:(NSString *)orderId productId:(nullable NSString *)productId preferWithdrawal:(BOOL)preferWithdrawal;

- (LoanZen_OrderSubmitMaskView *)LZ_orderSubmitMaskView;
- (void)LZ_showOrderSubmitMask;
- (void)LZ_hideOrderSubmitMask;

@end

NS_ASSUME_NONNULL_END
