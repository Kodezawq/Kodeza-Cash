#import "LoanZen_PenRadioPickerViewController.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_ColorUtils.h"
@import Masonry;

static NSString * const LZ_PickerGradientLayerName = @"LZ_pickerGradientLayer";

@interface LoanZen_PenRadioPickerViewController ()
@property (nonatomic, copy) NSString *pickerTitle;
@property (nonatomic, copy) NSArray<NSString *> *options;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, copy) void (^onConfirm)(NSInteger index);

@property (nonatomic, strong) UIView *dimView;
@property (nonatomic, strong) UIView *shell;
@property (nonatomic, strong) UIView *titleAccentLine;
@property (nonatomic, strong) UIScrollView *optionsScrollView;
@property (nonatomic, strong) UIStackView *optionsStack;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *optionRows;
@end

@implementation LoanZen_PenRadioPickerViewController

+ (void)LZ_presentFrom:(UIViewController *)host title:(NSString *)title options:(NSArray<NSString *> *)options selectedIndex:(NSInteger)selectedIndex onConfirm:(void (^)(NSInteger))onConfirm {
    LoanZen_PenRadioPickerViewController *vc = [[LoanZen_PenRadioPickerViewController alloc] init];
    vc.pickerTitle = title ?: @"";
    vc.options = options ?: @[];
    vc.onConfirm = onConfirm;
    if (vc.options.count == 0) {
        vc.selectedIndex = 0;
    } else if (selectedIndex < 0 || selectedIndex >= (NSInteger)vc.options.count) {
        vc.selectedIndex = 0;
    } else {
        vc.selectedIndex = selectedIndex;
    }
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [host presentViewController:vc animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    self.optionRows = [NSMutableArray array];

    self.dimView = [[UIView alloc] init];
    self.dimView.backgroundColor = [LoanZen_ColorUtils LZ_overlayDim73];
    [self.view addSubview:self.dimView];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(LZ_cancel)];
    [self.dimView addGestureRecognizer:tap];

    self.shell = [[UIView alloc] init];
    self.shell.backgroundColor = [LoanZen_ColorUtils LZ_modalCardBackground];
    self.shell.layer.cornerRadius = 24;
    self.shell.clipsToBounds = NO;
    self.shell.layer.borderWidth = 1;
    self.shell.layer.borderColor = [LoanZen_ColorUtils LZ_modalCardBorder].CGColor;
    self.shell.layer.shadowColor = [LoanZen_ColorUtils LZ_brandGradientStart].CGColor;
    self.shell.layer.shadowOpacity = 0.28;
    self.shell.layer.shadowRadius = 18;
    self.shell.layer.shadowOffset = CGSizeMake(0, 8);
    [self.view addSubview:self.shell];

    UIView *headerIconWrap = [[UIView alloc] init];
    headerIconWrap.backgroundColor = [LoanZen_ColorUtils LZ_pickerOptionBackground];
    headerIconWrap.layer.cornerRadius = 10;
    headerIconWrap.layer.borderWidth = 1;
    headerIconWrap.layer.borderColor = [LoanZen_ColorUtils LZ_pickerOptionBorder].CGColor;
    UIImage *icon = [LoanZen_Asset imageNamed:@"lz_tk_xz_u"];
    if (icon) icon = [icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *headerIcon = [[UIImageView alloc] initWithImage:icon ?: [UIImage systemImageNamed:@"list.bullet"]];
    headerIcon.tintColor = [LoanZen_ColorUtils LZ_brandGradientStart];
    headerIcon.contentMode = UIViewContentModeScaleAspectFit;
    [headerIconWrap addSubview:headerIcon];

    UILabel *headerTitle = [[UILabel alloc] init];
    headerTitle.text = self.pickerTitle;
    headerTitle.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    headerTitle.textColor = [LoanZen_ColorUtils LZ_textPrimary];
    headerTitle.numberOfLines = 0;

    self.titleAccentLine = [[UIView alloc] init];
    self.titleAccentLine.layer.cornerRadius = 1.5;
    self.titleAccentLine.clipsToBounds = YES;

    self.optionsScrollView = [[UIScrollView alloc] init];
    self.optionsScrollView.showsVerticalScrollIndicator = NO;
    self.optionsScrollView.alwaysBounceVertical = YES;

    self.optionsStack = [[UIStackView alloc] init];
    self.optionsStack.axis = UILayoutConstraintAxisVertical;
    self.optionsStack.spacing = 10;
    [self.optionsScrollView addSubview:self.optionsStack];

    if (self.options.count == 0) {
        UILabel *empty = [[UILabel alloc] init];
        empty.text = @"No options";
        empty.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        empty.textColor = [LoanZen_ColorUtils LZ_textSecondary];
        empty.textAlignment = NSTextAlignmentCenter;
        [self.optionsStack addArrangedSubview:empty];
        [empty mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(52); }];
    } else {
        [self.options enumerateObjectsUsingBlock:^(NSString *title, NSUInteger idx, BOOL *stop) {
            [self.optionsStack addArrangedSubview:[self LZ_makeOptionRow:title index:idx]];
        }];
    }

    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    self.cancelButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [self.cancelButton setTitleColor:[LoanZen_ColorUtils LZ_textSecondary] forState:UIControlStateNormal];
    self.cancelButton.backgroundColor = UIColor.clearColor;
    self.cancelButton.layer.cornerRadius = 12;
    self.cancelButton.layer.borderWidth = 1;
    self.cancelButton.layer.borderColor = [LoanZen_ColorUtils LZ_glassBorder10].CGColor;
    [self.cancelButton addTarget:self action:@selector(LZ_cancel) forControlEvents:UIControlEventTouchUpInside];

    self.confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.confirmButton setTitle:@"Confirm" forState:UIControlStateNormal];
    self.confirmButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.confirmButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [LoanZen_ColorUtils LZ_brandAccent];
    self.confirmButton.layer.cornerRadius = 12;
    self.confirmButton.clipsToBounds = YES;
    self.confirmButton.layer.shadowColor = [LoanZen_ColorUtils LZ_brandAccent].CGColor;
    self.confirmButton.layer.shadowOpacity = 0.42;
    self.confirmButton.layer.shadowRadius = 10;
    self.confirmButton.layer.shadowOffset = CGSizeMake(0, 5);
    self.confirmButton.layer.masksToBounds = NO;
    [self.confirmButton addTarget:self action:@selector(LZ_confirm) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *buttonRow = [[UIStackView alloc] initWithArrangedSubviews:@[self.cancelButton, self.confirmButton]];
    buttonRow.axis = UILayoutConstraintAxisHorizontal;
    buttonRow.spacing = 12;
    buttonRow.distribution = UIStackViewDistributionFill;
    [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) { make.width.mas_equalTo(110); }];

    UIStackView *contentStack = [[UIStackView alloc] initWithArrangedSubviews:@[headerIconWrap, headerTitle, self.titleAccentLine, self.optionsScrollView, buttonRow]];
    contentStack.axis = UILayoutConstraintAxisVertical;
    contentStack.spacing = 12;
    contentStack.alignment = UIStackViewAlignmentFill;
    contentStack.layoutMargins = UIEdgeInsetsMake(20, 20, 20, 20);
    contentStack.layoutMarginsRelativeArrangement = YES;
    contentStack.alignment = UIStackViewAlignmentLeading;
    [self.shell addSubview:contentStack];

    CGFloat listHeight = MIN(MAX((CGFloat)self.options.count * 62.f, 52.f), 260.f);

    [self.dimView mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.view); }];
    [self.shell mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.left.equalTo(self.view).offset(24);
        make.right.equalTo(self.view).offset(-24);
    }];
    [contentStack mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.shell); }];
    [buttonRow mas_makeConstraints:^(MASConstraintMaker *make) { make.width.equalTo(contentStack).offset(-40); }];
    [headerIconWrap mas_makeConstraints:^(MASConstraintMaker *make) { make.width.height.mas_equalTo(36); }];
    [headerIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(headerIconWrap);
        make.width.height.mas_equalTo(18);
    }];
    [headerTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(contentStack).offset(-40);
    }];
    [self.optionsScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(listHeight);
        make.width.equalTo(contentStack).offset(-40);
    }];
    [self.titleAccentLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(3);
        make.width.mas_equalTo(56);
    }];
    [self.optionsStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.optionsScrollView);
        make.width.equalTo(self.optionsScrollView);
    }];
    [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(48); }];
    [self.confirmButton mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(48); }];

    [self LZ_refreshSelectionAnimated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self LZ_applyConfirmButtonGradient];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self LZ_applyGradientToView:self.titleAccentLine layerName:@"LZ_pickerTitleAccent" colors:@[[LoanZen_ColorUtils LZ_brandGradientStart], [[LoanZen_ColorUtils LZ_brandGradientEnd] colorWithAlphaComponent:0]] cornerRadius:1.5];
    [self LZ_applyConfirmButtonGradient];
}

