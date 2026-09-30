#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_UserService : NSObject
+ (void)LZ_uploadUserInfoWithAdid:(nullable NSString *)adid
                       completion:(void (^ _Nullable)(NSDictionary * _Nullable user, NSError * _Nullable error))completion;
+ (void)LZ_fetchUserInfoWithCompletion:(void (^ _Nullable)(NSDictionary * _Nullable user, NSError * _Nullable error))completion;
@end

NS_ASSUME_NONNULL_END
