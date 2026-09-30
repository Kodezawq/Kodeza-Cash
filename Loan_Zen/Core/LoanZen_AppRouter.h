#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_AppRouter : NSObject

+ (void)LZ_showMainInterfaceInWindow:(nullable UIWindow *)window;
+ (void)LZ_showLoginInterfaceInWindow:(nullable UIWindow *)window;
+ (nullable UIWindow *)LZ_keyWindow;

@end

NS_ASSUME_NONNULL_END
