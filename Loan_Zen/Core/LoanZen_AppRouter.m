#import "LoanZen_AppRouter.h"
#import "LoanZen_MainTabController.h"
#import "LoanZen_LoginViewController.h"

@implementation LoanZen_AppRouter

+ (UIWindow *)LZ_keyWindow {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        for (UIWindow *window in windowScene.windows) {
            if (window.isKeyWindow) return window;
        }
    }
    return nil;
}

+ (void)LZ_showMainInterfaceInWindow:(UIWindow *)window {
    UIWindow *target = window ?: [self LZ_keyWindow];
    target.rootViewController = [[LoanZen_MainTabController alloc] init];
    [target makeKeyAndVisible];
}

+ (void)LZ_showLoginInterfaceInWindow:(UIWindow *)window {
    UIWindow *target = window ?: [self LZ_keyWindow];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[LoanZen_LoginViewController alloc] init]];
    [nav setNavigationBarHidden:YES animated:NO];
    target.rootViewController = nav;
    [target makeKeyAndVisible];
}

@end
