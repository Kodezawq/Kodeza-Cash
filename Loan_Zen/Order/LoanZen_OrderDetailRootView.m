#import "LoanZen_OrderDetailRootView.h"
#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_ColorUtils.h"
#import "LoanZen_PopupHelper.h"
#import "LoanZen_OrderDetailBankCardView.h"
@import Masonry;

static NSString * const kLZRepaymentHint = @"If you repay the first amount due on time, the remaining balance will be automatically reset to zero for you.";

@implementation LoanZen_OrderDetailPenRow
+ (instancetype)LZ_rowWithTitle:(NSString *)title value:(NSString *)value {
    LoanZen_OrderDetailPenRow *row = [[LoanZen_OrderDetailPenRow alloc] init];
    row.title = title ?: @"";
    row.value = value ?: @"—";
    return row;
}
@end

@interface LoanZen_OrderDetailRootView ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *scrollContent;
@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UIButton *deferButton;
@property (nonatomic, strong) UIButton *repayButton;
@property (nonatomic, strong) UIButton *primaryButton;
@property (nonatomic, copy) void (^repayAction)(void);
@property (nonatomic, copy) void (^deferAction)(void);
@property (nonatomic, copy) void (^primaryAction)(void);
@property (nonatomic, assign) BOOL showsRepay;
@property (nonatomic, assign) BOOL showsDefer;
@property (nonatomic, assign) BOOL isRepaymentExpanded;
@property (nonatomic, copy) NSArray<NSDictionary *> *scheduleItems;
@property (nonatomic, strong) UIStackView *scheduleRowsStack;
@property (nonatomic, strong) UIButton *scheduleToggleButton;
@property (nonatomic, strong) MASConstraint *scheduleCardHeightConstraint;
@end

@implementation LoanZen_OrderDetailRootView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.showsRepay = NO;
        self.showsDefer = NO;
        self.isRepaymentExpanded = NO;

        self.scrollView = [[UIScrollView alloc] init];
        self.scrollView.showsVerticalScrollIndicator = NO;
        self.scrollView.alwaysBounceVertical = YES;
        self.scrollContent = [[UIView alloc] init];

        self.bottomBar = [[UIView alloc] init];
        self.bottomBar.backgroundColor = UIColor.clearColor;

        self.deferButton = [self LZ_outlineButtonWithTitle:@"Defer"];
        self.repayButton = [self LZ_gradientButtonWithTitle:@"Repay"];
        self.primaryButton = [self LZ_gradientButtonWithTitle:@"Unfinished Application"];

        [self.deferButton addTarget:self action:@selector(LZ_tapDefer) forControlEvents:UIControlEventTouchUpInside];
        [self.repayButton addTarget:self action:@selector(LZ_tapRepay) forControlEvents:UIControlEventTouchUpInside];
        [self.primaryButton addTarget:self action:@selector(LZ_tapPrimary) forControlEvents:UIControlEventTouchUpInside];

        [self addSubview:self.scrollView];
        [self.scrollView addSubview:self.scrollContent];
        [self addSubview:self.bottomBar];

        [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(self);
            make.bottom.equalTo(self.bottomBar.mas_top);
        }];
        [self.scrollContent mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.scrollView);
            make.width.equalTo(self.scrollView);
        }];
        [self.bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self);
        }];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [LoanZen_ColorUtils LZ_applyBrandGradientToView:self.repayButton cornerRadius:self.repayButton.layer.cornerRadius];
    [LoanZen_ColorUtils LZ_applyBrandGradientToView:self.primaryButton cornerRadius:self.primaryButton.layer.cornerRadius];
}

#pragma mark - Public

- (void)LZ_setRepayAction:(void (^)(void))action { self.repayAction = action; }
- (void)LZ_setDeferAction:(void (^)(void))action { self.deferAction = action; }
- (void)LZ_setPrimaryActionWithTitle:(nullable NSString *)title action:(nullable void (^)(void))action {
    self.primaryAction = action;
    if (title.length > 0) [self.primaryButton setTitle:title forState:UIControlStateNormal];
}

- (void)LZ_setActionVisibilityShowRepay:(BOOL)showRepay showDefer:(BOOL)showDefer {
    self.showsRepay = showRepay;
    self.showsDefer = showDefer;
}

