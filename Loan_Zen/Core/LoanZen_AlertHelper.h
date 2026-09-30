#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_AlertHelper : NSObject

+ (void)LZ_showConfirmOn:(UIViewController *)controller
                   title:(NSString *)title
                 message:(nullable NSString *)message
            confirmTitle:(NSString *)confirmTitle
             cancelTitle:(nullable NSString *)cancelTitle
              onConfirm:(void (^)(void))onConfirm;

+ (void)LZ_showMessageOn:(UIViewController *)controller
                   title:(NSString *)title
                 message:(nullable NSString *)message
              buttonTitle:(NSString *)buttonTitle;

@end

NS_ASSUME_NONNULL_END
