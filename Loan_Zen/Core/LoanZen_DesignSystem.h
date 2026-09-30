#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 布局常量（对齐 AI-PH29-DC 375 宽设计稿）
FOUNDATION_EXPORT const CGFloat LZ_SizePageInset;
FOUNDATION_EXPORT const CGFloat LZ_SizeStatusBarHeight;
FOUNDATION_EXPORT const CGFloat LZ_SizeBottomBarHeight;
FOUNDATION_EXPORT const CGFloat LZ_SizePrimaryButtonHeight;

@interface LoanZen_Color : NSObject
+ (UIColor *)background;
+ (UIColor *)card;
+ (UIColor *)primaryText;
+ (UIColor *)secondaryText;
+ (UIColor *)accent;
+ (UIColor *)separator;
+ (UIColor *)danger;
+ (UIColor *)formTitleText;
+ (UIColor *)formPlaceholder;
+ (UIColor *)formInputBackground;
+ (UIColor *)modalCancelBackground;
+ (UIColor *)kycFormCardFill;
+ (UIColor *)kycFormCardBorder;
+ (UIColor *)kycFormInputFill;
+ (UIColor *)kycFormInputBorder;
+ (UIColor *)kycFormLabel;
+ (UIColor *)kycFormValue;
+ (UIColor *)kycFormPlaceholder;
+ (UIColor *)homePromptFill;
+ (UIColor *)homePromptBorder;
+ (UIColor *)kycProgressInactive;
@end

@interface LoanZen_Font : NSObject
+ (UIFont *)title1;
+ (UIFont *)title2;
+ (UIFont *)body;
+ (UIFont *)caption;
@end

/// 切图资源名（LZ_* 前缀，来自 AI-PH29-DC_slices）
@interface LoanZen_Asset : NSObject
+ (UIImage * _Nullable)imageNamed:(NSString *)name;
+ (NSString *)loginLogo;
+ (NSString *)pageBackground;
+ (NSString *)backArrow;
+ (NSString *)kycBackArrow;
+ (NSString *)expandChevron;
+ (NSString *)modalConfirmReturnIcon;
+ (NSString *)tabHomeNormal;
+ (NSString *)tabHomeSelected;
+ (NSString *)tabOrderNormal;
+ (NSString *)tabOrderSelected;
+ (NSString *)tabEMINormal;
+ (NSString *)tabEMISelected;
+ (NSString *)tabMeNormal;
+ (NSString *)tabMeSelected;
+ (NSString *)homeCenterLogo;
+ (NSString *)homeKycArrow;
+ (NSString *)homeComplianceBadge;
+ (NSString *)homeAvatarDot;
+ (NSString *)checkInDayDone;
+ (NSString *)checkInDayPending;
+ (NSString *)meBackground;
+ (NSString *)meAvatar;
+ (NSString *)mePhone;
+ (NSString *)meSignOut;
+ (NSString *)meBankCardBackground;
+ (NSString *)meBankChevron;
+ (NSString *)meListChevron;
+ (NSString *)meBank;
+ (NSString *)meContact;
+ (NSString *)meFeedback;
+ (NSString *)mePrivacy;
+ (NSString *)meTerms;
+ (NSString *)meRepayment;
+ (NSString *)meWebsite;
+ (NSString *)meAbout;
@end

NS_ASSUME_NONNULL_END
