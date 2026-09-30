#import "LoanZen_OrderWithdrawalRootView.h"
#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_ColorUtils.h"
#import "LoanZen_PopupHelper.h"
#import "LoanZen_OrderDetailBankCardView.h"
@import Masonry;

static const NSInteger kLZAmountButtonBaseTag = 7000;
static NSString * const kLZWithdrawTip = @"You have a pending withdrawal order, and we need your confirmation. Once confirmed, we will transfer the funds to your bank account immediately.";
static NSString * const kLZRepaymentHint = @"If you repay the first amount due on time, the remaining balance will be automatically reset to zero for you.";

@interface LoanZen_OrderWithdrawalRootView ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *scrollContent;
@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UIButton *withdrawButton;
@property (nonatomic, strong) UILabel *amountLabel;
@property (nonatomic, strong) UILabel *termValueLabel;
@property (nonatomic, strong) UIImageView *amountChevron;
@property (nonatomic, strong) UIImageView *termChevron;
@property (nonatomic, strong) UIStackView *scheduleRowsStack;
@property (nonatomic, strong) UIButton *scheduleToggleButton;
@property (nonatomic, assign) BOOL isRepaymentExpanded;
@property (nonatomic, copy) NSArray<NSDictionary *> *scheduleItems;
@property (nonatomic, assign) BOOL amountSelectable;
@property (nonatomic, assign) BOOL termSelectable;
@property (nonatomic, copy) NSArray<NSString *> *amountOptions;
@property (nonatomic, assign) NSInteger selectedAmountIndex;
@end

@implementation LoanZen_OrderWithdrawalRootView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.scrollView = [[UIScrollView alloc] init];
        self.scrollView.showsVerticalScrollIndicator = NO;
        self.scrollContent = [[UIView alloc] init];
        self.bottomBar = [[UIView alloc] init];
        self.withdrawButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.withdrawButton.layer.cornerRadius = 24;
        self.withdrawButton.clipsToBounds = YES;
        self.withdrawButton.layer.shadowColor = [LoanZen_Color accent].CGColor;
        self.withdrawButton.layer.shadowOpacity = 0.35;
        self.withdrawButton.layer.shadowRadius = 8;
        self.withdrawButton.layer.shadowOffset = CGSizeMake(0, 4);
        [self.withdrawButton setTitle:@"Withdraw" forState:UIControlStateNormal];
        [self.withdrawButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        self.withdrawButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        [self.withdrawButton addTarget:self action:@selector(LZ_tapWithdraw) forControlEvents:UIControlEventTouchUpInside];

        [self addSubview:self.scrollView];
        [self.scrollView addSubview:self.scrollContent];
        [self addSubview:self.bottomBar];
        [self.bottomBar addSubview:self.withdrawButton];

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
        [self.withdrawButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.bottomBar).inset(16);
            make.top.equalTo(self.bottomBar).offset(12);
            make.bottom.equalTo(self.bottomBar.mas_safeAreaLayoutGuideBottom).offset(-12);
            make.height.mas_equalTo(48);
        }];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [LoanZen_ColorUtils LZ_applyBrandGradientToView:self.withdrawButton cornerRadius:24];
}

