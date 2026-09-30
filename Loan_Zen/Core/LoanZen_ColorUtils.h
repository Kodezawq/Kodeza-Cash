#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 设计稿色值工具（AI-PH29-DC / 品牌渐变 #FF6C5C → #FF4A3F）
@interface LoanZen_ColorUtils : NSObject

#pragma mark - Base

+ (UIColor *)LZ_colorFromHex:(uint32_t)hex alpha:(CGFloat)alpha;
+ (UIColor *)LZ_colorFromHex:(uint32_t)hex;

#pragma mark - Brand

+ (UIColor *)LZ_brandGradientStart;   // #FF6C5C
+ (UIColor *)LZ_brandGradientEnd;     // #FF4A3F
+ (UIColor *)LZ_brandAccent;          // 主色，取渐变末端
+ (NSArray<UIColor *> *)LZ_brandGradientColors;
+ (UIColor *)LZ_brandDanger;          // #F53F3F

#pragma mark - KYC Progress（与品牌渐变一致）

+ (UIColor *)LZ_kycProgressGradientStart;
+ (UIColor *)LZ_kycProgressGradientEnd;
+ (NSArray<UIColor *> *)LZ_kycProgressGradientColors;
+ (UIColor *)LZ_kycProgressFilled;
+ (UIColor *)LZ_kycProgressInactive;

#pragma mark - Surface（深色主界面）

+ (UIColor *)LZ_background;           // #121212
+ (UIColor *)LZ_card;                 // #1E1E1E
+ (UIColor *)LZ_separator;            // #2A2A2A
+ (UIColor *)LZ_separatorLight;       // #E5E6EB
+ (UIColor *)LZ_inputBackground;      // #2A2A2A

#pragma mark - Text

+ (UIColor *)LZ_textPrimary;
+ (UIColor *)LZ_textSecondary;        // #86909C
+ (UIColor *)LZ_textTertiary;         // #C9CDD4
+ (UIColor *)LZ_formTitleText;        // #1D2129（白底弹窗/表单）

#pragma mark - Light Form / Modal

+ (UIColor *)LZ_formPlaceholder;
+ (UIColor *)LZ_formInputBackground;    // #F2F3F5
+ (UIColor *)LZ_modalCancelBackground;
+ (UIColor *)LZ_modalCardBackground;
+ (UIColor *)LZ_modalCardBorder;

#pragma mark - Glass（深色背景上的半透明层）

+ (UIColor *)LZ_glassFill06;
+ (UIColor *)LZ_glassFill08;
+ (UIColor *)LZ_glassBorder10;
+ (UIColor *)LZ_glassBorder14;
+ (UIColor *)LZ_glassBorder16;

#pragma mark - Home Prompt

+ (UIColor *)LZ_homePromptFill;
+ (UIColor *)LZ_homePromptBorder;

#pragma mark - KYC Form（深色 KYC 页）

+ (UIColor *)LZ_kycFormCardFill;
+ (UIColor *)LZ_kycFormCardBorder;
+ (UIColor *)LZ_kycFormInputFill;
+ (UIColor *)LZ_kycFormInputBorder;
+ (UIColor *)LZ_kycFormLabel;
+ (UIColor *)LZ_kycFormValue;
+ (UIColor *)LZ_kycFormPlaceholder;

#pragma mark - Order Status

+ (UIColor *)LZ_orderStatusPending;       // #FF7A45
+ (UIColor *)LZ_orderStatusReview;        // #722ED1
+ (UIColor *)LZ_orderStatusNeutral;       // #8C8C8C
+ (UIColor *)LZ_orderStatusActive;        // brand accent
+ (UIColor *)LZ_orderStatusWarning;       // #FA8C16
+ (UIColor *)LZ_orderStatusSuccess;       // #52C41A
+ (UIColor *)LZ_orderStatusOverdue;       // #FF4D4F

#pragma mark - Overlay / Misc

+ (UIColor *)LZ_overlayDim45;
+ (UIColor *)LZ_overlayDim73;
+ (UIColor *)LZ_iconBackdrop22;
+ (UIColor *)LZ_cameraBackground;
+ (UIColor *)LZ_toggleOffFill;
+ (UIColor *)LZ_lightPanelFill;
+ (UIColor *)LZ_lightPanelBorder;
+ (UIColor *)LZ_mutedButtonFill;

#pragma mark - Picker Modal

+ (UIColor *)LZ_pickerShellBackground;
+ (UIColor *)LZ_pickerOptionBackground;
+ (UIColor *)LZ_pickerOptionBorder;

#pragma mark - Gradient Layer

+ (CAGradientLayer *)LZ_horizontalGradientLayerWithColors:(NSArray<UIColor *> *)colors
                                                    frame:(CGRect)frame
                                             cornerRadius:(CGFloat)cornerRadius;
+ (CAGradientLayer *)LZ_brandGradientLayerWithFrame:(CGRect)frame
                                       cornerRadius:(CGFloat)cornerRadius;
+ (void)LZ_applyBrandGradientToView:(UIView *)view cornerRadius:(CGFloat)cornerRadius;
+ (void)LZ_removeBrandGradientFromView:(UIView *)view;
+ (void)LZ_applyTermSelectionPillStyleToView:(UIView *)view;
+ (void)LZ_styleLoanAmountChipButton:(UIButton *)button selected:(BOOL)selected cornerRadius:(CGFloat)cornerRadius;

@end

NS_ASSUME_NONNULL_END
