#import "LoanZen_LoginGatekeeper.h"
#import "LoanZen_SessionStore.h"
#import "LoanZen_AppRouter.h"
#import "LoanZen_LoginViewController.h"

@implementation LoanZen_LoginGatekeeper

+ (BOOL)LZ_requireLoginIfNeededFrom:(UIViewController *)controller {
    if (LoanZen_SessionStore.shared.isLoggedIn) return NO;
    if (controller.presentedViewController) return YES;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[LoanZen_LoginViewController alloc] init]];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [nav setNavigationBarHidden:YES animated:NO];
    [controller presentViewController:nav animated:YES completion:nil];
    return YES;
}

@end
