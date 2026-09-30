#import "LoanZen_EMIResultViewController.h"
#import "LoanZen_ScreenScaffoldView.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_ColorUtils.h"
#import "LoanZen_LoginGatekeeper.h"
#import "LoanZen_UserService.h"
#import "LoanZen_SupHomeParser.h"
#import "LoanZen_KYCFourService.h"
#import "LoanZen_KYCFourFlowNavigator.h"
#import "LoanZen_KYCFourFlowStore.h"
#import "LoanZen_BuryReporter.h"
#import "LoanZen_HUD.h"
#import "LoanZen_AppRouter.h"
#import "LoanZen_SessionStore.h"
#import "LoanZen_Notifications.h"
#import "LoanZen_MainTabController.h"
@import Masonry;

@interface LoanZen_EMIResultViewController ()
@property (nonatomic, strong) LoanZen_EMIResult *result;
@property (nonatomic, strong) LoanZen_ScreenScaffoldView *scaffold;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UIButton *applyButton;
@end

@implementation LoanZen_EMIResultViewController

- (instancetype)initWithResult:(LoanZen_EMIResult *)result {
    self = [super initWithNibName:nil bundle:nil];
    if (self) _result = result;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [LoanZen_Color background];
    self.navigationController.navigationBarHidden = YES;

    self.scaffold = [[LoanZen_ScreenScaffoldView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.scaffold];
    [self.scaffold mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.view); }];
    [self.scaffold LZ_useKYCStyle];
    [self.scaffold LZ_setHeaderTitle:@"EMI Calculator"];
    __weak typeof(self) weakSelf = self;
    [self.scaffold LZ_setBackAction:^{ [weakSelf.navigationController popViewControllerAnimated:YES]; }];

    self.bottomBar = [[UIView alloc] init];
    self.bottomBar.backgroundColor = UIColor.clearColor;
    [self.scaffold addSubview:self.bottomBar];

    self.applyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.applyButton.hidden = YES;
    self.applyButton.backgroundColor = [LoanZen_Color accent];
    self.applyButton.layer.cornerRadius = 24;
    self.applyButton.clipsToBounds = YES;
    self.applyButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.applyButton setTitle:@"Apply Now" forState:UIControlStateNormal];
    [self.applyButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.applyButton addTarget:self action:@selector(LZ_tapApply) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.applyButton];

    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.scaffold.contentView addSubview:self.scrollView];

    UIView *metricsCard = [self LZ_buildMetricsCard];
    UIView *detailsCard = [self LZ_buildDetailsCard];
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[metricsCard, detailsCard]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 16;
    [self.scrollView addSubview:stack];

    [self.bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.scaffold);
        make.bottom.equalTo(self.scaffold.mas_safeAreaLayoutGuideBottom);
        make.height.mas_equalTo(61);
    }];
    [self.applyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.bottomBar).inset(16);
        make.bottom.equalTo(self.bottomBar);
        make.height.mas_equalTo(48);
    }];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scaffold.contentView);
    }];
    [stack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.scrollView).insets(UIEdgeInsetsMake(16, 16, 0, 16));
        make.width.equalTo(self.scrollView).offset(-32);
        make.bottom.equalTo(self.scrollView).offset(-(16 + 61));
    }];
    [self.scaffold bringSubviewToFront:self.bottomBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self LZ_refreshApplyVisibility];
}

#pragma mark - UI builders

