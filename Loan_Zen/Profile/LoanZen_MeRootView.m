#import "LoanZen_MeRootView.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_ColorUtils.h"
@import Masonry;

@interface LoanZen_MeRootView ()
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIScrollView *menuScrollView;
@property (nonatomic, strong) UIView *menuContentView;
@property (nonatomic, strong) UIView *avatarView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIImageView *phoneIconView;
@property (nonatomic, strong) UILabel *phoneLabel;
@property (nonatomic, strong) UIControl *bankCard;
@property (nonatomic, strong) UIStackView *menuStack;
@property (nonatomic, strong) UIButton *signOutButton;
@end

@implementation LoanZen_MeRootView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [LoanZen_Color background];
        [self LZ_buildUI];
    }
    return self;
}

#pragma mark - Build

- (void)LZ_buildUI {
    UIImageView *bg = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:[LoanZen_Asset pageBackground]]];
    bg.contentMode = UIViewContentModeScaleAspectFill;
    [self addSubview:bg];
    [bg mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self); }];

    self.headerView = [[UIView alloc] init];
    self.headerView.backgroundColor = UIColor.clearColor;
    [self addSubview:self.headerView];

    self.menuScrollView = [[UIScrollView alloc] init];
    self.menuScrollView.showsVerticalScrollIndicator = NO;
    self.menuScrollView.alwaysBounceVertical = YES;
    self.menuScrollView.backgroundColor = UIColor.clearColor;
    [self addSubview:self.menuScrollView];

    self.menuContentView = [[UIView alloc] init];
    [self.menuScrollView addSubview:self.menuContentView];

    // 对齐截图：左 Icon；右上姓名、右下手机号
    self.avatarView = [[UIView alloc] init];
    self.avatarView.layer.cornerRadius = 11;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.backgroundColor = UIColor.clearColor;

    self.avatarImageView = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:[LoanZen_Asset loginLogo]]];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    [self.avatarView addSubview:self.avatarImageView];

    UIView *avatarGlow = [[UIView alloc] init];
    avatarGlow.backgroundColor = UIColor.clearColor;
    avatarGlow.layer.shadowColor = [LoanZen_Color accent].CGColor;
    avatarGlow.layer.shadowOpacity = 0.45;
    avatarGlow.layer.shadowRadius = 10;
    avatarGlow.layer.shadowOffset = CGSizeZero;
    [avatarGlow addSubview:self.avatarView];

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    self.nameLabel.textColor = [LoanZen_Color primaryText];
    self.nameLabel.numberOfLines = 1;
    self.nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;

    self.phoneIconView = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:[LoanZen_Asset mePhone]]];
    self.phoneIconView.contentMode = UIViewContentModeScaleAspectFit;

    self.phoneLabel = [[UILabel alloc] init];
    self.phoneLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    self.phoneLabel.textColor = [LoanZen_Color secondaryText];

    UIStackView *phoneRow = [[UIStackView alloc] initWithArrangedSubviews:@[self.phoneIconView, self.phoneLabel]];
    phoneRow.axis = UILayoutConstraintAxisHorizontal;
    phoneRow.spacing = 6;
    phoneRow.alignment = UIStackViewAlignmentCenter;

    UIStackView *profileTextStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.nameLabel, phoneRow]];
    profileTextStack.axis = UILayoutConstraintAxisVertical;
    profileTextStack.spacing = 6;
    profileTextStack.alignment = UIStackViewAlignmentLeading;

    UIStackView *profileRow = [[UIStackView alloc] initWithArrangedSubviews:@[avatarGlow, profileTextStack]];
    profileRow.axis = UILayoutConstraintAxisHorizontal;
    profileRow.spacing = 12;
    profileRow.alignment = UIStackViewAlignmentCenter;
    [self.headerView addSubview:profileRow];

    self.bankCard = [self LZ_makeBankCard];
    [self.headerView addSubview:self.bankCard];

    self.menuStack = [[UIStackView alloc] init];
    self.menuStack.axis = UILayoutConstraintAxisVertical;
    self.menuStack.spacing = 10;
    self.menuStack.alignment = UIStackViewAlignmentFill;
    [self.menuContentView addSubview:self.menuStack];

    self.signOutButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.signOutButton.layer.cornerRadius = 12;
    self.signOutButton.layer.borderWidth = 1;
    self.signOutButton.layer.borderColor = [LoanZen_Color danger].CGColor;
    self.signOutButton.backgroundColor = UIColor.clearColor;
    self.signOutButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.signOutButton setTitle:@"Sign out" forState:UIControlStateNormal];
    [self.signOutButton setTitleColor:[LoanZen_Color danger] forState:UIControlStateNormal];
    UIImage *signOutIcon = [LoanZen_Asset imageNamed:[LoanZen_Asset meSignOut]];
    if (signOutIcon) {
        [self.signOutButton setImage:signOutIcon forState:UIControlStateNormal];
        self.signOutButton.imageEdgeInsets = UIEdgeInsetsMake(0, -6, 0, 6);
    }
    [self.signOutButton addTarget:self action:@selector(LZ_tapSignOut) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.signOutButton];

    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
    }];
    [profileRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_safeAreaLayoutGuideTop).offset(12);
        make.left.equalTo(self.headerView).offset(LZ_SizePageInset);
        make.right.equalTo(self.headerView).offset(-LZ_SizePageInset);
    }];
    [avatarGlow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(48);
    }];
    [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(avatarGlow);
    }];
    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.avatarView);
    }];
    [self.phoneIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(14);
    }];
    [self.bankCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(profileRow.mas_bottom).offset(20);
        make.centerX.equalTo(self.headerView);
        make.width.mas_equalTo(343);
        make.height.mas_equalTo(88);
        make.bottom.equalTo(self.headerView).offset(-12);
    }];
    [self.signOutButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.width.mas_equalTo(343);
        make.height.mas_equalTo(LZ_SizePrimaryButtonHeight);
        make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-16);
    }];
    [self.menuScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom);
        make.left.right.equalTo(self);
        make.bottom.equalTo(self.signOutButton.mas_top).offset(-16);
    }];
    [self.menuContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.menuScrollView);
        make.width.equalTo(self.menuScrollView);
    }];
    [self.menuStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.menuContentView);
        make.centerX.equalTo(self.menuContentView);
        make.width.mas_equalTo(343);
        make.bottom.equalTo(self.menuContentView).offset(-8);
    }];
}

