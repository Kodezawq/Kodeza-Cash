#import "LoanZen_DeviceSnapshot.h"
#import "LoanZen_DeviceIdentity.h"
#import "LoanZen_DeviceHardwareCollector.h"
#import "LoanZen_DeviceNetworkCollector.h"

static NSString * const kLZNull = @"null";

@implementation LoanZen_DeviceSnapshot

+ (NSDictionary<NSString *, id> *)LZ_identityFields {
    return @{
        @"androidId": kLZNull,
        @"gaid": kLZNull,
        @"uuid": [LoanZen_DeviceIdentity LZ_uuidForDevicePayload],
        @"idfa": [LoanZen_DeviceIdentity LZ_idfaOrNull],
        @"idfv": [LoanZen_DeviceIdentity LZ_idfv],
    };
}

+ (NSDictionary<NSString *, id> *)LZ_mergeIdentityHardwareNetwork:(NSDictionary *)network {
    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    [payload addEntriesFromDictionary:[self LZ_identityFields]];
    [payload addEntriesFromDictionary:[LoanZen_DeviceHardwareCollector LZ_collectFields]];
    if (network) [payload addEntriesFromDictionary:network];
    return payload.copy;
}

+ (NSDictionary<NSString *, id> *)LZ_buildDeviceInfoPayload {
    return [self LZ_mergeIdentityHardwareNetwork:[LoanZen_DeviceNetworkCollector LZ_collectFields]];
}

+ (void)LZ_buildDeviceInfoPayload:(void (^)(NSDictionary<NSString *, id> *payload))completion {
    [LoanZen_DeviceNetworkCollector LZ_collectFieldsAfterWirelessReady:^(NSDictionary<NSString *, id> *fields) {
        NSDictionary *payload = [self LZ_mergeIdentityHardwareNetwork:fields];
        if (completion) completion(payload);
    }];
}

+ (NSDictionary<NSString *, NSString *> *)LZ_stringifyPayload:(NSDictionary<NSString *, id> *)payload {
    NSMutableDictionary<NSString *, NSString *> *result = [NSMutableDictionary dictionary];
    [payload enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            NSString *text = (NSString *)obj;
            result[key] = text.length > 0 ? text : kLZNull;
        } else if ([obj isKindOfClass:[NSNumber class]]) {
            result[key] = [(NSNumber *)obj stringValue];
        } else if (obj == nil || obj == [NSNull null]) {
            result[key] = kLZNull;
        } else {
            NSString *text = [NSString stringWithFormat:@"%@", obj];
            result[key] = text.length > 0 ? text : kLZNull;
        }
    }];
    return result.copy;
}

@end
