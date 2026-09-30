#import "LoanZen_DeviceHardwareCollector.h"
#import <UIKit/UIKit.h>
#import <sys/sysctl.h>
#import <mach/mach.h>

static NSString * const kLZNull = @"null";

@implementation LoanZen_DeviceHardwareCollector

+ (void)LZ_enableBatteryMonitoring {
    UIDevice.currentDevice.batteryMonitoringEnabled = YES;
}

+ (NSInteger)LZ_batteryLevelPercent {
    [self LZ_enableBatteryMonitoring];
    float lvl = UIDevice.currentDevice.batteryLevel;
    if (lvl < 0) return -99;
    return (NSInteger)(lvl * 100);
}

+ (BOOL)LZ_isCharging {
    [self LZ_enableBatteryMonitoring];
    UIDeviceBatteryState state = UIDevice.currentDevice.batteryState;
    return state == UIDeviceBatteryStateCharging || state == UIDeviceBatteryStateFull;
}

+ (NSString *)LZ_hardwareModelIdentifier {
    size_t size = 0;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *result = [NSString stringWithUTF8String:machine];
    free(machine);
    return result.length > 0 ? result : @"unknown";
}

+ (NSString *)LZ_deviceModelName {
    NSString *machine = [self LZ_hardwareModelIdentifier];
    static NSDictionary *map;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{
            @"iPhone1,1": @"iPhone",
            @"iPhone1,2": @"iPhone 3G",
            @"iPhone2,1": @"iPhone 3GS",
            @"iPhone3,1": @"iPhone 4", @"iPhone3,2": @"iPhone 4", @"iPhone3,3": @"iPhone 4",
            @"iPhone4,1": @"iPhone 4S",
            @"iPhone5,1": @"iPhone 5", @"iPhone5,2": @"iPhone 5",
            @"iPhone5,3": @"iPhone 5c", @"iPhone5,4": @"iPhone 5c",
            @"iPhone6,1": @"iPhone 5s", @"iPhone6,2": @"iPhone 5s",
            @"iPhone7,1": @"iPhone 6 Plus", @"iPhone7,2": @"iPhone 6",
            @"iPhone8,1": @"iPhone 6s", @"iPhone8,2": @"iPhone 6s Plus", @"iPhone8,4": @"iPhone SE",
            @"iPhone9,1": @"iPhone 7", @"iPhone9,3": @"iPhone 7",
            @"iPhone9,2": @"iPhone 7 Plus", @"iPhone9,4": @"iPhone 7 Plus",
            @"iPhone10,1": @"iPhone 8", @"iPhone10,4": @"iPhone 8",
            @"iPhone10,2": @"iPhone 8 Plus", @"iPhone10,5": @"iPhone 8 Plus",
            @"iPhone10,3": @"iPhone X", @"iPhone10,6": @"iPhone X",
            @"iPhone11,8": @"iPhone XR",
            @"iPhone11,2": @"iPhone XS",
            @"iPhone11,4": @"iPhone XS Max", @"iPhone11,6": @"iPhone XS Max",
            @"iPhone12,1": @"iPhone 11",
            @"iPhone12,3": @"iPhone 11 Pro",
            @"iPhone12,5": @"iPhone 11 Pro Max",
            @"iPhone12,8": @"iPhone SE (2nd generation)",
            @"iPhone13,1": @"iPhone 12 mini", @"iPhone13,2": @"iPhone 12",
            @"iPhone13,3": @"iPhone 12 Pro", @"iPhone13,4": @"iPhone 12 Pro Max",
            @"iPhone14,4": @"iPhone 13 mini", @"iPhone14,5": @"iPhone 13",
            @"iPhone14,2": @"iPhone 13 Pro", @"iPhone14,3": @"iPhone 13 Pro Max",
            @"iPhone14,6": @"iPhone SE (3rd generation)",
            @"iPhone14,7": @"iPhone 14", @"iPhone14,8": @"iPhone 14 Plus",
            @"iPhone15,2": @"iPhone 14 Pro", @"iPhone15,3": @"iPhone 14 Pro Max",
            @"iPhone15,4": @"iPhone 15", @"iPhone15,5": @"iPhone 15 Plus",
            @"iPhone16,1": @"iPhone 15 Pro", @"iPhone16,2": @"iPhone 15 Pro Max",
            @"iPhone17,1": @"iPhone 16 Pro", @"iPhone17,2": @"iPhone 16 Pro Max",
            @"iPhone17,3": @"iPhone 16", @"iPhone17,4": @"iPhone 16 Plus",
            @"iPhone17,5": @"iPhone 16e",
            @"iPhone18,1": @"iPhone 17 Pro", @"iPhone18,2": @"iPhone 17 Pro Max",
            @"iPhone18,3": @"iPhone 17", @"iPhone18,4": @"iPhone Air",
            @"iPhone18,5": @"iPhone 17e",
            @"iPhone19,1": @"iPhone 18 Pro", @"iPhone19,2": @"iPhone 18 Pro",
            @"iPhone19,3": @"iPhone 18 Pro Max", @"iPhone19,7": @"iPhone 18 Pro Max",
            @"iPhone19,4": @"iPhone Duo", @"iPhone19,5": @"iPhone Duo", @"iPhone19,6": @"iPhone Duo",
            @"i386": @"iPhone Simulator",
            @"x86_64": @"iPhone Simulator",
            @"arm64": @"iPhone Simulator",
        };
    });
    return map[machine] ?: machine;
}

