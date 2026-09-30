#import "LoanZen_KYCVerificationFailedViewController.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_ColorUtils.h"
@import Masonry;

@interface LoanZen_KYCVerificationFailedViewController ()
@property (nonatomic, strong) UIView *dimView;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIButton *confirmButton;
@end

@implementation LoanZen_KYCVerificationFailedViewController

+ (instancetype)LZ_presentFrom:(UIViewController *)host {
    return [self LZ_presentFrom:host onConfirm:nil];
}

+ (instancetype)LZ_presentFrom:(UIViewController *)host onConfirm:(void (^)(void))onConfirm {
    LoanZen_KYCVerificationFailedViewController *modal = [[LoanZen_KYCVerificationFailedViewController alloc] init];
    modal.onConfirm = onConfirm;
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

    self.cardView = [[UIView alloc] init];
    self.cardView.backgroundColor = [LoanZen_ColorUtils LZ_colorFromHex:0x161616 alpha:1];
    self.cardView.layer.cornerRadius = 24;
    self.cardView.layer.borderWidth = 1;
    self.cardView.layer.borderColor = [LoanZen_ColorUtils LZ_colorFromHex:0x2A2A2A alpha:1].CGColor;
    self.cardView.clipsToBounds = NO;

    UIImageView *iconView = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:@"lz_tk_cwts"]];
    iconView.contentMode = UIViewContentModeScaleAspectFit;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"Verification failed.";
    titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.numberOfLines = 0;

    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.text = @"Please upload the photo again.";
    subtitleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    subtitleLabel.textColor = [LoanZen_Color kycFormLabel];
    subtitleLabel.numberOfLines = 0;

    UIView *headerDivider = [self LZ_dividerView];

    UIView *failureHeader = [self LZ_sectionHeaderWithTitle:@"FAILURE REASON" color:[LoanZen_ColorUtils LZ_colorFromHex:0xFF4D4F alpha:1]];
    UIView *reason1 = [self LZ_reasonRowWithText:@"The ID photo is too small." imageName:@"lz_tk_cwts1"];
    UIView *reason2 = [self LZ_reasonRowWithText:@"The ID is partially covered." imageName:@"lz_tk_cwts2"];

    UIView *sectionDivider = [self LZ_dividerView];

    UIView *exampleHeader = [self LZ_sectionHeaderWithTitle:@"CORRECT EXAMPLE" color:[LoanZen_ColorUtils LZ_colorFromHex:0x00B578 alpha:1]];
    UIView *exampleRow = [self LZ_reasonRowWithText:@"Clear and unobstructed." imageName:@"lz_tk_cwts3"];

    self.confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.confirmButton.backgroundColor = [LoanZen_Color accent];
    self.confirmButton.layer.cornerRadius = 24;
    self.confirmButton.clipsToBounds = YES;
    self.confirmButton.layer.masksToBounds = NO;
    self.confirmButton.layer.shadowColor = [LoanZen_ColorUtils LZ_brandGradientEnd].CGColor;
    self.confirmButton.layer.shadowOpacity = 0.45;
    self.confirmButton.layer.shadowRadius = 12;
    self.confirmButton.layer.shadowOffset = CGSizeMake(0, 6);
    [self.confirmButton setTitle:@"Confirm" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.confirmButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.confirmButton addTarget:self action:@selector(LZ_tapConfirm) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *contentStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        iconView,
        titleLabel,
        subtitleLabel,
        headerDivider,
        failureHeader,
        reason1,
        reason2,
        sectionDivider,
        exampleHeader,
        exampleRow,
        self.confirmButton,
    ]];
    contentStack.axis = UILayoutConstraintAxisVertical;
    contentStack.spacing = 12;
    contentStack.alignment = UIStackViewAlignmentLeading;

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
    [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(40);
    }];
    [headerDivider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(1);
        make.width.equalTo(contentStack);
    }];
    [sectionDivider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(1);
        make.width.equalTo(contentStack);
    }];
    [reason1 mas_makeConstraints:^(MASConstraintMaker *make) { make.width.equalTo(contentStack); }];
    [reason2 mas_makeConstraints:^(MASConstraintMaker *make) { make.width.equalTo(contentStack); }];
    [exampleRow mas_makeConstraints:^(MASConstraintMaker *make) { make.width.equalTo(contentStack); }];
    [self.confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(48);
        make.width.equalTo(contentStack);
    }];

    [contentStack setCustomSpacing:8 afterView:titleLabel];
    [contentStack setCustomSpacing:16 afterView:subtitleLabel];
    [contentStack setCustomSpacing:16 afterView:headerDivider];
    [contentStack setCustomSpacing:8 afterView:failureHeader];
    [contentStack setCustomSpacing:16 afterView:reason2];
    [contentStack setCustomSpacing:8 afterView:exampleHeader];
    [contentStack setCustomSpacing:20 afterView:exampleRow];
}

- (UIView *)LZ_dividerView {
    UIView *divider = [[UIView alloc] init];
    divider.backgroundColor = [LoanZen_ColorUtils LZ_colorFromHex:0x2A2A2A alpha:1];
    return divider;
}

- (UIView *)LZ_sectionHeaderWithTitle:(NSString *)title color:(UIColor *)color {
    UIView *wrap = [[UIView alloc] init];
    UIView *dot = [[UIView alloc] init];
    dot.backgroundColor = color;
    dot.layer.cornerRadius = 3;
    dot.clipsToBounds = YES;

    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    label.textColor = color;
    label.numberOfLines = 1;

    [wrap addSubview:dot];
    [wrap addSubview:label];
    [dot mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.centerY.equalTo(wrap);
        make.width.height.mas_equalTo(6);
    }];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(dot.mas_right).offset(6);
        make.top.bottom.right.equalTo(wrap);
    }];
    return wrap;
}

- (UIView *)LZ_reasonRowWithText:(NSString *)text imageName:(NSString *)imageName {
    UIView *row = [[UIView alloc] init];

    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    label.textColor = [LoanZen_Color kycFormLabel];
    label.numberOfLines = 0;

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:imageName]];
    imageView.contentMode = UIViewContentModeScaleAspectFit;

    [row addSubview:label];
    [row addSubview:imageView];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(row);
        make.centerY.equalTo(row);
        make.right.lessThanOrEqualTo(imageView.mas_left).offset(-12);
    }];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.top.bottom.equalTo(row);
        make.width.height.mas_equalTo(56);
    }];
    [row mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_greaterThanOrEqualTo(56);
    }];
    return row;
}

- (void)LZ_tapConfirm {
    void (^callback)(void) = self.onConfirm;
    [self dismissViewControllerAnimated:YES completion:^{
        if (callback) callback();
    }];
}

@end
