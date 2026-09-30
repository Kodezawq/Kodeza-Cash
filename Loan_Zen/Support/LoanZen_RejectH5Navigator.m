#import "LoanZen_RejectH5Navigator.h"
#import "LoanZen_RejectH5ViewController.h"
#import "LoanZen_AppConfigStore.h"
#import "LoanZen_HUD.h"

@implementation LoanZen_RejectH5Navigator

+ (BOOL)LZ_hasURL {
    return [self LZ_resolvedURL] != nil;
}

+ (void)LZ_openFrom:(UIViewController *)host message:(NSString *)message {
    if (!host) return;
    NSURL *url = [self LZ_resolvedURL];
    if (!url) {
        NSString *msg = [message stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        [LoanZen_HUD LZ_showError:msg.length > 0 ? msg : @"System is busy, please try again later."];
        return;
    }
    LoanZen_RejectH5ViewController *vc = [[LoanZen_RejectH5ViewController alloc] initWithURL:url];
    if (host.navigationController) {
        [host.navigationController pushViewController:vc animated:YES];
    } else {
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        [host presentViewController:nav animated:YES completion:nil];
    }
}

+ (NSURL *)LZ_resolvedURL {
    NSString *raw = [[LoanZen_AppConfigStore LZ_resolvedRejectH5URL] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (raw.length == 0) return nil;
    NSURL *url = [NSURL URLWithString:raw];
    if (url.scheme.length > 0) return url;
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", raw]];
}

@end
