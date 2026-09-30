#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_LoginGatekeeper : NSObject

+ (BOOL)LZ_requireLoginIfNeededFrom:(UIViewController *)controller;

@end

NS_ASSUME_NONNULL_END