+ (NSString *)LZ_gigabytesFromBytes:(unsigned long long)bytes {
    return [NSString stringWithFormat:@"%.6f", (double)bytes / (1024.0 * 1024.0 * 1024.0)];
}

+ (NSString *)LZ_diskUsageGB:(BOOL)isTotal {
    NSURL *url = [NSURL fileURLWithPath:NSHomeDirectory()];
    NSError *error = nil;
    NSDictionary *values = [url resourceValuesForKeys:@[
        NSURLVolumeTotalCapacityKey,
        NSURLVolumeAvailableCapacityKey
    ] error:&error];
    NSNumber *capacity = isTotal ? values[NSURLVolumeTotalCapacityKey] : values[NSURLVolumeAvailableCapacityKey];
    long long bytes = capacity.longLongValue;
    if (bytes <= 0) return @"0.000000";
    return [self LZ_gigabytesFromBytes:(unsigned long long)bytes];
}

+ (NSString *)LZ_freeMemoryGB {
    mach_port_t host = mach_host_self();
    vm_size_t pageSize = 0;
    host_page_size(host, &pageSize);
    vm_statistics64_data_t stats;
    mach_msg_type_number_t count = HOST_VM_INFO64_COUNT;
    kern_return_t kr = host_statistics64(host, HOST_VM_INFO64, (host_info64_t)&stats, &count);
    if (kr != KERN_SUCCESS) return @"0.000000";
    unsigned long long freeBytes = (unsigned long long)stats.free_count * (unsigned long long)pageSize;
    return [self LZ_gigabytesFromBytes:freeBytes];
}

+ (NSDictionary<NSString *, id> *)LZ_collectFields {
    UIScreen *screen = UIScreen.mainScreen;
    CGFloat scale = screen.scale;
    CGFloat pointWidth = screen.bounds.size.width;
    CGFloat pointHeight = screen.bounds.size.height;
    CGFloat pxWidth = pointWidth * scale;
    CGFloat pxHeight = pointHeight * scale;

    NSString *ramTotal = [self LZ_gigabytesFromBytes:NSProcessInfo.processInfo.physicalMemory];
    NSTimeInterval uptime = NSProcessInfo.processInfo.systemUptime;
    long long uptimeMs = (long long)(uptime * 1000.0);
    long long lastBootMs = (long long)(([[NSDate date] timeIntervalSince1970] - uptime) * 1000.0);
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"1.0";

    return @{
        @"phoneBoard": kLZNull,
        @"phoneBrand": @"Apple",
        @"phoneMark": UIDevice.currentDevice.name ?: @"",
        @"phoneType": [self LZ_deviceModelName],
        @"systemVersions": UIDevice.currentDevice.systemVersion ?: @"",
        @"versionCode": appVersion,
        @"versionName": appVersion,
        @"sdkVersion": kLZNull,
        @"productionDate": kLZNull,
        @"serial": kLZNull,
        @"screenResolution": [NSString stringWithFormat:@"%.0f-%.0f", pxWidth, pxHeight],
        @"screenWidth": [NSString stringWithFormat:@"%d", (int)pointWidth],
        @"screenHeight": [NSString stringWithFormat:@"%d", (int)pointHeight],
        @"cpuNum": @(NSProcessInfo.processInfo.processorCount),
        @"ramCanUse": [self LZ_freeMemoryGB],
        @"ramTotal": ramTotal,
        @"cashCanUse": [self LZ_diskUsageGB:NO],
        @"cashTotal": [self LZ_diskUsageGB:YES],
        @"batteryLevel": [NSString stringWithFormat:@"%ld", (long)[self LZ_batteryLevelPercent]],
        @"batteryMax": @"100",
        @"totalBootTime": [NSString stringWithFormat:@"%lld", uptimeMs],
        @"totalBootTimeWake": [NSString stringWithFormat:@"%lld", uptimeMs],
        @"lastBootTime": [NSString stringWithFormat:@"%lld", lastBootMs],
        @"screenBrightness": [NSString stringWithFormat:@"%d", (int)(UIScreen.mainScreen.brightness * 100)],
        @"rooted": @"false",
        @"debugged": @"false",
        @"simulated": @"false",
        @"charged": [self LZ_isCharging] ? @"true" : @"false",
        @"deviceType": @3,
        @"operatingSystem": @"2",
        @"videoInternal": @"-99",
        @"imageInternal": @"-99",
        @"albumFile": @"-99",
        @"phoneNum": kLZNull,
        @"phoneNum2": kLZNull,
    };
}

@end
