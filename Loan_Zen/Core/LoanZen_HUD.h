#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_HUD : NSObject

+ (void)LZ_configureIfNeeded;
+ (void)LZ_requestWillBeginLoading;
+ (void)LZ_requestDidEndLoading;
+ (void)LZ_showBlockingLoading;
+ (void)LZ_showBlockingLoading:(nullable NSString *)status;
+ (void)LZ_hideBlockingLoading;
+ (void)LZ_showSuccess:(nullable NSString *)message;
+ (void)LZ_showError:(nullable NSString *)message;
/// 接口业务码非 200 时的错误 HUD，展示 4 秒。
+ (void)LZ_showAPIError:(nullable NSString *)message;

@end

NS_ASSUME_NONNULL_END
