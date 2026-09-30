#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_ProductService : NSObject
+ (NSDictionary *)LZ_mapProductItem:(NSDictionary *)item;
+ (void)LZ_fetchProductTermWithProductId:(NSString *)productId completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion;
+ (void)LZ_fetchProductTermEnvelopeWithProductId:(NSString *)productId showLoading:(BOOL)showLoading completion:(void (^)(NSDictionary * _Nullable json, NSError * _Nullable error))completion;
+ (void)LZ_fetchProductListWithCompletion:(void (^)(NSArray<NSDictionary *> * _Nullable list, NSError * _Nullable error))completion;
+ (void)LZ_fetchProductStateWithProductId:(nullable NSString *)productId completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion;
+ (void)LZ_submitOrderWithProductId:(NSString *)productId loanAmount:(NSString *)amount showTerm:(NSString *)showTerm bankCardBindId:(nullable NSString *)bindId longitude:(NSString *)longitude latitude:(NSString *)latitude completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion;
+ (void)LZ_submitOrderWithProductId:(NSString *)productId loanAmount:(NSString *)amount showTerm:(NSString *)showTerm bankCardBindId:(nullable NSString *)bindId longitude:(NSString *)longitude latitude:(NSString *)latitude showLoading:(BOOL)showLoading completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion;
@end

NS_ASSUME_NONNULL_END
