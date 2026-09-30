#import "LoanZen_OrderPostSubmitCoordinator.h"
#import "LoanZen_OrderContactUploadRunner.h"
#import "LoanZen_DeviceUploadService.h"

@implementation LoanZen_OrderPostSubmitCoordinator

+ (void)LZ_processOrderId:(NSString *)orderId
                presenter:(UIViewController *)presenter
                 maskView:(UIView *)maskView
               completion:(void (^)(BOOL, BOOL))completion {
    [LoanZen_DeviceUploadService LZ_uploadOrderDeviceWithOrderId:orderId completion:^(NSError *deviceError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (deviceError) {
                if (completion) completion(NO, NO);
                return;
            }
            [LoanZen_OrderContactUploadRunner LZ_runContactPhaseForOrderId:orderId
                                                                 presenter:presenter
                                                                  maskView:maskView
                                                                completion:completion];
        });
    }];
}

@end
