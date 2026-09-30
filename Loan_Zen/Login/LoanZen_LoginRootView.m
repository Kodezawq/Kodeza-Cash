#import "LoanZen_LoginRootView.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_ColorUtils.h"
#import "LoanZen_PhilippineMobile.h"
#import "UIColor+LoanZen_Hex.h"
@import Masonry;

@interface LoanZen_LoginRootView () <UITextViewDelegate, UITextFieldDelegate>
@property (nonatomic, strong, readwrite) UITextField *mobileField;
@property (nonatomic, strong, readwrite) UITextField *otpField;
@property (nonatomic, strong) UIButton *otpButton;
@property (nonatomic, strong) UIButton *signInButton;
@property (nonatomic, strong) UIButton *agreementButton;
@property (nonatomic, assign, readwrite) BOOL agreementAccepted;
@property (nonatomic, assign) BOOL otpCountdownActive;
@property (nonatomic, assign) NSInteger otpDisplayedSeconds;
@end

@implementation LoanZen_LoginRootView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _agreementAccepted = YES;
        self.backgroundColor = [LoanZen_Color background];

        UIImageView *bg = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:[LoanZen_Asset pageBackground]]];
        bg.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:bg];
        [bg mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];

        UIView *card = [[UIView alloc] init];
        card.backgroundColor = [LoanZen_Color card];
        card.layer.cornerRadius = 20;
        [self addSubview:card];
        [card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self).inset(LZ_SizePageInset);
            make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(16);
        }];

        UIImageView *logo = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:[LoanZen_Asset loginLogo]]];
        logo.contentMode = UIViewContentModeScaleAspectFit;
        [card addSubview:logo];
        [logo mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(card).offset(32);
            make.centerX.equalTo(card);
            make.width.height.mas_equalTo(72);
        }];

        UILabel *title = [[UILabel alloc] init];
        title.text = @"Welcome Back";
        title.font = [LoanZen_Font title1];
        title.textColor = [LoanZen_Color primaryText];
        title.textAlignment = NSTextAlignmentCenter;
        [card addSubview:title];
        [title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(logo.mas_bottom).offset(16);
            make.left.right.equalTo(card).inset(20);
        }];

        UILabel *mobileLabel = [[UILabel alloc] init];
        mobileLabel.text = @"Mobile Number";
        mobileLabel.font = [LoanZen_Font caption];
        mobileLabel.textColor = [LoanZen_Color secondaryText];

        UIView *mobileBox = [self LZ_makeFieldBox];
        UILabel *prefix = [[UILabel alloc] init];
        prefix.text = @"+63";
        prefix.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        prefix.textColor = [LoanZen_Color primaryText];
        [mobileBox addSubview:prefix];
        self.mobileField = [self LZ_makeTextFieldWithPlaceholder:@"Enter mobile number"];
        self.mobileField.keyboardType = UIKeyboardTypeNumberPad;
        self.mobileField.delegate = self;
        [self.mobileField addTarget:self action:@selector(LZ_mobileDidChange) forControlEvents:UIControlEventEditingChanged];
        [mobileBox addSubview:self.mobileField];
        [prefix mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(mobileBox).offset(12);
            make.centerY.equalTo(mobileBox);
            make.width.mas_equalTo(40);
        }];
        [self.mobileField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(prefix.mas_right).offset(8);
            make.right.equalTo(mobileBox).offset(-12);
            make.top.bottom.equalTo(mobileBox);
        }];

        UILabel *otpLabel = [[UILabel alloc] init];
        otpLabel.text = @"OTP";
        otpLabel.font = [LoanZen_Font caption];
        otpLabel.textColor = [LoanZen_Color secondaryText];

        UIView *otpBox = [self LZ_makeFieldBox];
        self.otpField = [self LZ_makeTextFieldWithPlaceholder:@"Enter OTP"];
        self.otpField.keyboardType = UIKeyboardTypeNumberPad;
        self.otpField.delegate = self;
        [self.otpField addTarget:self action:@selector(LZ_otpDidChange) forControlEvents:UIControlEventEditingChanged];
        [otpBox addSubview:self.otpField];
        self.otpButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.otpButton setTitle:@"Get OTP" forState:UIControlStateNormal];
        [self.otpButton setTitleColor:[LoanZen_Color accent] forState:UIControlStateNormal];
        self.otpButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        [self.otpButton addTarget:self action:@selector(LZ_tapOTP) forControlEvents:UIControlEventTouchUpInside];
        [otpBox addSubview:self.otpButton];
        [self.otpField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(otpBox).offset(12);
            make.top.bottom.equalTo(otpBox);
            make.right.equalTo(self.otpButton.mas_left).offset(-8);
        }];
        [self.otpButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(otpBox).offset(-12);
            make.centerY.equalTo(otpBox);
        }];

        self.signInButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.signInButton.backgroundColor = [LoanZen_Color accent];
        self.signInButton.layer.cornerRadius = 12;
        [self.signInButton setTitle:@"Sign in" forState:UIControlStateNormal];
        [self.signInButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        self.signInButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        [self.signInButton addTarget:self action:@selector(LZ_tapSignIn) forControlEvents:UIControlEventTouchUpInside];

        self.agreementButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.agreementButton addTarget:self action:@selector(LZ_toggleAgreement) forControlEvents:UIControlEventTouchUpInside];
        [self LZ_updateAgreementIcon];

        UITextView *agreementText = [[UITextView alloc] init];
        agreementText.backgroundColor = UIColor.clearColor;
        agreementText.editable = NO;
        agreementText.scrollEnabled = NO;
        agreementText.delegate = self;
        agreementText.textContainerInset = UIEdgeInsetsZero;
        agreementText.linkTextAttributes = @{NSForegroundColorAttributeName: [LoanZen_Color accent]};
        agreementText.attributedText = [self LZ_agreementText];

        UIStackView *agreementRow = [[UIStackView alloc] initWithArrangedSubviews:@[self.agreementButton, agreementText]];
        agreementRow.axis = UILayoutConstraintAxisHorizontal;
        agreementRow.spacing = 8;
        agreementRow.alignment = UIStackViewAlignmentTop;
        [self.agreementButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(20);
        }];

        UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[mobileLabel, mobileBox, otpLabel, otpBox, self.signInButton, agreementRow]];
        stack.axis = UILayoutConstraintAxisVertical;
        stack.spacing = 12;
        [card addSubview:stack];
        [mobileBox mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(48);
        }];
        [otpBox mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(48);
        }];
        [self.signInButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(LZ_SizePrimaryButtonHeight);
        }];
        [stack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(title.mas_bottom).offset(24);
            make.left.right.equalTo(card).inset(20);
            make.bottom.equalTo(card).offset(-24);
        }];
    }
    return self;
}

