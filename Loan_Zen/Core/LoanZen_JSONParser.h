#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSErrorDomain const LoanZen_JSONParserErrorDomain;

typedef NS_ERROR_ENUM(LoanZen_JSONParserErrorDomain, LoanZen_JSONParserError) {
    LoanZen_JSONParserErrorInvalidResponse = 1,
    LoanZen_JSONParserErrorMissingData = 2,
    LoanZen_JSONParserErrorInvalidModel = 3,
};

@protocol LoanZen_JSONMappable <NSObject>

+ (nullable instancetype)LZ_fromDictionary:(NSDictionary *)dictionary error:(NSError * _Nullable * _Nullable)error;

@end

@interface LoanZen_JSONParser : NSObject

+ (nullable NSDictionary *)LZ_dataDictionaryFromResponseJSON:(NSDictionary *)json
                                                         error:(NSError * _Nullable * _Nullable)error;

+ (nullable id)LZ_modelFromResponseJSON:(NSDictionary *)json
                             modelClass:(Class)modelClass
                                  error:(NSError * _Nullable * _Nullable)error;

+ (nullable id)LZ_modelFromDictionary:(NSDictionary *)dictionary
                           modelClass:(Class)modelClass
                                error:(NSError * _Nullable * _Nullable)error;

+ (nullable NSString *)LZ_stringForKey:(NSString *)key
                          inDictionary:(NSDictionary *)dictionary
                         alternateKeys:(nullable NSArray<NSString *> *)alternateKeys;

+ (NSInteger)LZ_integerForKey:(NSString *)key
                 inDictionary:(NSDictionary *)dictionary
                alternateKeys:(nullable NSArray<NSString *> *)alternateKeys
                 defaultValue:(NSInteger)defaultValue;

+ (BOOL)LZ_boolForKey:(NSString *)key
         inDictionary:(NSDictionary *)dictionary
        alternateKeys:(nullable NSArray<NSString *> *)alternateKeys
         defaultValue:(BOOL)defaultValue;

+ (nullable NSArray *)LZ_modelArrayFromArray:(NSArray *)array
                                modelClass:(Class)modelClass;

+ (NSInteger)LZ_businessCodeFromResponseJSON:(NSDictionary *)json;
+ (nullable NSString *)LZ_messageFromResponseJSON:(NSDictionary *)json;

@end

NS_ASSUME_NONNULL_END
