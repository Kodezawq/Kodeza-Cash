#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_MD5Signature : NSObject

+ (NSString *)LZ_md5LowerHex:(NSString *)string;
+ (NSString *)LZ_randomNonceWithLength:(NSInteger)length;
+ (NSString *)LZ_signEnvelopeWithDataParams:(NSDictionary<NSString *, id> *)dataParams
                                   deviceId:(NSString *)deviceId
                                      nonce:(NSString *)nonce
                                      appId:(NSString *)appId
                                    channel:(NSString *)channel
                                    version:(NSString *)version
                                       salt:(NSString *)salt;

@end

NS_ASSUME_NONNULL_END
