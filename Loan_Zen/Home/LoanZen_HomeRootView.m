#import "LoanZen_HomeRootView.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_ColorUtils.h"
@import Masonry;
@import SDWebImage;

static NSString * const kLZHomeProductCellId = @"LZHomeProductCell";

@interface LoanZen_HomeProductCell : UITableViewCell
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIView *logoContainer;
@property (nonatomic, strong) UIImageView *logoView;
@property (nonatomic, strong) UILabel *logoFallbackLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *applyChip;
@property (nonatomic, strong) UILabel *quotaCaptionLabel;
@property (nonatomic, strong) UILabel *quotaValueLabel;
@property (nonatomic, strong) UILabel *rateCaptionLabel;
@property (nonatomic, strong) UILabel *rateValueLabel;
- (void)LZ_configureWithProduct:(NSDictionary *)product;
@end

@implementation LoanZen_HomeProductCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.clearColor;
        self.contentView.backgroundColor = UIColor.clearColor;

        self.cardView = [[UIView alloc] init];
        self.cardView.backgroundColor = [LoanZen_ColorUtils LZ_glassFill06];
        self.cardView.layer.cornerRadius = 12;
        self.cardView.layer.borderWidth = 1;
        self.cardView.layer.borderColor = [LoanZen_ColorUtils LZ_glassBorder10].CGColor;
        self.cardView.clipsToBounds = YES;
        [self.contentView addSubview:self.cardView];
        [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(6, 0, 6, 0));
        }];

        self.logoContainer = [[UIView alloc] init];
        self.logoContainer.backgroundColor = [LoanZen_ColorUtils LZ_kycFormInputFill];
        self.logoContainer.layer.cornerRadius = 10;
        self.logoContainer.clipsToBounds = YES;

        self.logoView = [[UIImageView alloc] init];
        self.logoView.contentMode = UIViewContentModeScaleAspectFill;
        self.logoView.clipsToBounds = YES;
        [self.logoContainer addSubview:self.logoView];
        [self.logoView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.logoContainer);
        }];

        self.logoFallbackLabel = [[UILabel alloc] init];
        self.logoFallbackLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
        self.logoFallbackLabel.textColor = UIColor.whiteColor;
        self.logoFallbackLabel.textAlignment = NSTextAlignmentCenter;
        self.logoFallbackLabel.backgroundColor = [LoanZen_Color accent];
        self.logoFallbackLabel.hidden = YES;
        [self.logoContainer addSubview:self.logoFallbackLabel];
        [self.logoFallbackLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.logoContainer);
        }];

        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
        self.titleLabel.textColor = [LoanZen_Color primaryText];
        self.titleLabel.numberOfLines = 1;

        self.applyChip = [UIButton buttonWithType:UIButtonTypeCustom];
        self.applyChip.userInteractionEnabled = NO;
        self.applyChip.backgroundColor = [LoanZen_Color accent];
        self.applyChip.layer.cornerRadius = 10;
        self.applyChip.clipsToBounds = YES;
        self.applyChip.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
        [self.applyChip setTitle:@"Apply" forState:UIControlStateNormal];
        [self.applyChip setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];

        UIStackView *titleStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.titleLabel]];
        titleStack.axis = UILayoutConstraintAxisVertical;

        UIStackView *topRow = [[UIStackView alloc] initWithArrangedSubviews:@[self.logoContainer, titleStack, self.applyChip]];
        topRow.axis = UILayoutConstraintAxisHorizontal;
        topRow.alignment = UIStackViewAlignmentCenter;
        topRow.spacing = 12;

        [self.logoContainer mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(40);
        }];
        [self.applyChip mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(64);
            make.height.mas_equalTo(32);
        }];

        self.quotaCaptionLabel = [self LZ_captionLabelWithText:@"Quota range"];
        self.quotaValueLabel = [self LZ_valueLabel];
        self.rateCaptionLabel = [self LZ_captionLabelWithText:@"Reference Interest Rate"];
        self.rateCaptionLabel.textAlignment = NSTextAlignmentRight;
        self.rateValueLabel = [self LZ_valueLabel];
        self.rateValueLabel.textAlignment = NSTextAlignmentRight;
        self.rateValueLabel.textColor = [LoanZen_ColorUtils LZ_orderStatusSuccess];

        UIStackView *quotaStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.quotaCaptionLabel, self.quotaValueLabel]];
        quotaStack.axis = UILayoutConstraintAxisVertical;
        quotaStack.spacing = 4;
        quotaStack.alignment = UIStackViewAlignmentLeading;

        UIStackView *rateStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.rateCaptionLabel, self.rateValueLabel]];
        rateStack.axis = UILayoutConstraintAxisVertical;
        rateStack.spacing = 4;
        rateStack.alignment = UIStackViewAlignmentTrailing;

        UIStackView *metricsRow = [[UIStackView alloc] initWithArrangedSubviews:@[quotaStack, rateStack]];
        metricsRow.axis = UILayoutConstraintAxisHorizontal;
        metricsRow.distribution = UIStackViewDistributionFillEqually;
        metricsRow.alignment = UIStackViewAlignmentTop;
        metricsRow.spacing = 12;

        UIStackView *mainStack = [[UIStackView alloc] initWithArrangedSubviews:@[topRow, metricsRow]];
        mainStack.axis = UILayoutConstraintAxisVertical;
        mainStack.spacing = 12;
        [self.cardView addSubview:mainStack];
        [mainStack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.cardView).insets(UIEdgeInsetsMake(14, 14, 14, 14));
        }];
    }
    return self;
}

