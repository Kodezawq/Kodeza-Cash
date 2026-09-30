#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_DeviceHardwareCollector : NSObject
/// 营销机型名（如 iPhone 15 Pro Max），供 User-Agent / 设备上报共用
+ (NSString *)LZ_deviceModelName;
+ (NSDictionary<NSString *, id> *)LZ_collectFields;
@end

NS_ASSUME_NONNULL_END