- (void)LZ_configureWithTipMessage:(NSString *)tipMessage
                       productName:(NSString *)productName
                        loanAmount:(NSString *)loanAmount
                statusBarImageName:(NSString *)statusBarImageName
                        detailRows:(NSArray<LoanZen_OrderDetailPenRow *> *)detailRows
                     scheduleItems:(NSArray<NSDictionary *> *)scheduleItems
                  maskedCardNumber:(NSString *)maskedCardNumber {
    for (UIView *sub in self.scrollContent.subviews) [sub removeFromSuperview];
    for (UIView *sub in self.bottomBar.subviews) [sub removeFromSuperview];
    self.scheduleRowsStack = nil;
    self.scheduleToggleButton = nil;
    self.scheduleCardHeightConstraint = nil;
    self.isRepaymentExpanded = NO;
    self.scheduleItems = [scheduleItems copy] ?: @[];

    UIView *last = nil;
    if (tipMessage.length > 0) {
        UIView *tip = [self LZ_tipBannerWithText:tipMessage];
        [self.scrollContent addSubview:tip];
        [tip mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.scrollContent).offset(12);
            make.left.right.equalTo(self.scrollContent).inset(16);
        }];
        last = tip;
    }

    UIView *mainCard = [self LZ_mainCardWithProductName:productName
                                             loanAmount:loanAmount
                                     statusBarImageName:statusBarImageName
                                             detailRows:detailRows
                                       maskedCardNumber:maskedCardNumber];
    [self.scrollContent addSubview:mainCard];
    [mainCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.scrollContent).inset(16);
        if (last) make.top.equalTo(last.mas_bottom).offset(12);
        else make.top.equalTo(self.scrollContent).offset(12);
    }];
    last = mainCard;

    if (self.scheduleItems.count > 0) {
        UIView *scheduleCard = [self LZ_buildScheduleCard];
        [self.scrollContent addSubview:scheduleCard];
        [scheduleCard mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.scrollContent).inset(16);
            make.top.equalTo(last.mas_bottom).offset(12);
        }];
        last = scheduleCard;
    }

    [last mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.scrollContent).offset(-24);
    }];

    [self LZ_rebuildBottomBar];
}

#pragma mark - Bottom bar

- (void)LZ_rebuildBottomBar {
    BOOL hasPrimary = self.primaryAction != nil;
    self.bottomBar.hidden = !(hasPrimary || self.showsRepay || self.showsDefer);
    if (self.bottomBar.hidden) {
        [self.bottomBar mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self);
            make.height.mas_equalTo(0);
        }];
        return;
    }

    if (hasPrimary) {
        [self.bottomBar addSubview:self.primaryButton];
        [self.primaryButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.bottomBar).inset(16);
            make.top.equalTo(self.bottomBar).offset(12);
            make.bottom.equalTo(self.bottomBar.mas_safeAreaLayoutGuideBottom).offset(-12);
            make.height.mas_equalTo(48);
        }];
    } else if (self.showsRepay && self.showsDefer) {
        UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[self.deferButton, self.repayButton]];
        row.axis = UILayoutConstraintAxisHorizontal;
        row.spacing = 12;
        row.distribution = UIStackViewDistributionFill;
        [self.deferButton mas_makeConstraints:^(MASConstraintMaker *make) { make.width.equalTo(self.repayButton).multipliedBy(0.42); }];
        [self.bottomBar addSubview:row];
        [row mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.bottomBar).inset(16);
            make.top.equalTo(self.bottomBar).offset(12);
            make.bottom.equalTo(self.bottomBar.mas_safeAreaLayoutGuideBottom).offset(-12);
            make.height.mas_equalTo(48);
        }];
    } else if (self.showsRepay) {
        [self.bottomBar addSubview:self.repayButton];
        [self.repayButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.bottomBar).inset(16);
            make.top.equalTo(self.bottomBar).offset(12);
            make.bottom.equalTo(self.bottomBar.mas_safeAreaLayoutGuideBottom).offset(-12);
            make.height.mas_equalTo(48);
        }];
    } else if (self.showsDefer) {
        [self.bottomBar addSubview:self.deferButton];
        [self.deferButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.bottomBar).inset(16);
            make.top.equalTo(self.bottomBar).offset(12);
            make.bottom.equalTo(self.bottomBar.mas_safeAreaLayoutGuideBottom).offset(-12);
            make.height.mas_equalTo(48);
        }];
    }
    [self.bottomBar mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
    }];
}

