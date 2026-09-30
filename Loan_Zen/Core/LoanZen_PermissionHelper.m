#import "LoanZen_PermissionHelper.h"
#import "LoanZen_PopupHelper.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_BuryReporter.h"
@import AVFoundation;

@implementation LoanZen_PermissionHelper

+ (NSString *)LZ_appDisplayName {
    NSString *name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (name.length == 0) name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    return name.length > 0 ? name : @"Loan Zen";
}

+ (NSString *)LZ_settingsMessageForPermission:(NSString *)permissionTitle {
    NSString *app = [self LZ_appDisplayName];
    NSString *key = permissionTitle.lowercaseString;
    if ([key containsString:@"location"]) {
        return [NSString stringWithFormat:@"Please allow %@ to access location in the settings so that you can complete the loan application", app];
    }
    if ([key containsString:@"camera"]) {
        return [NSString stringWithFormat:@"Please allow %@ to access camera in the settings so that you can take photos", app];
    }
    if ([key containsString:@"isThirdAthena"] || [key containsString:@"album"]) {
        return [NSString stringWithFormat:@"Please allow %@ to access photo library in the settings so that you can select photos", app];
    }
    if ([key containsString:@"contact"]) {
        return [NSString stringWithFormat:@"%@ needs to access your contacts to perform fraud detection. This process helps us verify your identity and ensure the security of your account. To avoid affecting the review results, please select \"Allow Full Access\" when authorizing. We attach great importance to your privacy, and your contact information will be uploaded to our server, but will not be stored or shared with third parties. You can change your authorization at any time in the settings.", app];
    }
    return [NSString stringWithFormat:@"Please allow %@ to access %@ in the settings so that you can complete the loan application", app, key];
}

+ (NSString *)LZ_iconNameForPermission:(NSString *)permissionTitle {
    NSString *key = permissionTitle.lowercaseString;
    if ([key containsString:@"location"]) return @"lz_tk_dw";
    if ([key containsString:@"contact"]) return @"lz_tk_txl";
    if ([key containsString:@"camera"]) return @"lz_tk_xj";
    if ([key containsString:@"isThirdAthena"] || [key containsString:@"album"]) return @"lz_tk_xj";
    return nil;
}

+ (LoanZen_PopupFrame)LZ_popupFrameForPermissionTitle:(NSString *)permissionTitle {
    NSString *key = permissionTitle.lowercaseString;
    if ([key containsString:@"contact"]) return LoanZen_PopupFrameContacts;
    return LoanZen_PopupFramePermission;
}

+ (void)LZ_openSettings {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if (url) [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

+ (void)LZ_showSettingsGuideOn:(UIViewController *)controller
                         title:(NSString *)title
               permissionTitle:(NSString *)permissionTitle {
    [self LZ_showSettingsGuideOn:controller title:title permissionTitle:permissionTitle onCancel:nil onConfirmSettings:nil];
}

+ (void)LZ_showSettingsGuideOn:(UIViewController *)controller
                         title:(NSString *)title
               permissionTitle:(NSString *)permissionTitle
                      onCancel:(void (^)(void))onCancel
             onConfirmSettings:(void (^)(void))onConfirmSettings {
    if (!controller) return;
    NSString *icon = [self LZ_iconNameForPermission:permissionTitle];
    LoanZen_PopupFrame frame = [self LZ_popupFrameForPermissionTitle:permissionTitle];
    [LoanZen_PopupHelper LZ_showFrame:frame
                                   on:controller
                                title:title ?: @"Permission"
                              message:[self LZ_settingsMessageForPermission:permissionTitle]
                             iconName:icon
                              actions:@[
        @{@"title": @"Cancel", @"style": @(LoanZen_ModalActionStyleCancel), @"handler": onCancel ?: ^{}},
        @{@"title": @"Confirm", @"style": @(LoanZen_ModalActionStylePrimary), @"handler": ^{
            if (onConfirmSettings) onConfirmSettings();
            [self LZ_openSettings];
        }},
    ]];
}

+ (void)LZ_requestCameraAccessOn:(UIViewController *)controller granted:(void (^)(void))granted {
    if (!controller || !granted) return;
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusAuthorized) {
        [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventCameraPermissionSuccess];
        granted();
        return;
    }
    if (status == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL allowed) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (allowed) {
                    [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventCameraPermissionSuccess];
                    granted();
                    return;
                }
                /// 系统弹窗点不允许后不自动弹二次引导；已拒绝状态下再次点击 Camera 再提示去设置。
                [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventCameraPermissionFailure];
            });
        }];
        return;
    }
    [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventCameraPermissionFailure];
    [self LZ_showSettingsGuideOn:controller title:@"Camera" permissionTitle:@"Camera"];
}

@end
