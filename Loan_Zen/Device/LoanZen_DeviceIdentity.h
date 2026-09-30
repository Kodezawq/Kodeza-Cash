#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 设备标识与客户端公参（登录/下单 envelope 共用）
@interface LoanZen_DeviceIdentity : NSObject

/// 持久设备唯一 ID（Keychain），与 `serialNo` / 上报 `uuid` 相同；卸载重装尽量不变
+ (NSString *)LZ_deviceId;
+ (NSString *)LZ_serialNo;
+ (NSString *)LZ_imei;
+ (NSString *)LZ_appVersion;
+ (NSString *)LZ_clientLanguage;
+ (long long)LZ_clientTimeMillis;
/// 设备上报字段 `uuid`，与 `deviceId` / `serialNo` 共用持久 ID
+ (NSString *)LZ_uuidForDevicePayload;
/// 系统 IDFV（可随卸载变化，仅作独立字段上报）
+ (NSString *)LZ_idfv;
+ (NSString *)LZ_idfaOrNull;

/// 请求 ATT 授权（仅弹窗一次）；completion 在主线程回调。
+ (void)LZ_requestIDFAAuthorizationIfNeededWithCompletion:(void (^ _Nullable)(void))completion;

/// iOS 14+ 是否仍需弹出 ATT 授权（`NotDetermined`）。
+ (BOOL)LZ_needsIDFAAuthorizationPrompt;

@end

NS_ASSUME_NONNULL_END
