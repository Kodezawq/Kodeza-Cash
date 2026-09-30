#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 监听网络可用（NWPathMonitor），满足后回调一次并停止监听。
@interface LoanZen_NetworkPermissionMonitor : NSObject

+ (void)LZ_whenNetworkAvailable:(void (^)(void))handler;

@end

NS_ASSUME_NONNULL_END
