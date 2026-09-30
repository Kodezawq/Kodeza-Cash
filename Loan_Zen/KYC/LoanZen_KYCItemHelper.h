#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const LZKYCFormRowKindKey;
FOUNDATION_EXPORT NSString * const LZKYCFormRowItemKey;
FOUNDATION_EXPORT NSString * const LZKYCFormRowCodeKey;
FOUNDATION_EXPORT NSString * const LZKYCFormRowPairsKey;
FOUNDATION_EXPORT NSString * const LZKYCFormRowKindText;
FOUNDATION_EXPORT NSString * const LZKYCFormRowKindSelect;

@interface LoanZen_KYCItemHelper : NSObject

+ (nullable NSString *)LZ_resolvedItemCodeForItem:(NSDictionary *)item;
+ (BOOL)LZ_isRequiredForItem:(NSDictionary *)item;
+ (NSArray<NSDictionary *> *)LZ_sortedSearchItems:(NSArray<NSDictionary *> *)items;
+ (NSArray<NSDictionary *> *)LZ_buildFormRowsFromItems:(NSArray<NSDictionary *> *)items;
+ (NSArray<NSDictionary *> *)LZ_optionPairsFromItem:(NSDictionary *)item;
+ (nullable NSDictionary *)LZ_itemForCode:(NSString *)code inItems:(NSArray<NSDictionary *> *)items;
+ (NSString *)LZ_fieldTitleForItem:(NSDictionary *)item code:(NSString *)code;
+ (NSString *)LZ_displayTitleForSelectItem:(NSDictionary *)item
                                      code:(NSString *)code
                                     value:(nullable NSString *)value
                              displayLabel:(nullable NSString *)displayLabel;
+ (BOOL)LZ_matchesRegex:(NSString *)value pattern:(NSString *)pattern;
+ (NSInteger)LZ_maxInputLengthForItem:(nullable NSDictionary *)item defaultLength:(NSInteger)defaultLength;

@end

NS_ASSUME_NONNULL_END
