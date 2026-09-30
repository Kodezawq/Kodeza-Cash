#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_DeviceUploadService : NSObject

/// 登录成功后：/app/v3/mobile/registerDevice
+ (void)LZ_registerDeviceWithCompletion:(void (^ _Nullable)(NSError * _Nullable error))completion;

/// 下单成功后：/app/v3/mobile/device（orderId + 设备字段合并上传）
+ (void)LZ_uploadOrderDeviceWithOrderId:(NSString *)orderId
                              completion:(void (^ _Nullable)(NSError * _Nullable error))completion;

/// 通讯录分批上传：/app/v3/mobile/contact
+ (void)LZ_uploadOrderContactsWithOrderId:(NSString *)orderId
                                 contacts:(NSArray<NSDictionary *> *)contacts
                               completion:(void (^ _Nullable)(NSError * _Nullable error))completion;

/// 订单推进 ready：/app/v3/order/ready
+ (void)LZ_markOrderReadyWithOrderId:(NSString *)orderId
                           completion:(void (^ _Nullable)(NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