- (UILabel *)LZ_captionLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
    label.textColor = [LoanZen_Color secondaryText];
    label.numberOfLines = 1;
    return label;
}

- (UILabel *)LZ_valueLabel {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    label.textColor = [LoanZen_Color primaryText];
    label.numberOfLines = 1;
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.8;
    return label;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.logoView sd_cancelCurrentImageLoad];
    self.logoView.image = nil;
    self.logoView.hidden = YES;
    self.logoFallbackLabel.hidden = YES;
    self.logoFallbackLabel.text = nil;
}

- (void)LZ_configureWithProduct:(NSDictionary *)product {
    NSString *name = product[@"name"] ?: @"Loan";
    self.titleLabel.text = name;
    self.quotaValueLabel.text = product[@"quotaRange"] ?: product[@"amount"] ?: @"—";
    self.rateValueLabel.text = product[@"interestRate"] ?: @"—";

    NSString *logoURL = product[@"productLogo"];
    [self.logoView sd_cancelCurrentImageLoad];
    self.logoView.image = nil;

    if (logoURL.length == 0) {
        [self LZ_showLogoFallbackForName:name];
        return;
    }

    NSURL *url = [NSURL URLWithString:logoURL];
    if (!url) {
        NSString *encoded = [logoURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
        url = encoded.length > 0 ? [NSURL URLWithString:encoded] : nil;
    }
    if (!url) {
        [self LZ_showLogoFallbackForName:name];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [self.logoView sd_setImageWithURL:url
                     placeholderImage:nil
                              options:SDWebImageRetryFailed
                            completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (image) {
            self.logoView.hidden = NO;
            self.logoFallbackLabel.hidden = YES;
        } else {
            [self LZ_showLogoFallbackForName:name];
        }
    }];
}

- (void)LZ_showLogoFallbackForName:(NSString *)name {
    self.logoView.hidden = YES;
    self.logoFallbackLabel.hidden = NO;
    NSString *trimmed = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.logoFallbackLabel.text = trimmed.length > 0 ? [[trimmed substringToIndex:1] uppercaseString] : @"L";
}

@end

@interface LoanZen_HomeRootView () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UILabel *greetingLabel;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UIStackView *headerRow;
@property (nonatomic, strong) UIView *checkInCard;
@property (nonatomic, strong) UIStackView *checkInDayRow;
@property (nonatomic, strong) UIButton *checkInButton;
@property (nonatomic, strong) NSMutableArray<UIImageView *> *checkInDayDots;
@property (nonatomic, strong) NSMutableArray<UILabel *> *checkInDayLabels;
@property (nonatomic, strong) UIView *kycCard;
@property (nonatomic, strong) UILabel *kycLabel;
@property (nonatomic, strong) UIImageView *kycArrow;
@property (nonatomic, strong) UIView *productShell;
@property (nonatomic, strong) UITableView *productTableView;
@property (nonatomic, strong) UIImageView *centerLogoView;
@property (nonatomic, strong) UIButton *applyButton;
@property (nonatomic, strong) UIImageView *complianceBadgeView;
@property (nonatomic, strong) MASConstraint *productHeightConstraint;
@property (nonatomic, copy) NSArray<NSDictionary *> *products;
@property (nonatomic, assign) BOOL centerVisible;
@end

@implementation LoanZen_HomeRootView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [LoanZen_Color background];
        [self LZ_buildBackground];
        [self LZ_buildContent];
    }
    return self;
}

