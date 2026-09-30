#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_PermissionHelper : NSObject

+ (NSString *)LZ_appDisplayName;
+ (NSString *)LZ_settingsMessageForPermission:(NSString *)permissionTitle;
+ (nullable NSString *)LZ_iconNameForPermission:(NSString *)permissionTitle;
+ (void)LZ_openSettings;


+ (void)LZ_showSettingsGuideOn:(UIViewController *)controller
                         title:(NSString *)title
               permissionTitle:(NSString *)permissionTitle;

+ (void)LZ_showSettingsGuideOn:(UIViewController *)controller
                         title:(NSString *)title
               permissionTitle:(NSString *)permissionTitle
                      onCancel:(void (^ _Nullable)(void))onCancel
             onConfirmSettings:(void (^ _Nullable)(void))onConfirmSettings;


+ (void)LZ_requestCameraAccessOn:(UIViewController *)controller
                          granted:(void (^)(void))granted;

@end

NS_ASSUME_NONNULL_END
