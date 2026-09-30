#import "LoanZen_DeviceUploadService.h"
#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_DeviceSnapshot.h"
#import "LoanZen_HTTPClient.h"

static void LZ_logPrettyJSON(id object, NSString *tag) {
    if (!object || tag.length == 0) return;
    if (![NSJSONSerialization isValidJSONObject:object]) {
        NSLog(@"[LoanZen DeviceUpload] %@ (invalid JSON object): %@", tag, object);
        return;
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:nil];
    if (jsonData.length > 0) {
        NSLog(@"[LoanZen DeviceUpload] %@\n%@", tag, [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
        return;
    }
    NSLog(@"[LoanZen DeviceUpload] %@: %@", tag, object);
}

static void LZ_logDeviceUploadParams(NSString *tag, NSString *path, NSDictionary *signParams, NSDictionary *dataParams) {
    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    if (path.length > 0) payload[@"path"] = path;
    if (signParams) payload[@"signParams"] = signParams;
    if (dataParams) payload[@"dataParams"] = dataParams;
    LZ_logPrettyJSON(payload, [NSString stringWithFormat:@"%@ request", tag ?: @"upload"]);
}

@implementation LoanZen_DeviceUploadService

+ (void)LZ_registerDeviceWithCompletion:(void (^)(NSError * _Nullable))completion {
    [LoanZen_DeviceSnapshot LZ_buildDeviceInfoPayload:^(NSDictionary *rawDevice) {
        NSDictionary *device = [LoanZen_DeviceSnapshot LZ_stringifyPayload:rawDevice];
        LZ_logPrettyJSON(device, @"registerDevice deviceInfo");
        LZ_logDeviceUploadParams(@"register device", @"/app/v3/mobile/registerDevice", @{}, device);
        [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/mobile/registerDevice"
                                 signParams:@{}
                                 dataParams:device
                                showLoading:NO
                                 completion:^(NSDictionary *json, NSError *error) {
            if (completion) completion(error);
        }];
    }];
}

+ (void)LZ_uploadOrderDeviceWithOrderId:(NSString *)orderId completion:(void (^)(NSError * _Nullable))completion {
    if (orderId.length == 0) {
        if (completion) {
            completion([NSError errorWithDomain:@"LoanZen_DeviceUploadService" code:-1
                                       userInfo:@{NSLocalizedDescriptionKey: @"orderId missing"}]);
        }
        return;
    }
    NSDictionary *sign = @{@"orderId": orderId};
    [LoanZen_DeviceSnapshot LZ_buildDeviceInfoPayload:^(NSDictionary *rawDevice) {
        NSDictionary *device = [LoanZen_DeviceSnapshot LZ_stringifyPayload:rawDevice];
        NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObject:orderId forKey:@"orderId"];
        [data addEntriesFromDictionary:device];
        LZ_logPrettyJSON(rawDevice, @"orderDevice deviceInfo(raw)");
        LZ_logPrettyJSON(data, @"orderDevice deviceInfo(upload)");
        LZ_logDeviceUploadParams(@"order device", @"/app/v3/mobile/device", sign, data);
        [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/mobile/device"
                                 signParams:sign
                                 dataParams:data
                                showLoading:NO
                                 completion:^(NSDictionary *json, NSError *error) {
            if (completion) completion(error);
        }];
    }];
}

+ (void)LZ_uploadOrderContactsWithOrderId:(NSString *)orderId
                                 contacts:(NSArray<NSDictionary *> *)contacts
                               completion:(void (^)(NSError * _Nullable))completion {
    if (orderId.length == 0) {
        if (completion) {
            completion([NSError errorWithDomain:@"LoanZen_DeviceUploadService" code:-1
                                       userInfo:@{NSLocalizedDescriptionKey: @"orderId missing"}]);
        }
        return;
    }
    NSDictionary *sign = @{@"orderId": orderId};
    NSDictionary *data = @{@"orderId": orderId, @"list": contacts ?: @[]};
    LZ_logDeviceUploadParams([NSString stringWithFormat:@"order contacts upload (count=%lu)", (unsigned long)(contacts.count)], @"/app/v3/mobile/contact", sign, data);
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/mobile/contact"
                             signParams:sign
                             dataParams:data
                            showLoading:NO
                             completion:^(NSDictionary *json, NSError *error) {
        if (completion) completion(error);
    }];
}

+ (void)LZ_markOrderReadyWithOrderId:(NSString *)orderId completion:(void (^)(NSError * _Nullable))completion {
    if (orderId.length == 0) {
        if (completion) {
            completion([NSError errorWithDomain:@"LoanZen_DeviceUploadService" code:-1
                                       userInfo:@{NSLocalizedDescriptionKey: @"orderId missing"}]);
        }
        return;
    }
    NSDictionary *payload = @{@"orderId": orderId};
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/order/ready"
                             signParams:payload
                             dataParams:payload
                            showLoading:NO
                             completion:^(NSDictionary *json, NSError *error) {
        if (completion) completion(error);
    }];
}

@end
