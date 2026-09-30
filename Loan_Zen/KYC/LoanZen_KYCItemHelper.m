#import "LoanZen_KYCItemHelper.h"
#import "LoanZen_APIFieldKeys.h"

NSString * const LZKYCFormRowKindKey = @"kind";
NSString * const LZKYCFormRowItemKey = @"item";
NSString * const LZKYCFormRowCodeKey = @"code";
NSString * const LZKYCFormRowPairsKey = @"pairs";
NSString * const LZKYCFormRowKindText = @"text";
NSString * const LZKYCFormRowKindSelect = @"select";

@implementation LoanZen_KYCItemHelper

+ (nullable NSString *)LZ_resolvedItemCodeForItem:(NSDictionary *)item {
    if (![item isKindOfClass:[NSDictionary class]]) return nil;
    NSString *itemCode = [item[LZAPIFieldItemCode] isKindOfClass:[NSString class]]
        ? [item[LZAPIFieldItemCode] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] : @"";
    if (itemCode.length > 0) return itemCode;
    itemCode = [item[@"itemCode"] isKindOfClass:[NSString class]]
        ? [item[@"itemCode"] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] : @"";
    if (itemCode.length > 0) return itemCode;
    NSString *itemId = [item[@"itemId"] isKindOfClass:[NSString class]]
        ? [item[@"itemId"] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] : @"";
    return itemId.length > 0 ? itemId : nil;
}

+ (BOOL)LZ_isRequiredForItem:(NSDictionary *)item {
    id required = item[@"required"];
    if ([required isKindOfClass:[NSNumber class]]) return [required boolValue];
    id isRequired = item[LZAPIFieldIsRequired];
    if ([isRequired isKindOfClass:[NSNumber class]]) return [isRequired integerValue] == 1;
    return NO;
}

+ (NSArray<NSDictionary *> *)LZ_sortedSearchItems:(NSArray<NSDictionary *> *)items {
    return [items sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        NSInteger sa = [a[LZAPIFieldItemSort] respondsToSelector:@selector(integerValue)] ? [a[LZAPIFieldItemSort] integerValue] : 0;
        NSInteger sb = [b[LZAPIFieldItemSort] respondsToSelector:@selector(integerValue)] ? [b[LZAPIFieldItemSort] integerValue] : 0;
        if (sa == sb) return NSOrderedSame;
        return sa < sb ? NSOrderedAscending : NSOrderedDescending;
    }];
}

+ (NSArray<NSDictionary *> *)LZ_optionPairsFromItem:(NSDictionary *)item {
    NSArray *buttons = [item[LZAPIFieldButtonList] isKindOfClass:[NSArray class]] ? item[LZAPIFieldButtonList] : @[];
    NSMutableArray<NSDictionary *> *pairs = [NSMutableArray array];
    for (NSDictionary *btn in buttons) {
        if (![btn isKindOfClass:[NSDictionary class]]) continue;
        NSString *value = btn[LZAPIFieldButtonKey];
        if (![value isKindOfClass:[NSString class]] || value.length == 0) {
            value = btn[@"buttonValue"];
        }
        if (![value isKindOfClass:[NSString class]]) continue;
        value = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (value.length == 0) continue;
        NSString *label = [btn[LZAPIFieldButtonLabel] isKindOfClass:[NSString class]] ? [btn[LZAPIFieldButtonLabel] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] : @"";
        if (label.length == 0) label = value;
        [pairs addObject:@{ @"label": label, @"value": value }];
    }
    return pairs.copy;
}

