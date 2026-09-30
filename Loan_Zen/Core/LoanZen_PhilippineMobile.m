#import "LoanZen_PhilippineMobile.h"

@implementation LoanZen_PhilippineMobile

+ (NSString *)LZ_digitsOnly:(NSString *)raw {
    if (raw.length == 0) return @"";
    NSMutableString *result = [NSMutableString string];
    for (NSUInteger i = 0; i < raw.length; i++) {
        unichar c = [raw characterAtIndex:i];
        if (c >= '0' && c <= '9') [result appendFormat:@"%C", c];
    }
    return result.copy;
}

+ (NSString *)LZ_nationalDigitsFromRaw:(NSString *)raw {
    NSString *digits = [self LZ_digitsOnly:raw];
    if ([digits hasPrefix:@"63"]) {
        digits = [digits substringFromIndex:MIN(2, digits.length)];
    }
    if (digits.length > 11) {
        digits = [digits substringToIndex:11];
    }
    return digits;
}

+ (NSString *)LZ_sanitizeFieldDigits:(NSString *)raw {
    return [self LZ_nationalDigitsFromRaw:raw];
}

+ (BOOL)LZ_isValidPhilippineMobile:(NSString *)raw {
    return [self LZ_normalizedNational10ForAPI:raw] != nil;
}

+ (BOOL)LZ_shouldApplyPhilippineMsisdnRulesForItemCode:(NSString *)itemCode {
    NSString *c = itemCode.lowercaseString ?: @"";
    if ([c containsString:@"microphone"]) return NO;
    if ([c hasSuffix:@"_phone"]) return YES;
    if ([c isEqualToString:@"mobile"] || [c hasSuffix:@"_mobile"]) return YES;
    if ([c containsString:@"cell_phone"] || [c isEqualToString:@"cellphone"]) return YES;
    return NO;
}

+ (NSString *)LZ_cleanContactPhoneFromPicker:(NSString *)raw {
    NSString *digits = [self LZ_digitsOnly:raw];
    if ([digits hasPrefix:@"63"]) {
        digits = [digits substringFromIndex:MIN(2, digits.length)];
    }
    if (digits.length == 11 && [digits hasPrefix:@"09"]) {
        digits = [digits substringFromIndex:1];
    } else if ([digits hasPrefix:@"0"]) {
        digits = [digits substringFromIndex:1];
    }
    return digits;
}

+ (NSString *)LZ_normalizedNational10ForAPI:(NSString *)raw {
    NSString *d = [self LZ_nationalDigitsFromRaw:raw];
    if (d.length == 0) return nil;
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(09\\d{9}|9\\d{9})$" options:0 error:&error];
    if (error) return nil;
    NSUInteger matches = [regex numberOfMatchesInString:d options:0 range:NSMakeRange(0, d.length)];
    if (matches == 0) return nil;
    if ([d hasPrefix:@"09"]) {
        return [d substringFromIndex:1];
    }
    return d;
}

+ (NSString *)LZ_normalizedNational10ForContactUpload:(NSString *)raw {
    NSString *digits = [self LZ_digitsOnly:raw];
    if (digits.length == 0) return nil;

    NSString *processed = digits;
    if ([processed hasPrefix:@"63"]) {
        NSString *withoutCountryCode = [processed substringFromIndex:MIN(2, processed.length)];
        if (withoutCountryCode.length == 10 || withoutCountryCode.length == 11) {
            processed = withoutCountryCode;
        }
    }

    BOOL valid = (processed.length == 10 && [processed hasPrefix:@"9"])
              || (processed.length == 11 && [processed hasPrefix:@"09"]);
    if (!valid) return nil;

    if (processed.length == 11 && [processed hasPrefix:@"09"]) {
        return [processed substringFromIndex:1];
    }
    return processed;
}

@end
