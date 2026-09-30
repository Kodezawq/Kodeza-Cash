#import "LoanZen_RepaymentViewController.h"
#import "LoanZen_ScreenScaffoldView.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_ColorUtils.h"
#import "LoanZen_AppConfigStore.h"
#import "LoanZen_AuthService.h"
#import "LoanZen_HUD.h"
@import Masonry;

/// 个人中心 Repayment Instructions
/// 官网 / 客服邮箱本地写死，见 `LoanZen_AppConfigStore`

@interface LoanZen_RepaymentViewController ()
@property (nonatomic, strong) UILabel *websiteValueLabel;
@property (nonatomic, strong) UILabel *emailValueLabel;
@property (nonatomic, copy) NSString *websiteValue;
@property (nonatomic, copy) NSString *emailValue;
@end

@implementation LoanZen_RepaymentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;

    LoanZen_ScreenScaffoldView *scaffold = [[LoanZen_ScreenScaffoldView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:scaffold];
    [scaffold mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.view); }];
    [scaffold LZ_useProfilePageStyle];
    [scaffold LZ_setHeaderTitle:@"Repayment instructions"];
    __weak typeof(self) weakSelf = self;
    [scaffold LZ_setBackAction:^{ [weakSelf.navigationController popViewControllerAnimated:YES]; }];

    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.alwaysBounceVertical = YES;
    scroll.showsVerticalScrollIndicator = NO;
    [scaffold.contentView addSubview:scroll];
    [scroll mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(scaffold.contentView); }];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;
    [scroll addSubview:stack];
    [stack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(scroll).offset(12);
        make.left.right.equalTo(scroll).inset(16);
        make.width.equalTo(scroll).offset(-32);
        make.bottom.equalTo(scroll).offset(-24);
    }];

    UIView *websiteCard = [self LZ_actionCardWithBody:
        @"Please get your repayment link from the Kodeza Cash app first. If the app is unavailable, you can also repay through our official website. Using any repayment link that differs from the one shown in the app or on the official website will be treated as a failed repayment."
        iconName:@"lz_contactus_website"
        valueLabel:&_websiteValueLabel
        copyEmptyHint:@"Website not available"
        copySuccessHint:@"Website copied"
        copyAction:@selector(LZ_copyWebsite)];

    UIView *emailCard = [self LZ_actionCardWithBody:
        @"If anything looks suspicious while you are making a repayment, please email Kodeza Cash customer service first. We will help you resolve the issue as soon as possible."
        iconName:@"lz_contactus_email"
        valueLabel:&_emailValueLabel
        copyEmptyHint:@"Email not available"
        copySuccessHint:@"Email copied"
        copyAction:@selector(LZ_copyEmail)];

    UIView *warningCard = [self LZ_warningCard];

    [stack addArrangedSubview:websiteCard];
    [stack addArrangedSubview:emailCard];
    [stack addArrangedSubview:warningCard];

    [self LZ_applyContent];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    __weak typeof(self) weakSelf = self;
    [LoanZen_AuthService LZ_fetchAppConfigWithCompletion:^(NSDictionary *config, NSError *error) {
        (void)error;
        (void)config;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf LZ_applyContent];
        });
    }];
}

#pragma mark - Content

- (void)LZ_applyContent {
    self.websiteValue = [LoanZen_AppConfigStore LZ_resolvedOfficialWebsiteURL];
    self.emailValue = [LoanZen_AppConfigStore LZ_resolvedSupportEmail];

    self.websiteValueLabel.text = self.websiteValue.length > 0 ? self.websiteValue : @"—";
    self.emailValueLabel.text = self.emailValue.length > 0 ? self.emailValue : @"—";
}

#pragma mark - Cards

- (UIView *)LZ_darkCard {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [LoanZen_Color kycFormCardFill];
    card.layer.cornerRadius = 16;
    card.layer.borderWidth = 1;
    card.layer.borderColor = [[LoanZen_Color accent] colorWithAlphaComponent:0.35].CGColor;
    card.clipsToBounds = YES;
    return card;
}

