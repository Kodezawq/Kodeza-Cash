#import "LoanZen_APIConfig.h"

static NSString * const kLZAPIAppId = @"kodezacash";
static NSString * const kLZAPIBaseURL = @"https://api.kodezacash.com";
static NSString * const kLZAPIChannel = @"app_store";
static NSString * const kLZAPIProtocolVersion = @"2.0";
static NSString * const kLZAPISignSalt = @"hZucetjrXOoLd2ZA";
static NSString * const kLZAdjustAppToken = @"d178oflmp3i8";

@implementation LoanZen_APIConfig

+ (NSString *)appId {
    
    return kLZAPIAppId;
    
}

+ (NSString *)channel {
    
    return kLZAPIChannel;
    
}

+ (NSString *)protocolVersion {
    
    return kLZAPIProtocolVersion;
    
}

+ (NSString *)signSalt {
    
    return kLZAPISignSalt;
    
}

+ (NSString *)adjustAppToken {
    
    return kLZAdjustAppToken;
}

+ (NSString *)fixedBaseURL {
    
    return kLZAPIBaseURL;
    
}

+ (BOOL)hasSigningProfile {
    
    return self.appId.length > 0 && self.channel.length > 0 && self.signSalt.length > 0;
}

+ (NSString *)LZ_normalizedBaseURLString {
    NSString *fixed = self.fixedBaseURL;
    if (fixed.length == 0) return nil;
    while ([fixed hasSuffix:@"/"]) {
        fixed = [fixed substringToIndex:fixed.length - 1];
    }
    return fixed;
}

@end
