#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_OrderService : NSObject

+ (void)LZ_fetchOrderListWithStatus:(NSInteger)orderStatus
                        showLoading:(BOOL)showLoading
                         completion:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion;

+ (void)LZ_fetchOrderDetailWithOrderId:(NSString *)orderId
                             productId:(nullable NSString *)productId
                            completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion;

+ (void)LZ_repayConnectWithOrderId:(NSString *)orderId
                 payAccountNumber:(nullable NSString *)payAccountNumber
                       completion:(void (^)(NSString * _Nullable link, NSError * _Nullable error))completion;

+ (void)LZ_repayExtensionWithOrderId:(NSString *)orderId
                    payAccountNumber:(nullable NSString *)payAccountNumber
                          completion:(void (^)(NSString * _Nullable link, NSError * _Nullable error))completion;

+ (void)LZ_fetchWithdrawalDetailWithOrderId:(NSString *)orderId
                                  productId:(nullable NSString *)productId
                                 completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion;

+ (void)LZ_applyWithdrawalWithOrderId:(NSString *)orderId
                           loanAmount:(nullable NSString *)loanAmount
                             loanTerm:(nullable NSString *)loanTerm
                           completion:(void (^)(NSError * _Nullable))completion;

@end

NS_ASSUME_NONNULL_END
