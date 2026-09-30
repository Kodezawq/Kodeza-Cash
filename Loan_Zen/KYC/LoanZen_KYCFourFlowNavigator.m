#import "LoanZen_KYCFourFlowNavigator.h"
#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_KYCFourStepViewController.h"
#import "LoanZen_KYCFourContactViewController.h"
#import "LoanZen_KYCFourIdentityViewController.h"
#import "LoanZen_KYCFourService.h"
#import "LoanZen_KYCFourFlowStore.h"
#import "LoanZen_EMIResultViewController.h"
#import "LoanZen_MainTabController.h"
#import "LoanZen_HUD.h"
#import "LoanZen_AppRouter.h"
#import "LoanZen_SessionStore.h"
#import "LoanZen_PopupHelper.h"
#import "LoanZen_Notifications.h"

@implementation LoanZen_KYCFourFlowNavigator

+ (BOOL)LZ_isKYCViewController:(UIViewController *)vc {
    return [vc isKindOfClass:[LoanZen_KYCFourStepViewController class]]
        || [vc isKindOfClass:[LoanZen_KYCFourContactViewController class]]
        || [vc isKindOfClass:[LoanZen_KYCFourIdentityViewController class]];
}

+ (UIViewController *)LZ_viewControllerForStep:(NSInteger)step {
    if (step == 4) return [[LoanZen_KYCFourIdentityViewController alloc] init];
    if (step == 3) return [[LoanZen_KYCFourContactViewController alloc] init];
    return [[LoanZen_KYCFourStepViewController alloc] initWithStep:step];
}

+ (void)LZ_applyStageKycIdFromSearchItems:(NSInteger)step list:(NSArray<NSDictionary *> *)list {
    NSString *stageKycId = nil;
    if (step == 2) {
        stageKycId = @"work_questionnaire";
    } else {
        NSMutableSet<NSString *> *unique = [NSMutableSet set];
        for (NSDictionary *item in list) {
            NSString *kid = [item[LZAPIFieldKycId] isKindOfClass:[NSString class]] ? [item[LZAPIFieldKycId] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] : @"";
            if (kid.length > 0) [unique addObject:kid];
        }
        stageKycId = unique.anyObject;
    }
    [LoanZen_KYCFourFlowStore.shared LZ_applyStageKycId:stageKycId];
}

+ (void)LZ_continueToStep:(NSInteger)step from:(UIViewController *)host pushNext:(BOOL)pushNext animated:(BOOL)animated {
    UINavigationController *nav = host.navigationController;
    if (!nav) {
        [LoanZen_HUD LZ_showError:@"Unable to open KYC page."];
        return;
    }
    UIViewController *next = [self LZ_viewControllerForStep:step];
    if (pushNext) {
        [nav pushViewController:next animated:animated];
        return;
    }
    NSMutableArray *vcs = nav.viewControllers.mutableCopy;
    NSInteger idx = [vcs indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [self LZ_isKYCViewController:obj];
    }];
    if (idx != NSNotFound) {
        [vcs replaceObjectsInRange:NSMakeRange(idx, vcs.count - idx) withObjectsFromArray:@[next]];
        [nav setViewControllers:vcs animated:animated];
    } else {
        [nav pushViewController:next animated:animated];
    }
}

+ (void)LZ_syncNavigationToCurrentStepFrom:(UIViewController *)host animated:(BOOL)animated {
    NSNumber *stepNumber = LoanZen_KYCFourFlowStore.shared.currentStepNumber;
    if (stepNumber == nil || stepNumber.integerValue < 1 || stepNumber.integerValue > 4) return;
    [self LZ_continueToStep:stepNumber.integerValue from:host pushNext:NO animated:animated];
}

+ (void)LZ_pushPreparedStep:(NSInteger)step from:(UIViewController *)host animated:(BOOL)animated {
    if (step < 1 || step > 4) return;
    [self LZ_continueToStep:step from:host pushNext:YES animated:animated];
}

+ (void)LZ_openStepAfterStatus:(NSInteger)targetStep from:(UIViewController *)host animated:(BOOL)animated {
    [LoanZen_KYCFourService LZ_fetchSearchItemsForStep:targetStep showLoading:NO completion:^(NSArray<NSDictionary *> *list, NSError *searchError) {
        (void)list;
        (void)searchError;
        [LoanZen_HUD LZ_hideBlockingLoading];
        [self LZ_pushPreparedStep:targetStep from:host animated:animated];
    }];
}