- (UIView *)LZ_makeFieldBox {
    UIView *box = [[UIView alloc] init];
    box.backgroundColor = [LoanZen_ColorUtils LZ_inputBackground];
    box.layer.cornerRadius = 12;
    box.layer.borderWidth = 1;
    box.layer.borderColor = [LoanZen_Color separator].CGColor;
    return box;
}

- (UITextField *)LZ_makeTextFieldWithPlaceholder:(NSString *)placeholder {
    UITextField *field = [[UITextField alloc] init];
    field.font = [LoanZen_Font body];
    field.textColor = [LoanZen_Color primaryText];
    field.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:@{NSForegroundColorAttributeName: [LoanZen_Color secondaryText]}];
    return field;
}

- (NSAttributedString *)LZ_agreementText {
    NSString *text = @"I have read and agree to Privacy Policy and Service Agreement";
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSForegroundColorAttributeName: [LoanZen_Color secondaryText], NSFontAttributeName: [LoanZen_Font caption]}];
    [attr addAttribute:NSLinkAttributeName value:@"privacy://" range:[text rangeOfString:@"Privacy Policy"]];
    [attr addAttribute:NSLinkAttributeName value:@"service://" range:[text rangeOfString:@"Service Agreement"]];
    return attr;
}

- (void)LZ_setAgreementAccepted:(BOOL)accepted {
    if (self.agreementAccepted == accepted) return;
    self.agreementAccepted = accepted;
    [self LZ_updateAgreementIcon];
}

- (void)LZ_updateAgreementIcon {
    NSString *imageName = self.agreementAccepted ? @"lz_dx_u" : @"lz_dx_n";
    UIImage *image = [LoanZen_Asset imageNamed:imageName];
    [self.agreementButton setImage:image forState:UIControlStateNormal];
}

