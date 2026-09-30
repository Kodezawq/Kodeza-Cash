#import "LoanZen_LoginResult.h"
#import "LoanZen_APIFieldKeys.h"

@interface LoanZen_LoginResult ()
@property (nonatomic, copy, readwrite) NSString *token;
@property (nonatomic, copy, readwrite, nullable) NSString *userId;
@property (nonatomic, copy, readwrite, nullable) NSString *mobile;
@end

@implementation LoanZen_LoginResult

+ (instancetype)LZ_fromDictionary:(NSDictionary *)dictionary error:(NSError **)error {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        if (error) *error = nil;
        return nil;
    }

    LoanZen_LoginResult *result = [[LoanZen_LoginResult alloc] init];
    result.token = [LoanZen_JSONParser LZ_stringForKey:LZAPIFieldToken inDictionary:dictionary alternateKeys:@[@"token"]] ?: @"";
    result.userId = [LoanZen_JSONParser LZ_stringForKey:LZAPIFieldUserId inDictionary:dictionary alternateKeys:@[@"uid", @"userId"]];
    result.mobile = [LoanZen_JSONParser LZ_stringForKey:@"mobile" inDictionary:dictionary alternateKeys:@[LZAPIFieldPhone, @"mobileNo"]];

    if (result.token.length == 0) {
        if (error) *error = nil;
        return nil;
    }
    return result;
}

@end
