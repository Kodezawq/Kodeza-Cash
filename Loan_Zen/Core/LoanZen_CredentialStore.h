#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_CredentialStore : NSObject

@property (class, nonatomic, copy) NSString *token;
@property (class, nonatomic, copy) NSString *userId;
@property (class, nonatomic, copy) NSString *mobileDigits;

+ (void)LZ_clearAuth;

@end

NS_ASSUME_NONNULL_END
