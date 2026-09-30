#import "LoanZen_TermBusinessHelper.h"
#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_PopupHelper.h"
#import "LoanZen_SupHomeParser.h"
#import "LoanZen_OrderDetailViewController.h"
#import "LoanZen_MainTabController.h"
#import "LoanZen_JSONParser.h"
#import "LoanZen_RejectH5Navigator.h"

static NSString * const LZ_DefaultProcessingOrderMessage =
@"You have already applied for this product, and your current application is being processed. You cannot apply again at this time. You can view the order details or go back to choose another product to apply for.";

@implementation LoanZen_TermBusinessHelper

+ (BOOL)LZ_handleTermResponse:(NSDictionary *)json
                   controller:(UIViewController *)controller
                    productId:(NSString *)productId
                    onSuccess:(void (^)(NSDictionary *))onSuccess {
    NSInteger code = [LoanZen_JSONParser LZ_businessCodeFromResponseJSON:json];
    if (code == 6230002) {
        NSString *message = [LoanZen_JSONParser LZ_messageFromResponseJSON:json];
        [self LZ_presentProcessingOrderFrom:controller message:message productId:productId preferWithdrawal:NO];
        return YES;
    }
    if (code == 6230003) {
        NSString *message = [LoanZen_JSONParser LZ_messageFromResponseJSON:json];
        [self LZ_presentProcessingOrderFrom:controller message:message productId:productId preferWithdrawal:YES];
        return YES;
    }
    if (code == 6234303) {
        if (![LoanZen_RejectH5Navigator LZ_hasURL]) return NO;
        [LoanZen_RejectH5Navigator LZ_openFrom:controller message:[LoanZen_JSONParser LZ_messageFromResponseJSON:json]];
        return YES;
    }
    BOOL success = [json[LZAPIResponseSuccess] boolValue] || code == 200;
    NSDictionary *data = [json[LZAPIResponseData] isKindOfClass:[NSDictionary class]] ? json[LZAPIResponseData] : nil;
    if (!success || !data) return NO;
    if (onSuccess) {
        onSuccess(data);
        return YES;
    }
    return NO;
}

+ (void)LZ_presentPendingWithdrawalFrom:(UIViewController *)controller
                              productId:(NSString *)productId
                                orderId:(NSString *)orderId {
    [self LZ_presentPendingWithdrawalFrom:controller productId:productId orderId:orderId message:nil];
}

+ (void)LZ_presentPendingWithdrawalFrom:(UIViewController *)controller
                              productId:(NSString *)productId
                                orderId:(NSString *)orderId
                                message:(NSString *)message {
    NSString *resolvedMessage = message.length > 0 ? message
        : @"You have an order pending withdrawal. After entering the page to confirm, the funds will be transferred to your bank account immediately.";
    __weak UIViewController *weakController = controller;
    [LoanZen_PopupHelper LZ_showFrame:LoanZen_PopupFrameWithdraw
                                   on:controller
                                title:@"To be withdrawn"
                              message:resolvedMessage
                             iconName:nil
                              actions:@[
        @{@"title": @"Cancel", @"style": @(LoanZen_ModalActionStyleCancel)},
        @{@"title": @"Withdraw", @"style": @(LoanZen_ModalActionStylePrimary), @"handler": ^{
            NSString *resolvedOrderId = orderId.length > 0 ? orderId : @"1";
            [LoanZen_TermBusinessHelper LZ_navigateToOrderDetailWithOrderId:resolvedOrderId
                                                                  productId:productId
                                                         preferWithdrawal:YES
                                                                       from:weakController];
        }},
    ]];
}

+ (void)LZ_presentProcessingOrderFrom:(UIViewController *)controller {
    [self LZ_presentProcessingOrderFrom:controller message:nil productId:nil preferWithdrawal:NO];
}

+ (void)LZ_presentProcessingOrderFrom:(UIViewController *)controller
                              message:(NSString *)message
                            productId:(NSString *)productId {
    [self LZ_presentProcessingOrderFrom:controller message:message productId:productId preferWithdrawal:NO];
}

+ (void)LZ_presentProcessingOrderFrom:(UIViewController *)controller
                              message:(NSString *)message
                            productId:(NSString *)productId
                   preferWithdrawal:(BOOL)preferWithdrawal {
    NSString *resolvedMessage = message.length > 0 ? message : LZ_DefaultProcessingOrderMessage;
    __weak UIViewController *weakController = controller;
    [LoanZen_PopupHelper LZ_showFrame:LoanZen_PopupFrameTips
                                   on:controller
                                title:@"Tip"
                              message:resolvedMessage
                              actions:@[
        @{@"title": @"Back", @"style": @(LoanZen_ModalActionStyleCancel)},
        @{@"title": @"View More", @"style": @(LoanZen_ModalActionStylePrimary), @"handler": ^{
            [LoanZen_TermBusinessHelper LZ_navigateToOrderDetailWithOrderId:@"1"
                                                                  productId:productId
                                                         preferWithdrawal:preferWithdrawal
                                                                       from:weakController];
        }},
    ]];
}

+ (void)LZ_navigateToOrderDetailWithOrderId:(NSString *)orderId
                                   productId:(NSString *)productId
                          preferWithdrawal:(BOOL)preferWithdrawal
                                        from:(UIViewController *)controller {
    if (!controller.navigationController) return;
    NSString *resolvedOrderId = orderId.length > 0 ? orderId : @"1";
    LoanZen_OrderDetailViewController *detail = [[LoanZen_OrderDetailViewController alloc] initWithOrderId:resolvedOrderId
                                                                                                productId:productId
                                                                                       preferWithdrawal:preferWithdrawal];
    [controller.navigationController pushViewController:detail animated:YES];
}

+ (LoanZen_MainTabController *)LZ_mainTabControllerFrom:(UIViewController *)controller {
    UIResponder *responder = controller;
    while (responder) {
        if ([responder isKindOfClass:[LoanZen_MainTabController class]]) {
            return (LoanZen_MainTabController *)responder;
        }
        responder = responder.nextResponder;
    }
    return nil;
}

+ (void)LZ_navigateToOrdersWithRequestStatus:(NSInteger)requestStatus from:(UIViewController *)controller {
    LoanZen_MainTabController *tab = [self LZ_mainTabControllerFrom:controller];
    if (!tab) return;
    [tab LZ_switchToOrderTabWithRequestStatus:requestStatus];
}

@end
