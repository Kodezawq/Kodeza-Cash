#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_TermBusinessHelper : NSObject

+ (BOOL)LZ_handleTermResponse:(NSDictionary *)json
                   controller:(UIViewController *)controller
                    productId:(NSString *)productId
                    onSuccess:(void (^ _Nullable)(NSDictionary *termData))onSuccess;

+ (void)LZ_presentPendingWithdrawalFrom:(UIViewController *)controller
                                productId:(nullable NSString *)productId
                                  orderId:(nullable NSString *)orderId;

+ (void)LZ_presentPendingWithdrawalFrom:(UIViewController *)controller
                                productId:(nullable NSString *)productId
                                  orderId:(nullable NSString *)orderId
                                  message:(nullable NSString *)message;

+ (void)LZ_presentProcessingOrderFrom:(UIViewController *)controller;

+ (void)LZ_presentProcessingOrderFrom:(UIViewController *)controller
                              message:(nullable NSString *)message
                            productId:(nullable NSString *)productId;

+ (void)LZ_presentProcessingOrderFrom:(UIViewController *)controller
                              message:(nullable NSString *)message
                            productId:(nullable NSString *)productId
                     preferWithdrawal:(BOOL)preferWithdrawal;

+ (void)LZ_navigateToOrderDetailWithOrderId:(NSString *)orderId
                                   productId:(nullable NSString *)productId
                          preferWithdrawal:(BOOL)preferWithdrawal
                                        from:(UIViewController *)controller;

+ (void)LZ_navigateToOrdersWithRequestStatus:(NSInteger)requestStatus from:(UIViewController *)controller;

@end

NS_ASSUME_NONNULL_END