- (UIControl *)LZ_makeBankCard {
    UIControl *card = [[UIControl alloc] init];
    card.layer.cornerRadius = 16;
    card.clipsToBounds = YES;
    [card addTarget:self action:@selector(LZ_tapBank) forControlEvents:UIControlEventTouchUpInside];

    UIImageView *bg = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:[LoanZen_Asset meBankCardBackground]]];
    bg.contentMode = UIViewContentModeScaleAspectFill;
    bg.clipsToBounds = YES;
    [card addSubview:bg];

    UIImageView *icon = [self LZ_makeLeadingIconViewNamed:[LoanZen_Asset meBank] size:36];

    UILabel *title = [[UILabel alloc] init];
    title.text = @"Bank Account";
    title.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    title.textColor = [LoanZen_Color primaryText];
    title.userInteractionEnabled = NO;

    UILabel *subtitle = [[UILabel alloc] init];
    subtitle.text = @"Manage your accounts";
    subtitle.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    subtitle.textColor = [LoanZen_Color secondaryText];
    subtitle.userInteractionEnabled = NO;

    UIStackView *textStack = [[UIStackView alloc] initWithArrangedSubviews:@[title, subtitle]];
    textStack.axis = UILayoutConstraintAxisVertical;
    textStack.spacing = 4;
    textStack.alignment = UIStackViewAlignmentLeading;
    textStack.userInteractionEnabled = NO;

    UIImageView *chevron = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:[LoanZen_Asset meBankChevron]]];
    chevron.contentMode = UIViewContentModeScaleAspectFit;
    chevron.userInteractionEnabled = NO;

    [card addSubview:bg];
    [card addSubview:icon];
    [card addSubview:textStack];
    [card addSubview:chevron];

    [bg mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(card); }];
    [icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(card).offset(16);
        make.centerY.equalTo(card);
    }];
    [textStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(icon.mas_right).offset(14);
        make.centerY.equalTo(card);
        make.right.lessThanOrEqualTo(chevron.mas_left).offset(-12);
    }];
    [chevron mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(card).offset(-16);
        make.centerY.equalTo(card);
        make.width.height.mas_equalTo(14);
    }];
    return card;
}

