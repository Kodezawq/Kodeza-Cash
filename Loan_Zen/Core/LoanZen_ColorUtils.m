#import "LoanZen_ColorUtils.h"
#import "UIColor+LoanZen_Hex.h"

static NSString * const LZ_BrandGradientLayerName = @"LZ_brandGradientLayer";

@implementation LoanZen_ColorUtils

#pragma mark - Base

+ (UIColor *)LZ_colorFromHex:(uint32_t)hex alpha:(CGFloat)alpha {
    return [UIColor LZ_colorWithHex:hex alpha:alpha];
}

+ (UIColor *)LZ_colorFromHex:(uint32_t)hex {
    return [self LZ_colorFromHex:hex alpha:1];
}

#pragma mark - Brand

+ (UIColor *)LZ_brandGradientStart { return [self LZ_colorFromHex:0xFF6C5C]; }
+ (UIColor *)LZ_brandGradientEnd { return [self LZ_colorFromHex:0xFF4A3F]; }
+ (UIColor *)LZ_brandAccent { return [self LZ_brandGradientEnd]; }
+ (NSArray<UIColor *> *)LZ_brandGradientColors {
    return @[[self LZ_brandGradientStart], [self LZ_brandGradientEnd]];
}
+ (UIColor *)LZ_brandDanger { return [self LZ_colorFromHex:0xF53F3F]; }

#pragma mark - KYC Progress

+ (UIColor *)LZ_kycProgressGradientStart { return [self LZ_brandGradientStart]; }
+ (UIColor *)LZ_kycProgressGradientEnd { return [self LZ_brandGradientEnd]; }
+ (NSArray<UIColor *> *)LZ_kycProgressGradientColors { return [self LZ_brandGradientColors]; }
+ (UIColor *)LZ_kycProgressFilled { return [self LZ_brandGradientEnd]; }
+ (UIColor *)LZ_kycProgressInactive { return [[self LZ_textPrimary] colorWithAlphaComponent:0.16]; }

#pragma mark - Surface

+ (UIColor *)LZ_background { return [self LZ_colorFromHex:0x121212]; }
+ (UIColor *)LZ_card { return [self LZ_colorFromHex:0x1E1E1E]; }
+ (UIColor *)LZ_separator { return [self LZ_colorFromHex:0x2A2A2A]; }
+ (UIColor *)LZ_separatorLight { return [self LZ_colorFromHex:0xE5E6EB]; }
+ (UIColor *)LZ_inputBackground { return [self LZ_separator]; }

#pragma mark - Text

+ (UIColor *)LZ_textPrimary { return UIColor.whiteColor; }
+ (UIColor *)LZ_textSecondary { return [self LZ_colorFromHex:0x86909C]; }
+ (UIColor *)LZ_textTertiary { return [self LZ_colorFromHex:0xC9CDD4]; }
+ (UIColor *)LZ_formTitleText { return [self LZ_colorFromHex:0x1D2129]; }

#pragma mark - Light Form / Modal

+ (UIColor *)LZ_formPlaceholder { return [self LZ_textTertiary]; }
+ (UIColor *)LZ_formInputBackground { return [self LZ_colorFromHex:0xF2F3F5]; }
+ (UIColor *)LZ_modalCancelBackground { return UIColor.clearColor; }
+ (UIColor *)LZ_modalCardBackground { return [self LZ_colorFromHex:0x1A1B23]; }
+ (UIColor *)LZ_modalCardBorder { return [[self LZ_textPrimary] colorWithAlphaComponent:0.08]; }

#pragma mark - Glass

+ (UIColor *)LZ_glassFill06 { return [[self LZ_textPrimary] colorWithAlphaComponent:0.06]; }
+ (UIColor *)LZ_glassFill08 { return [[self LZ_textPrimary] colorWithAlphaComponent:0.08]; }
+ (UIColor *)LZ_glassBorder10 { return [[self LZ_textPrimary] colorWithAlphaComponent:0.10]; }
+ (UIColor *)LZ_glassBorder14 { return [[self LZ_textPrimary] colorWithAlphaComponent:0.14]; }
+ (UIColor *)LZ_glassBorder16 { return [[self LZ_textPrimary] colorWithAlphaComponent:0.16]; }

#pragma mark - Home Prompt（首页 KYC 消息条）

+ (UIColor *)LZ_homePromptFill { return [[self LZ_textPrimary] colorWithAlphaComponent:0.05]; }
+ (UIColor *)LZ_homePromptBorder { return [[self LZ_brandAccent] colorWithAlphaComponent:0.28]; }

#pragma mark - KYC Form

+ (UIColor *)LZ_kycFormCardFill { return [self LZ_glassFill08]; }
+ (UIColor *)LZ_kycFormCardBorder { return [self LZ_glassBorder14]; }
+ (UIColor *)LZ_kycFormInputFill { return [self LZ_glassFill06]; }
+ (UIColor *)LZ_kycFormInputBorder { return [self LZ_glassBorder10]; }
+ (UIColor *)LZ_kycFormLabel { return [self LZ_textSecondary]; }
+ (UIColor *)LZ_kycFormValue { return [self LZ_textPrimary]; }
+ (UIColor *)LZ_kycFormPlaceholder { return [self LZ_textSecondary]; }

#pragma mark - Order Status