- (void)LZ_configureWithProductName:(NSString *)productName
                             amount:(NSString *)amount
                               term:(NSString *)term
                     amountReceived:(NSString *)amountReceived
                          serviceFee:(NSString *)serviceFee
                            interest:(NSString *)interest
                     applicationDate:(NSString *)applicationDate
                             dueDate:(NSString *)dueDate
                       scheduleItems:(NSArray<NSDictionary *> *)scheduleItems
                    maskedCardNumber:(NSString *)maskedCardNumber
                    amountSelectable:(BOOL)amountSelectable
                      termSelectable:(BOOL)termSelectable
                       amountOptions:(NSArray<NSString *> *)amountOptions
                 selectedAmountIndex:(NSInteger)selectedAmountIndex {
    self.amountSelectable = amountSelectable;
    self.termSelectable = termSelectable;
    self.amountOptions = amountOptions ?: @[];
    self.selectedAmountIndex = selectedAmountIndex;
    self.scheduleItems = scheduleItems ?: @[];
    self.isRepaymentExpanded = NO;

    for (UIView *sub in self.scrollContent.subviews) [sub removeFromSuperview];

    UIView *tip = [self LZ_tipBannerWithText:kLZWithdrawTip];
    [self.scrollContent addSubview:tip];
    [tip mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.scrollContent).offset(12);
        make.left.right.equalTo(self.scrollContent).inset(16);
    }];

    UIView *mainCard = [self LZ_buildMainCardWithProductName:productName
                                                      amount:amount
                                                        term:term
                                              amountReceived:amountReceived
                                                   serviceFee:serviceFee
                                                     interest:interest
                                              applicationDate:applicationDate
                                                      dueDate:dueDate
                                             maskedCardNumber:maskedCardNumber];
    [self.scrollContent addSubview:mainCard];
    [mainCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.scrollContent).inset(16);
        make.top.equalTo(tip.mas_bottom).offset(12);
    }];

    UIView *scheduleCard = [self LZ_buildScheduleCard];
    [self.scrollContent addSubview:scheduleCard];
    [scheduleCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.scrollContent).inset(16);
        make.top.equalTo(mainCard.mas_bottom).offset(12);
        make.bottom.equalTo(self.scrollContent).offset(-24);
    }];
}

#pragma mark - UI builders

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

- (UIView *)LZ_buildMainCardWithProductName:(NSString *)productName
                                     amount:(NSString *)amount
                                       term:(NSString *)term
                             amountReceived:(NSString *)amountReceived
                                  serviceFee:(NSString *)serviceFee
                                    interest:(NSString *)interest
                             applicationDate:(NSString *)applicationDate
                                     dueDate:(NSString *)dueDate
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

    self.amountLabel = [[UILabel alloc] init];
    self.amountLabel.text = amount.length > 0 ? amount : @"—";
    self.amountLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    self.amountLabel.textColor = [LoanZen_Color accent];
    self.amountChevron = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:@"lz_loan_jexl"]];
    self.amountChevron.contentMode = UIViewContentModeScaleAspectFit;
    self.amountChevron.hidden = !self.amountSelectable;
    [self.amountChevron mas_makeConstraints:^(MASConstraintMaker *make) { make.width.height.mas_equalTo(14); }];

    UIStackView *amountStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.amountLabel, self.amountChevron]];
    amountStack.axis = UILayoutConstraintAxisHorizontal;
    amountStack.spacing = 4;
    amountStack.alignment = UIStackViewAlignmentCenter;

    UIControl *amountTap = [[UIControl alloc] init];
    [amountTap addTarget:self action:@selector(LZ_tapAmount) forControlEvents:UIControlEventTouchUpInside];
    amountTap.enabled = self.amountSelectable;
    [amountTap addSubview:amountStack];
    [amountStack mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(amountTap); }];

    UIStackView *header = [[UIStackView alloc] initWithArrangedSubviews:@[iconTile, nameLabel, amountTap]];
    header.axis = UILayoutConstraintAxisHorizontal;
    header.alignment = UIStackViewAlignmentCenter;
    header.spacing = 10;
    [nameLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

    BOOL showsAmountGrid = self.amountOptions.count > 1;
    amountTap.hidden = showsAmountGrid;

    UIImageView *statusBar = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:@"lz_order_tbw"]];
    statusBar.contentMode = UIViewContentModeScaleAspectFit;

    UIView *amountSection = showsAmountGrid ? [self LZ_buildAmountSelectionSection] : nil;
    UIView *termRow = [self LZ_tappableTermRowWithTerm:term];

    UIStackView *detailsStack = [[UIStackView alloc] init];
    detailsStack.axis = UILayoutConstraintAxisVertical;
    detailsStack.spacing = 0;
    NSArray *rows = @[
        @[@"Service fee", serviceFee ?: @"—", @"This is the fee charged by the financial institution for providing loan services."],
        @[@"Interest", interest ?: @"—", @"Calculated based on your loan amount, loan term, and the interest rate of the current product."],
        @[@"Amount received", amountReceived ?: @"—", @"The actual amount you receive is calculated by deducting the service fee from the loan amount."],
        @[@"Date of application", applicationDate ?: @"—", @""],
        @[@"Due date", dueDate ?: @"—", @""],
    ];
    for (NSInteger i = 0; i < (NSInteger)rows.count; i++) {
        NSArray *item = rows[i];
        NSString *tip = item[2];
        [detailsStack addArrangedSubview:[self LZ_detailRowWithTitle:item[0] value:item[1] tipMessage:tip.length > 0 ? tip : nil]];
        if (i < (NSInteger)rows.count - 1) [detailsStack addArrangedSubview:[self LZ_separator]];
    }

    LoanZen_OrderDetailBankCardView *bankCardView = [[LoanZen_OrderDetailBankCardView alloc] init];
    [bankCardView LZ_configureWithMaskedCardNumber:maskedCardNumber];

    NSMutableArray *stackItems = [NSMutableArray arrayWithObjects:header, statusBar, nil];
    if (amountSection) [stackItems addObject:amountSection];
    [stackItems addObjectsFromArray:@[termRow, detailsStack, bankCardView]];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:stackItems];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;
    [card addSubview:stack];
    [stack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(card).insets(UIEdgeInsetsMake(16, 16, 16, 16));
    }];
    [statusBar mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(34); }];
    if (amountSection) {
        [amountSection mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo([self LZ_amountGridHeightForCount:self.amountOptions.count]);
        }];
    }
    [termRow mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(34); }];
    return card;
}

