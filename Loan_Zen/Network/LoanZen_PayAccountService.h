#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_PayAccountService : NSObject
+ (void)LZ_fetchPayAccountList:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion;
+ (void)LZ_fetchPayAccountItemList:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion;
+ (void)LZ_fetchPayAccountItemListWithShowLoading:(BOOL)showLoading completion:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion;
+ (void)LZ_fetchBankList:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion;
+ (void)LZ_fetchBankListWithShowLoading:(BOOL)showLoading completion:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion;
+ (void)LZ_fetchWalletList:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion;
+ (void)LZ_fetchWalletListWithShowLoading:(BOOL)showLoading completion:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion;
+ (void)LZ_savePayAccountWithDefaultFlag:(NSString *)defaultFlag commits:(NSArray<NSDictionary *> *)commits completion:(void (^)(NSError * _Nullable))completion;
+ (void)LZ_updatePayAccountWithRecordId:(NSString *)recordId defaultFlag:(NSString *)defaultFlag commits:(NSArray<NSDictionary *> *)commits completion:(void (^)(NSError * _Nullable))completion;
@end

NS_ASSUME_NONNULL_END