#pragma mark - Components

- (UIView *)LZ_tipBannerWithText:(NSString *)text {
    UIView *wrap = [[UIView alloc] init];
    wrap.backgroundColor = [[LoanZen_Color accent] colorWithAlphaComponent:0.12];
    wrap.layer.cornerRadius = 12;
    wrap.layer.borderWidth = 1;
    wrap.layer.borderColor = [[LoanZen_Color accent] colorWithAlphaComponent:0.35].CGColor;
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    label.textColor = [LoanZen_Color kycFormLabel];
    [wrap addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(wrap).insets(UIEdgeInsetsMake(12, 14, 12, 14));
    }];
    return wrap;
}

- (UIView *)LZ_glassCard {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [LoanZen_ColorUtils LZ_glassFill08];
    card.layer.cornerRadius = 16;
    card.layer.borderWidth = 1;
    card.layer.borderColor = [LoanZen_ColorUtils LZ_glassBorder14].CGColor;
    card.clipsToBounds = YES;
    return card;
}

- (UIView *)LZ_mainCardWithProductName:(NSString *)productName
                            loanAmount:(NSString *)loanAmount
                    statusBarImageName:(NSString *)statusBarImageName
                            detailRows:(NSArray<LoanZen_OrderDetailPenRow *> *)detailRows
                      maskedCardNumber:(NSString *)maskedCardNumber {
    UIView *card = [self LZ_glassCard];

    UIView *iconTile = [[UIView alloc] init];
    iconTile.backgroundColor = [[LoanZen_Color accent] colorWithAlphaComponent:0.18];
    iconTile.layer.cornerRadius = 10;
    iconTile.layer.borderWidth = 1;
    iconTile.layer.borderColor = [[LoanZen_Color accent] colorWithAlphaComponent:0.35].CGColor;
    UILabel *initial = [[UILabel alloc] init];
    initial.text = productName.length > 0 ? [[productName substringToIndex:MIN(1, productName.length)] uppercaseString] : @"—";
    initial.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    initial.textColor = [LoanZen_Color primaryText];
    [iconTile addSubview:initial];
    [initial mas_makeConstraints:^(MASConstraintMaker *make) { make.center.equalTo(iconTile); }];
    [iconTile mas_makeConstraints:^(MASConstraintMaker *make) { make.width.height.mas_equalTo(40); }];

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.text = productName.length > 0 ? productName : @"—";
    nameLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    nameLabel.textColor = [LoanZen_Color primaryText];

    UILabel *amountLabel = [[UILabel alloc] init];
    amountLabel.text = loanAmount.length > 0 ? loanAmount : @"—";
    amountLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    amountLabel.textColor = [LoanZen_Color accent];
    amountLabel.textAlignment = NSTextAlignmentRight;

    UIStackView *header = [[UIStackView alloc] initWithArrangedSubviews:@[iconTile, nameLabel, amountLabel]];
    header.axis = UILayoutConstraintAxisHorizontal;
    header.alignment = UIStackViewAlignmentCenter;
    header.spacing = 10;
    [nameLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [amountLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    UIImage *statusImage = statusBarImageName.length > 0 ? [LoanZen_Asset imageNamed:statusBarImageName] : nil;
    UIImageView *statusBar = [[UIImageView alloc] initWithImage:statusImage];
    statusBar.contentMode = UIViewContentModeScaleAspectFit;
    statusBar.hidden = statusImage == nil;

    UIStackView *detailsStack = [[UIStackView alloc] init];
    detailsStack.axis = UILayoutConstraintAxisVertical;
    detailsStack.spacing = 0;
    for (NSInteger i = 0; i < (NSInteger)detailRows.count; i++) {
        LoanZen_OrderDetailPenRow *row = detailRows[i];
        [detailsStack addArrangedSubview:[self LZ_detailRow:row]];
        if (i < (NSInteger)detailRows.count - 1) {
            [detailsStack addArrangedSubview:[self LZ_separator]];
        }
    }

    LoanZen_OrderDetailBankCardView *bankCardView = [[LoanZen_OrderDetailBankCardView alloc] init];
    [bankCardView LZ_configureWithMaskedCardNumber:maskedCardNumber];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;
    stack.alignment = UIStackViewAlignmentFill;
    [stack addArrangedSubview:header];
    [stack addArrangedSubview:statusBar];
    [stack addArrangedSubview:detailsStack];
    [stack addArrangedSubview:bankCardView];
    [card addSubview:stack];
    [stack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(card).insets(UIEdgeInsetsMake(16, 16, 16, 16));
    }];
    if (statusImage) {
        [statusBar mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(34); }];
    }
    return card;
}

