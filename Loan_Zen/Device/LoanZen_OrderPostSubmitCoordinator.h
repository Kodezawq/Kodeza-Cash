#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_OrderPostSubmitCoordinator : NSObject

/// 下单成功后：设备 → 通讯录（可选/分批）→ order/ready
/// contactsBlocked=YES 表示强抓通讯录失败或用户关闭引导；产品详情页退出并刷新首页，订单详情页 pop。
+ (void)LZ_processOrderId:(NSString *)orderId
                presenter:(UIViewController *)presenter
                 maskView:(UIView * _Nullable)maskView
               completion:(void (^ _Nullable)(BOOL success, BOOL contactsBlocked))completion;

@end

NS_ASSUME_NONNULL_END
