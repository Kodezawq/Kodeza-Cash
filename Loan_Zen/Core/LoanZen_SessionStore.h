#import <Foundation/Foundation.h>

@class LoanZen_LoginResult;

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_SessionStore : NSObject

@property (class, nonatomic, readonly) LoanZen_SessionStore *shared;
@property (nonatomic, assign, readonly) BOOL isLoggedIn;
@property (nonatomic, copy, readonly) NSString *mobileDisplay;
@property (nonatomic, copy, readonly) NSString *userName;
@property (nonatomic, copy, readonly) NSString *appUserType;

- (void)LZ_reloadFromStore;
- (void)LZ_applyUserInfo:(nullable NSDictionary *)userInfo;
- (void)LZ_applyLoginWithToken:(NSString *)token userId:(nullable NSString *)userId mobileDigits:(NSString *)mobileDigits;
- (void)LZ_applyLoginResult:(LoanZen_LoginResult *)result fallbackMobileDigits:(NSString *)fallbackMobileDigits;
- (void)LZ_applyDemoLoginWithMobileDigits:(NSString *)mobileDigits;
- (void)LZ_clearSession;

@end

NS_ASSUME_NONNULL_END