#pragma mark - Build

- (void)LZ_buildBackground {
    UIImageView *bg = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:[LoanZen_Asset pageBackground]]];
    bg.contentMode = UIViewContentModeScaleAspectFill;
    [self addSubview:bg];
    [bg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
}

- (void)LZ_buildContent {
    [self LZ_buildHeader];
    [self LZ_buildCheckInCard];
    [self LZ_buildKycCard];
    [self LZ_buildProductArea];
    [self LZ_buildCenterAndApply];
    [self LZ_buildComplianceFooter];
}

- (void)LZ_buildHeader {
    self.greetingLabel = [[UILabel alloc] init];
    self.greetingLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.greetingLabel.textColor = [LoanZen_Color secondaryText];

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    self.nameLabel.textColor = [LoanZen_Color primaryText];

    self.avatarView = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:[LoanZen_Asset homeAvatarDot]]];
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarView.layer.cornerRadius = 24;
    self.avatarView.clipsToBounds = YES;

    UIStackView *nameStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.greetingLabel, self.nameLabel]];
    nameStack.axis = UILayoutConstraintAxisVertical;
    nameStack.spacing = 4;
    nameStack.alignment = UIStackViewAlignmentLeading;

    UIStackView *headerRow = [[UIStackView alloc] initWithArrangedSubviews:@[nameStack, self.avatarView]];
    headerRow.axis = UILayoutConstraintAxisHorizontal;
    headerRow.alignment = UIStackViewAlignmentCenter;
    headerRow.distribution = UIStackViewDistributionEqualSpacing;
    self.headerRow = headerRow;

    [self addSubview:headerRow];
    [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(48);
    }];
    [headerRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_top).offset(LZ_SizeStatusBarHeight + 10);
        make.centerX.equalTo(self);
        make.width.mas_equalTo(343);
    }];
}

- (void)LZ_buildCheckInCard {
    self.checkInCard = [[UIView alloc] init];
    self.checkInCard.backgroundColor = [LoanZen_ColorUtils LZ_glassFill06];
    self.checkInCard.layer.cornerRadius = 16;
    self.checkInCard.layer.masksToBounds = YES;
    [self addSubview:self.checkInCard];

    UILabel *tip = [[UILabel alloc] init];
    tip.numberOfLines = 0;
    tip.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    tip.textColor = [LoanZen_Color secondaryText];
    tip.text = @"If you check in continuously, you'll have the chance to get a quick review.";

    self.checkInDayDots = [NSMutableArray array];
    self.checkInDayLabels = [NSMutableArray array];
    self.checkInDayRow = [[UIStackView alloc] init];
    self.checkInDayRow.axis = UILayoutConstraintAxisHorizontal;
    self.checkInDayRow.distribution = UIStackViewDistributionEqualSpacing;
    self.checkInDayRow.alignment = UIStackViewAlignmentCenter;
    for (NSInteger day = 1; day <= 7; day++) {
        [self.checkInDayRow addArrangedSubview:[self LZ_makeDayNode:day]];
    }

    self.checkInButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.checkInButton.backgroundColor = [LoanZen_Color accent];
    self.checkInButton.layer.cornerRadius = 24;
    self.checkInButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    [self.checkInButton setTitle:@"Check in immediately" forState:UIControlStateNormal];
    [self.checkInButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.checkInButton addTarget:self action:@selector(LZ_tapCheckIn) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[tip, self.checkInDayRow, self.checkInButton]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 16;
    stack.alignment = UIStackViewAlignmentFill;
    [self.checkInCard addSubview:stack];

    [self.checkInButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(48);
    }];
    [stack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.checkInCard).insets(UIEdgeInsetsMake(16, 16, 16, 16));
    }];
    [self.checkInCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerRow.mas_bottom).offset(20);
        make.centerX.equalTo(self);
        make.width.mas_equalTo(343);
    }];
}