- (UIView *)LZ_buildMetricsCard {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [LoanZen_ColorUtils LZ_glassFill06];
    card.layer.cornerRadius = 16;
    card.layer.borderWidth = 1;
    card.layer.borderColor = [[LoanZen_Color accent] colorWithAlphaComponent:0.55].CGColor;
    card.layer.shadowColor = [LoanZen_Color accent].CGColor;
    card.layer.shadowOpacity = 0.22;
    card.layer.shadowRadius = 10;
    card.layer.shadowOffset = CGSizeZero;

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 0;
    [card addSubview:stack];
    [stack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(card).insets(UIEdgeInsetsMake(4, 16, 4, 16));
    }];

    NSArray *rows = @[
        @[@"Total payment", [self LZ_formatPeso:self.result.totalPayment]],
        @[@"Monthly EMI", [self LZ_formatPeso:self.result.monthlyEMI]],
        @[@"Total interest", [self LZ_formatPeso:self.result.totalInterest]],
    ];
    [rows enumerateObjectsUsingBlock:^(NSArray *item, NSUInteger idx, BOOL *stop) {
        [stack addArrangedSubview:[self LZ_metricRowWithTitle:item[0] value:item[1]]];
        if (idx + 1 < rows.count) {
            [stack addArrangedSubview:[self LZ_separatorLine]];
        }
    }];
    return card;
}

- (UIView *)LZ_buildDetailsCard {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [LoanZen_Color kycFormCardFill];
    card.layer.cornerRadius = 16;
    card.layer.borderWidth = 1;
    card.layer.borderColor = [LoanZen_Color kycFormCardBorder].CGColor;

    NSString *amount = [self LZ_formatPlainAmount:self.result.input.amount];
    NSString *years = [NSString stringWithFormat:@"%ld", (long)self.result.input.years];
    NSString *rate = [self LZ_formatRate:self.result.input.annualRatePercent];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 0;
    [card addSubview:stack];
    [stack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(card).insets(UIEdgeInsetsMake(4, 16, 4, 16));
    }];

    NSArray *rows = @[
        @[@"Total loan amount (₱)", amount],
        @[@"Duration (Year)", years],
        @[@"Interest rate (%)", rate],
    ];
    [rows enumerateObjectsUsingBlock:^(NSArray *item, NSUInteger idx, BOOL *stop) {
        [stack addArrangedSubview:[self LZ_detailRowWithTitle:item[0] value:item[1]]];
        if (idx + 1 < rows.count) {
            [stack addArrangedSubview:[self LZ_separatorLine]];
        }
    }];
    return card;
}

- (UIView *)LZ_metricRowWithTitle:(NSString *)title value:(NSString *)value {
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    titleLabel.textColor = [LoanZen_Color secondaryText];

    UILabel *valueLabel = [[UILabel alloc] init];
    valueLabel.text = value;
    valueLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    valueLabel.textColor = [LoanZen_Color accent];
    valueLabel.textAlignment = NSTextAlignmentRight;

    UIView *row = [[UIView alloc] init];
    [row addSubview:titleLabel];
    [row addSubview:valueLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.centerY.equalTo(row);
        make.top.bottom.equalTo(row).inset(14);
    }];
    [valueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.centerY.equalTo(row);
        make.left.greaterThanOrEqualTo(titleLabel.mas_right).offset(12);
    }];
    return row;
}

- (UIView *)LZ_detailRowWithTitle:(NSString *)title value:(NSString *)value {
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    titleLabel.textColor = [LoanZen_Color secondaryText];

    UILabel *valueLabel = [[UILabel alloc] init];
    valueLabel.text = value;
    valueLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    valueLabel.textColor = [LoanZen_Color primaryText];
    valueLabel.textAlignment = NSTextAlignmentRight;

    UIView *row = [[UIView alloc] init];
    [row addSubview:titleLabel];
    [row addSubview:valueLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.centerY.equalTo(row);
        make.top.bottom.equalTo(row).inset(14);
    }];
    [valueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.centerY.equalTo(row);
        make.left.greaterThanOrEqualTo(titleLabel.mas_right).offset(12);
    }];
    return row;
}

- (UIView *)LZ_separatorLine {
    UIView *line = [[UIView alloc] init];
    line.backgroundColor = [LoanZen_ColorUtils LZ_glassBorder10];
    [line mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(1); }];
    return line;
}

#pragma mark - Formatting

