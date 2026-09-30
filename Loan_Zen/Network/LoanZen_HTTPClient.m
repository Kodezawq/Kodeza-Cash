#import "LoanZen_HTTPClient.h"
#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_APIConfig.h"
#import "LoanZen_CredentialStore.h"
#import "LoanZen_HUD.h"
#import "LoanZen_MD5Signature.h"
#import "LoanZen_AppRouter.h"
#import "LoanZen_SessionStore.h"
#import "LoanZen_JSONParser.h"
#import "LoanZen_DeviceIdentity.h"
#import "LoanZen_DeviceHardwareCollector.h"
#import <UIKit/UIKit.h>

@implementation LoanZen_HTTPClient

static inline void LZHTTPComplete(void (^completion)(NSDictionary * _Nullable, NSError * _Nullable), NSDictionary *json, NSError *error) {
    if (completion) completion(json, error);
}

+ (NSString *)LZ_deviceId {
    NSString *deviceId = [LoanZen_DeviceIdentity LZ_deviceId];
    return deviceId.length > 0 ? deviceId : @"unknown";
}

/// 与 Easy 一致：`{appId}/{version}(Apple;Mobile;{机型};iOS {系统};)`
+ (NSString *)LZ_userAgent {
    NSString *appId = LoanZen_APIConfig.appId ?: @"";
    NSString *version = [LoanZen_DeviceIdentity LZ_appVersion] ?: @"1.0";
    NSString *model = [LoanZen_DeviceHardwareCollector LZ_deviceModelName] ?: @"iPhone";
    NSString *system = UIDevice.currentDevice.systemVersion ?: @"";
    return [NSString stringWithFormat:@"%@/%@(Apple;Mobile;%@;iOS %@;)", appId, version, model, system];
}

+ (BOOL)LZ_isBusinessSuccessJSON:(NSDictionary *)json {
    NSInteger codeValue = [LoanZen_JSONParser LZ_businessCodeFromResponseJSON:json];
    NSNumber *codeNumber = @(codeValue);
    BOOL successFlagFalse = [json[LZAPIResponseSuccess] isKindOfClass:[NSNumber class]] && ![json[LZAPIResponseSuccess] boolValue];
    if (successFlagFalse && codeValue != 200 && codeValue != 0) {
        return NO;
    }
    if ([[self LZ_businessSuccessDespiteCode] containsObject:codeNumber]) return YES;
    return codeValue == 200 || codeValue == 0;
}

+ (NSDictionary *)LZ_buildEnvelopeWithSignParams:(NSDictionary *)signParams dataParams:(NSDictionary *)dataParams {
    NSString *deviceId = [self LZ_deviceId];
    NSString *nonce = [LoanZen_MD5Signature LZ_randomNonceWithLength:16];
    long long clientTimeMillis = [LoanZen_DeviceIdentity LZ_clientTimeMillis];
    NSString *sign = [LoanZen_MD5Signature LZ_signEnvelopeWithDataParams:signParams ?: @{}
                                                          deviceId:deviceId
                                                             nonce:nonce
                                                             appId:LoanZen_APIConfig.appId
                                                           channel:LoanZen_APIConfig.channel
                                                           version:LoanZen_APIConfig.protocolVersion
                                                              salt:LoanZen_APIConfig.signSalt];
    return @{
        @"appId": LoanZen_APIConfig.appId,
        @"channel": LoanZen_APIConfig.channel,
        @"clientLanguage": [LoanZen_DeviceIdentity LZ_clientLanguage],
        @"clientTime": [NSString stringWithFormat:@"%lld", clientTimeMillis],
        @"clientVersion": [LoanZen_DeviceIdentity LZ_appVersion],
        @"data": dataParams ?: @{},
        @"deviceId": deviceId,
        @"nonce": nonce,
        @"os": @"2",
        @"sign": sign,
        @"version": LoanZen_APIConfig.protocolVersion,
        @"token": LoanZen_CredentialStore.token ?: @"",
        @"userId": LoanZen_CredentialStore.userId ?: @""
    };
}

+ (NSDictionary *)LZ_buildEnvelopeWithData:(NSDictionary *)dataParams {
    return [self LZ_buildEnvelopeWithSignParams:dataParams dataParams:dataParams];
}

