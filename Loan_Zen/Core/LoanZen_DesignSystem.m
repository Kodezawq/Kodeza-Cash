#import "LoanZen_DesignSystem.h"
#import "LoanZen_ColorUtils.h"

const CGFloat LZ_SizePageInset = 16.0;
const CGFloat LZ_SizeStatusBarHeight = 44.0;
const CGFloat LZ_SizeBottomBarHeight = 48.0;
const CGFloat LZ_SizePrimaryButtonHeight = 48.0;

@implementation LoanZen_Color

+ (UIColor *)background { return [LoanZen_ColorUtils LZ_background]; }
+ (UIColor *)card { return [LoanZen_ColorUtils LZ_card]; }
+ (UIColor *)primaryText { return [LoanZen_ColorUtils LZ_textPrimary]; }
+ (UIColor *)secondaryText { return [LoanZen_ColorUtils LZ_textSecondary]; }
+ (UIColor *)accent { return [LoanZen_ColorUtils LZ_brandAccent]; }
+ (UIColor *)separator { return [LoanZen_ColorUtils LZ_separator]; }
+ (UIColor *)danger { return [LoanZen_ColorUtils LZ_brandDanger]; }
+ (UIColor *)formTitleText { return [LoanZen_ColorUtils LZ_formTitleText]; }
+ (UIColor *)formPlaceholder { return [LoanZen_ColorUtils LZ_formPlaceholder]; }
+ (UIColor *)formInputBackground { return [LoanZen_ColorUtils LZ_formInputBackground]; }
+ (UIColor *)modalCancelBackground { return [LoanZen_ColorUtils LZ_modalCancelBackground]; }
+ (UIColor *)kycFormCardFill { return [LoanZen_ColorUtils LZ_kycFormCardFill]; }
+ (UIColor *)kycFormCardBorder { return [LoanZen_ColorUtils LZ_kycFormCardBorder]; }
+ (UIColor *)kycFormInputFill { return [LoanZen_ColorUtils LZ_kycFormInputFill]; }
+ (UIColor *)kycFormInputBorder { return [LoanZen_ColorUtils LZ_kycFormInputBorder]; }
+ (UIColor *)kycFormLabel { return [LoanZen_ColorUtils LZ_kycFormLabel]; }
+ (UIColor *)kycFormValue { return [LoanZen_ColorUtils LZ_kycFormValue]; }
+ (UIColor *)kycFormPlaceholder { return [LoanZen_ColorUtils LZ_kycFormPlaceholder]; }
+ (UIColor *)homePromptFill { return [LoanZen_ColorUtils LZ_homePromptFill]; }
+ (UIColor *)homePromptBorder { return [LoanZen_ColorUtils LZ_homePromptBorder]; }
+ (UIColor *)kycProgressInactive { return [LoanZen_ColorUtils LZ_kycProgressInactive]; }

@end

@implementation LoanZen_Font

+ (UIFont *)title1 { return [UIFont systemFontOfSize:22 weight:UIFontWeightBold]; }
+ (UIFont *)title2 { return [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold]; }
+ (UIFont *)body { return [UIFont systemFontOfSize:15 weight:UIFontWeightRegular]; }
+ (UIFont *)caption { return [UIFont systemFontOfSize:13 weight:UIFontWeightRegular]; }

@end

@implementation LoanZen_Asset

+ (UIImage *)imageNamed:(NSString *)name {
    return [UIImage imageNamed:name];
}

+ (NSString *)loginLogo { return @"lz_dly_logo"; }
+ (NSString *)pageBackground { return @"lz_ymbg"; }
+ (NSString *)backArrow { return @"lz_fh"; }
+ (NSString *)kycBackArrow { return @"lz_kyc_fh"; }
+ (NSString *)expandChevron { return @"lz_xl"; }
+ (NSString *)modalConfirmReturnIcon { return @"lz_kyc_fh"; }
+ (NSString *)tabHomeNormal { return @"lz_home_n"; }
+ (NSString *)tabHomeSelected { return @"lz_hone_u"; }
+ (NSString *)tabOrderNormal { return @"lz_order_n"; }
+ (NSString *)tabOrderSelected { return @"lz_order_u"; }
+ (NSString *)tabEMINormal { return @"lz_emi_n"; }
+ (NSString *)tabEMISelected { return @"lz_emi_u"; }
+ (NSString *)tabMeNormal { return @"lz_me_n"; }
+ (NSString *)tabMeSelected { return @"lz_me_u"; }
+ (NSString *)homeCenterLogo { return @"lz_dly_logo"; }
+ (NSString *)homeKycArrow { return @"lz_home_jt"; }
+ (NSString *)homeComplianceBadge { return @"lz_home_bslogo"; }
+ (NSString *)homeAvatarDot { return @"lz_home_logo"; }
+ (NSString *)checkInDayDone { return @"lz_qd_u"; }
+ (NSString *)checkInDayPending { return @"lz_qd_n"; }
+ (NSString *)meBackground { return @"lz_me_bankbg"; }
+ (NSString *)meAvatar { return @"lz_dly_logo"; }
+ (NSString *)mePhone { return @"lz_me_sjh"; }
+ (NSString *)meSignOut { return @"lz_me_signout"; }
+ (NSString *)meBankCardBackground { return @"lz_me_bankbg"; }
+ (NSString *)meBankChevron { return @"lz_me_bankjt"; }
+ (NSString *)meListChevron { return @"lz_me_jt"; }
+ (NSString *)meBank { return @"lz_me_bank"; }
+ (NSString *)meContact { return @"lz_me_contactus"; }
+ (NSString *)meFeedback { return @"lz_me_feedback"; }
+ (NSString *)mePrivacy { return @"lz_me_ysxy"; }
+ (NSString *)meTerms { return @"lz_me_jkxz"; }
+ (NSString *)meRepayment { return @"lz_me_hkxz"; }
+ (NSString *)meWebsite { return @"lz_me_gwlj"; }
+ (NSString *)meAbout { return @"lz_me_about"; }

@end
