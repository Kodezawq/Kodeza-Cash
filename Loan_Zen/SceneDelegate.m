//
//  SceneDelegate.m
//  Loan_Zen
//

#import "SceneDelegate.h"
#import "LoanZen_AppRouter.h"
#import "LoanZen_AdjustUserInfoSync.h"
#import "LoanZen_SessionStore.h"

@interface SceneDelegate ()
@end

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) return;
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    [LoanZen_AppRouter LZ_showMainInterfaceInWindow:self.window];
    if (LoanZen_SessionStore.shared.isLoggedIn) {
        [LoanZen_AdjustUserInfoSync LZ_scheduleUserInfoReport];
    }
}

@end
