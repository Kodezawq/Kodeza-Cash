#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, LoanZen_KYCIDCaptureSide) {
    LoanZen_KYCIDCaptureSideFront = 0,
    LoanZen_KYCIDCaptureSideBack = 1,
};

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_KYCFourIDCameraViewController : UIViewController
- (instancetype)initWithSide:(LoanZen_KYCIDCaptureSide)side onConfirmed:(void (^)(NSString *code, NSString *base64, UIImage *preview))onConfirmed;
@end

NS_ASSUME_NONNULL_END
