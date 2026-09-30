#import "LoanZen_DeviceNetworkCollector.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <CFNetwork/CFNetwork.h>
#import <NetworkExtension/NetworkExtension.h>
@import Network;

static NSString * const kLZNull = @"null";

@implementation LoanZen_DeviceNetworkCollector

static NSLock *LZ_wifiLock(void) {
    static NSLock *lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ lock = [[NSLock alloc] init]; });
    return lock;
}

static NSString *_lzCachedSSID;
static NSString *_lzCachedBSSID;

+ (void)LZ_setWifiCacheSSID:(NSString *)ssid bssid:(NSString *)bssid {
    [LZ_wifiLock() lock];
    _lzCachedSSID = ssid;
    _lzCachedBSSID = bssid;
    [LZ_wifiLock() unlock];
}

+ (void)LZ_readWifiCacheSSID:(NSString * _Nullable * _Nonnull)ssid bssid:(NSString * _Nullable * _Nonnull)bssid {
    [LZ_wifiLock() lock];
    *ssid = _lzCachedSSID;
    *bssid = _lzCachedBSSID;
    [LZ_wifiLock() unlock];
}

+ (NSString *)LZ_nonEmpty:(NSString *)raw {
    if (raw.length == 0 || [raw isEqualToString:@"null"]) return nil;
    return raw;
}

+ (NSString *)LZ_sanitizedSSID:(NSString *)raw {
    NSString *value = [self LZ_nonEmpty:raw];
    if (!value || [value isEqualToString:@"0"]) return kLZNull;
    return value;
}

+ (void)LZ_legacyCaptiveNetworkSSID:(NSString * _Nullable * _Nonnull)ssid bssid:(NSString * _Nullable * _Nonnull)bssid {
    *ssid = nil;
    *bssid = nil;
    CFArrayRef interfaces = CNCopySupportedInterfaces();
    if (!interfaces) return;
    NSArray *list = (__bridge_transfer NSArray *)interfaces;
    for (NSString *iface in list) {
        CFDictionaryRef info = CNCopyCurrentNetworkInfo((__bridge CFStringRef)iface);
        if (!info) continue;
        NSDictionary *dict = (__bridge_transfer NSDictionary *)info;
        NSString *s = dict[(id)kCNNetworkInfoKeySSID] ?: dict[@"SSID"];
        NSString *b = dict[(id)kCNNetworkInfoKeyBSSID] ?: dict[@"BSSID"];
        if ([self LZ_nonEmpty:s] || [self LZ_nonEmpty:b]) {
            *ssid = s;
            *bssid = b;
            return;
        }
    }
}

+ (void)LZ_resolveWirelessWithCompletion:(void (^)(NSString * _Nullable ssid, NSString * _Nullable bssid))completion {
    if (@available(iOS 14.0, *)) {
        __block BOOL finished = NO;
        void (^finish)(NSString *, NSString *) = ^(NSString *ssid, NSString *bssid) {
            [LZ_wifiLock() lock];
            BOOL already = finished;
            if (!already) {
                finished = YES;
                _lzCachedSSID = ssid;
                _lzCachedBSSID = bssid;
            }
            [LZ_wifiLock() unlock];
            if (already) return;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(ssid, bssid);
            });
        };
        [NEHotspotNetwork fetchCurrentWithCompletionHandler:^(NEHotspotNetwork * _Nullable currentNetwork) {
            finish(currentNetwork.SSID, currentNetwork.BSSID);
        }];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            NSString *ssid = nil;
            NSString *bssid = nil;
            [self LZ_readWifiCacheSSID:&ssid bssid:&bssid];
            finish(ssid, bssid);
        });
        return;
    }

    NSString *ssid = nil;
    NSString *bssid = nil;
    [self LZ_legacyCaptiveNetworkSSID:&ssid bssid:&bssid];
    [self LZ_setWifiCacheSSID:ssid bssid:bssid];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (completion) completion(ssid, bssid);
    });
}

