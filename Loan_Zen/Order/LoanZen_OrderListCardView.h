#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_OrderListCardView : UIView

+ (instancetype)LZ_cardWithProduct:(NSString *)product
                            amount:(NSString *)amount
                    statusBarImage:(nullable UIImage *)statusBarImage
                         leftTitle:(NSString *)leftTitle
                         leftValue:(NSString *)leftValue
                        rightTitle:(NSString *)rightTitle
                        rightValue:(NSString *)rightValue;

@end

NS_ASSUME_NONNULL_END