- (CGFloat)LZ_amountButtonWidth {
    CGFloat cardWidth = UIScreen.mainScreen.bounds.size.width - 16 * 2 - 32;
    return floor((cardWidth - 10.0 * 2) / 3.0);
}

- (CGFloat)LZ_amountGridHeightForCount:(NSInteger)count {
    if (count <= 0) return 0;
    NSInteger columns = 3;
    NSInteger rows = MAX(1, (NSInteger)ceil((double)count / (double)columns));
    return 18 + 12 + rows * 36.0 + (rows - 1) * 10.0;
}

- (UIView *)LZ_buildAmountSelectionSection {
    UIView *section = [[UIView alloc] init];

    UILabel *tips = [[UILabel alloc] init];
    tips.text = @"Tips: Select loan amount first";
    tips.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    tips.textColor = [LoanZen_Color kycFormLabel];
    [section addSubview:tips];

    UIView *container = [[UIView alloc] init];
    [section addSubview:container];

    NSInteger columns = 3;
    CGFloat btnW = [self LZ_amountButtonWidth];
    for (NSInteger index = 0; index < (NSInteger)self.amountOptions.count; index++) {
        NSString *title = self.amountOptions[index];
        BOOL selected = index == self.selectedAmountIndex;
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = kLZAmountButtonBaseTag + index;
        [btn setTitle:title forState:UIControlStateNormal];
        [LoanZen_ColorUtils LZ_styleLoanAmountChipButton:btn selected:selected cornerRadius:8];
        [btn addTarget:self action:@selector(LZ_tapAmountChip:) forControlEvents:UIControlEventTouchUpInside];
        [container addSubview:btn];
        NSInteger row = index / columns;
        NSInteger col = index % columns;
        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(container).offset(col * (btnW + 10.0));
            make.top.equalTo(container).offset(row * (36.0 + 10.0));
            make.width.mas_equalTo(btnW);
            make.height.mas_equalTo(36.0);
        }];
    }

    [tips mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.equalTo(section);
    }];
    [container mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(section);
        make.top.equalTo(tips.mas_bottom).offset(12);
        NSInteger rows = MAX(1, (NSInteger)ceil((double)self.amountOptions.count / 3.0));
        make.height.mas_equalTo(rows * 36.0 + (rows - 1) * 10.0);
    }];
    return section;
}

