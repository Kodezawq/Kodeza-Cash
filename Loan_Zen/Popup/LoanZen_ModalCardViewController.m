#import "LoanZen_ModalCardViewController.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_ColorUtils.h"
@import Masonry;

static NSString * const LZ_ModalGradientLayerName = @"LZ_modalGradientLayer";
static NSString * const LZ_ModalAccentLayerName = @"LZ_modalAccentLayer";

@interface LoanZen_ModalCardViewController ()
@property (nonatomic, strong) UIView *dimView;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *titleAccentLine;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIStackView *buttonStack;
@property (nonatomic, strong) NSMutableArray<UIButton *> *gradientButtons;
@end

@implementation LoanZen_ModalCardViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _buttonHeight = 48;
        _buttonCornerRadius = 12;
        _contentCornerRadius = 16;
        _centersHeaderContent = NO;
        _allowsDimTapDismiss = YES;
        _gradientButtons = [NSMutableArray array];
    }
    return self;
}

+ (instancetype)LZ_presentFrom:(UIViewController *)host title:(NSString *)title message:(NSString *)message actions:(NSArray<LoanZen_ModalAction *> *)actions {
    return [self LZ_presentFrom:host title:title message:message iconName:nil actions:actions buttonHeight:48 buttonCornerRadius:12 contentCornerRadius:16];
}

+ (instancetype)LZ_presentFrom:(UIViewController *)host title:(NSString *)title message:(NSString *)message iconName:(NSString *)iconName actions:(NSArray<LoanZen_ModalAction *> *)actions {
    return [self LZ_presentFrom:host title:title message:message iconName:iconName actions:actions buttonHeight:48 buttonCornerRadius:12 contentCornerRadius:16];
}

+ (instancetype)LZ_presentFrom:(UIViewController *)host title:(NSString *)title message:(NSString *)message iconName:(NSString *)iconName actions:(NSArray<LoanZen_ModalAction *> *)actions buttonHeight:(CGFloat)buttonHeight buttonCornerRadius:(CGFloat)buttonCornerRadius contentCornerRadius:(CGFloat)contentCornerRadius {
    LoanZen_ModalCardViewController *modal = [[LoanZen_ModalCardViewController alloc] init];
    modal.modalTitle = title ?: @"";
    modal.message = message ?: @"";
    modal.iconName = iconName;
    modal.actions = actions ?: @[];
    modal.buttonHeight = buttonHeight;
    modal.buttonCornerRadius = buttonCornerRadius;
    modal.contentCornerRadius = contentCornerRadius;
    modal.modalPresentationStyle = UIModalPresentationOverFullScreen;
    modal.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [host presentViewController:modal animated:YES completion:nil];
    return modal;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;

    self.dimView = [[UIView alloc] init];
    self.dimView.backgroundColor = [LoanZen_ColorUtils LZ_overlayDim73];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(LZ_dimTapped)];
    [self.dimView addGestureRecognizer:tap];

    self.cardView = [[UIView alloc] init];
    self.cardView.backgroundColor = [LoanZen_ColorUtils LZ_modalCardBackground];
    self.cardView.layer.cornerRadius = 24;
    self.cardView.clipsToBounds = NO;
    self.cardView.layer.borderWidth = 1;
    self.cardView.layer.borderColor = [LoanZen_ColorUtils LZ_modalCardBorder].CGColor;
    self.cardView.layer.shadowColor = [LoanZen_ColorUtils LZ_brandGradientStart].CGColor;
    self.cardView.layer.shadowOpacity = 0.18;
    self.cardView.layer.shadowRadius = 20;
    self.cardView.layer.shadowOffset = CGSizeMake(0, 10);

    self.iconView = [[UIImageView alloc] init];
    self.iconView.contentMode = UIViewContentModeScaleAspectFit;
    self.iconView.hidden = self.iconName.length == 0;

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    self.titleLabel.textColor = [LoanZen_Color primaryText];
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.text = self.modalTitle;
    self.titleLabel.textAlignment = self.centersHeaderContent ? NSTextAlignmentCenter : NSTextAlignmentLeft;

    self.titleAccentLine = [[UIView alloc] init];
    self.titleAccentLine.layer.cornerRadius = 1.5;
    self.titleAccentLine.clipsToBounds = YES;

    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.text = self.message;
    self.messageLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.messageLabel.textColor = [LoanZen_Color kycFormLabel];
    self.messageLabel.numberOfLines = 0;
    self.messageLabel.textAlignment = self.centersHeaderContent ? NSTextAlignmentCenter : NSTextAlignmentLeft;

    self.buttonStack = [[UIStackView alloc] init];
    self.buttonStack.axis = self.actions.count == 2 ? UILayoutConstraintAxisHorizontal : UILayoutConstraintAxisVertical;
    self.buttonStack.spacing = 12;
    if (self.actions.count == 2) {
        self.buttonStack.distribution = UIStackViewDistributionFillEqually;
    }

    CGFloat actionCornerRadius = self.actions.count == 1 ? MAX(self.buttonCornerRadius, 24) : self.buttonCornerRadius;
    for (LoanZen_ModalAction *action in self.actions) {
        UIButton *btn = [self LZ_makeButtonForAction:action index:[self.actions indexOfObject:action] cornerRadius:actionCornerRadius];
        [self.buttonStack addArrangedSubview:btn];
    }

    UIStackView *contentStack = [[UIStackView alloc] init];
    contentStack.axis = UILayoutConstraintAxisVertical;
    contentStack.spacing = 12;
    contentStack.alignment = self.centersHeaderContent ? UIStackViewAlignmentCenter : UIStackViewAlignmentLeading;
    if (self.iconName.length > 0) {
        self.iconView.image = [LoanZen_Asset imageNamed:self.iconName];
        [contentStack addArrangedSubview:self.iconView];
        [self.iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(40);
        }];
    }
    [contentStack addArrangedSubview:self.titleLabel];
    [contentStack addArrangedSubview:self.titleAccentLine];
    [contentStack addArrangedSubview:self.messageLabel];
    [contentStack addArrangedSubview:self.buttonStack];

    [self.view addSubview:self.dimView];
    [self.view addSubview:self.cardView];
    [self.cardView addSubview:contentStack];

    [self.dimView mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.view); }];
    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.width.mas_equalTo(300);
        make.left.greaterThanOrEqualTo(self.view).offset(24);
        make.right.lessThanOrEqualTo(self.view).offset(-24);
    }];
    [contentStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.cardView).insets(UIEdgeInsetsMake(20, 20, 20, 20));
    }];
    [self.titleAccentLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(3);
        make.width.mas_equalTo(56);
    }];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(contentStack);
    }];
    [self.messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(contentStack);
    }];
    [self.buttonStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(contentStack);
    }];
    [contentStack setCustomSpacing:20 afterView:self.messageLabel];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self LZ_applyGradientToView:self.titleAccentLine
                       layerName:LZ_ModalAccentLayerName
                          colors:@[[LoanZen_ColorUtils LZ_brandGradientStart],
                                   [[LoanZen_ColorUtils LZ_brandGradientEnd] colorWithAlphaComponent:0]]
                    cornerRadius:1.5];
    for (UIButton *btn in self.gradientButtons) {
        [LoanZen_ColorUtils LZ_applyBrandGradientToView:btn cornerRadius:btn.layer.cornerRadius];
    }
}