+ (NSString *)LZ_radioLabelForTechnology:(NSString *)tech {
    if (tech.length == 0) return @"0";
    if (@available(iOS 14.1, *)) {
        if ([tech isEqualToString:CTRadioAccessTechnologyNR] ||
            [tech isEqualToString:CTRadioAccessTechnologyNRNSA]) {
            return @"5";
        }
    }
    if ([tech isEqualToString:CTRadioAccessTechnologyLTE]) return @"4";
    if ([tech isEqualToString:CTRadioAccessTechnologyEdge] ||
        [tech isEqualToString:CTRadioAccessTechnologyCDMA1x] ||
        [tech isEqualToString:CTRadioAccessTechnologyGPRS]) {
        return @"2";
    }
    if ([tech isEqualToString:CTRadioAccessTechnologyWCDMA] ||
        [tech isEqualToString:CTRadioAccessTechnologyHSDPA] ||
        [tech isEqualToString:CTRadioAccessTechnologyHSUPA] ||
        [tech isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0] ||
        [tech isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA] ||
        [tech isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB] ||
        [tech isEqualToString:CTRadioAccessTechnologyeHRPD]) {
        return @"3";
    }
    return @"0";
}

+ (NSString *)LZ_networkCategory {
    __block NSString *result = @"0";
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    nw_path_monitor_t monitor = nw_path_monitor_create();
    dispatch_queue_t queue = dispatch_queue_create("com.loanzen.device.network", DISPATCH_QUEUE_SERIAL);
    nw_path_monitor_set_queue(monitor, queue);
    nw_path_monitor_set_update_handler(monitor, ^(nw_path_t path) {
        if (nw_path_get_status(path) != nw_path_status_satisfied) {
            result = @"0";
            dispatch_semaphore_signal(sema);
            nw_path_monitor_cancel(monitor);
            return;
        }
        if (nw_path_uses_interface_type(path, nw_interface_type_wifi) ||
            nw_path_uses_interface_type(path, nw_interface_type_wired)) {
            result = @"1";
            dispatch_semaphore_signal(sema);
            nw_path_monitor_cancel(monitor);
            return;
        }
        CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
        NSString *tech = info.currentRadioAccessTechnology;
        if (tech.length == 0) {
            tech = info.serviceCurrentRadioAccessTechnology.allValues.firstObject;
        }
        result = [self LZ_radioLabelForTechnology:tech];
        dispatch_semaphore_signal(sema);
        nw_path_monitor_cancel(monitor);
    });
    nw_path_monitor_start(monitor);
    dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)));
    return result;
}

+ (NSDictionary<NSString *, NSString *> *)LZ_telephonyInfo {
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    NSDictionary<NSString *, CTCarrier *> *providers = info.serviceSubscriberCellularProviders;
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    for (CTCarrier *carrier in providers.allValues) {
        if (carrier.carrierName.length > 0) [names addObject:carrier.carrierName];
    }
    NSInteger slotCount = MAX((NSInteger)providers.count, 1);
    NSString *secondary = names.count > 1 ? names[1] : kLZNull;
    return @{
        @"secondary": secondary,
        @"slotCount": [NSString stringWithFormat:@"%ld", (long)slotCount],
        @"simCount": [NSString stringWithFormat:@"%lu", (unsigned long)names.count],
    };
}

+ (BOOL)LZ_isSystemProxyEnabled {
    CFDictionaryRef proxySettings = CFNetworkCopySystemProxySettings();
    if (!proxySettings) return NO;
    CFURLRef url = (__bridge CFURLRef)[NSURL URLWithString:@"https://www.apple.com"];
    CFArrayRef proxies = CFNetworkCopyProxiesForURL(url, proxySettings);
    CFRelease(proxySettings);
    if (!proxies || CFArrayGetCount(proxies) == 0) {
        if (proxies) CFRelease(proxies);
        return NO;
    }
    CFDictionaryRef settings = CFArrayGetValueAtIndex(proxies, 0);
    CFStringRef proxyType = CFDictionaryGetValue(settings, kCFProxyTypeKey);
    BOOL enabled = proxyType && CFStringCompare(proxyType, kCFProxyTypeNone, 0) != kCFCompareEqualTo;
    CFRelease(proxies);
    return enabled;
}

