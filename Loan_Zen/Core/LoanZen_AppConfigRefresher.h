#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 静默拉取 `/app/v3/app/config` 并写入 `LoanZen_AppConfigStore`（对齐 LoanEase `LEAppConfigRefresher`）。
@interface LoanZen_AppConfigRefresher : NSObject

+ (void)LZ_refreshIfPossible;
+ (void)LZ_refreshIfPossibleWithCompletion:(void (^ _Nullable)(NSDictionary * _Nullable config, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
