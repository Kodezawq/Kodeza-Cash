#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class LoanZen_OrdersRootView;

@protocol LoanZen_OrdersRootViewDelegate <NSObject>
- (void)LZ_ordersRootView:(LoanZen_OrdersRootView *)view didSelectTabIndex:(NSInteger)index;
- (void)LZ_ordersRootView:(LoanZen_OrdersRootView *)view didSelectOrderAtIndex:(NSInteger)index;
@end

@interface LoanZen_OrdersRootView : UIView

@property (nonatomic, weak, nullable) id<LoanZen_OrdersRootViewDelegate> delegate;
@property (nonatomic, strong, readonly) UITableView *tableView;

- (void)LZ_renderTabs:(NSArray<NSString *> *)titles selectedIndex:(NSInteger)selectedIndex;
- (void)LZ_reloadCards:(NSArray<NSDictionary *> *)cards;

@end

NS_ASSUME_NONNULL_END
