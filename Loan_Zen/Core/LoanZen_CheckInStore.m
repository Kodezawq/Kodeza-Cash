#import "LoanZen_CheckInStore.h"
#import "LoanZen_CredentialStore.h"

static NSString * const kLZCheckInDaysKey = @"LZ_CheckInCompletedDays";
static NSString * const kLZCheckInLastDateKey = @"LZ_CheckInLastDate";

@implementation LoanZen_CheckInStore

+ (NSString *)LZ_storageKeyPrefix {
    NSString *userId = [LoanZen_CredentialStore.userId stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (userId.length == 0) userId = @"guest";
    return userId;
}

+ (NSString *)LZ_daysKey {
    return [NSString stringWithFormat:@"%@.%@", kLZCheckInDaysKey, [self LZ_storageKeyPrefix]];
}

+ (NSString *)LZ_lastDateKey {
    return [NSString stringWithFormat:@"%@.%@", kLZCheckInLastDateKey, [self LZ_storageKeyPrefix]];
}

+ (NSString *)LZ_todayString {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.timeZone = [NSTimeZone localTimeZone];
        formatter.dateFormat = @"yyyy-MM-dd";
    });
    return [formatter stringFromDate:[NSDate date]] ?: @"";
}

+ (NSString *)LZ_yesterdayString {
    NSDate *yesterday = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay value:-1 toDate:[NSDate date] options:0];
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.timeZone = [NSTimeZone localTimeZone];
        formatter.dateFormat = @"yyyy-MM-dd";
    });
    return [formatter stringFromDate:yesterday] ?: @"";
}

+ (void)LZ_normalizeStreakIfNeeded {
    NSString *lastDate = [[NSUserDefaults standardUserDefaults] stringForKey:[self LZ_lastDateKey]] ?: @"";
    if (lastDate.length == 0) return;
    NSString *today = [self LZ_todayString];
    NSString *yesterday = [self LZ_yesterdayString];
    if ([lastDate isEqualToString:today] || [lastDate isEqualToString:yesterday]) return;
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:[self LZ_daysKey]];
}

+ (NSInteger)LZ_completedDays {
    [self LZ_normalizeStreakIfNeeded];
    NSInteger days = [[NSUserDefaults standardUserDefaults] integerForKey:[self LZ_daysKey]];
    if (days < 0) return 0;
    if (days > 7) return 7;
    return days;
}

+ (BOOL)LZ_hasCheckedInToday {
    NSString *lastDate = [[NSUserDefaults standardUserDefaults] stringForKey:[self LZ_lastDateKey]] ?: @"";
    return lastDate.length > 0 && [lastDate isEqualToString:[self LZ_todayString]];
}

+ (BOOL)LZ_checkInTodayIfNeeded {
    if ([self LZ_hasCheckedInToday]) return NO;
    [self LZ_normalizeStreakIfNeeded];

    NSString *lastDate = [[NSUserDefaults standardUserDefaults] stringForKey:[self LZ_lastDateKey]] ?: @"";
    NSString *today = [self LZ_todayString];
    NSString *yesterday = [self LZ_yesterdayString];
    NSInteger days = [self LZ_completedDays];

    if (lastDate.length == 0) {
        days = 1;
    } else if ([lastDate isEqualToString:yesterday]) {
        days = days >= 7 ? 1 : days + 1;
    } else {
        days = 1;
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:days forKey:[self LZ_daysKey]];
    [defaults setObject:today forKey:[self LZ_lastDateKey]];
    return YES;
}

+ (void)LZ_clearForCurrentUser {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:[self LZ_daysKey]];
    [defaults removeObjectForKey:[self LZ_lastDateKey]];
}

@end
