#import "LoanZen_EMIRootView.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_ColorUtils.h"
@import Masonry;

static const double kLZEMIAmountMin = 1;
static const double kLZEMIAmountMax = 10000000;
static const NSInteger kLZEMIYearsMin = 1;
static const NSInteger kLZEMIYearsMax = 25;
static const double kLZEMIRateMin = 1;
static const double kLZEMIRateMax = 22;

@interface LoanZen_EMIRootView ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *pageTitleLabel;
@property (nonatomic, strong) UITextField *amountField;
@property (nonatomic, strong) UITextField *yearsField;
@property (nonatomic, strong) UITextField *rateField;
@property (nonatomic, strong) UISlider *yearsSlider;
@property (nonatomic, strong) UISlider *rateSlider;
@end

@implementation LoanZen_EMIRootView

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

    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];

    self.pageTitleLabel = [[UILabel alloc] init];
    self.pageTitleLabel.text = @"EMI Calculator";
    self.pageTitleLabel.font = [LoanZen_Font title1];
    self.pageTitleLabel.textColor = [LoanZen_Color primaryText];
    self.pageTitleLabel.textAlignment = NSTextAlignmentRight;
    [self.contentView addSubview:self.pageTitleLabel];

    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [LoanZen_Color card];
    card.layer.cornerRadius = 20;
    card.layer.borderWidth = 1;
    card.layer.borderColor = [LoanZen_Color separator].CGColor;
    card.clipsToBounds = YES;

    self.amountField = [self LZ_makeField:@"50000" placeholder:@"50,000" keyboard:UIKeyboardTypeNumberPad];
    self.yearsField = [self LZ_makeField:@"5" placeholder:@"e.g. 5" keyboard:UIKeyboardTypeNumberPad];
    self.rateField = [self LZ_makeField:@"3" placeholder:@"1~22" keyboard:UIKeyboardTypeDecimalPad];

    self.yearsSlider = [self LZ_makeSliderMin:kLZEMIYearsMin max:kLZEMIYearsMax value:5];
    self.rateSlider = [self LZ_makeSliderMin:kLZEMIRateMin max:kLZEMIRateMax value:3];

    [self.yearsSlider addTarget:self action:@selector(LZ_yearsSliderChanged:) forControlEvents:UIControlEventValueChanged];
    [self.rateSlider addTarget:self action:@selector(LZ_rateSliderChanged:) forControlEvents:UIControlEventValueChanged];

    [self.amountField addTarget:self action:@selector(LZ_amountFieldEditingChanged) forControlEvents:UIControlEventEditingChanged];
    [self.yearsField addTarget:self action:@selector(LZ_yearsFieldEditingChanged) forControlEvents:UIControlEventEditingChanged];
    [self.rateField addTarget:self action:@selector(LZ_rateFieldEditingChanged) forControlEvents:UIControlEventEditingChanged];
    [self.amountField addTarget:self action:@selector(LZ_amountFieldDidEnd) forControlEvents:UIControlEventEditingDidEnd];
    [self.yearsField addTarget:self action:@selector(LZ_yearsFieldDidEnd) forControlEvents:UIControlEventEditingDidEnd];
    [self.rateField addTarget:self action:@selector(LZ_rateFieldDidEnd) forControlEvents:UIControlEventEditingDidEnd];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[
        [self LZ_blockWithTitle:@"Total loan amount" hint:@"(1~10,000,000₱)" field:self.amountField slider:nil],
        [self LZ_blockWithTitle:@"Duration" hint:@"(1~25 Year)" field:self.yearsField slider:self.yearsSlider],
        [self LZ_blockWithTitle:@"Interest rate" hint:@"(1~22%)" field:self.rateField slider:self.rateSlider],
    ]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 20;
    [card addSubview:stack];
    [stack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(card).insets(UIEdgeInsetsMake(16, 16, 16, 16));
    }];

    UIButton *submit = [UIButton buttonWithType:UIButtonTypeCustom];
    submit.backgroundColor = [LoanZen_Color accent];
    submit.layer.cornerRadius = 12;
    [submit setTitle:@"Submit" forState:UIControlStateNormal];
    [submit setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    submit.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [submit addTarget:self action:@selector(LZ_tapSubmit) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *outer = [[UIStackView alloc] initWithArrangedSubviews:@[card, submit]];
    outer.axis = UILayoutConstraintAxisVertical;
    outer.spacing = 16;
    [self.contentView addSubview:outer];

    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];
    [self.pageTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(8);
        make.right.equalTo(self.contentView).offset(-LZ_SizePageInset);
        make.left.greaterThanOrEqualTo(self.contentView).offset(LZ_SizePageInset);
    }];
    [outer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.pageTitleLabel.mas_bottom).offset(20);
        make.left.right.equalTo(self.contentView).inset(LZ_SizePageInset);
        make.bottom.equalTo(self.contentView).offset(-24);
    }];
    [submit mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(LZ_SizePrimaryButtonHeight);
    }];
}