+ (NSArray<NSDictionary *> *)LZ_buildFormRowsFromItems:(NSArray<NSDictionary *> *)items {
    NSMutableArray<NSDictionary *> *rows = [NSMutableArray array];
    for (NSDictionary *item in [self LZ_sortedSearchItems:items]) {
        NSString *code = [self LZ_resolvedItemCodeForItem:item];
        if (code.length == 0) continue;
        NSInteger itemType = [item[LZAPIFieldItemType] integerValue];
        switch (itemType) {
            case 1:
            case 2:
                [rows addObject:@{
                    LZKYCFormRowKindKey: LZKYCFormRowKindText,
                    LZKYCFormRowItemKey: item,
                    LZKYCFormRowCodeKey: code,
                }];
                break;
            case 3: {
                NSArray *pairs = [self LZ_optionPairsFromItem:item];
                if (pairs.count == 0) break;
                [rows addObject:@{
                    LZKYCFormRowKindKey: LZKYCFormRowKindSelect,
                    LZKYCFormRowItemKey: item,
                    LZKYCFormRowCodeKey: code,
                    LZKYCFormRowPairsKey: pairs,
                }];
                break;
            }
            case 4:
                [rows addObject:@{
                    LZKYCFormRowKindKey: LZKYCFormRowKindSelect,
                    LZKYCFormRowItemKey: item,
                    LZKYCFormRowCodeKey: code,
                    LZKYCFormRowPairsKey: [self LZ_optionPairsFromItem:item],
                }];
                break;
            default:
                break;
        }
    }
    return rows.copy;
}

+ (nullable NSDictionary *)LZ_itemForCode:(NSString *)code inItems:(NSArray<NSDictionary *> *)items {
    for (NSDictionary *item in items) {
        if ([[self LZ_resolvedItemCodeForItem:item] isEqualToString:code]) return item;
    }
    return nil;
}

+ (NSString *)LZ_fieldTitleForItem:(NSDictionary *)item code:(NSString *)code {
    NSString *name = [item[LZAPIFieldItemName] isKindOfClass:[NSString class]] ? [item[LZAPIFieldItemName] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] : @"";
    if (name.length == 0) name = code;
    return [self LZ_isRequiredForItem:item] ? [NSString stringWithFormat:@"%@ *", name] : name;
}

+ (NSString *)LZ_displayTitleForSelectItem:(NSDictionary *)item
                                      code:(NSString *)code
                                     value:(NSString *)value
                              displayLabel:(NSString *)displayLabel {
    NSString *trimmedValue = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmedValue.length == 0) {
        NSString *placeholder = [item[@"placeholder"] isKindOfClass:[NSString class]] ? [item[@"placeholder"] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] : @"";
        return placeholder.length > 0 ? placeholder : @"Please choose";
    }
    NSString *trimmedDisplay = [displayLabel stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmedDisplay.length > 0) return trimmedDisplay;
    NSArray *buttons = [item[LZAPIFieldButtonList] isKindOfClass:[NSArray class]] ? item[LZAPIFieldButtonList] : @[];
    for (NSDictionary *btn in buttons) {
        if (![btn isKindOfClass:[NSDictionary class]]) continue;
        NSString *key = btn[LZAPIFieldButtonKey];
        if ([key isKindOfClass:[NSString class]] && [key isEqualToString:trimmedValue]) {
            NSString *label = [btn[LZAPIFieldButtonLabel] isKindOfClass:[NSString class]] ? [btn[LZAPIFieldButtonLabel] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] : @"";
            if (label.length > 0) return label;
        }
    }
    return trimmedValue;
}

+ (BOOL)LZ_matchesRegex:(NSString *)value pattern:(NSString *)pattern {
    if (value.length == 0 || pattern.length == 0) return YES;
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    if (error || !regex) return YES;
    return [regex numberOfMatchesInString:value options:0 range:NSMakeRange(0, value.length)] > 0;
}

+ (NSInteger)LZ_maxInputLengthForItem:(NSDictionary *)item defaultLength:(NSInteger)defaultLength {
    if (!item) return defaultLength;
    for (NSString *key in @[@"itemLength", @"maxLength", @"itemMaxLength"]) {
        id raw = item[key];
        if ([raw respondsToSelector:@selector(integerValue)]) {
            NSInteger length = [raw integerValue];
            if (length > 0) return length;
        }
    }
    return defaultLength;
}

@end