- (UIView *)LZ_buildScheduleCard {
    UIView *card = [self LZ_glassCard];
    UILabel *title = [[UILabel alloc] init];
    title.text = @"Repayment plan";
    title.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    title.textColor = [LoanZen_Color primaryText];

    self.scheduleToggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.scheduleToggleButton.contentMode = UIViewContentModeCenter;
    [self.scheduleToggleButton setImage:[LoanZen_Asset imageNamed:@"lz_loan_zk"] forState:UIControlStateNormal];
    [self.scheduleToggleButton addTarget:self action:@selector(LZ_toggleSchedule) forControlEvents:UIControlEventTouchUpInside];
    self.scheduleToggleButton.hidden = self.scheduleItems.count <= 1;

    UIStackView *header = [[UIStackView alloc] initWithArrangedSubviews:@[title, [[UIView alloc] init], self.scheduleToggleButton]];
    header.axis = UILayoutConstraintAxisHorizontal;
    header.alignment = UIStackViewAlignmentCenter;

    self.scheduleRowsStack = [[UIStackView alloc] init];
    self.scheduleRowsStack.axis = UILayoutConstraintAxisVertical;
    self.scheduleRowsStack.spacing = 0;
    [self LZ_rebuildScheduleRows];

    UILabel *hint = [[UILabel alloc] init];
    hint.text = kLZRepaymentHint;
    hint.numberOfLines = 0;
    hint.font = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
    hint.textColor = [LoanZen_Color kycFormPlaceholder];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[header, self.scheduleRowsStack, hint]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 10;
    [card addSubview:stack];
    [stack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(card).insets(UIEdgeInsetsMake(16, 16, 16, 16));
    }];
    // 与 LoanBase 一致：扩大下拉按钮点击区域
    [self.scheduleToggleButton mas_makeConstraints:^(MASConstraintMaker *make) { make.width.height.mas_equalTo(40); }];
    return card;
}

- (void)LZ_rebuildScheduleRows {
    for (UIView *v in self.scheduleRowsStack.arrangedSubviews) {
        [self.scheduleRowsStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    [self.scheduleRowsStack addArrangedSubview:[self LZ_scheduleHeaderRow]];
    NSArray *items = self.scheduleItems ?: @[];
    NSArray *visible = (!self.isRepaymentExpanded && items.count > 1) ? @[items.firstObject] : items;
    for (NSDictionary *item in visible) {
        [self.scheduleRowsStack addArrangedSubview:[self LZ_scheduleDataRowWithDueDate:item[LZAPIFieldDueDate] amountDue:item[LZAPIFieldAmount]]];
    }
    self.scheduleToggleButton.hidden = items.count <= 1;
    [self.scheduleToggleButton setImage:[LoanZen_Asset imageNamed:self.isRepaymentExpanded ? @"lz_loan_sq" : @"lz_loan_zk"] forState:UIControlStateNormal];
}

- (UIView *)LZ_detailRow:(LoanZen_OrderDetailPenRow *)row {
    UIView *container = [[UIView alloc] init];
    UIStackView *leftStack = [[UIStackView alloc] init];
    leftStack.axis = UILayoutConstraintAxisHorizontal;
    leftStack.spacing = 4;
    leftStack.alignment = UIStackViewAlignmentCenter;
    UILabel *title = [[UILabel alloc] init];
    title.text = row.title;
    title.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    title.textColor = [LoanZen_Color kycFormLabel];
    [leftStack addArrangedSubview:title];
    if (row.showsInfoGlyph) {
        UIImageView *info = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:@"lz_loan_sm"]];
        info.contentMode = UIViewContentModeScaleAspectFit;
        info.userInteractionEnabled = row.tipMessage.length > 0;
        if (row.tipMessage.length > 0) {
            info.accessibilityHint = row.tipMessage;
            [info addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(LZ_tapInfo:)]];
        }
        [info mas_makeConstraints:^(MASConstraintMaker *make) { make.width.height.mas_equalTo(14); }];
        [leftStack addArrangedSubview:info];
    }
    UILabel *value = [[UILabel alloc] init];
    value.text = row.value;
    value.textAlignment = NSTextAlignmentRight;
    if (row.valueIsAccentTerm) {
        value.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        value.textColor = [LoanZen_Color accent];
    } else if (row.valueIsSuccess) {
        value.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
        value.textColor = [LoanZen_ColorUtils LZ_orderStatusSuccess];
    } else {
        value.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
        value.textColor = [LoanZen_Color primaryText];
    }
    [container addSubview:leftStack];
    [container addSubview:value];
    [container mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(28); }];
    [leftStack mas_makeConstraints:^(MASConstraintMaker *make) { make.left.centerY.equalTo(container); }];
    [value mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.centerY.equalTo(container);
        make.left.greaterThanOrEqualTo(leftStack.mas_right).offset(8);
    }];
    return container;
}

