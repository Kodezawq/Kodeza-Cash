#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_CheckInStore : NSObject

/// 当前连续签到天数（0~7）。
+ (NSInteger)LZ_completedDays;
/// 今日是否已签到。
+ (BOOL)LZ_hasCheckedInToday;
/// 执行签到；若今日已签到返回 NO。
+ (BOOL)LZ_checkInTodayIfNeeded;

+ (void)LZ_clearForCurrentUser;

@end

NS_ASSUME_NONNULL_END
