#import <Foundation/Foundation.h>

@class LoanZen_LoginResult;

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_AuthService : NSObject

+ (void)LZ_sendOTPWithMobileDigits:(NSString *)mobileDigits
                        completion:(void (^)(NSError * _Nullable error))completion;

+ (void)LZ_registerOrLoginWithMobileDigits:(NSString *)mobileDigits
                                verifyCode:(NSString *)verifyCode
                                completion:(void (^)(LoanZen_LoginResult * _Nullable result, NSError * _Nullable error))completion;

+ (void)LZ_fetchAppConfigWithCompletion:(void (^ _Nullable)(NSDictionary * _Nullable config, NSError * _Nullable error))completion;

+ (void)LZ_logoutWithCompletion:(void (^ _Nullable)(NSError * _Nullable error))completion;

+ (void)LZ_closeAccountWithCompletion:(void (^ _Nullable)(NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