+ (UIColor *)LZ_orderStatusPending { return [self LZ_colorFromHex:0xFF7A45]; }
+ (UIColor *)LZ_orderStatusReview { return [self LZ_colorFromHex:0x722ED1]; }
+ (UIColor *)LZ_orderStatusNeutral { return [self LZ_colorFromHex:0x8C8C8C]; }
+ (UIColor *)LZ_orderStatusActive { return [self LZ_brandAccent]; }
+ (UIColor *)LZ_orderStatusWarning { return [self LZ_colorFromHex:0xFA8C16]; }
+ (UIColor *)LZ_orderStatusSuccess { return [self LZ_colorFromHex:0x52C41A]; }
+ (UIColor *)LZ_orderStatusOverdue { return [self LZ_colorFromHex:0xFF4D4F]; }

#pragma mark - Overlay / Misc

+ (UIColor *)LZ_overlayDim45 { return [UIColor colorWithWhite:0 alpha:0.45]; }
+ (UIColor *)LZ_overlayDim73 { return [UIColor colorWithWhite:0 alpha:0x73 / 255.0]; }
+ (UIColor *)LZ_iconBackdrop22 { return [[self LZ_textPrimary] colorWithAlphaComponent:0.22]; }
+ (UIColor *)LZ_cameraBackground { return [self LZ_colorFromHex:0x1A1A1A]; }
+ (UIColor *)LZ_toggleOffFill { return [self LZ_card]; }
+ (UIColor *)LZ_lightPanelFill { return [self LZ_colorFromHex:0xEBEBEB]; }
+ (UIColor *)LZ_lightPanelBorder { return [[self LZ_textPrimary] colorWithAlphaComponent:0.9]; }
+ (UIColor *)LZ_mutedButtonFill { return [[self LZ_textPrimary] colorWithAlphaComponent:0.25]; }

#pragma mark - Picker Modal

+ (UIColor *)LZ_pickerShellBackground { return [self LZ_colorFromHex:0x1A1A1E]; }
+ (UIColor *)LZ_pickerOptionBackground { return [self LZ_colorFromHex:0x252529]; }
+ (UIColor *)LZ_pickerOptionBorder { return [[self LZ_brandGradientStart] colorWithAlphaComponent:0.55]; }

#pragma mark - Gradient Layer

+ (CAGradientLayer *)LZ_horizontalGradientLayerWithColors:(NSArray<UIColor *> *)colors
                                                    frame:(CGRect)frame
                                             cornerRadius:(CGFloat)cornerRadius {
    CAGradientLayer *layer = [CAGradientLayer layer];
    NSMutableArray *cgColors = [NSMutableArray arrayWithCapacity:colors.count];
    for (UIColor *color in colors) {
        [cgColors addObject:(id)color.CGColor];
    }
    layer.colors = cgColors;
    layer.startPoint = CGPointMake(0, 0.5);
    layer.endPoint = CGPointMake(1, 0.5);
    layer.frame = frame;
    layer.cornerRadius = cornerRadius;
    return layer;
}

+ (CAGradientLayer *)LZ_brandGradientLayerWithFrame:(CGRect)frame cornerRadius:(CGFloat)cornerRadius {
    CAGradientLayer *layer = [self LZ_horizontalGradientLayerWithColors:[self LZ_brandGradientColors]
                                                                  frame:frame
                                                           cornerRadius:cornerRadius];
    layer.name = LZ_BrandGradientLayerName;
    return layer;
}

+ (void)LZ_applyBrandGradientToView:(UIView *)view cornerRadius:(CGFloat)cornerRadius {
    view.backgroundColor = UIColor.clearColor;
    view.layer.cornerRadius = cornerRadius;
    view.clipsToBounds = YES;
    for (CALayer *sublayer in [view.layer.sublayers copy]) {
        if ([sublayer.name isEqualToString:LZ_BrandGradientLayerName]) {
            [sublayer removeFromSuperlayer];
        }
    }
    CAGradientLayer *gradient = [self LZ_brandGradientLayerWithFrame:view.bounds cornerRadius:cornerRadius];
    [view.layer insertSublayer:gradient atIndex:0];
}

+ (void)LZ_removeBrandGradientFromView:(UIView *)view {
    for (CALayer *sublayer in [view.layer.sublayers copy]) {
        if ([sublayer.name isEqualToString:LZ_BrandGradientLayerName]) {
            [sublayer removeFromSuperlayer];
        }
    }
}

+ (void)LZ_applyTermSelectionPillStyleToView:(UIView *)view {
    [self LZ_removeBrandGradientFromView:view];
    view.backgroundColor = [[self LZ_brandAccent] colorWithAlphaComponent:0.12];
    view.layer.borderWidth = 1;
    view.layer.borderColor = [[self LZ_brandGradientStart] colorWithAlphaComponent:0.35].CGColor;
    view.clipsToBounds = YES;
}

+ (void)LZ_styleLoanAmountChipButton:(UIButton *)button selected:(BOOL)selected cornerRadius:(CGFloat)cornerRadius {
    button.layer.cornerRadius = cornerRadius;
    button.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    [self LZ_removeBrandGradientFromView:button];
    if (selected) {
        button.backgroundColor = [self LZ_brandAccent];
        button.clipsToBounds = YES;
        button.layer.masksToBounds = NO;
        button.layer.borderWidth = 0;
        [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        button.layer.shadowColor = [self LZ_brandAccent].CGColor;
        button.layer.shadowOpacity = 0.35;
        button.layer.shadowRadius = 8;
        button.layer.shadowOffset = CGSizeMake(0, 2);
    } else {
        button.clipsToBounds = YES;
        button.layer.masksToBounds = YES;
        button.backgroundColor = [self LZ_kycFormInputFill];
        button.layer.borderWidth = 1;
        button.layer.borderColor = [self LZ_kycFormInputBorder].CGColor;
        [button setTitleColor:[self LZ_kycFormLabel] forState:UIControlStateNormal];
        button.layer.shadowOpacity = 0;
    }
}

@end