+ (BOOL)LZ_isVPNViaScopedProxy {
    CFDictionaryRef proxySettings = CFNetworkCopySystemProxySettings();
    if (!proxySettings) return NO;
    NSDictionary *dict = (__bridge NSDictionary *)proxySettings;
    NSDictionary *scoped = dict[@"__SCOPED__"];
    CFRelease(proxySettings);
    if (![scoped isKindOfClass:[NSDictionary class]]) return NO;
    for (NSString *key in scoped.allKeys) {
        NSString *lower = key.lowercaseString;
        if ([lower containsString:@"tap"] || [lower containsString:@"tun"] ||
            [lower containsString:@"ppp"] || [lower containsString:@"ipsec"]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)LZ_isVPNViaPathInterfaces {
    __block BOOL active = NO;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    nw_path_monitor_t monitor = nw_path_monitor_create();
    dispatch_queue_t queue = dispatch_queue_create("com.loanzen.device.vpn", DISPATCH_QUEUE_SERIAL);
    nw_path_monitor_set_queue(monitor, queue);
    nw_path_monitor_set_update_handler(monitor, ^(nw_path_t path) {
        nw_path_enumerate_interfaces(path, ^bool(nw_interface_t interface) {
            const char *cname = nw_interface_get_name(interface);
            if (!cname) return true;
            NSString *name = [[NSString stringWithUTF8String:cname] lowercaseString];
            if ([name hasPrefix:@"utun"] || [name hasPrefix:@"ipsec"] || [name hasPrefix:@"ppp"]) {
                active = YES;
                return false;
            }
            return true;
        });
        dispatch_semaphore_signal(sema);
        nw_path_monitor_cancel(monitor);
    });
    nw_path_monitor_start(monitor);
    dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)));
    return active;
}

+ (BOOL)LZ_isVPNOn {
    if ([self LZ_isVPNViaScopedProxy]) return YES;
    return [self LZ_isVPNViaPathInterfaces];
}

+ (NSDictionary<NSString *, id> *)LZ_collectFieldsWithSSID:(NSString *)ssid bssid:(NSString *)bssid {
    NSDictionary *telephony = [self LZ_telephonyInfo];
    NSString *wifiName = [self LZ_sanitizedSSID:ssid];
    NSString *resolvedBSSID = [self LZ_nonEmpty:bssid] ?: kLZNull;

    return @{
        @"defaultLanguage": ({
            NSString *lang = [[NSLocale preferredLanguages] firstObject];
            [[lang componentsSeparatedByString:@"-"] firstObject] ?: @"";
        }),
        @"defaultTimeZone": NSTimeZone.localTimeZone.name ?: @"",
        @"telephony2": telephony[@"secondary"] ?: kLZNull,
        @"slotCount": telephony[@"slotCount"] ?: @"1",
        @"simCount": telephony[@"simCount"] ?: @"0",
        @"network": [self LZ_networkCategory],
        @"mac": resolvedBSSID,
        @"wifiName": wifiName,
        @"wifiBssid": resolvedBSSID,
        @"wifiSsid": wifiName,
        @"proxied": [self LZ_isSystemProxyEnabled] ? @"true" : @"false",
        @"isvpn": [self LZ_isVPNOn] ? @"true" : @"false",
    };
}

+ (NSDictionary<NSString *, id> *)LZ_collectFields {
    NSString *ssid = nil;
    NSString *bssid = nil;
    [self LZ_readWifiCacheSSID:&ssid bssid:&bssid];
    if (![self LZ_nonEmpty:ssid] && ![self LZ_nonEmpty:bssid]) {
        [self LZ_legacyCaptiveNetworkSSID:&ssid bssid:&bssid];
    }
    return [self LZ_collectFieldsWithSSID:ssid bssid:bssid];
}

+ (void)LZ_collectFieldsAfterWirelessReady:(void (^)(NSDictionary<NSString *, id> *fields))completion {
    [self LZ_resolveWirelessWithCompletion:^(NSString *ssid, NSString *bssid) {
        NSDictionary *fields = [self LZ_collectFieldsWithSSID:ssid bssid:bssid];
        if (completion) completion(fields);
    }];
}

@end
