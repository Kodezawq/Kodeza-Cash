#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_DeviceNetworkCollector : NSObject
+ (NSDictionary<NSString *, id> *)LZ_collectFields;
/// 先异步解析 Wi‑Fi，再组网相关字段（上报前优先使用）
+ (void)LZ_collectFieldsAfterWirelessReady:(void (^)(NSDictionary<NSString *, id> *fields))completion;
@end

NS_ASSUME_NONNULL_END