+ (void)LZ_executePostURL:(NSURL *)url
              signParams:(NSDictionary *)signParams
              dataParams:(NSDictionary *)dataParams
             showLoading:(BOOL)showLoading
              completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    if (showLoading) [LoanZen_HUD LZ_requestWillBeginLoading];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:[self LZ_userAgent] forHTTPHeaderField:@"User-Agent"];
    request.timeoutInterval = 30;
    NSError *jsonError = nil;
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:[self LZ_buildEnvelopeWithSignParams:signParams dataParams:dataParams] options:0 error:&jsonError];
    if (jsonError) {
        if (showLoading) [LoanZen_HUD LZ_requestDidEndLoading];
        LZHTTPComplete(completion, nil, jsonError);
        return;
    }

    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (showLoading) [LoanZen_HUD LZ_requestDidEndLoading];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{ LZHTTPComplete(completion, nil, error); });
            return;
        }
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
        if (http.statusCode < 200 || http.statusCode >= 300) {
            dispatch_async(dispatch_get_main_queue(), ^{
                LZHTTPComplete(completion, nil, [NSError errorWithDomain:@"LoanZen_HTTPClient" code:http.statusCode userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"HTTP %ld", (long)http.statusCode]}]);
            });
            return;
        }
        NSError *parseError = nil;
        id object = data.length > 0 ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError] : nil;
        if (parseError || ![object isKindOfClass:[NSDictionary class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                LZHTTPComplete(completion, nil, parseError ?: [NSError errorWithDomain:@"LoanZen_HTTPClient" code:-4 userInfo:@{NSLocalizedDescriptionKey: @"Invalid response."}]);
            });
            return;
        }
        NSDictionary *json = (NSDictionary *)object;
        NSInteger codeValue = [LoanZen_JSONParser LZ_businessCodeFromResponseJSON:json];
        NSNumber *code = @(codeValue);
        BOOL success = [self LZ_isBusinessSuccessJSON:json];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                LZHTTPComplete(completion, json, nil);
                return;
            }
            [self LZ_handleForcedLoginIfNeeded:code];
            NSString *message = [LoanZen_JSONParser LZ_messageFromResponseJSON:json];
            if (message.length == 0) message = @"Request rejected.";
            if (![[self LZ_suppressBusinessErrorHUDCodes] containsObject:code]) {
                [LoanZen_HUD LZ_showError:message];
            }
            LZHTTPComplete(completion, nil, [NSError errorWithDomain:@"LoanZen_HTTPClient" code:codeValue userInfo:@{NSLocalizedDescriptionKey: message}]);
        });
    }] resume];
}

+ (NSSet<NSNumber *> *)LZ_forcedLoginCodes {
    return [NSSet setWithObjects:@2000001, @2000002, @2002001, nil];
}

+ (NSSet<NSNumber *> *)LZ_businessSuccessDespiteCode {
    return [NSSet setWithObjects:@6230002, @6230003, @6234303, nil];
}

+ (NSSet<NSNumber *> *)LZ_suppressBusinessErrorHUDCodes {
    return [NSSet setWithObjects:@6230002, @6230003, @6234303, @6212009, @6212011, nil];
}

+ (void)LZ_handleForcedLoginIfNeeded:(NSNumber *)code {
    if (code == nil || ![[self LZ_forcedLoginCodes] containsObject:code]) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [LoanZen_SessionStore.shared LZ_clearSession];
        [LoanZen_AppRouter LZ_showLoginInterfaceInWindow:nil];
    });
}