- (UIView *)LZ_makeDayNode:(NSInteger)day {
    UIView *wrap = [[UIView alloc] init];

    UIImageView *dot = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:[LoanZen_Asset checkInDayPending]]];
    dot.contentMode = UIViewContentModeScaleAspectFit;

    UILabel *label = [[UILabel alloc] init];
    label.text = [NSString stringWithFormat:@"Day %ld", (long)day];
    label.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    label.textColor = [LoanZen_Color secondaryText];
    label.textAlignment = NSTextAlignmentCenter;

    UIStackView *col = [[UIStackView alloc] initWithArrangedSubviews:@[dot, label]];
    col.axis = UILayoutConstraintAxisVertical;
    col.spacing = 6;
    col.alignment = UIStackViewAlignmentCenter;
    [wrap addSubview:col];
    [dot mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(20);
    }];
    [col mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(wrap);
    }];
    [self.checkInDayDots addObject:dot];
    [self.checkInDayLabels addObject:label];
    return wrap;
}

- (void)LZ_refreshCheckInUIWithCompletedDays:(NSInteger)completedDays hasCheckedInToday:(BOOL)hasCheckedInToday {
    for (NSInteger index = 0; index < self.checkInDayDots.count; index++) {
        BOOL checked = (index + 1) <= completedDays;
        UIImageView *dot = self.checkInDayDots[index];
        UILabel *label = self.checkInDayLabels[index];
        dot.image = [LoanZen_Asset imageNamed:checked ? [LoanZen_Asset checkInDayDone] : [LoanZen_Asset checkInDayPending]];
        label.textColor = checked ? [LoanZen_Color accent] : [LoanZen_Color secondaryText];
        [dot mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(checked ? 24 : 20);
        }];
    }

    if (hasCheckedInToday) {
        [self.checkInButton setTitle:@"Checked in" forState:UIControlStateNormal];
        self.checkInButton.enabled = NO;
        self.checkInButton.alpha = 0.55;
    } else {
        [self.checkInButton setTitle:@"Check in immediately" forState:UIControlStateNormal];
        self.checkInButton.enabled = YES;
        self.checkInButton.alpha = 1.0;
    }
}

- (void)LZ_buildKycCard {
    self.kycCard = [[UIView alloc] init];
    self.kycCard.backgroundColor = [LoanZen_Color homePromptFill];
    self.kycCard.layer.cornerRadius = 12;
    self.kycCard.layer.borderWidth = 1.0 / UIScreen.mainScreen.scale;
    self.kycCard.layer.borderColor = [LoanZen_Color homePromptBorder].CGColor;
    UITapGestureRecognizer *kycTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(LZ_tapKYC)];
    [self.kycCard addGestureRecognizer:kycTap];
    [self addSubview:self.kycCard];

    self.kycLabel = [[UILabel alloc] init];
    self.kycLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    self.kycLabel.textColor = [LoanZen_Color primaryText];
    self.kycLabel.numberOfLines = 0;
    self.kycLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.kycLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];

    self.kycArrow = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:[LoanZen_Asset homeKycArrow]]];
    self.kycArrow.contentMode = UIViewContentModeScaleAspectFit;
    self.kycArrow.hidden = YES;

    UIView *kycSpacer = [[UIView alloc] init];
    [kycSpacer setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [kycSpacer setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[self.kycLabel, kycSpacer, self.kycArrow]];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.spacing = 8;
    row.alignment = UIStackViewAlignmentTop;
    [self.kycCard addSubview:row];
    [self.kycArrow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(16);
    }];
    [row mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.kycCard).inset(14);
        make.top.bottom.equalTo(self.kycCard).inset(14);
    }];
    [self.kycCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.checkInCard.mas_bottom).offset(16);
        make.centerX.equalTo(self);
        make.width.mas_equalTo(343);
    }];
}

