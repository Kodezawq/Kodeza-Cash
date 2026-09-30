#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const LZ_NotificationLoginDidSucceed;
FOUNDATION_EXPORT NSNotificationName const LZ_NotificationLogoutDidFinish;
FOUNDATION_EXPORT NSNotificationName const LZ_NotificationHomeShouldRefresh;
FOUNDATION_EXPORT NSNotificationName const LZ_NotificationOrderListShouldRefresh;

/// `HomeShouldRefresh` 携带此 key 且值为 @YES 时，首页不再重复请求 suphome，直接应用 `SupHomeStore` 缓存。
FOUNDATION_EXPORT NSString * const LZ_NotificationUserInfoSuphomePrefetched;

NS_ASSUME_NONNULL_END
