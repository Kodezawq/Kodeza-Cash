#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_OrderStatusPresentation : NSObject

+ (NSString *)LZ_listBadgeTitleForStatus:(nullable NSNumber *)status;
+ (UIColor *)LZ_listBadgeColorForStatus:(nullable NSNumber *)status;
+ (nullable NSString *)LZ_listStatusBarImageNameForStatus:(nullable NSNumber *)status;
/// 拒量订单：status 31 / 41
+ (BOOL)LZ_isRejectedStatus:(nullable NSNumber *)status;

/// 历史订单列表双列日期：按状态切换标题与取值
/// - 61：Payment date / Due date
/// - 40/70/71：Payment date / Repayment date
/// - 20/60/63：Payment date（空则申请日） / Due date
/// - 其他：Date of application / Due date
+ (NSDictionary<NSString *, NSString *> *)LZ_listDateMetricsForStatus:(nullable NSNumber *)status
                                                            applyDate:(nullable NSString *)applyDate
                                                              dueDate:(nullable NSString *)dueDate
                                                           payoutDate:(nullable NSString *)payoutDate
                                                             loanDate:(nullable NSString *)loanDate
                                                        repaymentDate:(nullable NSString *)repaymentDate
                                                            repayDate:(nullable NSString *)repayDate;

+ (NSString *)LZ_detailStatusTextForStatus:(nullable NSNumber *)status;
+ (BOOL)LZ_showsRepayButtonForStatus:(nullable NSNumber *)status;
+ (BOOL)LZ_showsExtensionButtonForStatus:(nullable NSNumber *)status ifExtension:(nullable NSString *)ifExtension;
+ (nullable NSString *)LZ_primaryActionTitleForStatus:(nullable NSNumber *)status;
+ (nullable NSString *)LZ_bottomTipForStatus:(nullable NSNumber *)status;

@end

NS_ASSUME_NONNULL_END
