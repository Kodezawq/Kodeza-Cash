#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_PhilippineMobile : NSObject

+ (NSString *)LZ_digitsOnly:(NSString *)raw;
/// 输入框内：只保留数字、去 63 前缀、最多 11 位国内号段
+ (NSString *)LZ_sanitizeFieldDigits:(NSString *)raw;
+ (BOOL)LZ_isValidPhilippineMobile:(NSString *)raw;
+ (nullable NSString *)LZ_normalizedNational10ForAPI:(NSString *)raw;
/// 通讯录批量上传：提取菲律宾 9 开头 10 位号码（规则与 CMDKuan filterAndNormalizePhoneNumber 一致）
+ (nullable NSString *)LZ_normalizedNational10ForContactUpload:(NSString *)raw;
+ (BOOL)LZ_shouldApplyPhilippineMsisdnRulesForItemCode:(NSString *)itemCode;
/// 通讯录选号清洗（对齐 CMDKuan cleanPhoneNumber）
+ (NSString *)LZ_cleanContactPhoneFromPicker:(NSString *)raw;

@end

NS_ASSUME_NONNULL_END