- (UITextField *)LZ_makeField:(NSString *)text placeholder:(NSString *)placeholder keyboard:(UIKeyboardType)keyboard {
    UITextField *field = [[UITextField alloc] init];
    field.text = text;
    field.placeholder = placeholder;
    field.keyboardType = keyboard;
    field.font = [LoanZen_Font body];
    field.backgroundColor = [LoanZen_Color background];
    field.textColor = [LoanZen_Color primaryText];
    field.layer.cornerRadius = 8;
    field.layer.masksToBounds = YES;
    field.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 48)];
    field.leftViewMode = UITextFieldViewModeAlways;
    field.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 48)];
    field.rightViewMode = UITextFieldViewModeAlways;
    [field mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(48); }];
    return field;
}

- (UISlider *)LZ_makeSliderMin:(float)min max:(float)max value:(float)value {
    UISlider *slider = [[UISlider alloc] init];
    slider.minimumValue = min;
    slider.maximumValue = max;
    slider.value = value;
    slider.minimumTrackTintColor = [LoanZen_Color accent];
    slider.maximumTrackTintColor = [LoanZen_ColorUtils LZ_inputBackground];
    slider.thumbTintColor = UIColor.whiteColor;
    [slider mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(32); }];
    return slider;
}

- (UIView *)LZ_blockWithTitle:(NSString *)title hint:(NSString *)hint field:(UITextField *)field slider:(UISlider *)slider {
    UILabel *left = [[UILabel alloc] init];
    left.text = title;
    left.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    left.textColor = [LoanZen_Color primaryText];

    UILabel *right = [[UILabel alloc] init];
    right.text = hint;
    right.font = [LoanZen_Font caption];
    right.textColor = [LoanZen_Color secondaryText];
    [right setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    UIStackView *titleRow = [[UIStackView alloc] initWithArrangedSubviews:@[left, right]];
    titleRow.axis = UILayoutConstraintAxisHorizontal;
    titleRow.alignment = UIStackViewAlignmentCenter;
    titleRow.distribution = UIStackViewDistributionEqualSpacing;

    NSMutableArray *items = [NSMutableArray arrayWithObjects:titleRow, field, nil];
    if (slider) [items addObject:slider];
    UIStackView *col = [[UIStackView alloc] initWithArrangedSubviews:items];
    col.axis = UILayoutConstraintAxisVertical;
    col.spacing = 8;
    return col;
}

#pragma mark - Render

- (void)LZ_renderAmount:(double)amount years:(NSInteger)years rate:(double)rate {
    self.amountField.text = [self LZ_stringForAmount:amount];
    self.yearsField.text = [NSString stringWithFormat:@"%ld", (long)years];
    self.rateField.text = [self LZ_stringForRate:rate];
    self.yearsSlider.value = years;
    self.rateSlider.value = rate;
}

#pragma mark - Parsing / Formatting

- (NSString *)LZ_trimmedRawText:(NSString *)text {
    NSString *safe = text.length > 0 ? text : @"";
    return [safe stringByReplacingOccurrencesOfString:@"," withString:@""];
}

- (NSString *)LZ_stringForAmount:(double)amount {
    return [NSString stringWithFormat:@"%.0f", amount];
}

- (NSString *)LZ_stringForRate:(double)rate {
    if (fabs(rate - round(rate)) < 0.001) {
        return [NSString stringWithFormat:@"%.0f", rate];
    }
    return [NSString stringWithFormat:@"%.1f", rate];
}

- (double)LZ_clampedAmountFromRaw:(NSString *)raw defaultValue:(double)defaultValue {
    NSString *trimmed = [[raw stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] copy];
    double value = defaultValue;
    if (trimmed.length > 0) {
        value = trimmed.doubleValue;
    }
    return MIN(MAX(value, kLZEMIAmountMin), kLZEMIAmountMax);
}

- (NSInteger)LZ_clampedYearsFromRaw:(NSString *)raw defaultValue:(NSInteger)defaultValue {
    NSString *trimmed = [[raw stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] copy];
    NSInteger value = defaultValue;
    if (trimmed.length > 0) {
        value = trimmed.integerValue;
    }
    return MIN(MAX(value, kLZEMIYearsMin), kLZEMIYearsMax);
}

- (double)LZ_clampedRateFromRaw:(NSString *)raw defaultValue:(double)defaultValue {
    NSString *trimmed = [[raw stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] copy];
    double value = defaultValue;
    if (trimmed.length > 0) {
        value = trimmed.doubleValue;
    }
    return MIN(MAX(value, kLZEMIRateMin), kLZEMIRateMax);
}

#pragma mark - Normalization

- (void)LZ_normalizeAmountField {
    double value = [self LZ_clampedAmountFromRaw:[self LZ_trimmedRawText:self.amountField.text] defaultValue:kLZEMIAmountMin];
    self.amountField.text = [self LZ_stringForAmount:value];
}

- (void)LZ_normalizeYearsField {
    NSInteger value = [self LZ_clampedYearsFromRaw:self.yearsField.text defaultValue:kLZEMIYearsMin];
    self.yearsField.text = [NSString stringWithFormat:@"%ld", (long)value];
    self.yearsSlider.value = value;
}

- (void)LZ_normalizeRateField {
    double value = [self LZ_clampedRateFromRaw:[self LZ_trimmedRawText:self.rateField.text] defaultValue:kLZEMIRateMin];
    self.rateField.text = [self LZ_stringForRate:value];
    self.rateSlider.value = value;
}

- (void)LZ_normalizeAllFields {
    [self LZ_normalizeAmountField];
    [self LZ_normalizeYearsField];
    [self LZ_normalizeRateField];
}

#pragma mark - Events

- (void)LZ_yearsSliderChanged:(UISlider *)slider {
    self.yearsField.text = [NSString stringWithFormat:@"%d", (int)roundf(slider.value)];
    [self LZ_notifyDelegate];
}

- (void)LZ_rateSliderChanged:(UISlider *)slider {
    self.rateField.text = [self LZ_stringForRate:slider.value];
    [self LZ_notifyDelegate];
}

- (void)LZ_amountFieldEditingChanged {
    [self LZ_notifyDelegate];
}

- (void)LZ_yearsFieldEditingChanged {
    NSString *raw = [self.yearsField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (raw.length > 0) {
        NSInteger value = MIN(MAX(raw.integerValue, kLZEMIYearsMin), kLZEMIYearsMax);
        self.yearsSlider.value = value;
    }
    [self LZ_notifyDelegate];
}

- (void)LZ_rateFieldEditingChanged {
    NSString *raw = [[self LZ_trimmedRawText:self.rateField.text] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (raw.length > 0) {
        double value = MIN(MAX(raw.doubleValue, kLZEMIRateMin), kLZEMIRateMax);
        self.rateSlider.value = value;
    }
    [self LZ_notifyDelegate];
}

- (void)LZ_amountFieldDidEnd {
    [self LZ_normalizeAmountField];
    [self LZ_notifyDelegate];
}

- (void)LZ_yearsFieldDidEnd {
    [self LZ_normalizeYearsField];
    [self LZ_notifyDelegate];
}

- (void)LZ_rateFieldDidEnd {
    [self LZ_normalizeRateField];
    [self LZ_notifyDelegate];
}

- (void)LZ_notifyDelegate {
    if ([self.delegate respondsToSelector:@selector(LZ_emiRootView:didChangeAmount:years:rate:)]) {
        double amount = [self LZ_clampedAmountFromRaw:[self LZ_trimmedRawText:self.amountField.text] defaultValue:kLZEMIAmountMin];
        NSInteger years = [self LZ_clampedYearsFromRaw:self.yearsField.text defaultValue:kLZEMIYearsMin];
        double rate = [self LZ_clampedRateFromRaw:[self LZ_trimmedRawText:self.rateField.text] defaultValue:kLZEMIRateMin];
        [self.delegate LZ_emiRootView:self didChangeAmount:amount years:years rate:rate];
    }
}

- (void)LZ_tapSubmit {
    [self LZ_normalizeAllFields];
    [self LZ_notifyDelegate];
    if ([self.delegate respondsToSelector:@selector(LZ_emiRootViewDidSubmit:)]) {
        [self.delegate LZ_emiRootViewDidSubmit:self];
    }
}

@end
