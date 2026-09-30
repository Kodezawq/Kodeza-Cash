#import "LoanZen_ViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_OrdersViewModel : LoanZen_ViewModel

@property (nonatomic, assign, readonly) NSInteger selectedTabIndex;
@property (nonatomic, copy, readonly) NSArray<NSDictionary *> *displayCards;

- (NSArray<NSString *> *)LZ_tabTitles;
- (void)LZ_selectTabIndex:(NSInteger)index;
- (void)LZ_loadOrdersWithLoading:(BOOL)showLoading;

@end

NS_ASSUME_NONNULL_END