- (UIView *)LZ_actionCardWithBody:(NSString *)body
                         iconName:(NSString *)iconName
                       valueLabel:(UILabel * __strong *)outValueLabel
                    copyEmptyHint:(NSString *)copyEmptyHint
                  copySuccessHint:(NSString *)copySuccessHint
                       copyAction:(SEL)copyAction {
    UIView *card = [self LZ_darkCard];

    UILabel *bodyLabel = [[UILabel alloc] init];
    bodyLabel.numberOfLines = 0;
    bodyLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    bodyLabel.textColor = [LoanZen_Color kycFormLabel];
    bodyLabel.text = body;

    UIView *actionRow = [[UIView alloc] init];
    actionRow.backgroundColor = [LoanZen_Color kycFormInputFill];
    actionRow.layer.cornerRadius = 12;
    actionRow.layer.borderWidth = 1;
    actionRow.layer.borderColor = [LoanZen_Color kycFormInputBorder].CGColor;
    actionRow.clipsToBounds = YES;

    UIImageView *iconView = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:iconName]];
    iconView.contentMode = UIViewContentModeScaleAspectFit;

    UILabel *valueLabel = [[UILabel alloc] init];
    valueLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    valueLabel.textColor = [LoanZen_Color kycFormValue];
    valueLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    if (outValueLabel) *outValueLabel = valueLabel;

    UIControl *copyControl = [self LZ_copyControlWithEmptyHint:copyEmptyHint successHint:copySuccessHint action:copyAction];

    [card addSubview:bodyLabel];
    [card addSubview:actionRow];
    [actionRow addSubview:iconView];
    [actionRow addSubview:valueLabel];
    [actionRow addSubview:copyControl];

    [bodyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(card).insets(UIEdgeInsetsMake(16, 16, 0, 16));
    }];
    [actionRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(bodyLabel.mas_bottom).offset(12);
        make.left.right.bottom.equalTo(card).insets(UIEdgeInsetsMake(0, 16, 16, 16));
        make.height.mas_equalTo(60);
    }];
    [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(actionRow).offset(12);
        make.centerY.equalTo(actionRow);
        make.width.height.mas_equalTo(36);
    }];
    [copyControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(actionRow).offset(-12);
        make.centerY.equalTo(actionRow);
    }];
    [valueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(iconView.mas_right).offset(12);
        make.centerY.equalTo(actionRow);
        make.right.lessThanOrEqualTo(copyControl.mas_left).offset(-8);
    }];
    return card;
}

- (UIView *)LZ_warningCard {
    UIView *card = [self LZ_darkCard];
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];

    NSString *prefix = @"If anyone asks you to split the full repayment into several payments, or sends a repayment link that does not match the one shown in the Kodeza Cash app or on the official website, please contact customer service right away. ";
    NSString *suffix = @"After we verify the case, the service fee will be waived for you.";
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:[prefix stringByAppendingString:suffix]];
    [text addAttribute:NSForegroundColorAttributeName value:[LoanZen_Color kycFormLabel] range:NSMakeRange(0, prefix.length)];
    [text addAttribute:NSForegroundColorAttributeName value:[LoanZen_ColorUtils LZ_colorFromHex:0x00B578 alpha:1] range:NSMakeRange(prefix.length, suffix.length)];
    label.attributedText = text;

    [card addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(card).insets(UIEdgeInsetsMake(16, 16, 16, 16));
    }];
    return card;
}

#pragma mark - Copy

- (UIControl *)LZ_copyControlWithEmptyHint:(NSString *)emptyHint
                               successHint:(NSString *)successHint
                                    action:(SEL)action {
    UIControl *control = [[UIControl alloc] init];
    control.backgroundColor = UIColor.clearColor;
    control.layer.cornerRadius = 8;
    control.layer.borderWidth = 1;
    control.layer.borderColor = [LoanZen_Color accent].CGColor;

    UIImageView *icon = [[UIImageView alloc] initWithImage:[[LoanZen_Asset imageNamed:@"lz_contactus_copy"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    icon.tintColor = [LoanZen_Color accent];
    icon.contentMode = UIViewContentModeScaleAspectFit;

    UILabel *label = [[UILabel alloc] init];
    label.text = @"Copy";
    label.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    label.textColor = [LoanZen_Color accent];

    [control addSubview:icon];
    [control addSubview:label];
    [icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(control).offset(8);
        make.centerY.equalTo(control);
        make.width.height.mas_equalTo(14);
    }];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(icon.mas_right).offset(4);
        make.right.equalTo(control).offset(-8);
        make.centerY.equalTo(control);
    }];
    [control mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(32);
    }];

    (void)emptyHint;
    (void)successHint;
    [control addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return control;
}

- (void)LZ_copyWebsite {
    [self LZ_copyValue:self.websiteValue emptyHint:@"Website not available" successHint:@"Website copied"];
}

- (void)LZ_copyEmail {
    [self LZ_copyValue:self.emailValue emptyHint:@"Email not available" successHint:@"Email copied"];
}

- (void)LZ_copyValue:(NSString *)value emptyHint:(NSString *)emptyHint successHint:(NSString *)successHint {
    NSString *trimmed = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        [LoanZen_HUD LZ_showError:emptyHint];
        return;
    }
    [UIPasteboard generalPasteboard].string = trimmed;
    [LoanZen_HUD LZ_showSuccess:successHint];
}

@end
