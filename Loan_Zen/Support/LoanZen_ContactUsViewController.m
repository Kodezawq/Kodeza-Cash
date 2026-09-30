#import "LoanZen_ContactUsViewController.h"
#import "LoanZen_ScreenScaffoldView.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_ColorUtils.h"
#import "LoanZen_AppConfigStore.h"
#import "LoanZen_HUD.h"
@import Masonry;

@implementation LoanZen_ContactUsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;

    LoanZen_ScreenScaffoldView *scaffold = [[LoanZen_ScreenScaffoldView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:scaffold];
    [scaffold mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.view); }];
    [scaffold LZ_useProfilePageStyle];
    [scaffold LZ_setHeaderTitle:@"Contact us"];
    __weak typeof(self) weakSelf = self;
    [scaffold LZ_setBackAction:^{ [weakSelf.navigationController popViewControllerAnimated:YES]; }];

    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.alwaysBounceVertical = YES;
    [scaffold.contentView addSubview:scroll];
    [scroll mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(scaffold.contentView); }];

    UIView *content = [[UIView alloc] init];
    [scroll addSubview:content];
    [content mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(scroll);
        make.width.equalTo(scroll);
    }];

    UIView *tipCard = [self LZ_tipCardWithText:@"If you have any questions, please save the proof and contact customer service."];
    [content addSubview:tipCard];
    [tipCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(content).offset(12);
        make.left.right.equalTo(content).inset(16);
    }];

    NSString *email = [LoanZen_AppConfigStore LZ_resolvedSupportEmail];
    NSString *website = [LoanZen_AppConfigStore LZ_resolvedOfficialWebsiteURL];

    UIView *emailCard = [self LZ_contactCardWithIcon:@"lz_contactus_email" value:email];
    UIView *websiteCard = [self LZ_contactCardWithIcon:@"lz_contactus_website" value:website];
    [content addSubview:emailCard];
    [content addSubview:websiteCard];
    [emailCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tipCard.mas_bottom).offset(16);
        make.left.right.equalTo(content).inset(16);
        make.height.mas_equalTo(72);
    }];
    [websiteCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(emailCard.mas_bottom).offset(12);
        make.left.right.equalTo(content).inset(16);
        make.height.mas_equalTo(72);
        make.bottom.equalTo(content).offset(-24);
    }];
}

#pragma mark - UI helpers

- (UIView *)LZ_darkCard {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [LoanZen_Color kycFormCardFill];
    card.layer.cornerRadius = 16;
    card.layer.borderWidth = 1;
    card.layer.borderColor = [LoanZen_Color kycFormCardBorder].CGColor;
    card.clipsToBounds = YES;
    return card;
}

- (UIView *)LZ_tipCardWithText:(NSString *)text {
    UIView *card = [self LZ_darkCard];
    card.backgroundColor = [[LoanZen_Color accent] colorWithAlphaComponent:0.10];
    card.layer.borderColor = [[LoanZen_Color accent] colorWithAlphaComponent:0.35].CGColor;
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    label.textColor = [LoanZen_Color kycFormLabel];
    label.text = text;
    [card addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(card).insets(UIEdgeInsetsMake(14, 16, 14, 16));
    }];
    return card;
}

- (UIView *)LZ_contactCardWithIcon:(NSString *)icon value:(NSString *)value {
    UIView *card = [self LZ_darkCard];
    UIImageView *iconView = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:icon]];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    UILabel *label = [[UILabel alloc] init];
    label.text = value;
    label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    label.textColor = [LoanZen_Color kycFormValue];
    label.lineBreakMode = NSLineBreakByTruncatingMiddle;
    UIButton *copyButton = [self LZ_copyButtonForValue:value];
    [card addSubview:iconView];
    [card addSubview:label];
    [card addSubview:copyButton];
    [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(card).offset(16);
        make.centerY.equalTo(card);
        make.width.height.mas_equalTo(36);
    }];
    [copyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(card).offset(-16);
        make.centerY.equalTo(card);
        make.width.height.mas_equalTo(32);
    }];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(iconView.mas_right).offset(12);
        make.centerY.equalTo(card);
        make.right.lessThanOrEqualTo(copyButton.mas_left).offset(-8);
    }];
    return card;
}

- (UIButton *)LZ_copyButtonForValue:(NSString *)value {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = UIColor.clearColor;
    button.layer.cornerRadius = 8;
    button.layer.borderWidth = 1;
    button.layer.borderColor = [LoanZen_Color accent].CGColor;
    UIImage *icon = [[LoanZen_Asset imageNamed:@"lz_contactus_copy"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [button setImage:icon forState:UIControlStateNormal];
    button.tintColor = [LoanZen_Color accent];
    button.contentEdgeInsets = UIEdgeInsetsMake(7, 7, 7, 7);
    button.adjustsImageWhenHighlighted = NO;
    [button addAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        [UIPasteboard generalPasteboard].string = value ?: @"";
        [LoanZen_HUD LZ_showSuccess:@"Copied"];
    }] forControlEvents:UIControlEventTouchUpInside];
    return button;
}

@end