- (UIView *)LZ_tappableTermRowWithTerm:(NSString *)term {
    UILabel *title = [[UILabel alloc] init];
    title.text = self.termSelectable ? @"Select the loan term" : @"Loan term";
    title.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    title.textColor = [LoanZen_Color kycFormLabel];

    self.termValueLabel = [[UILabel alloc] init];
    self.termValueLabel.text = term.length > 0 ? term : @"—";
    self.termValueLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    self.termValueLabel.textColor = [LoanZen_Color accent];

    self.termChevron = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:@"lz_loan_jexl"]];
    self.termChevron.contentMode = UIViewContentModeScaleAspectFit;
    self.termChevron.hidden = !self.termSelectable;
    [self.termChevron mas_makeConstraints:^(MASConstraintMaker *make) { make.width.height.mas_equalTo(14); }];

    UIView *pill = [[UIView alloc] init];
    pill.layer.cornerRadius = 17;
    pill.clipsToBounds = YES;
    [LoanZen_ColorUtils LZ_applyTermSelectionPillStyleToView:pill];
    [pill addSubview:self.termValueLabel];

    UIControl *tap = [[UIControl alloc] init];
    tap.enabled = self.termSelectable;
    [tap addTarget:self action:@selector(LZ_tapTerm) forControlEvents:UIControlEventTouchUpInside];
    [tap addSubview:title];
    [tap addSubview:pill];
    [tap addSubview:self.termChevron];
    [title mas_makeConstraints:^(MASConstraintMaker *make) { make.left.centerY.equalTo(tap); }];
    [self.termChevron mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.centerY.equalTo(tap);
        make.width.height.mas_equalTo(self.termSelectable ? 14 : 0);
    }];
    [pill mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.termChevron.mas_left).offset(-6);
        make.centerY.equalTo(tap);
        make.height.mas_equalTo(34);
        make.left.greaterThanOrEqualTo(title.mas_right).offset(8);
    }];
    [self.termValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(pill).offset(14);
        make.right.equalTo(pill).offset(-14);
        make.centerY.equalTo(pill);
    }];
    return tap;
}

- (UIView *)LZ_buildScheduleCard {
    UIView *card = [self LZ_glassCard];
    UILabel *title = [[UILabel alloc] init];
    title.text = @"Repayment Schedule";
    title.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    title.textColor = [LoanZen_Color primaryText];
    self.scheduleToggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.scheduleToggleButton setImage:[LoanZen_Asset imageNamed:@"lz_loan_sq"] forState:UIControlStateNormal];
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
    [self.scheduleToggleButton mas_makeConstraints:^(MASConstraintMaker *make) { make.width.height.mas_equalTo(20); }];
    return card;
}

