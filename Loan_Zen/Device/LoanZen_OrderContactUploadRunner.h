#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^LoanZen_OrderContactUploadCompletion)(BOOL success, BOOL contactsBlocked);

/// 下单后通讯录权限、切片采集与分批上传。
@interface LoanZen_OrderContactUploadRunner : NSObject

+ (void)LZ_runContactPhaseForOrderId:(NSString *)orderId
                          presenter:(UIViewController *)presenter
                           maskView:(UIView * _Nullable)maskView
                         completion:(LoanZen_OrderContactUploadCompletion)completion;

@end

NS_ASSUME_NONNULL_END