- (UIView *)LZ_separator {
    UIView *line = [[UIView alloc] init];
    line.backgroundColor = [LoanZen_ColorUtils LZ_glassBorder10];
    [line mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(1); }];
    return line;
}

- (UIView *)LZ_scheduleHeaderRow {
    UIView *row = [[UIView alloc] init];
    UILabel *left = [[UILabel alloc] init];
    left.text = @"Due Date";
    left.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    left.textColor = [LoanZen_Color kycFormPlaceholder];
    UILabel *right = [[UILabel alloc] init];
    right.text = @"Amount Due";
    right.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    right.textColor = [LoanZen_Color kycFormPlaceholder];
    right.textAlignment = NSTextAlignmentRight;
    [row addSubview:left];
    [row addSubview:right];
    [row mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(18); }];
    [left mas_makeConstraints:^(MASConstraintMaker *make) { make.left.centerY.equalTo(row); }];
    [right mas_makeConstraints:^(MASConstraintMaker *make) { make.right.centerY.equalTo(row); }];
    return row;
}

- (UIView *)LZ_scheduleDataRowWithDueDate:(NSString *)dueDate amountDue:(NSString *)amountDue {
    UIView *row = [[UIView alloc] init];
    UILabel *left = [[UILabel alloc] init];
    left.text = dueDate;
    left.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    left.textColor = [LoanZen_Color primaryText];
    UILabel *right = [[UILabel alloc] init];
    right.text = amountDue;
    right.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    right.textColor = [LoanZen_ColorUtils LZ_orderStatusSuccess];
    right.textAlignment = NSTextAlignmentRight;
    [row addSubview:left];
    [row addSubview:right];
    [row mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(36); }];
    [left mas_makeConstraints:^(MASConstraintMaker *make) { make.left.centerY.equalTo(row); }];
    [right mas_makeConstraints:^(MASConstraintMaker *make) { make.right.centerY.equalTo(row); }];
    return row;
}

- (UIButton *)LZ_outlineButtonWithTitle:(NSString *)title {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.layer.cornerRadius = 24;
    btn.layer.borderWidth = 1;
    btn.layer.borderColor = [LoanZen_ColorUtils LZ_glassBorder14].CGColor;
    btn.backgroundColor = [LoanZen_ColorUtils LZ_glassFill06];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[LoanZen_Color kycFormLabel] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    return btn;
}

- (UIButton *)LZ_gradientButtonWithTitle:(NSString *)title {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.layer.cornerRadius = 24;
    btn.clipsToBounds = YES;
    btn.layer.masksToBounds = NO;
    btn.layer.shadowColor = [LoanZen_Color accent].CGColor;
    btn.layer.shadowOpacity = 0.35;
    btn.layer.shadowRadius = 8;
    btn.layer.shadowOffset = CGSizeMake(0, 4);
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    return btn;
}

#pragma mark - Actions

- (void)LZ_tapRepay { if (self.repayAction) self.repayAction(); }
- (void)LZ_tapDefer { if (self.deferAction) self.deferAction(); }
- (void)LZ_tapPrimary { if (self.primaryAction) self.primaryAction(); }

- (void)LZ_toggleSchedule {
    self.isRepaymentExpanded = !self.isRepaymentExpanded;
    [self LZ_rebuildScheduleRows];
}

- (void)LZ_tapInfo:(UITapGestureRecognizer *)gesture {
    NSString *message = gesture.view.accessibilityHint;
    if (message.length == 0) return;
    UIView *host = self.window ?: self;
    [LoanZen_PopupHelper LZ_showTapToDismissMessage:message onView:host];
}

@end
