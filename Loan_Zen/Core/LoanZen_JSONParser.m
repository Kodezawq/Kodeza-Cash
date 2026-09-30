#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_JSONParser.h"

NSErrorDomain const LoanZen_JSONParserErrorDomain = @"LoanZen_JSONParserErrorDomain";

@implementation LoanZen_JSONParser

+ (nullable NSDictionary *)LZ_dataDictionaryFromResponseJSON:(NSDictionary *)json error:(NSError **)error {
    if (![json isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    id data = json[LZAPIResponseData];
    if (![data isKindOfClass:[NSDictionary class]]) {
        data = json[@"data"];
    }
    if (![data isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return (NSDictionary *)data;
}

+ (nullable id)LZ_modelFromResponseJSON:(NSDictionary *)json
                             modelClass:(Class)modelClass
                                  error:(NSError **)error {
    NSDictionary *data = [self LZ_dataDictionaryFromResponseJSON:json error:error];
    if (!data) return nil;
    return [self LZ_modelFromDictionary:data modelClass:modelClass error:error];
}

+ (nullable id)LZ_modelFromDictionary:(NSDictionary *)dictionary
                           modelClass:(Class)modelClass
                                error:(NSError **)error {
    if (![modelClass conformsToProtocol:@protocol(LoanZen_JSONMappable)]) {
        if (error) {
            *error = [NSError errorWithDomain:LoanZen_JSONParserErrorDomain
                                         code:LoanZen_JSONParserErrorInvalidModel
                                     userInfo:@{NSLocalizedDescriptionKey: @"Unsupported model class."}];
        }
        return nil;
    }
    Class<LoanZen_JSONMappable> mappableClass = modelClass;
    return [mappableClass LZ_fromDictionary:dictionary error:error];
}

+ (nullable NSString *)LZ_trimmedStringFromValue:(id)value {
    if ([value isKindOfClass:[NSString class]]) {
        NSString *text = [(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        return text.length > 0 ? text : nil;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value stringValue];
    }
    return nil;
}

+ (nullable NSString *)LZ_stringForKey:(NSString *)key
                          inDictionary:(NSDictionary *)dictionary
                         alternateKeys:(NSArray<NSString *> *)alternateKeys {
    if (![dictionary isKindOfClass:[NSDictionary class]]) return nil;
    NSString *value = [self LZ_trimmedStringFromValue:dictionary[key]];
    if (value.length > 0) return value;
    for (NSString *alt in alternateKeys) {
        value = [self LZ_trimmedStringFromValue:dictionary[alt]];
        if (value.length > 0) return value;
    }
    return nil;
}

+ (NSInteger)LZ_integerForKey:(NSString *)key
                 inDictionary:(NSDictionary *)dictionary
                alternateKeys:(NSArray<NSString *> *)alternateKeys
                 defaultValue:(NSInteger)defaultValue {
    if (![dictionary isKindOfClass:[NSDictionary class]]) return defaultValue;
    id value = dictionary[key];
    if (value == nil || value == [NSNull null]) {
        for (NSString *alt in alternateKeys) {
            value = dictionary[alt];
            if (value != nil && value != [NSNull null]) break;
        }
    }
    if ([value isKindOfClass:[NSNumber class]]) return [(NSNumber *)value integerValue];
    if ([value isKindOfClass:[NSString class]]) return [(NSString *)value integerValue];
    return defaultValue;
}

+ (BOOL)LZ_boolForKey:(NSString *)key
         inDictionary:(NSDictionary *)dictionary
        alternateKeys:(NSArray<NSString *> *)alternateKeys
         defaultValue:(BOOL)defaultValue {
    if (![dictionary isKindOfClass:[NSDictionary class]]) return defaultValue;
    id value = dictionary[key];
    if (value == nil || value == [NSNull null]) {
        for (NSString *alt in alternateKeys) {
            value = dictionary[alt];
            if (value != nil && value != [NSNull null]) break;
        }
    }
    if ([value isKindOfClass:[NSNumber class]]) return [(NSNumber *)value boolValue];
    if ([value isKindOfClass:[NSString class]]) return [(NSString *)value boolValue];
    return defaultValue;
}

+ (nullable NSArray *)LZ_modelArrayFromArray:(NSArray *)array modelClass:(Class)modelClass {
    if (![array isKindOfClass:[NSArray class]]) return @[];
    if (![modelClass conformsToProtocol:@protocol(LoanZen_JSONMappable)]) return @[];
    Class<LoanZen_JSONMappable> mappableClass = modelClass;
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:array.count];
    for (id element in array) {
        if (![element isKindOfClass:[NSDictionary class]]) continue;
        NSError *error = nil;
        id model = [mappableClass LZ_fromDictionary:(NSDictionary *)element error:&error];
        if (model) [items addObject:model];
    }
    return items.copy;
}

+ (NSInteger)LZ_businessCodeFromResponseJSON:(NSDictionary *)json {
    if (![json isKindOfClass:[NSDictionary class]]) return NSIntegerMax;
    id resultCode = json[LZAPIResponseResultCode];
    if ([resultCode isKindOfClass:[NSNumber class]]) return [(NSNumber *)resultCode integerValue];
    if ([resultCode isKindOfClass:[NSString class]]) return [(NSString *)resultCode integerValue];
    id legacyResultCode = json[@"resultCode"];
    if ([legacyResultCode isKindOfClass:[NSNumber class]]) return [(NSNumber *)legacyResultCode integerValue];
    if ([legacyResultCode isKindOfClass:[NSString class]]) return [(NSString *)legacyResultCode integerValue];
    id code = json[@"code"];
    if ([code isKindOfClass:[NSNumber class]]) return [(NSNumber *)code integerValue];
    if ([code isKindOfClass:[NSString class]]) return [(NSString *)code integerValue];
    return 200;
}

+ (nullable NSString *)LZ_messageFromResponseJSON:(NSDictionary *)json {
    if (![json isKindOfClass:[NSDictionary class]]) return nil;
    return [self LZ_stringForKey:@"message" inDictionary:json alternateKeys:@[LZAPIResponseResultMsg, @"resultMessage", @"resultMsg", @"msg"]];
}

@end
