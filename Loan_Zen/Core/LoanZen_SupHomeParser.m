#import "LoanZen_SupHomeParser.h"
#import "LoanZen_APIFieldKeys.h"

@implementation LoanZen_SupHomeParser

+ (NSInteger)LZ_flexibleIntFromValue:(id)value {
    if ([value isKindOfClass:[NSNumber class]]) return [(NSNumber *)value integerValue];
    if ([value isKindOfClass:[NSString class]]) return [(NSString *)value integerValue];
    return NSIntegerMax;
}

+ (NSInteger)LZ_pickIntFromDict:(NSDictionary *)dict keys:(NSArray<NSString *> *)keys {
    for (NSString *key in keys) {
        NSInteger v = [self LZ_flexibleIntFromValue:dict[key]];
        if (v != NSIntegerMax) return v;
    }
    return NSIntegerMax;
}

+ (NSString *)LZ_pickStringFromDict:(NSDictionary *)dict keys:(NSArray<NSString *> *)keys {
    for (NSString *key in keys) {
        id value = dict[key];
        if ([value isKindOfClass:[NSString class]] && [(NSString *)value length] > 0) return value;
        if ([value isKindOfClass:[NSNumber class]]) return [(NSNumber *)value stringValue];
    }
    return nil;
}

+ (NSInteger)LZ_userStatusFromData:(NSDictionary *)data {
    if (![data isKindOfClass:[NSDictionary class]]) return NSIntegerMax;
    return [self LZ_pickIntFromDict:data keys:@[LZAPIFieldUserStatus, @"kycStatus"]];
}

+ (NSString *)LZ_promptCopyFromData:(NSDictionary *)data {
    if (![data isKindOfClass:[NSDictionary class]]) return nil;
    return [self LZ_pickStringFromDict:data keys:@[LZAPIFieldPromptCopy, @"kycStatusDesc"]];
}

+ (NSString *)LZ_displayNameFromData:(NSDictionary *)data {
    if (![data isKindOfClass:[NSDictionary class]]) return nil;
    return [self LZ_pickStringFromDict:data keys:@[LZAPIFieldName, @"name", @"userName", @"nickName", @"realName"]];
}

+ (NSString *)LZ_displayNameFromUserInfo:(NSDictionary *)userInfo {
    if (![userInfo isKindOfClass:[NSDictionary class]]) return nil;
    return [self LZ_pickStringFromDict:userInfo keys:@[LZAPIFieldName, @"name", @"userName", @"nickName", @"realName"]];
}

+ (NSString *)LZ_displayPhoneFromUserInfo:(NSDictionary *)userInfo {
    if (![userInfo isKindOfClass:[NSDictionary class]]) return nil;
    return [self LZ_pickStringFromDict:userInfo keys:@[LZAPIFieldPhone, @"phone", @"mobile", @"mobileNo"]];
}

+ (NSString *)LZ_withdrawalOrderIdFromData:(NSDictionary *)data {
    if (![data isKindOfClass:[NSDictionary class]]) return nil;
    return [self LZ_pickStringFromDict:data keys:@[@"withdrawalOrderId", @"withdrawOrderId"]];
}

+ (BOOL)LZ_canJumpByUserStatus:(NSInteger)userStatus {
    // 对齐 LoanBase：仅这些状态显示消息框箭头并可跳转；100 与其余状态隐藏
    // 10 待 KYC；30 待抓取；32 待提现；41 待改卡；80/81 待还款/逾期
    if (userStatus == NSIntegerMax || userStatus == 100) return NO;
    NSSet *jumpable = [NSSet setWithObjects:@10, @30, @32, @41, @80, @81, nil];
    return [jumpable containsObject:@(userStatus)];
}

+ (NSInteger)LZ_orderTabIndexForRequestStatus:(NSInteger)requestStatus {
    switch (requestStatus) {
        case 10: return 1;
        case 20: return 0;
        case 30: return 2;
        case 40: return 3;
        default: return 1;
    }
}

@end
