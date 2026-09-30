#import "LoanZen_OrderContactUploadRunner.h"
#import "LoanZen_OrderContactSliceBuilder.h"
#import "LoanZen_DeviceUploadService.h"
#import "LoanZen_AppConfigStore.h"
#import "LoanZen_PermissionHelper.h"
#import "LoanZen_BuryReporter.h"
#import "LoanZen_Notifications.h"
#import <Contacts/Contacts.h>

static void LZContactFinish(BOOL success, BOOL contactsBlocked, LoanZen_OrderContactUploadCompletion completion) {
    if (completion) completion(success, contactsBlocked);
}

@implementation LoanZen_OrderContactUploadRunner

+ (BOOL)LZ_requiresStrictContactCollection {
    return [LoanZen_AppConfigStore LZ_isStrongDataCollectionRequired];
}

+ (UIViewController *)LZ_topPresenterFrom:(UIViewController *)presenter {
    if (!presenter) return nil;
    UIViewController *top = presenter;
    while (top.presentedViewController) {
        top = top.presentedViewController;
    }
    return top;
}

#pragma mark - HopeLoan ContactManager dismiss / request blocks

/// 对齐 HopeLoan `dismissPermissionBlock`：系统弹窗拒绝、Limited 仅部分授权、上传失败等 — 不弹自定义引导，直接结束。
+ (void)LZ_finishContactsDismissFromMaskView:(UIView *)maskView
                                  completion:(LoanZen_OrderContactUploadCompletion)completion {
    if (maskView) maskView.hidden = YES;
    LZContactFinish(NO, YES, completion);
}

/// 对齐 HopeLoan `requestPermissionBlock`：已拒绝/受限/Limited 强抓时弹自定义引导；Cancel/Confirm 均结束流程，Confirm 再跳设置。
+ (void)LZ_showContactsSettingsGuideFromPresenter:(UIViewController *)presenter
                                        maskView:(UIView *)maskView
                                      completion:(LoanZen_OrderContactUploadCompletion)completion {
    UIViewController *host = [self LZ_topPresenterFrom:presenter];
    if (!host) {
        [self LZ_finishContactsDismissFromMaskView:maskView completion:completion];
        return;
    }
    if (maskView) maskView.hidden = NO;
    void (^finishGuide)(void) = ^{
        [self LZ_finishContactsDismissFromMaskView:maskView completion:completion];
    };
    [LoanZen_PermissionHelper LZ_showSettingsGuideOn:host
                                               title:@"Contacts"
                                     permissionTitle:@"Contacts"
                                            onCancel:finishGuide
                                   onConfirmSettings:finishGuide];
}

#pragma mark - order/ready

+ (void)LZ_markOrderReady:(NSString *)orderId completion:(LoanZen_OrderContactUploadCompletion)completion {
    [LoanZen_DeviceUploadService LZ_markOrderReadyWithOrderId:orderId completion:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                [NSNotificationCenter.defaultCenter postNotificationName:LZ_NotificationOrderListShouldRefresh object:nil];
            }
            if (error && [self LZ_requiresStrictContactCollection]) {
                [self LZ_finishContactsDismissFromMaskView:nil completion:completion];
                return;
            }
            LZContactFinish(error == nil, NO, completion);
        });
    }];
}

#pragma mark - slice upload

+ (void)LZ_uploadPayloadBatch:(NSArray *)batch
                     allPayloads:(NSArray *)allPayloads
                         orderId:(NSString *)orderId
                      nextOffset:(NSInteger)nextOffset
                      batchLimit:(NSInteger)batchLimit
                      completion:(LoanZen_OrderContactUploadCompletion)completion {
    [LoanZen_DeviceUploadService LZ_uploadOrderContactsWithOrderId:orderId contacts:batch completion:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                if ([self LZ_requiresStrictContactCollection]) {
                    [self LZ_finishContactsDismissFromMaskView:nil completion:completion];
                    return;
                }
                if (error.domain.length > 0 && [error.domain isEqualToString:NSURLErrorDomain]) {
                    LZContactFinish(NO, NO, completion);
                    return;
                }
                [self LZ_markOrderReady:orderId completion:completion];
                return;
            }
            if (nextOffset >= (NSInteger)allPayloads.count) {
                [self LZ_markOrderReady:orderId completion:completion];
            } else {
                [self LZ_uploadPayloads:allPayloads
                                orderId:orderId
                             fromOffset:nextOffset
                             batchLimit:batchLimit
                             completion:completion];
            }
        });
    }];
}

+ (void)LZ_uploadPayloads:(NSArray *)payloads
                  orderId:(NSString *)orderId
               fromOffset:(NSInteger)fromOffset
               batchLimit:(NSInteger)batchLimit
               completion:(LoanZen_OrderContactUploadCompletion)completion {
    if (fromOffset >= payloads.count) {
        [self LZ_markOrderReady:orderId completion:completion];
        return;
    }

    NSInteger endOffset = MIN(fromOffset + batchLimit, (NSInteger)payloads.count);
    NSArray *batch = [payloads subarrayWithRange:NSMakeRange((NSUInteger)fromOffset, (NSUInteger)(endOffset - fromOffset))];
    [LoanZen_OrderContactSliceBuilder LZ_logContactUploadPayload:batch
                                                         orderId:orderId
                                                         context:[NSString stringWithFormat:@"upload batch offset=%ld size=%lu total=%lu",
                                                                  (long)fromOffset,
                                                                  (unsigned long)batch.count,
                                                                  (unsigned long)payloads.count]];
    [self LZ_uploadPayloadBatch:batch
                    allPayloads:payloads
                        orderId:orderId
                     nextOffset:endOffset
                     batchLimit:batchLimit
                     completion:completion];
}

