#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_OrderDetailBankCardView : UIView

+ (BOOL)LZ_hasDisplayableCardNumber:(nullable NSString *)maskedCardNumber;
- (void)LZ_configureWithMaskedCardNumber:(nullable NSString *)maskedCardNumber;

@end

NS_ASSUME_NONNULL_END