- (void)LZ_buildProductArea {
    self.productShell = [[UIView alloc] init];
    self.productShell.backgroundColor = UIColor.clearColor;
    self.productShell.clipsToBounds = YES;
    self.productShell.hidden = YES;
    [self addSubview:self.productShell];

    self.productTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.productTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.productTableView.backgroundColor = UIColor.clearColor;
    self.productTableView.scrollEnabled = NO;
    self.productTableView.dataSource = self;
    self.productTableView.delegate = self;
    self.productTableView.rowHeight = 128;
    self.productTableView.estimatedRowHeight = 128;
    self.productTableView.showsVerticalScrollIndicator = YES;
    [self.productTableView registerClass:[LoanZen_HomeProductCell class] forCellReuseIdentifier:kLZHomeProductCellId];
    [self.productShell addSubview:self.productTableView];

    [self.productTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.productShell);
    }];
    [self.productShell mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.kycCard.mas_bottom).offset(12);
        make.centerX.equalTo(self);
        make.width.mas_equalTo(343);
        self.productHeightConstraint = make.height.mas_equalTo(0);
    }];
}

- (void)LZ_buildCenterAndApply {
    self.centerLogoView = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:[LoanZen_Asset homeCenterLogo]]];
    self.centerLogoView.contentMode = UIViewContentModeScaleAspectFit;
    self.centerLogoView.hidden = YES;
    [self addSubview:self.centerLogoView];

    self.applyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.applyButton.backgroundColor = [LoanZen_Color accent];
    self.applyButton.layer.cornerRadius = 24;
    self.applyButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.applyButton setTitle:@"Apply Now" forState:UIControlStateNormal];
    [self.applyButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.applyButton addTarget:self action:@selector(LZ_tapApply) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.applyButton];

    [self.centerLogoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(0);
    }];
    [self.applyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.productShell.mas_bottom).offset(40);
        make.centerX.equalTo(self);
        make.width.mas_equalTo(343);
        make.height.mas_equalTo(LZ_SizePrimaryButtonHeight);
    }];
}

- (void)LZ_buildComplianceFooter {
    self.complianceBadgeView = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:[LoanZen_Asset homeComplianceBadge]]];
    self.complianceBadgeView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.complianceBadgeView];
    [self.complianceBadgeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.width.mas_equalTo(343);
        make.height.mas_equalTo(56);
        make.bottom.equalTo(self).offset(-8);
    }];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    [self LZ_recalculateProductTableHeight];
}

- (void)LZ_recalculateProductTableHeight {
    BOOL showProducts = !self.productShell.hidden && self.products.count > 0;
    CGFloat tableHeight = 0;
    if (showProducts) {
        [self layoutIfNeeded];
        CGFloat footerTop = CGRectGetMinY(self.complianceBadgeView.frame) - 12;
        if (self.centerVisible) {
            footerTop = MIN(footerTop, CGRectGetMinY(self.applyButton.frame) - 12);
        }
        CGFloat available = footerTop - CGRectGetMinY(self.productShell.frame);
        CGFloat maxHeight = MAX(128, available);
        CGFloat raw = self.products.count * 128;
        tableHeight = MIN(MAX(raw, 128), maxHeight);
    }
    [self.productHeightConstraint setOffset:tableHeight];
    [self.productTableView layoutIfNeeded];
    self.productTableView.scrollEnabled = showProducts && self.productTableView.contentSize.height > tableHeight + 0.5;
}

#pragma mark - Render

- (NSString *)LZ_greetingForCurrentHour {
    NSInteger hour = [[NSCalendar currentCalendar] component:NSCalendarUnitHour fromDate:[NSDate date]];
    if (hour < 12) return @"Good morning,";
    if (hour < 18) return @"Good afternoon,";
    return @"Good evening,";
}