+ (void)LZ_collectAndUploadForOrderId:(NSString *)orderId
                              maskView:(UIView *)maskView
                            completion:(LoanZen_OrderContactUploadCompletion)completion {
    if (maskView) maskView.hidden = NO;

    NSInteger itemCap = [LoanZen_AppConfigStore LZ_contactMaxCount];
    NSInteger batchLimit = [LoanZen_AppConfigStore LZ_contactBatchSize];

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSArray *initialSlice = [LoanZen_OrderContactSliceBuilder LZ_prepareInitialUploadSliceWithItemCap:itemCap
                                                                                            partitionSize:itemCap];
        [LoanZen_OrderContactSliceBuilder LZ_logSlicePhones:initialSlice context:@"initial slice"];
        [LoanZen_OrderContactSliceBuilder LZ_logContactUploadPayload:initialSlice
                                                             orderId:orderId
                                                             context:@"initial slice upload payload"];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (initialSlice.count == 0) {
                NSLog(@"[LoanZen OrderContact] no uploadable entries, skip /mobile/contact");
                [self LZ_markOrderReady:orderId completion:completion];
                return;
            }
            [self LZ_uploadPayloads:initialSlice
                            orderId:orderId
                         fromOffset:0
                         batchLimit:(batchLimit ?: 0)
                         completion:completion];
        });
    });
}

#pragma mark - CN permission

+ (void)LZ_runContactPhaseForOrderId:(NSString *)orderId
                          presenter:(UIViewController *)presenter
                           maskView:(UIView *)maskView
                         completion:(LoanZen_OrderContactUploadCompletion)completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
        BOOL strict = [self LZ_requiresStrictContactCollection];
        switch (status) {
            case CNAuthorizationStatusAuthorized:
                [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventContactsPermissionSuccess];
                [self LZ_collectAndUploadForOrderId:orderId maskView:maskView completion:completion];
                break;
            case CNAuthorizationStatusNotDetermined: {
                CNContactStore *store = [[CNContactStore alloc] init];
                [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError *error) {
                    (void)error;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (granted) {
                            [self LZ_confirmContactAccessForOrderId:orderId presenter:presenter maskView:maskView completion:completion];
                            return;
                        }
                        [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventContactsPermissionFailure];
                        if (strict) {
                            // HopeLoan：首次系统弹窗点拒绝 → dismissPermissionBlock，不弹自定义引导
                            [self LZ_finishContactsDismissFromMaskView:maskView completion:completion];
                        } else {
                            [self LZ_markOrderReady:orderId completion:completion];
                        }
                    });
                }];
                break;
            }
            case CNAuthorizationStatusRestricted:
            case CNAuthorizationStatusDenied:
                [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventContactsPermissionFailure];
                if (strict) {
                    // HopeLoan：已拒绝/受限 → requestPermissionBlock → 自定义引导
                    [self LZ_showContactsSettingsGuideFromPresenter:presenter maskView:maskView completion:completion];
                } else {
                    [self LZ_markOrderReady:orderId completion:completion];
                }
                break;
            case CNAuthorizationStatusLimited:
                [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventContactsPermissionPartial];
                if (strict) {
                    [self LZ_showContactsSettingsGuideFromPresenter:presenter maskView:maskView completion:completion];
                } else {
                    [self LZ_collectAndUploadForOrderId:orderId maskView:maskView completion:completion];
                }
                break;
            default:
                break;
        }
    });
}

+ (void)LZ_confirmContactAccessForOrderId:(NSString *)orderId
                               presenter:(UIViewController *)presenter
                                maskView:(UIView *)maskView
                              completion:(LoanZen_OrderContactUploadCompletion)completion {
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    BOOL strict = [self LZ_requiresStrictContactCollection];
    switch (status) {
        case CNAuthorizationStatusAuthorized:
            [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventContactsPermissionSuccess];
            [self LZ_collectAndUploadForOrderId:orderId maskView:maskView completion:completion];
            break;
        case CNAuthorizationStatusLimited:
            [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventContactsPermissionPartial];
            if (strict) {
                // HopeLoan checkContactsPermission2：Limited 强抓 → dismissPermissionBlock，不弹自定义引导
                [self LZ_finishContactsDismissFromMaskView:maskView completion:completion];
            } else {
                [self LZ_collectAndUploadForOrderId:orderId maskView:maskView completion:completion];
            }
            break;
        case CNAuthorizationStatusNotDetermined:
        case CNAuthorizationStatusRestricted:
        case CNAuthorizationStatusDenied:
            break;
        default:
            break;
    }
}

@end
