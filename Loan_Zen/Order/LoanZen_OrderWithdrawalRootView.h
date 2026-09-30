#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class LoanZen_OrderWithdrawalRootView;

@protocol LoanZen_OrderWithdrawalRootViewDelegate <NSObject>
- (void)LZ_withdrawalRootViewDidTapAmount:(UIView *)view;
- (void)LZ_withdrawalRootView:(LoanZen_OrderWithdrawalRootView *)view didSelectAmountAtIndex:(NSInteger)index;
- (void)LZ_withdrawalRootViewDidTapTerm:(UIView *)view;
- (void)LZ_withdrawalRootViewDidTapWithdraw:(UIView *)view;
@end

@interface LoanZen_OrderWithdrawalRootView : UIView

@property (nonatomic, weak, nullable) id<LoanZen_OrderWithdrawalRootViewDelegate> delegate;

- (void)LZ_configureWithProductName:(NSString *)productName
                             amount:(NSString *)amount
                               term:(NSString *)term
                      scheduleItems:(NSArray<NSDictionary *> *)scheduleItems;

- (void)LZ_configureWithProductName:(NSString *)productName
                             amount:(NSString *)amount
                               term:(NSString *)term
                     amountReceived:(NSString *)amountReceived
                          serviceFee:(NSString *)serviceFee
                            interest:(NSString *)interest
                     applicationDate:(NSString *)applicationDate
                             dueDate:(NSString *)dueDate
                       scheduleItems:(NSArray<NSDictionary *> *)scheduleItems
                    maskedCardNumber:(NSString *)maskedCardNumber
                    amountSelectable:(BOOL)amountSelectable
                      termSelectable:(BOOL)termSelectable
                       amountOptions:(NSArray<NSString *> *)amountOptions
                 selectedAmountIndex:(NSInteger)selectedAmountIndex;

- (void)LZ_updateDisplayedAmount:(NSString *)amount term:(NSString *)term;

@end

NS_ASSUME_NONNULL_END
