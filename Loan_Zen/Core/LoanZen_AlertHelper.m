#import "LoanZen_AlertHelper.h"
#import "LoanZen_PopupHelper.h"
#import "LoanZen_ModalAction.h"

@implementation LoanZen_AlertHelper

+ (void)LZ_showConfirmOn:(UIViewController *)controller
                   title:(NSString *)title
                 message:(NSString *)message
            confirmTitle:(NSString *)confirmTitle
             cancelTitle:(NSString *)cancelTitle
              onConfirm:(void (^)(void))onConfirm {
    [LoanZen_PopupHelper LZ_showConfirmOn:controller
                                    title:title
                                  message:message
                             confirmTitle:confirmTitle
                              cancelTitle:cancelTitle
                                onConfirm:onConfirm];
}

+ (void)LZ_showMessageOn:(UIViewController *)controller
                   title:(NSString *)title
                 message:(NSString *)message
              buttonTitle:(NSString *)buttonTitle {
    [LoanZen_PopupHelper LZ_showFrame:LoanZen_PopupFrameTips
                                   on:controller
                                title:title
                              message:message
                              actions:@[@{@"title": buttonTitle ?: @"OK", @"style": @(LoanZen_ModalActionStylePrimary)}]];
}

@end