- (UIButton *)LZ_makeButtonForAction:(LoanZen_ModalAction *)action index:(NSInteger)index cornerRadius:(CGFloat)cornerRadius {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.layer.cornerRadius = cornerRadius;
    btn.titleLabel.font = [UIFont systemFontOfSize:15 weight:(action.style == LoanZen_ModalActionStylePrimary || action.style == LoanZen_ModalActionStyleDestructive) ? UIFontWeightSemibold : UIFontWeightMedium];
    [btn setTitle:action.title forState:UIControlStateNormal];
    switch (action.style) {
        case LoanZen_ModalActionStylePrimary:
            btn.backgroundColor = UIColor.clearColor;
            btn.clipsToBounds = YES;
            btn.layer.masksToBounds = NO;
            btn.layer.shadowColor = [LoanZen_Color accent].CGColor;
            btn.layer.shadowOpacity = 0.42;
            btn.layer.shadowRadius = 10;
            btn.layer.shadowOffset = CGSizeMake(0, 5);
            [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
            [self.gradientButtons addObject:btn];
            break;
        case LoanZen_ModalActionStyleDestructive:
            btn.backgroundColor = [LoanZen_Color danger];
            btn.clipsToBounds = YES;
            [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
            break;
        case LoanZen_ModalActionStyleSecondary:
        case LoanZen_ModalActionStyleCancel:
        default:
            btn.backgroundColor = [LoanZen_Color modalCancelBackground];
            btn.layer.borderWidth = 1;
            btn.layer.borderColor = [LoanZen_ColorUtils LZ_glassBorder10].CGColor;
            [btn setTitleColor:[LoanZen_Color kycFormLabel] forState:UIControlStateNormal];
            break;
    }
    btn.tag = index;
    [btn addTarget:self action:@selector(LZ_tapAction:) forControlEvents:UIControlEventTouchUpInside];
    [btn mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(self.buttonHeight); }];
    return btn;
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

- (void)LZ_dimTapped {
    if (self.allowsDimTapDismiss) [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)LZ_tapAction:(UIButton *)sender {
    NSInteger idx = sender.tag;
    if (idx >= 0 && idx < (NSInteger)self.actions.count) {
        LoanZen_ModalAction *action = self.actions[idx];
        [self dismissViewControllerAnimated:YES completion:^{
            if (action.handler) action.handler();
        }];
        return;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