- (void)LZ_applyConfirmButtonGradient {
    if (CGRectIsEmpty(self.confirmButton.bounds)) return;
    [self LZ_applyGradientToView:self.confirmButton
                       layerName:LZ_PickerGradientLayerName
                          colors:[LoanZen_ColorUtils LZ_brandGradientColors]
                    cornerRadius:12];
}

- (void)LZ_applyGradientToView:(UIView *)view layerName:(NSString *)name colors:(NSArray<UIColor *> *)colors cornerRadius:(CGFloat)radius {
    if (CGRectIsEmpty(view.bounds)) return;
    for (CALayer *layer in [view.layer.sublayers copy]) {
        if ([layer.name isEqualToString:name]) [layer removeFromSuperlayer];
    }
    CAGradientLayer *gradient = [LoanZen_ColorUtils LZ_horizontalGradientLayerWithColors:colors frame:view.bounds cornerRadius:radius];
    gradient.name = name;
    [view.layer insertSublayer:gradient atIndex:0];
}

- (UIView *)LZ_makeOptionRow:(NSString *)title index:(NSInteger)index {
    UIView *card = [[UIView alloc] init];
    card.layer.cornerRadius = 12;
    card.clipsToBounds = NO;

    UIControl *control = [[UIControl alloc] init];
    control.tag = index;
    [control addTarget:self action:@selector(LZ_optionTap:) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:control];

    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    label.textColor = [LoanZen_ColorUtils LZ_textSecondary];
    label.userInteractionEnabled = NO;
    [card addSubview:label];

    UIView *radio = [[UIView alloc] init];
    radio.userInteractionEnabled = NO;
    radio.layer.cornerRadius = 10;
    radio.layer.borderWidth = 1.5;
    radio.layer.borderColor = [LoanZen_ColorUtils LZ_textSecondary].CGColor;
    radio.backgroundColor = UIColor.clearColor;
    [card addSubview:radio];

    UIView *radioDot = [[UIView alloc] init];
    radioDot.backgroundColor = UIColor.whiteColor;
    radioDot.layer.cornerRadius = 3;
    radioDot.hidden = YES;
    [radio addSubview:radioDot];

    [control mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(card); }];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(card).offset(16);
        make.centerY.equalTo(card);
        make.right.lessThanOrEqualTo(radio.mas_left).offset(-12);
    }];
    [radio mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(card).offset(-16);
        make.centerY.equalTo(card);
        make.width.height.mas_equalTo(20);
    }];
    [radioDot mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(radio);
        make.width.height.mas_equalTo(6);
    }];
    [card mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(52); }];

    [self.optionRows addObject:@{@"currencySymbol": card, @"label": label, @"radio": radio, @"radioDot": radioDot}];
    return card;
}