+ (void)LZ_enterFlowFrom:(UIViewController *)host animated:(BOOL)animated {
    if (!LoanZen_SessionStore.shared.isLoggedIn) {
        [LoanZen_AppRouter LZ_showLoginInterfaceInWindow:host.view.window];
        return;
    }
    LoanZen_KYCFourFlowStore.shared.flowOrigin = LoanZen_KYCFlowOriginDefault;
    __weak UIViewController *weakHost = host;
    [LoanZen_HUD LZ_showBlockingLoading];
    [LoanZen_KYCFourService LZ_fetchFourStatusWithLoading:NO completion:^(NSNumber *step, NSError *error) {
        UIViewController *strongHost = weakHost;
        if (!strongHost) {
            [LoanZen_HUD LZ_hideBlockingLoading];
            return;
        }
        if (error) {
            [LoanZen_HUD LZ_hideBlockingLoading];
            [LoanZen_HUD LZ_showError:error.localizedDescription];
            return;
        }
        if (step == nil) {
            [LoanZen_HUD LZ_hideBlockingLoading];
            [LoanZen_HUD LZ_showError:@"Failed to load KYC status."];
            return;
        }
        if (step.integerValue == -1) {
            [LoanZen_HUD LZ_hideBlockingLoading];
            [LoanZen_HUD LZ_showSuccess:@"All KYC steps are completed."];
            [NSNotificationCenter.defaultCenter postNotificationName:LZ_NotificationHomeShouldRefresh object:nil];
            return;
        }
        if (step.integerValue < 1 || step.integerValue > 4) {
            [LoanZen_HUD LZ_hideBlockingLoading];
            [LoanZen_HUD LZ_showError:@"Invalid KYC step from server."];
            return;
        }
        [self LZ_openStepAfterStatus:step.integerValue from:strongHost animated:animated];
    }];
}

+ (void)LZ_advanceFrom:(UIViewController *)host pushNext:(BOOL)pushNext animated:(BOOL)animated {
    __weak UIViewController *weakHost = host;
    [LoanZen_KYCFourService LZ_fetchFourStatusWithLoading:NO completion:^(NSNumber *step, NSError *error) {
        UIViewController *strongHost = weakHost;
        if (!strongHost) return;
        if (error && !pushNext) {
            [LoanZen_HUD LZ_showError:error.localizedDescription];
            return;
        }
        if (step == nil) return;
        if (step.integerValue == -1) {
            [self LZ_exitFlowFrom:strongHost completed:YES];
            return;
        }
        if (step.integerValue < 1 || step.integerValue > 4) return;
        NSInteger targetStep = step.integerValue;
        [LoanZen_KYCFourService LZ_fetchSearchItemsForStep:targetStep showLoading:NO completion:^(NSArray<NSDictionary *> *list, NSError *searchError) {
            (void)list;
            (void)searchError;
            [self LZ_continueToStep:targetStep from:strongHost pushNext:pushNext animated:animated];
        }];
    }];
}

+ (void)LZ_confirmExitFrom:(UIViewController *)host {
    BOOL fromEMI = LoanZen_KYCFourFlowStore.shared.flowOrigin == LoanZen_KYCFlowOriginEMIResult;
    NSString *message = fromEMI
        ? @"Do you want to pause the authentication and return to the EMI calculator?"
        : @"Do you want to pause the authentication and return to the homepage?";
    __weak UIViewController *weakHost = host;
    [LoanZen_PopupHelper LZ_showConfirmOn:host title:@"Confirm to return?" message:message confirmTitle:@"Confirm" cancelTitle:@"Cancel" onConfirm:^{
        [self LZ_exitFlowFrom:weakHost completed:NO];
    }];
}

+ (void)LZ_switchToHomeTabFrom:(UIViewController *)host {
    UIResponder *responder = host;
    while (responder) {
        if ([responder isKindOfClass:[LoanZen_MainTabController class]]) {
            UINavigationController *nav = host.navigationController;
            if (nav.viewControllers.count > 1) {
                [nav popToRootViewControllerAnimated:NO];
            }
            [(LoanZen_MainTabController *)responder LZ_switchToHomeTab];
            return;
        }
        responder = responder.nextResponder;
    }
    [LoanZen_AppRouter LZ_showMainInterfaceInWindow:host.view.window];
}

+ (void)LZ_exitFlowFrom:(UIViewController *)host completed:(BOOL)completed {
    if (!host) return;
    LoanZen_KYCFlowOrigin origin = LoanZen_KYCFourFlowStore.shared.flowOrigin;
    [LoanZen_KYCFourFlowStore.shared LZ_resetFlowOrigin];

    if (completed) {
        if (origin == LoanZen_KYCFlowOriginEMIResult) {
            [self LZ_switchToHomeTabFrom:host];
        } else {
            [LoanZen_AppRouter LZ_showMainInterfaceInWindow:host.view.window];
        }
        [NSNotificationCenter.defaultCenter postNotificationName:LZ_NotificationHomeShouldRefresh object:nil];
        return;
    }

    if (origin == LoanZen_KYCFlowOriginEMIResult) {
        UINavigationController *nav = host.navigationController;
        for (UIViewController *vc in nav.viewControllers) {
            if ([vc isKindOfClass:[LoanZen_EMIResultViewController class]]) {
                [nav popToViewController:vc animated:YES];
                return;
            }
        }
    }

    [LoanZen_AppRouter LZ_showMainInterfaceInWindow:host.view.window];
}

@end
