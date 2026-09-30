#import "LoanZen_OrderSubmitMaskView.h"
#import "LoanZen_ColorUtils.h"
#import "LoanZen_DesignSystem.h"
@import Masonry;

@implementation LoanZen_OrderSubmitMaskView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self LZ_buildUI];
    }
    return self;
}

- (void)LZ_buildUI {
    self.backgroundColor = [LoanZen_ColorUtils LZ_overlayDim73];
    self.userInteractionEnabled = YES;

    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [LoanZen_ColorUtils LZ_colorFromHex:0x141414 alpha:1.0];
    card.layer.cornerRadius = 24;
    card.layer.borderWidth = 1;
    card.layer.borderColor = [LoanZen_ColorUtils LZ_glassBorder10].CGColor;
    card.clipsToBounds = YES;

    UIView *iconShell = [[UIView alloc] init];
    iconShell.backgroundColor = [LoanZen_ColorUtils LZ_colorFromHex:0x1E1E1E alpha:1.0];
    iconShell.layer.cornerRadius = 12;
    iconShell.layer.borderWidth = 1;
    iconShell.layer.borderColor = [LoanZen_ColorUtils LZ_brandGradientStart].CGColor;

    UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"lz_tk_sb"]];
    iconView.contentMode = UIViewContentModeScaleAspectFit;

    UILabel *percentLabel = [[UILabel alloc] init];
    percentLabel.text = @"80%";
    percentLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
    percentLabel.textColor = [LoanZen_ColorUtils LZ_brandGradientStart];
    percentLabel.textAlignment = NSTextAlignmentRight;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"Under review";
    titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.numberOfLines = 0;

    UIView *titleAccent = [[UIView alloc] init];
    titleAccent.backgroundColor = [LoanZen_ColorUtils LZ_brandGradientStart];
    titleAccent.layer.cornerRadius = 1.5;

    UILabel *descLabel = [[UILabel alloc] init];
    descLabel.numberOfLines = 0;
    descLabel.attributedText = [self LZ_reviewDescriptionText];

    UIView *flowShell = [[UIView alloc] init];
    flowShell.backgroundColor = [LoanZen_ColorUtils LZ_colorFromHex:0x1A1A1A alpha:1.0];
    flowShell.layer.cornerRadius = 16;

    UIImageView *flowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"lz_tk_sb_flow"]];
    flowView.contentMode = UIViewContentModeScaleAspectFit;

    UIView *noticeBox = [[UIView alloc] init];
    noticeBox.backgroundColor = [LoanZen_ColorUtils LZ_colorFromHex:0x2A1515 alpha:1.0];
    noticeBox.layer.cornerRadius = 12;
    noticeBox.layer.borderWidth = 1;
    noticeBox.layer.borderColor = [LoanZen_ColorUtils LZ_colorFromHex:0x8B2E2E alpha:0.55].CGColor;

    UILabel *infoIcon = [[UILabel alloc] init];
    infoIcon.text = @"i";
    infoIcon.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    infoIcon.textColor = [LoanZen_ColorUtils LZ_brandGradientStart];
    infoIcon.textAlignment = NSTextAlignmentCenter;
    infoIcon.backgroundColor = [LoanZen_ColorUtils LZ_colorFromHex:0x3A2020 alpha:1.0];
    infoIcon.layer.cornerRadius = 10;
    infoIcon.clipsToBounds = YES;

    UILabel *noticeLabel = [[UILabel alloc] init];
    noticeLabel.text = @"Just one more step before your loan is credited, please don't leave this page.";
    noticeLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    noticeLabel.textColor = [LoanZen_ColorUtils LZ_colorFromHex:0xE8C4C4 alpha:0.85];
    noticeLabel.numberOfLines = 0;

    [self addSubview:card];
    [card addSubview:iconShell];
    [iconShell addSubview:iconView];
    [card addSubview:percentLabel];
    [card addSubview:titleLabel];
    [card addSubview:titleAccent];
    [card addSubview:descLabel];
    [card addSubview:flowShell];
    [flowShell addSubview:flowView];
    [card addSubview:noticeBox];
    [noticeBox addSubview:infoIcon];
    [noticeBox addSubview:noticeLabel];

    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
    }];

    [iconShell mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(card).offset(20);
        make.size.mas_equalTo(CGSizeMake(48, 48));
    }];
    [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(iconShell);
        make.size.mas_equalTo(CGSizeMake(28, 28));
    }];
    [percentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(iconShell);
        make.right.equalTo(card).offset(-20);
        make.left.greaterThanOrEqualTo(iconShell.mas_right).offset(12);
    }];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(iconShell.mas_bottom).offset(20);
        make.left.equalTo(card).offset(20);
        make.right.equalTo(card).offset(-20);
    }];
    [titleAccent mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(8);
        make.left.equalTo(titleLabel);
        make.size.mas_equalTo(CGSizeMake(36, 3));
    }];
    [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleAccent.mas_bottom).offset(12);
        make.left.equalTo(card).offset(20);
        make.right.equalTo(card).offset(-20);
    }];
    [flowShell mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(descLabel.mas_bottom).offset(20);
        make.left.equalTo(card).offset(16);
        make.right.equalTo(card).offset(-16);
    }];
    [flowView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(flowShell).insets(UIEdgeInsetsMake(12, 8, 12, 8));
        make.height.mas_equalTo(92);
    }];
    [noticeBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(flowShell.mas_bottom).offset(16);
        make.left.equalTo(card).offset(16);
        make.right.equalTo(card).offset(-16);
        make.bottom.equalTo(card).offset(-16);
    }];
    [infoIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(noticeBox).offset(12);
        make.top.equalTo(noticeBox).offset(12);
        make.size.mas_equalTo(CGSizeMake(20, 20));
    }];
    [noticeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(infoIcon.mas_right).offset(10);
        make.top.equalTo(noticeBox).offset(12);
        make.right.equalTo(noticeBox).offset(-12);
        make.bottom.equalTo(noticeBox).offset(-12);
    }];
}

- (NSAttributedString *)LZ_reviewDescriptionText {
    NSString *plain = @"Updating your credit score, please do not leave this page. This process takes about 15 seconds...";
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:plain attributes:@{
        NSFontAttributeName: [UIFont systemFontOfSize:14 weight:UIFontWeightRegular],
        NSForegroundColorAttributeName: [LoanZen_ColorUtils LZ_textSecondary],
    }];
    NSRange highlight = [plain rangeOfString:@"15 seconds..."];
    if (highlight.location != NSNotFound) {
        [text addAttribute:NSForegroundColorAttributeName value:[LoanZen_ColorUtils LZ_brandGradientStart] range:highlight];
        [text addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14 weight:UIFontWeightSemibold] range:highlight];
    }
    return text;
}

@end