- (void)LZ_updateOTPButtonWithRemaining:(NSInteger)seconds completedOnce:(BOOL)completedOnce {
    if (seconds > 0) {
        if (!self.otpCountdownActive) {
            self.otpCountdownActive = YES;
            self.otpButton.enabled = NO;
        }
        if (seconds == self.otpDisplayedSeconds) return;
        self.otpDisplayedSeconds = seconds;
        NSString *title = [NSString stringWithFormat:@"%lds", (long)seconds];
        [UIView performWithoutAnimation:^{
            [self.otpButton setTitle:title forState:UIControlStateNormal];
        }];
        return;
    }

    NSString *idleTitle = completedOnce ? @"Reacquire" : @"Get OTP";
    if (self.otpCountdownActive) {
        self.otpCountdownActive = NO;
        self.otpDisplayedSeconds = -1;
        self.otpButton.enabled = YES;
        [UIView performWithoutAnimation:^{
            [self.otpButton setTitle:idleTitle forState:UIControlStateNormal];
        }];
        return;
    }
    if (![self.otpButton.currentTitle isEqualToString:idleTitle]) {
        [UIView performWithoutAnimation:^{
            [self.otpButton setTitle:idleTitle forState:UIControlStateNormal];
        }];
    }
}

- (void)LZ_toggleAgreement {
    self.agreementAccepted = !self.agreementAccepted;
    [self LZ_updateAgreementIcon];
}

- (void)LZ_tapOTP {
    if ([self.delegate respondsToSelector:@selector(LZ_loginRootViewDidTapGetOTP:)]) {
        [self.delegate LZ_loginRootViewDidTapGetOTP:self];
    }
}

- (void)LZ_tapSignIn {
    if ([self.delegate respondsToSelector:@selector(LZ_loginRootViewDidTapSignIn:)]) {
        [self.delegate LZ_loginRootViewDidTapSignIn:self];
    }
}

- (void)LZ_mobileDidChange {
    NSString *sanitized = [LoanZen_PhilippineMobile LZ_sanitizeFieldDigits:self.mobileField.text ?: @""];
    if (![sanitized isEqualToString:self.mobileField.text ?: @""]) {
        self.mobileField.text = sanitized;
    }
}

- (void)LZ_otpDidChange {
    NSString *digits = [LoanZen_PhilippineMobile LZ_digitsOnly:self.otpField.text ?: @""];
    NSString *limited = digits.length > 6 ? [digits substringToIndex:6] : digits;
    if (![limited isEqualToString:self.otpField.text ?: @""]) {
        self.otpField.text = limited;
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.mobileField) {
        NSString *current = textField.text ?: @"";
        if (range.location > current.length || NSMaxRange(range) > current.length) return NO;
        NSString *merged = [current stringByReplacingCharactersInRange:range withString:string];
        NSString *mergedDigits = [LoanZen_PhilippineMobile LZ_digitsOnly:merged];
        textField.text = [LoanZen_PhilippineMobile LZ_sanitizeFieldDigits:mergedDigits];
        return NO;
    }
    if (textField == self.otpField) {
        NSString *digits = [LoanZen_PhilippineMobile LZ_digitsOnly:string];
        if (![digits isEqualToString:string]) {
            NSString *current = textField.text ?: @"";
            if (range.location > current.length || NSMaxRange(range) > current.length) return NO;
            NSString *next = [current stringByReplacingCharactersInRange:range withString:digits];
            [self LZ_applyOTPDigits:next toField:textField];
            return NO;
        }
        NSString *current = textField.text ?: @"";
        if (range.location > current.length || NSMaxRange(range) > current.length) return NO;
        NSString *next = [current stringByReplacingCharactersInRange:range withString:string];
        return next.length <= 6;
    }
    return YES;
}

- (void)LZ_applyOTPDigits:(NSString *)raw toField:(UITextField *)textField {
    NSString *digits = [LoanZen_PhilippineMobile LZ_digitsOnly:raw];
    textField.text = digits.length > 6 ? [digits substringToIndex:6] : digits;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    if ([URL.absoluteString isEqualToString:@"privacy://"]) {
        if (self.onTapPrivacyPolicy) self.onTapPrivacyPolicy();
    } else if ([URL.absoluteString isEqualToString:@"service://"]) {
        if (self.onTapServiceAgreement) self.onTapServiceAgreement();
    }
    return NO;
}

@end
