#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_SupHomeParser : NSObject

+ (NSInteger)LZ_flexibleIntFromValue:(nullable id)value;
+ (NSInteger)LZ_userStatusFromData:(nullable NSDictionary *)data;
+ (nullable NSString *)LZ_promptCopyFromData:(nullable NSDictionary *)data;
+ (nullable NSString *)LZ_displayNameFromData:(nullable NSDictionary *)data;
+ (nullable NSString *)LZ_displayNameFromUserInfo:(nullable NSDictionary *)userInfo;
+ (nullable NSString *)LZ_displayPhoneFromUserInfo:(nullable NSDictionary *)userInfo;
+ (nullable NSString *)LZ_withdrawalOrderIdFromData:(nullable NSDictionary *)data;
+ (BOOL)LZ_canJumpByUserStatus:(NSInteger)userStatus;
+ (NSInteger)LZ_orderTabIndexForRequestStatus:(NSInteger)requestStatus;

@end

NS_ASSUME_NONNULL_END
