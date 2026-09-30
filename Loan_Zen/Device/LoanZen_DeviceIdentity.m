#import "LoanZen_DeviceIdentity.h"
#import "LoanZen_BuryReporter.h"
#import <UIKit/UIKit.h>
#import <AdSupport/AdSupport.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <Security/Security.h>

static NSString * const kLZNullToken = @"null";
/// Keychain 持久设备 ID：卸载重装后尽量保持不变（与 Easy 一致）
static NSString * const kLZKeychainService = @"com.loanzen.install.deviceId";
static NSString * const kLZDefaultsDeviceIdKey = @"LZ.install.deviceId";

@implementation LoanZen_DeviceIdentity

+ (NSString *)LZ_deviceId { return [self LZ_persistentDeviceId]; }
+ (NSString *)LZ_serialNo { return [self LZ_persistentDeviceId]; }
+ (NSString *)LZ_imei { return kLZNullToken; }
+ (NSString *)LZ_appVersion {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"1.0";
}
+ (NSString *)LZ_clientLanguage {
    // 对齐 LoanEase / CMD：服务端要求枚举值，固定传 en。
    return @"en";
}
+ (long long)LZ_clientTimeMillis {
    return (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
}
+ (NSString *)LZ_idfv {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString] ?: @"";
}

/// 请求 envelope `deviceId` / 登录 `serialNo` / 设备上报 `uuid` 共用同一持久 ID。
+ (NSString *)LZ_uuidForDevicePayload {
    return [self LZ_persistentDeviceId];
}

+ (NSString *)LZ_persistentDeviceId {
    static NSString *cached;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cached = [self LZ_loadOrCreatePersistentDeviceId];
    });
    return cached ?: @"";
}

+ (NSString *)LZ_loadOrCreatePersistentDeviceId {
    NSString *fromKeychain = [self LZ_keychainLoad:kLZKeychainService];
    if (fromKeychain.length > 0) {
        [self LZ_defaultsSave:fromKeychain];
        return fromKeychain;
    }

    NSString *fromDefaults = [[NSUserDefaults standardUserDefaults] stringForKey:kLZDefaultsDeviceIdKey];
    if (fromDefaults.length > 0) {
        [self LZ_keychainSave:kLZKeychainService value:fromDefaults];
        return fromDefaults;
    }

    // 兼容旧版仅用 IDFV 作为 deviceId 的用户，优先落盘 IDFV，避免升级后换号
    NSString *legacyKeychain = [self LZ_keychainLoad:@"com.loanzen.device.uuid"];
    if (legacyKeychain.length > 0) {
        [self LZ_persistDeviceId:legacyKeychain];
        return legacyKeychain;
    }

    NSString *idfv = [self LZ_idfv];
    NSString *fresh = idfv.length > 0 ? idfv : [[NSUUID UUID] UUIDString];
    [self LZ_persistDeviceId:fresh];
    return fresh;
}

+ (void)LZ_persistDeviceId:(NSString *)deviceId {
    if (deviceId.length == 0) return;
    [self LZ_keychainSave:kLZKeychainService value:deviceId];
    [self LZ_defaultsSave:deviceId];
}

+ (void)LZ_defaultsSave:(NSString *)deviceId {
    if (deviceId.length == 0) return;
    [[NSUserDefaults standardUserDefaults] setObject:deviceId forKey:kLZDefaultsDeviceIdKey];
}

+ (NSString *)LZ_idfaOrNull {
    if (@available(iOS 14, *)) {
        if (ATTrackingManager.trackingAuthorizationStatus == ATTrackingManagerAuthorizationStatusAuthorized) {
            return [ASIdentifierManager sharedManager].advertisingIdentifier.UUIDString;
        }
        return kLZNullToken;
    }
    return [ASIdentifierManager sharedManager].advertisingIdentifier.UUIDString;
}

+ (BOOL)LZ_needsIDFAAuthorizationPrompt {
    if (@available(iOS 14, *)) {
        return ATTrackingManager.trackingAuthorizationStatus == ATTrackingManagerAuthorizationStatusNotDetermined;
    }
    return NO;
}

+ (void)LZ_requestIDFAAuthorizationIfNeededWithCompletion:(void (^)(void))completion {
    void (^finish)(void) = ^{
        if (completion) completion();
    };

    if (@available(iOS 14, *)) {
        ATTrackingManagerAuthorizationStatus status = ATTrackingManager.trackingAuthorizationStatus;
        if (status != ATTrackingManagerAuthorizationStatusNotDetermined) {
            [self LZ_trackIDFAStatus:status];
            finish();
            return;
        }

        if (![NSThread isMainThread]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self LZ_requestIDFAAuthorizationIfNeededWithCompletion:completion];
            });
            return;
        }

        if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive) {
            finish();
            return;
        }

        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus authStatus) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (authStatus != ATTrackingManagerAuthorizationStatusNotDetermined) {
                    [self LZ_trackIDFAStatus:authStatus];
                }
                finish();
            });
        }];
        return;
    }

    finish();
}

+ (void)LZ_trackIDFAStatus:(ATTrackingManagerAuthorizationStatus)status API_AVAILABLE(ios(14)) {
    if (status == ATTrackingManagerAuthorizationStatusAuthorized) {
        [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventIDFAPermissionSuccess];
    } else if (status == ATTrackingManagerAuthorizationStatusDenied
               || status == ATTrackingManagerAuthorizationStatusRestricted) {
        [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventIDFAPermissionFailure];
    }
}

+ (NSString *)LZ_keychainLoad:(NSString *)service {
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: service,
        (__bridge id)kSecAttrAccount: service,
        (__bridge id)kSecReturnData: @YES,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne,
    };
    CFTypeRef item = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &item);
    if (status != errSecSuccess || !item) return nil;
    NSData *data = (__bridge_transfer NSData *)item;
    NSString *value = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return value.length > 0 ? value : nil;
}

+ (void)LZ_keychainSave:(NSString *)service value:(NSString *)value {
    if (value.length == 0) return;
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) return;
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: service,
        (__bridge id)kSecAttrAccount: service,
    };
    SecItemDelete((__bridge CFDictionaryRef)query);
    NSDictionary *add = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: service,
        (__bridge id)kSecAttrAccount: service,
        (__bridge id)kSecValueData: data,
        (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlock,
    };
    SecItemAdd((__bridge CFDictionaryRef)add, NULL);
}

@end
