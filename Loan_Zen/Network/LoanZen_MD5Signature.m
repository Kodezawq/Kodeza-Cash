#import "LoanZen_MD5Signature.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation LoanZen_MD5Signature

+ (NSString *)LZ_md5LowerHex:(NSString *)string {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (CC_LONG)data.length, digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

+ (NSString *)LZ_randomNonceWithLength:(NSInteger)length {
    NSString *chars = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *result = [NSMutableString stringWithCapacity:length];
    for (NSInteger i = 0; i < length; i++) {
        u_int32_t idx = arc4random_uniform((u_int32_t)chars.length);
        [result appendFormat:@"%C", [chars characterAtIndex:idx]];
    }
    return result;
}

+ (NSString *)LZ_stringValue:(id)value {
    if ([value isKindOfClass:[NSString class]]) return value;
    if ([value isKindOfClass:[NSNumber class]]) return [(NSNumber *)value stringValue];
    if (value == nil || value == [NSNull null]) return @"";
    return [NSString stringWithFormat:@"%@", value];
}

+ (NSString *)LZ_signEnvelopeWithDataParams:(NSDictionary<NSString *,id> *)dataParams
                                   deviceId:(NSString *)deviceId
                                      nonce:(NSString *)nonce
                                      appId:(NSString *)appId
                                    channel:(NSString *)channel
                                    version:(NSString *)version
                                       salt:(NSString *)salt {
    NSMutableDictionary<NSString *, NSString *> *params = [@{
        @"appId": appId ?: @"",
        @"deviceId": deviceId ?: @"",
        @"channel": channel ?: @"",
        @"nonce": nonce ?: @"",
        @"version": version ?: @""
    } mutableCopy];
    [dataParams enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        if (obj == nil || obj == [NSNull null]) return;
        params[key] = [self LZ_stringValue:obj];
    }];
    NSArray<NSString *> *values = [[params allValues] sortedArrayUsingSelector:@selector(compare:)];
    values = [[values reverseObjectEnumerator] allObjects];
    NSString *joined = [values componentsJoinedByString:@"*"];
    NSString *trimmedSalt = [salt stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *saltSuffix = [trimmedSalt hasPrefix:@"MD"] ? trimmedSalt : [@"MD" stringByAppendingString:trimmedSalt];
    NSString *joinedWithSalt = [joined stringByAppendingString:saltSuffix];
    NSString *md5Lower = [self LZ_md5LowerHex:joinedWithSalt];
    return [md5Lower uppercaseStringWithLocale:[NSLocale localeWithLocaleIdentifier:@"tr_TR"]];
}

@end
