#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_OrderDetailPenRow : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *value;
@property (nonatomic, assign) BOOL valueIsAccentTerm;
@property (nonatomic, assign) BOOL valueIsSuccess;
@property (nonatomic, assign) BOOL showsInfoGlyph;
@property (nonatomic, copy, nullable) NSString *tipMessage;
+ (instancetype)LZ_rowWithTitle:(NSString *)title value:(NSString *)value;
@end

@interface LoanZen_OrderDetailRootView : UIView

- (void)LZ_setRepayAction:(nullable void (^)(void))action;
- (void)LZ_setDeferAction:(nullable void (^)(void))action;
- (void)LZ_setPrimaryActionWithTitle:(nullable NSString *)title action:(nullable void (^)(void))action;
- (void)LZ_setActionVisibilityShowRepay:(BOOL)showRepay showDefer:(BOOL)showDefer;

- (void)LZ_configureWithTipMessage:(NSString *)tipMessage
                       productName:(NSString *)productName
                        loanAmount:(NSString *)loanAmount
                  statusBarImageName:(nullable NSString *)statusBarImageName
                        detailRows:(NSArray<LoanZen_OrderDetailPenRow *> *)detailRows
                     scheduleItems:(NSArray<NSDictionary *> *)scheduleItems
                  maskedCardNumber:(NSString *)maskedCardNumber;

@end

NS_ASSUME_NONNULL_END
