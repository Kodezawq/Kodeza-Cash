#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_SupHomeStore : NSObject
+ (nullable NSDictionary *)LZ_lastResponse;
+ (void)LZ_applyResponse:(nullable NSDictionary *)response;
+ (void)LZ_clear;
@end

@interface LoanZen_SupHomeService : NSObject

+ (void)LZ_refreshIfLoggedInWithShowLoading:(BOOL)showLoading
                                completion:(void (^ _Nullable)(NSDictionary * _Nullable, NSError * _Nullable))completion;

@end

NS_ASSUME_NONNULL_END