- (NSString *)LZ_formatPeso:(NSString *)raw {
    NSString *cleaned = [[raw ?: @"" stringByReplacingOccurrencesOfString:@"," withString:@""] copy];
    double value = round(cleaned.doubleValue);
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.minimumFractionDigits = 0;
    formatter.maximumFractionDigits = 0;
    formatter.groupingSeparator = @",";
    formatter.usesGroupingSeparator = YES;
    NSString *formatted = [formatter stringFromNumber:@(value)] ?: [NSString stringWithFormat:@"%.0f", value];
    return [NSString stringWithFormat:@"₱%@", formatted];
}

- (NSString *)LZ_formatPlainAmount:(double)amount {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.maximumFractionDigits = 0;
    formatter.minimumFractionDigits = 0;
    formatter.groupingSeparator = @",";
    formatter.usesGroupingSeparator = YES;
    return [formatter stringFromNumber:@(amount)] ?: [NSString stringWithFormat:@"%.0f", amount];
}

- (NSString *)LZ_formatRate:(double)rate {
    if (fabs(rate - round(rate)) < 0.001) {
        return [NSString stringWithFormat:@"%.0f", rate];
    }
    return [NSString stringWithFormat:@"%.1f", rate];
}

#pragma mark - Apply (LoanBase / LoanEase)

- (void)LZ_refreshApplyVisibility {
    if (!LoanZen_SessionStore.shared.isLoggedIn) {
        self.applyButton.hidden = YES;
        return;
    }
    [LoanZen_UserService LZ_fetchUserInfoWithCompletion:^(NSDictionary *user, NSError *error) {
        NSInteger status = [LoanZen_SupHomeParser LZ_userStatusFromData:user];
        self.applyButton.hidden = !(status == 10 || status == 20);
    }];
}

- (void)LZ_tapApply {
    if ([LoanZen_LoginGatekeeper LZ_requireLoginIfNeededFrom:self]) return;
    [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventClickHomePageButton];
    __weak typeof(self) weakSelf = self;
    [LoanZen_UserService LZ_fetchUserInfoWithCompletion:^(NSDictionary *user, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        NSInteger userStatus = [LoanZen_SupHomeParser LZ_userStatusFromData:user];
        [LoanZen_HUD LZ_showBlockingLoading];
        [LoanZen_KYCFourService LZ_fetchFourStatusWithLoading:NO completion:^(NSNumber *step, NSError *kycError) {
            [LoanZen_HUD LZ_hideBlockingLoading];
            if (kycError) {
                [LoanZen_HUD LZ_showError:kycError.localizedDescription];
                return;
            }
            if (step == nil) {
                [LoanZen_HUD LZ_showError:@"Failed to load KYC status."];
                return;
            }
            if (userStatus == 20) {
                [self LZ_switchToHomeTab];
                return;
            }
            if (step.integerValue == -1) {
                [LoanZen_HUD LZ_showSuccess:@"All KYC steps are completed."];
                [LoanZen_KYCFourFlowNavigator LZ_exitFlowFrom:self completed:YES];
                return;
            }
            if (step.integerValue < 1 || step.integerValue > 4) {
                [LoanZen_HUD LZ_showError:@"Invalid KYC step from server."];
                return;
            }
            LoanZen_KYCFourFlowStore.shared.flowOrigin = LoanZen_KYCFlowOriginEMIResult;
            [LoanZen_KYCFourFlowNavigator LZ_openStepAfterStatus:step.integerValue from:self animated:NO];
        }];
    }];
}

- (void)LZ_switchToHomeTab {
    UIResponder *responder = self;
    while (responder) {
        if ([responder isKindOfClass:[LoanZen_MainTabController class]]) {
            UINavigationController *emiNav = self.navigationController;
            if (emiNav.viewControllers.count > 1) {
                [emiNav popToRootViewControllerAnimated:NO];
            }
            [(LoanZen_MainTabController *)responder LZ_switchToHomeTab];
            return;
        }
        responder = responder.nextResponder;
    }
    [LoanZen_AppRouter LZ_showMainInterfaceInWindow:self.view.window];
}

@end
