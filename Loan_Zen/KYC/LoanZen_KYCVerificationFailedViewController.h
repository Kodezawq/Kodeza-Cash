#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// KYC 证件/活体上传失败说明弹窗（对齐 LoanBase / CMD 错误码 6212009、6212011）。
@interface LoanZen_KYCVerificationFailedViewController : UIViewController

@property (nonatomic, copy, nullable) void (^onConfirm)(void);

+ (instancetype)LZ_presentFrom:(UIViewController *)host;
+ (instancetype)LZ_presentFrom:(UIViewController *)host onConfirm:(nullable void (^)(void))onConfirm;

@end

NS_ASSUME_NONNULL_END
