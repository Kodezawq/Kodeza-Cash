#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_APIConfig : NSObject

@property (class, nonatomic, readonly) NSString *appId;
@property (class, nonatomic, readonly) NSString *channel;
@property (class, nonatomic, readonly) NSString *protocolVersion;
@property (class, nonatomic, readonly) NSString *signSalt;
@property (class, nonatomic, readonly, nullable) NSString *fixedBaseURL;
@property (class, nonatomic, readonly) NSString *adjustAppToken;
@property (class, nonatomic, readonly) BOOL hasSigningProfile;

+ (nullable NSString *)LZ_normalizedBaseURLString;

@end

NS_ASSUME_NONNULL_END
