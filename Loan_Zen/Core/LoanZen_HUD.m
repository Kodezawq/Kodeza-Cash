#import "LoanZen_HUD.h"
#import "LoanZen_ColorUtils.h"
@import SVProgressHUD;

@implementation LoanZen_HUD {
}
static NSLock *sLock;
static NSInteger sRequestDepth;
static BOOL sConfigured;

+ (void)initialize {
    if (self == [LoanZen_HUD class]) {
        sLock = [[NSLock alloc] init];
        sRequestDepth = 0;
        sConfigured = NO;
    }
}

+ (void)LZ_configureIfNeeded {
    [sLock lock];
    if (sConfigured) {
        [sLock unlock];
        return;
    }
    sConfigured = YES;
    [sLock unlock];
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD setDefaultStyle:SVProgressHUDStyleCustom];
        [SVProgressHUD setBackgroundColor:[LoanZen_ColorUtils LZ_modalCardBackground]];
        [SVProgressHUD setForegroundColor:UIColor.whiteColor];
        [SVProgressHUD setCornerRadius:16];
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
        [SVProgressHUD setMinimumDismissTimeInterval:1.2];
    });
}

+ (void)LZ_requestWillBeginLoading {
    dispatch_async(dispatch_get_main_queue(), ^{
        [sLock lock];
        sRequestDepth += 1;
        BOOL first = sRequestDepth == 1;
        [sLock unlock];
        if (!first) return;
        [self LZ_configureIfNeeded];
        [SVProgressHUD showWithStatus:@"Loading"];
    });
}

+ (void)LZ_requestDidEndLoading {
    dispatch_async(dispatch_get_main_queue(), ^{
        [sLock lock];
        sRequestDepth = MAX(0, sRequestDepth - 1);
        BOOL done = sRequestDepth == 0;
        [sLock unlock];
        if (!done) return;
        [SVProgressHUD dismiss];
    });
}

+ (void)LZ_showBlockingLoading {
    [self LZ_showBlockingLoading:@"Loading"];
}

+ (void)LZ_showBlockingLoading:(NSString *)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self LZ_configureIfNeeded];
        NSString *text = [status stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (text.length == 0) text = @"Loading";
        [SVProgressHUD showWithStatus:text];
    });
}

+ (void)LZ_hideBlockingLoading {
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
    });
}

+ (void)LZ_showSuccess:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self LZ_configureIfNeeded];
        [SVProgressHUD showSuccessWithStatus:message ?: @""];
    });
}

+ (void)LZ_showError:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self LZ_configureIfNeeded];
        [SVProgressHUD showErrorWithStatus:message ?: @""];
    });
}

@end