- (void)LZ_rebuildScheduleRows {
    for (UIView *v in self.scheduleRowsStack.arrangedSubviews) {
        [self.scheduleRowsStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    [self.scheduleRowsStack addArrangedSubview:[self LZ_scheduleHeaderRow]];
    NSArray *items = self.scheduleItems.count > 0 ? self.scheduleItems : @[@{LZAPIFieldDueDate: @"—", LZAPIFieldAmount: @"—"}];
    NSArray *visible = (!self.isRepaymentExpanded && items.count > 1) ? @[items.firstObject] : items;
    for (NSDictionary *item in visible) {
        [self.scheduleRowsStack addArrangedSubview:[self LZ_scheduleDataRowWithDueDate:item[LZAPIFieldDueDate] amountDue:item[LZAPIFieldAmount]]];
    }
    self.scheduleToggleButton.hidden = items.count <= 1;
    [self.scheduleToggleButton setImage:[LoanZen_Asset imageNamed:self.isRepaymentExpanded ? @"lz_loan_sq" : @"lz_loan_zk"] forState:UIControlStateNormal];
}

- (UIView *)LZ_detailRowWithTitle:(NSString *)title value:(NSString *)value tipMessage:(NSString *)tipMessage {
    UIView *container = [[UIView alloc] init];
    UIStackView *leftStack = [[UIStackView alloc] init];
    leftStack.axis = UILayoutConstraintAxisHorizontal;
    leftStack.spacing = 4;
    UILabel *left = [[UILabel alloc] init];
    left.text = title;
    left.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    left.textColor = [LoanZen_Color kycFormLabel];
    [leftStack addArrangedSubview:left];
    if (tipMessage.length > 0) {
        UIImageView *info = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:@"lz_loan_sm"]];
        info.userInteractionEnabled = YES;
        info.accessibilityHint = tipMessage;
        [info addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(LZ_tapFieldTip:)]];
        [info mas_makeConstraints:^(MASConstraintMaker *make) { make.width.height.mas_equalTo(14); }];
        [leftStack addArrangedSubview:info];
    }
    UILabel *right = [[UILabel alloc] init];
    right.text = value;
    right.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    right.textColor = [LoanZen_Color primaryText];
    right.textAlignment = NSTextAlignmentRight;
    [container addSubview:leftStack];
    [container addSubview:right];
    [container mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(28); }];
    [leftStack mas_makeConstraints:^(MASConstraintMaker *make) { make.left.centerY.equalTo(container); }];
    [right mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.centerY.equalTo(container);
        make.left.greaterThanOrEqualTo(leftStack.mas_right).offset(8);
    }];
    return container;
}

- (void)LZ_tapFieldTip:(UITapGestureRecognizer *)gesture {
    NSString *message = gesture.view.accessibilityHint;
    if (message.length == 0) return;
    UIView *host = self.window ?: self;
    [LoanZen_PopupHelper LZ_showTapToDismissMessage:message onView:host];
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

#pragma mark - Legacy API

- (void)LZ_configureWithProductName:(NSString *)productName amount:(NSString *)amount term:(NSString *)term scheduleItems:(NSArray<NSDictionary *> *)scheduleItems {
    [self LZ_configureWithProductName:productName
                               amount:amount
                                 term:term
                       amountReceived:@"—"
                            serviceFee:@"—"
                              interest:@"—"
                       applicationDate:@"—"
                               dueDate:@"—"
                         scheduleItems:scheduleItems
                      maskedCardNumber:@"—"
                      amountSelectable:YES
                        termSelectable:YES
                         amountOptions:@[]
                   selectedAmountIndex:0];
}

#pragma mark - Actions

- (void)LZ_tapAmountChip:(UIButton *)sender {
    NSInteger index = sender.tag - kLZAmountButtonBaseTag;
    if (index < 0 || index >= (NSInteger)self.amountOptions.count) return;
    if ([self.delegate respondsToSelector:@selector(LZ_withdrawalRootView:didSelectAmountAtIndex:)]) {
        [self.delegate LZ_withdrawalRootView:self didSelectAmountAtIndex:index];
    }
}

- (void)LZ_tapAmount {
    if ([self.delegate respondsToSelector:@selector(LZ_withdrawalRootViewDidTapAmount:)]) {
        [self.delegate LZ_withdrawalRootViewDidTapAmount:self];
    }
}

- (void)LZ_tapTerm {
    if ([self.delegate respondsToSelector:@selector(LZ_withdrawalRootViewDidTapTerm:)]) {
        [self.delegate LZ_withdrawalRootViewDidTapTerm:self];
    }
}

- (void)LZ_tapWithdraw {
    if ([self.delegate respondsToSelector:@selector(LZ_withdrawalRootViewDidTapWithdraw:)]) {
        [self.delegate LZ_withdrawalRootViewDidTapWithdraw:self];
    }
}

- (void)LZ_toggleSchedule {
    self.isRepaymentExpanded = !self.isRepaymentExpanded;
    [self LZ_rebuildScheduleRows];
}

- (void)LZ_updateDisplayedAmount:(NSString *)amount term:(NSString *)term {
    self.amountLabel.text = amount.length > 0 ? amount : @"—";
    self.termValueLabel.text = term.length > 0 ? term : @"—";
}

@end
