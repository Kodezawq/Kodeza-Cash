#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 合并各 Collector，产出设备上报字典（字段取值对齐 EasyFund）
@interface LoanZen_DeviceSnapshot : NSObject
+ (NSDictionary<NSString *, id> *)LZ_buildDeviceInfoPayload;
+ (void)LZ_buildDeviceInfoPayload:(void (^)(NSDictionary<NSString *, id> *payload))completion;
+ (NSDictionary<NSString *, NSString *> *)LZ_stringifyPayload:(NSDictionary<NSString *, id> *)payload;
@end

NS_ASSUME_NONNULL_END
