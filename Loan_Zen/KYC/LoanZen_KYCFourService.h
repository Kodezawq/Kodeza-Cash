#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_KYCFourService : NSObject

+ (void)LZ_fetchFourStatusWithLoading:(BOOL)showLoading completion:(void (^)(NSNumber * _Nullable step, NSError * _Nullable error))completion;
+ (void)LZ_fetchSearchItemsForStep:(NSInteger)step showLoading:(BOOL)showLoading completion:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion;
+ (void)LZ_fetchSearchItemsForStep:(NSInteger)step completion:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion;
+ (void)LZ_fetchSearchItemsWithCompletion:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion;
+ (void)LZ_fetchProvinceListWithCountryId:(NSString *)countryId completion:(void (^)(NSArray<NSDictionary *> * _Nullable pairs, NSError * _Nullable error))completion;
+ (void)LZ_fetchCityListWithCountryId:(NSString *)countryId provinceId:(NSString *)provinceId completion:(void (^)(NSArray<NSDictionary *> * _Nullable pairs, NSError * _Nullable error))completion;
+ (void)LZ_submitStep:(NSInteger)step fields:(NSDictionary *)fields completion:(void (^)(NSError * _Nullable))completion;

@end

NS_ASSUME_NONNULL_END