- (UIImageView *)LZ_makeLeadingIconViewNamed:(NSString *)name size:(CGFloat)size {
    UIImage *image = name.length > 0 ? [LoanZen_Asset imageNamed:name] : nil;
    UIImageView *icon = [[UIImageView alloc] initWithImage:image];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.userInteractionEnabled = NO;
    if (image) {
        [icon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(size);
        }];
    }
    return icon;
}

- (UIControl *)LZ_makeMenuRowWithItem:(NSDictionary *)item {
    UIControl *row = [[UIControl alloc] init];
    row.accessibilityIdentifier = item[@"action"] ?: @"";
    row.backgroundColor = [LoanZen_ColorUtils LZ_glassFill08];
    row.layer.cornerRadius = 16;
    row.layer.borderWidth = 1;
    row.layer.borderColor = [LoanZen_ColorUtils LZ_glassBorder14].CGColor;
    row.clipsToBounds = YES;

    UIImageView *icon = [self LZ_makeLeadingIconViewNamed:item[@"icon"] size:36];

    UILabel *title = [[UILabel alloc] init];
    title.text = item[@"title"];
    title.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    title.textColor = [LoanZen_Color primaryText];
    title.userInteractionEnabled = NO;

    UIImageView *chevron = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:[LoanZen_Asset meListChevron]]];
    chevron.contentMode = UIViewContentModeScaleAspectFit;
    chevron.userInteractionEnabled = NO;

    [row addSubview:icon];
    [row addSubview:title];
    [row addSubview:chevron];
    [row mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(56); }];

    [icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(row).offset(16);
        make.centerY.equalTo(row);
    }];
    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(icon.mas_right).offset(12);
        make.centerY.equalTo(row);
        make.right.lessThanOrEqualTo(chevron.mas_left).offset(-8);
    }];
    [chevron mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(row).offset(-16);
        make.centerY.equalTo(row);
        make.width.height.mas_equalTo(14);
    }];

    [row addTarget:self action:@selector(LZ_tapMenuRow:) forControlEvents:UIControlEventTouchUpInside];
    return row;
}

#pragma mark - Render

- (NSString *)LZ_appDisplayName {
    NSString *name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (name.length == 0) name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    return name.length > 0 ? name : @"Kodeza Cash";
}

- (void)LZ_renderWithName:(NSString *)name phone:(NSString *)phone menuItems:(NSArray<NSDictionary *> *)menuItems {
    NSString *trimmed = [name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    BOOL missingName = trimmed.length == 0 || [trimmed isEqualToString:@"User name"];
    self.nameLabel.text = missingName ? [self LZ_appDisplayName] : trimmed;
    self.phoneLabel.text = phone.length > 0 ? phone : @"+63";

    if (self.menuStack.arrangedSubviews.count > 0) return;

    [menuItems enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        (void)idx;
        [self.menuStack addArrangedSubview:[self LZ_makeMenuRowWithItem:item]];
    }];
}

#pragma mark - Actions

- (void)LZ_tapBank {
    if ([self.delegate respondsToSelector:@selector(LZ_meRootViewDidTapBankAccount:)]) {
        [self.delegate LZ_meRootViewDidTapBankAccount:self];
    }
}

- (void)LZ_tapMenuRow:(UIControl *)sender {
    NSString *action = sender.accessibilityIdentifier ?: @"";
    if (action.length == 0) return;
    if ([self.delegate respondsToSelector:@selector(LZ_meRootView:didSelectMenuAction:)]) {
        [self.delegate LZ_meRootView:self didSelectMenuAction:action];
    }
}

- (void)LZ_tapSignOut {
    if ([self.delegate respondsToSelector:@selector(LZ_meRootViewDidTapSignOut:)]) {
        [self.delegate LZ_meRootViewDidTapSignOut:self];
    }
}

@end