- (void)LZ_optionTap:(UIControl *)sender {
    self.selectedIndex = sender.tag;
    [self LZ_refreshSelectionAnimated:YES];
}

- (void)LZ_refreshSelectionAnimated:(BOOL)animated {
    void (^changes)(void) = ^{
        [self.optionRows enumerateObjectsUsingBlock:^(NSDictionary *row, NSUInteger idx, BOOL *stop) {
            UIView *card = row[@"currencySymbol"];
            UILabel *label = row[@"label"];
            UIView *radio = row[@"radio"];
            UIView *radioDot = row[@"radioDot"];
            BOOL on = (NSInteger)idx == self.selectedIndex;

            card.backgroundColor = [LoanZen_ColorUtils LZ_pickerOptionBackground];
            card.layer.borderWidth = on ? 1.5 : 0;
            card.layer.borderColor = on ? [LoanZen_ColorUtils LZ_brandGradientStart].CGColor : UIColor.clearColor.CGColor;
            card.layer.shadowColor = on ? [LoanZen_ColorUtils LZ_brandAccent].CGColor : UIColor.clearColor.CGColor;
            card.layer.shadowOpacity = on ? 0.35 : 0;
            card.layer.shadowRadius = on ? 8 : 0;
            card.layer.shadowOffset = CGSizeZero;

            label.textColor = on ? [LoanZen_ColorUtils LZ_textPrimary] : [LoanZen_ColorUtils LZ_textSecondary];
            label.font = [UIFont systemFontOfSize:15 weight:on ? UIFontWeightSemibold : UIFontWeightRegular];

            if (on) {
                radio.backgroundColor = [LoanZen_ColorUtils LZ_brandAccent];
                radio.layer.borderColor = [LoanZen_ColorUtils LZ_brandAccent].CGColor;
                radioDot.hidden = NO;
            } else {
                radio.backgroundColor = UIColor.clearColor;
                radio.layer.borderColor = [LoanZen_ColorUtils LZ_textSecondary].CGColor;
                radioDot.hidden = YES;
            }
        }];
    };
    if (animated) {
        [UIView animateWithDuration:0.2 animations:changes];
    } else {
        changes();
    }
}

- (void)LZ_confirm {
    if (self.options.count == 0) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    NSInteger idx = self.selectedIndex;
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.onConfirm) self.onConfirm(idx);
    }];
}

- (void)LZ_cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