- (void)LZ_renderWithWelcome:(NSString *)welcome
                     kycHint:(NSString *)kycHint
                    products:(NSArray<NSDictionary *> *)products
              kycJumpEnabled:(BOOL)kycJumpEnabled
                   pendingKyc:(BOOL)pendingKyc
           hideCenterAndApply:(BOOL)hideCenterAndApply
         checkInCompletedDays:(NSInteger)checkInCompletedDays
            hasCheckedInToday:(BOOL)hasCheckedInToday {
    self.greetingLabel.text = [self LZ_greetingForCurrentHour];
    NSString *fallback = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (fallback.length == 0) fallback = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    if (fallback.length == 0) fallback = @"Kodeza Cash";
    NSString *name = welcome.length > 0 ? welcome : fallback;
    self.nameLabel.text = name;

    self.products = products ?: @[];
    self.kycLabel.text = kycHint;
    self.kycArrow.hidden = !kycJumpEnabled;
    self.kycCard.userInteractionEnabled = kycJumpEnabled;

    BOOL hasPrompt = kycHint.length > 0;
    BOOL showKycCard = pendingKyc || hasPrompt;
    self.kycCard.hidden = !showKycCard;

    BOOL showProducts = products.count > 0;
    self.productShell.hidden = !showProducts;
    self.centerVisible = !hideCenterAndApply;
    self.centerLogoView.hidden = YES;
    self.applyButton.hidden = hideCenterAndApply;

    [self LZ_refreshCheckInUIWithCompletedDays:checkInCompletedDays hasCheckedInToday:hasCheckedInToday];
    [self.productTableView reloadData];
    [self LZ_updateVerticalChainWithKycVisible:showKycCard productsVisible:showProducts centerVisible:self.centerVisible];
    [self setNeedsLayout];
}

- (void)LZ_updateVerticalChainWithKycVisible:(BOOL)kycVisible productsVisible:(BOOL)productsVisible centerVisible:(BOOL)centerVisible {
    UIView *productTopAnchor = kycVisible ? self.kycCard : self.checkInCard;
    CGFloat productTopOffset = kycVisible ? 12 : 16;
    [self.productShell mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(productTopAnchor.mas_bottom).offset(productTopOffset);
        make.centerX.equalTo(self);
        make.width.mas_equalTo(343);
        self.productHeightConstraint = make.height.mas_equalTo(0);
    }];

    if (centerVisible) {
        [self.applyButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.productShell.mas_bottom).offset(40);
            make.centerX.equalTo(self);
            make.width.mas_equalTo(343);
            make.height.mas_equalTo(LZ_SizePrimaryButtonHeight);
        }];
    } else {
        [self.applyButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.productShell.mas_bottom);
            make.centerX.equalTo(self);
            make.width.mas_equalTo(343);
            make.height.mas_equalTo(0);
        }];
    }

    [self.complianceBadgeView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.width.mas_equalTo(343);
        make.height.mas_equalTo(56);
        make.bottom.equalTo(self).offset(-8);
    }];

    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.products.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LoanZen_HomeProductCell *cell = [tableView dequeueReusableCellWithIdentifier:kLZHomeProductCellId forIndexPath:indexPath];
    [cell LZ_configureWithProduct:self.products[indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(LZ_homeRootView:didSelectProductAtIndex:)]) {
        [self.delegate LZ_homeRootView:self didSelectProductAtIndex:indexPath.row];
    }
}

#pragma mark - Actions

- (void)LZ_tapApply {
    if ([self.delegate respondsToSelector:@selector(LZ_homeRootViewDidTapApply:)]) {
        [self.delegate LZ_homeRootViewDidTapApply:self];
    }
}

- (void)LZ_tapCheckIn {
    if ([self.delegate respondsToSelector:@selector(LZ_homeRootViewDidTapCheckIn:)]) {
        [self.delegate LZ_homeRootViewDidTapCheckIn:self];
    }
}

- (void)LZ_tapKYC {
    if ([self.delegate respondsToSelector:@selector(LZ_homeRootViewDidTapKYC:)]) {
        [self.delegate LZ_homeRootViewDidTapKYC:self];
    }
}

@end