+ (void)LZ_postWithPath:(NSString *)path
             dataParams:(NSDictionary<NSString *,id> *)dataParams
             showLoading:(BOOL)showLoading
             completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    if (!LoanZen_APIConfig.hasSigningProfile) {
        LZHTTPComplete(completion, nil, [NSError errorWithDomain:@"LoanZen_HTTPClient" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Signing profile missing."}]);
        return;
    }
    NSString *base = [LoanZen_APIConfig LZ_normalizedBaseURLString];
    if (base.length == 0) {
        LZHTTPComplete(completion, nil, [NSError errorWithDomain:@"LoanZen_HTTPClient" code:-2 userInfo:@{NSLocalizedDescriptionKey: @"Base URL missing."}]);
        return;
    }
    NSString *full = [base stringByAppendingString:[path hasPrefix:@"/"] ? path : [@"/" stringByAppendingString:path]];
    NSURL *url = [NSURL URLWithString:full];
    if (!url) {
        LZHTTPComplete(completion, nil, [NSError errorWithDomain:@"LoanZen_HTTPClient" code:-3 userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL."}]);
        return;
    }

    [self LZ_executePostURL:url signParams:dataParams dataParams:dataParams showLoading:showLoading completion:completion];
}

+ (void)LZ_postWithPath:(NSString *)path
             signParams:(NSDictionary<NSString *,id> *)signParams
             dataParams:(NSDictionary<NSString *,id> *)dataParams
            showLoading:(BOOL)showLoading
             completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    if (!LoanZen_APIConfig.hasSigningProfile) {
        LZHTTPComplete(completion, nil, [NSError errorWithDomain:@"LoanZen_HTTPClient" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Signing profile missing."}]);
        return;
    }
    NSString *base = [LoanZen_APIConfig LZ_normalizedBaseURLString];
    if (base.length == 0) {
        LZHTTPComplete(completion, nil, [NSError errorWithDomain:@"LoanZen_HTTPClient" code:-2 userInfo:@{NSLocalizedDescriptionKey: @"Base URL missing."}]);
        return;
    }
    NSString *full = [base stringByAppendingString:[path hasPrefix:@"/"] ? path : [@"/" stringByAppendingString:path]];
    NSURL *url = [NSURL URLWithString:full];
    if (!url) {
        LZHTTPComplete(completion, nil, [NSError errorWithDomain:@"LoanZen_HTTPClient" code:-3 userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL."}]);
        return;
    }
    [self LZ_executePostURL:url signParams:signParams dataParams:dataParams showLoading:showLoading completion:completion];
}

+ (void)LZ_appendMultipartField:(NSString *)name
                          value:(id)value
                       boundary:(NSString *)boundary
                           body:(NSMutableData *)body {
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", name] dataUsingEncoding:NSUTF8StringEncoding]];
    if ([value isKindOfClass:[NSString class]]) {
        [body appendData:[(NSString *)value dataUsingEncoding:NSUTF8StringEncoding]];
    } else if ([value isKindOfClass:[NSNumber class]]) {
        [body appendData:[[(NSNumber *)value stringValue] dataUsingEncoding:NSUTF8StringEncoding]];
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        NSData *nested = [NSJSONSerialization dataWithJSONObject:value options:0 error:nil];
        if (nested) [body appendData:nested];
    }
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (void)LZ_uploadMultipartWithPath:(NSString *)path
                          fileData:(NSData *)fileData
                          fileName:(NSString *)fileName
                          mimeType:(NSString *)mimeType
                       showLoading:(BOOL)showLoading
                        completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    if (!LoanZen_APIConfig.hasSigningProfile) {
        LZHTTPComplete(completion, nil, [NSError errorWithDomain:@"LoanZen_HTTPClient" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Signing profile missing."}]);
        return;
    }
    NSString *base = [LoanZen_APIConfig LZ_normalizedBaseURLString];
    if (base.length == 0) {
        LZHTTPComplete(completion, nil, [NSError errorWithDomain:@"LoanZen_HTTPClient" code:-2 userInfo:@{NSLocalizedDescriptionKey: @"Base URL missing."}]);
        return;
    }
    NSString *full = [base stringByAppendingString:[path hasPrefix:@"/"] ? path : [@"/" stringByAppendingString:path]];
    NSURL *url = [NSURL URLWithString:full];
    if (!url || fileData.length == 0) {
        LZHTTPComplete(completion, nil, [NSError errorWithDomain:@"LoanZen_HTTPClient" code:-3 userInfo:@{NSLocalizedDescriptionKey: @"Invalid upload request."}]);
        return;
    }

    if (showLoading) [LoanZen_HUD LZ_requestWillBeginLoading];
    NSDictionary *envelope = [self LZ_buildEnvelopeWithSignParams:@{} dataParams:@{}];
    NSString *boundary = [NSString stringWithFormat:@"Boundary-%@", NSUUID.UUID.UUIDString];
    NSMutableData *body = [NSMutableData data];
    for (NSString *key in envelope) {
        [self LZ_appendMultipartField:key value:envelope[key] boundary:boundary body:body];
    }
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", fileName ?: @"image.jpg"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mimeType ?: @"image/jpeg"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:fileData];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:[self LZ_userAgent] forHTTPHeaderField:@"User-Agent"];
    request.timeoutInterval = 30;
    request.HTTPBody = body;

    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (showLoading) [LoanZen_HUD LZ_requestDidEndLoading];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{ LZHTTPComplete(completion, nil, error); });
            return;
        }
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
        if (http.statusCode < 200 || http.statusCode >= 300) {
            dispatch_async(dispatch_get_main_queue(), ^{
                LZHTTPComplete(completion, nil, [NSError errorWithDomain:@"LoanZen_HTTPClient" code:http.statusCode userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"HTTP %ld", (long)http.statusCode]}]);
            });
            return;
        }
        id object = data.length > 0 ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        if (![object isKindOfClass:[NSDictionary class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                LZHTTPComplete(completion, nil, [NSError errorWithDomain:@"LoanZen_HTTPClient" code:-4 userInfo:@{NSLocalizedDescriptionKey: @"Invalid response."}]);
            });
            return;
        }
        NSDictionary *json = (NSDictionary *)object;
        BOOL success = [self LZ_isBusinessSuccessJSON:json];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                LZHTTPComplete(completion, json, nil);
                return;
            }
            NSString *message = [LoanZen_JSONParser LZ_messageFromResponseJSON:json];
            if (message.length == 0) message = @"Upload failed.";
            LZHTTPComplete(completion, nil, [NSError errorWithDomain:@"LoanZen_HTTPClient" code:[LoanZen_JSONParser LZ_businessCodeFromResponseJSON:json] userInfo:@{NSLocalizedDescriptionKey: message}]);
        });
    }] resume];
}

@end
