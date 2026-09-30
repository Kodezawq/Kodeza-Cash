#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_MainTabController : UIViewController <UINavigationControllerDelegate>

- (void)LZ_refreshBottomBarIfNeeded;

/// 切换到 TabBar 首页 Tab。
- (void)LZ_switchToHomeTab;

/// 切换到 TabBar 订单页，并选中对应状态子 Tab。
- (void)LZ_switchToOrderTabWithRequestStatus:(NSInteger)requestStatus;

/// 首页下单遮罩需盖在 content + bottomBar 之上；传 nil 清除。
- (void)LZ_setOverlayOrderSubmitMask:(UIView * _Nullable)maskView;

@end

NS_ASSUME_NONNULL_END
