#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_RejectH5Navigator : NSObject

+ (BOOL)LZ_hasURL;
/// 打开拒量 H5；无 URL 时用 message 或默认文案 Toast
+ (void)LZ_openFrom:(UIViewController *)host message:(nullable NSString *)message;

@end

NS_ASSUME_NONNULL_END
