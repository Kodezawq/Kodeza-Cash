#import "LoanZen_LoanConfirmationViewController.h"
#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_ScreenScaffoldView.h"
#import "LoanZen_ProductService.h"
#import "LoanZen_PayAccountService.h"
#import "LoanZen_PopupHelper.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_ColorUtils.h"
#import "LoanZen_HUD.h"
#import "LoanZen_BuryReporter.h"
#import "LoanZen_Notifications.h"
#import "LoanZen_BankFormViewController.h"
#import "LoanZen_WebDocumentViewController.h"
#import "LoanZen_OrderPostSubmitCoordinator.h"
#import "LoanZen_LocationManager.h"
#import "LoanZen_AppConfigStore.h"
#import "LoanZen_AuthService.h"
#import "LoanZen_TermBusinessHelper.h"
#import "LoanZen_MainTabController.h"
#import "LoanZen_OrderSubmitMaskView.h"
#import "LoanZen_AppRouter.h"
@import Masonry;
@import SDWebImage;

static const NSInteger kLZAmountButtonBaseTag = 6000;

@interface LoanZen_LoanConfirmationViewController () <UITextViewDelegate>
@property (nonatomic, copy) NSString *productId;
@property (nonatomic, assign, readwrite) BOOL embeddedInKYCFlow;
@property (nonatomic, strong) LoanZen_ScreenScaffoldView *scaffold;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIView *productHeaderView;
@property (nonatomic, strong) UIView *productIconContainer;
@property (nonatomic, strong) UIImageView *productIconView;
@property (nonatomic, strong) UILabel *productLogoFallbackLabel;
@property (nonatomic, strong) UILabel *productNameLabel;
@property (nonatomic, strong) UIView *creditTipView;
@property (nonatomic, strong) UIView *singleAmountBlock;
@property (nonatomic, strong) UILabel *loanAmountTitleLabel;
@property (nonatomic, strong) UILabel *amountHeadlineLabel;

@property (nonatomic, strong) UIView *card1;
@property (nonatomic, strong) UIView *accountCard;
@property (nonatomic, strong) UIView *detailCard;
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) UIView *amountsContainer;
@property (nonatomic, strong) UILabel *accountTitleLabel;
@property (nonatomic, strong) UIView *accountRow;
@property (nonatomic, strong) UILabel *accountValueLabel;
@property (nonatomic, strong) UIView *termRow;
@property (nonatomic, strong) UILabel *singleTermTitleLabel;
@property (nonatomic, strong) UIView *termValuePill;
@property (nonatomic, strong) UILabel *termValueLabel;
@property (nonatomic, strong) UIImageView *singleTermChevron;
@property (nonatomic, strong) UIView *multiTermRow;
@property (nonatomic, strong) UILabel *multiTermTitleLabel;
@property (nonatomic, strong) UIView *multiTermPill;
@property (nonatomic, strong) UILabel *multiTermPillLabel;
@property (nonatomic, strong) UIImageView *multiTermChevron;
@property (nonatomic, strong) UIView *multiTermDivider;
@property (nonatomic, strong) UIView *detailContainer;
@property (nonatomic, strong) UIStackView *detailPairsStack;

@property (nonatomic, strong) UIView *repaymentCard;
@property (nonatomic, strong) UIStackView *repaymentRowsStack;
@property (nonatomic, strong) UIButton *repaymentToggleButton;
@property (nonatomic, strong) UILabel *repaymentHintLabel;

@property (nonatomic, strong) UIView *agreementBar;
@property (nonatomic, strong) UIButton *agreementCheckButton;
@property (nonatomic, strong) UIButton *submitButton;

@property (nonatomic, strong) MASConstraint *amountsContainerHeightConstraint;
@property (nonatomic, strong) MASConstraint *multiTermRowHeightConstraint;
@property (nonatomic, strong) MASConstraint *multiTermDividerHeightConstraint;
@property (nonatomic, strong) MASConstraint *termRowHeightConstraint;
@property (nonatomic, strong) MASConstraint *repaymentCardHeightConstraint;
@property (nonatomic, strong) MASConstraint *card1TopConstraint;
@property (nonatomic, strong) MASConstraint *card1BottomConstraint;
@property (nonatomic, strong) MASConstraint *card1HeightConstraint;
@property (nonatomic, strong) MASConstraint *accountCardTopConstraint;
@property (nonatomic, strong) MASConstraint *singleAmountBlockHeightConstraint;
@property (nonatomic, strong) MASConstraint *detailContainerTopConstraint;
@property (nonatomic, strong) MASConstraint *detailPairsTopConstraint;

@property (nonatomic, copy) NSDictionary *termData;
@property (nonatomic, copy) NSArray<NSDictionary *> *amountDetails;
@property (nonatomic, assign) NSInteger selectedAmountIndex;
@property (nonatomic, assign) NSInteger selectedTermIndex;
@property (nonatomic, copy) NSString *selectedBankBindId;
@property (nonatomic, copy) NSArray<NSDictionary *> *payAccounts;
@property (nonatomic, assign) BOOL agreementAccepted;
@property (nonatomic, assign) BOOL isRepaymentExpanded;
@property (nonatomic, assign) BOOL isSubmitting;
@property (nonatomic, assign) BOOL isHandlingBack;
@property (nonatomic, assign) BOOL hasShownBackConfirm;
@property (nonatomic, strong) LoanZen_OrderSubmitMaskView *orderSubmitMaskView;
@end

@implementation LoanZen_LoanConfirmationViewController

- (instancetype)initWithProductId:(NSString *)productId {
    return [self initWithProductId:productId embeddedInKYCFlow:NO];
}

- (instancetype)initWithProductId:(NSString *)productId embeddedInKYCFlow:(BOOL)embeddedInKYCFlow {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _productId = productId.copy;
        _embeddedInKYCFlow = embeddedInKYCFlow;
        _agreementAccepted = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [LoanZen_AuthService LZ_fetchAppConfigWithCompletion:nil];
    self.view.backgroundColor = [LoanZen_Color background];
    self.navigationController.navigationBarHidden = YES;

    self.scaffold = [[LoanZen_ScreenScaffoldView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.scaffold];
    [self.scaffold mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.view); }];
    [self.scaffold LZ_useLoanConfirmationStyle];
    [self.scaffold LZ_setHeaderTitle:@"Loan confirmation"];
    __weak typeof(self) weakSelf = self;
    [self.scaffold LZ_setBackAction:^{ [weakSelf LZ_handleBackTapped]; }];

    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.showsVerticalScrollIndicator = YES;
    self.scrollView.alwaysBounceVertical = YES;
    [self.scaffold.contentView addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scaffold.contentView);
    }];

    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];

    [self LZ_buildDarkLayout];

    self.agreementBar = [self LZ_buildAgreementBar];
    [self.view addSubview:self.agreementBar];
    [self.agreementBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
    }];
    UIView *agreementStack = self.agreementBar.subviews.firstObject;
    [agreementStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-12);
    }];
    [self.scrollView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.scaffold.contentView);
        make.bottom.equalTo(self.agreementBar.mas_top);
    }];
    self.scrollView.contentInset = UIEdgeInsetsZero;
    self.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;

    [self LZ_loadTerm];
    [self LZ_loadBanks];

    // mask 挂在当前页 view 最底层遮罩之上、各类弹窗（定位/通讯录）之下
    self.orderSubmitMaskView = [[LoanZen_OrderSubmitMaskView alloc] init];
    self.orderSubmitMaskView.hidden = YES;
    [self.view addSubview:self.orderSubmitMaskView];
    [self.orderSubmitMaskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self.view insertSubview:self.orderSubmitMaskView aboveSubview:self.scaffold];
    if (self.agreementBar.superview == self.view) {
        [self.view insertSubview:self.orderSubmitMaskView aboveSubview:self.agreementBar];
    }
}

- (void)LZ_showOrderSubmitMask {
    self.orderSubmitMaskView.hidden = NO;
    [self.view insertSubview:self.orderSubmitMaskView aboveSubview:self.scaffold];
    if (self.agreementBar.superview == self.view) {
        [self.view insertSubview:self.orderSubmitMaskView aboveSubview:self.agreementBar];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self LZ_loadBanks];
    [self LZ_refreshMainTabBarVisibility];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isMovingFromParentViewController) {
        [self LZ_refreshMainTabBarVisibility];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [LoanZen_ColorUtils LZ_applyBrandGradientToView:self.submitButton cornerRadius:24];
    [self LZ_refreshTermPillStyle];
}

#pragma mark - Layout

- (UIView *)LZ_buildProductIdentityView {
    UIView *header = [[UIView alloc] init];

    self.productIconContainer = [[UIView alloc] init];
    self.productIconContainer.backgroundColor = UIColor.clearColor;
    self.productIconContainer.layer.cornerRadius = 10;
    self.productIconContainer.clipsToBounds = YES;
    [header addSubview:self.productIconContainer];
    [self.productIconContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(header);
        make.width.height.mas_equalTo(30);
    }];

    self.productIconView = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:[LoanZen_Asset loginLogo]]];
    self.productIconView.contentMode = UIViewContentModeScaleAspectFill;
    self.productIconView.clipsToBounds = YES;
    self.productIconView.hidden = NO;
    [self.productIconContainer addSubview:self.productIconView];
    [self.productIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.productIconContainer);
    }];

    self.productLogoFallbackLabel = [[UILabel alloc] init];
    self.productLogoFallbackLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    self.productLogoFallbackLabel.textColor = UIColor.whiteColor;
    self.productLogoFallbackLabel.textAlignment = NSTextAlignmentCenter;
    self.productLogoFallbackLabel.hidden = YES;
    [self.productIconContainer addSubview:self.productLogoFallbackLabel];
    [self.productLogoFallbackLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.productIconContainer);
    }];

    self.productNameLabel = [[UILabel alloc] init];
    self.productNameLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.productNameLabel.textColor = [LoanZen_Color primaryText];
    self.productNameLabel.numberOfLines = 1;
    self.productNameLabel.adjustsFontSizeToFitWidth = YES;
    self.productNameLabel.minimumScaleFactor = 0.7;
    self.productNameLabel.text = @"Product";
    [self.productNameLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.productNameLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [header addSubview:self.productNameLabel];
    [self.productNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.productIconContainer.mas_right).offset(10);
        make.centerY.equalTo(header);
        make.right.equalTo(header);
    }];
    return header;
}

- (void)LZ_placeProductIdentityMultiAmount:(BOOL)isMultiAmount {
    [self.productHeaderView removeFromSuperview];
    if (isMultiAmount) {
        // 截图1：金额选择卡内左上 Icon + 名称，其下 Tips / 金额网格
        [self.card1 insertSubview:self.productHeaderView atIndex:0];
        [self.productHeaderView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.card1).offset(16);
            make.right.lessThanOrEqualTo(self.card1).offset(-16);
            make.top.equalTo(self.card1).offset(16);
            make.height.mas_equalTo(30);
        }];
        [self.tipsLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.card1).offset(16);
            make.top.equalTo(self.productHeaderView.mas_bottom).offset(10);
        }];
    } else {
        // 截图：单金额整体卡片内 Icon+名称 / Loan amount / 金额
        [self.singleAmountBlock insertSubview:self.productHeaderView atIndex:0];
        [self.productHeaderView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.singleAmountBlock).offset(16);
            make.centerX.equalTo(self.singleAmountBlock);
            make.height.mas_equalTo(30);
            make.left.greaterThanOrEqualTo(self.singleAmountBlock).offset(16);
            make.right.lessThanOrEqualTo(self.singleAmountBlock).offset(-16);
        }];
        [self.loanAmountTitleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.productHeaderView.mas_bottom).offset(14);
            make.centerX.equalTo(self.singleAmountBlock);
        }];
        [self.amountHeadlineLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.loanAmountTitleLabel.mas_bottom).offset(8);
            make.centerX.equalTo(self.singleAmountBlock);
            make.bottom.equalTo(self.singleAmountBlock).offset(-16);
        }];
    }
}

- (void)LZ_buildDarkLayout {
    self.productHeaderView = [self LZ_buildProductIdentityView];

    self.creditTipView = [[UIView alloc] init];
    self.creditTipView.backgroundColor = [[LoanZen_Color accent] colorWithAlphaComponent:0.12];
    self.creditTipView.layer.cornerRadius = 12;
    self.creditTipView.layer.borderWidth = 1;
    self.creditTipView.layer.borderColor = [[LoanZen_Color accent] colorWithAlphaComponent:0.35].CGColor;
    self.creditTipView.clipsToBounds = YES;
    UILabel *creditLabel = [[UILabel alloc] init];
    creditLabel.numberOfLines = 0;
    creditLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    creditLabel.textColor = [LoanZen_Color kycFormLabel];
    creditLabel.text = @"Your credit status directly affects your loan limit, and a good credit history helps you secure better loan terms.";
    [self.creditTipView addSubview:creditLabel];
    [creditLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.creditTipView).insets(UIEdgeInsetsMake(12, 14, 12, 14));
    }];
    [self.contentView addSubview:self.creditTipView];
    [self.creditTipView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.contentView).inset(16.0);
        make.top.equalTo(self.contentView).offset(12);
    }];

    self.singleAmountBlock = [self LZ_darkCard];
    [self.contentView addSubview:self.singleAmountBlock];
    [self.singleAmountBlock mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.contentView).inset(16.0);
        make.top.equalTo(self.creditTipView.mas_bottom).offset(16);
        // 内容用 bottom 约束撑开；多金额时高度置 0
        self.singleAmountBlockHeightConstraint = make.height.mas_equalTo(0);
    }];
    [self.singleAmountBlockHeightConstraint uninstall];

    self.loanAmountTitleLabel = [[UILabel alloc] init];
    self.loanAmountTitleLabel.text = @"Loan amount";
    self.loanAmountTitleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    self.loanAmountTitleLabel.textColor = [LoanZen_Color kycFormLabel];
    self.loanAmountTitleLabel.textAlignment = NSTextAlignmentCenter;
    [self.singleAmountBlock addSubview:self.loanAmountTitleLabel];

    self.amountHeadlineLabel = [[UILabel alloc] init];
    self.amountHeadlineLabel.font = [UIFont systemFontOfSize:34 weight:UIFontWeightBold];
    self.amountHeadlineLabel.textColor = [LoanZen_Color accent];
    self.amountHeadlineLabel.textAlignment = NSTextAlignmentCenter;
    self.amountHeadlineLabel.text = @"—";
    [self.singleAmountBlock addSubview:self.amountHeadlineLabel];

    self.card1 = [self LZ_darkCard];
    [self.contentView addSubview:self.card1];
    [self.card1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.contentView).inset(16.0);
        self.card1TopConstraint = make.top.equalTo(self.singleAmountBlock.mas_bottom).offset(12);
    }];

    self.tipsLabel = [[UILabel alloc] init];
    self.tipsLabel.text = @"Tips: Select loan amount first";
    self.tipsLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    self.tipsLabel.textColor = [LoanZen_Color kycFormLabel];
    [self.card1 addSubview:self.tipsLabel];

    [self LZ_placeProductIdentityMultiAmount:YES];

    self.amountsContainer = [[UIView alloc] init];
    [self.card1 addSubview:self.amountsContainer];
    [self.amountsContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.card1).inset(16);
        make.top.equalTo(self.tipsLabel.mas_bottom).offset(12);
        self.amountsContainerHeightConstraint = make.height.mas_equalTo(82);
    }];
    [self.card1 mas_makeConstraints:^(MASConstraintMaker *make) {
        self.card1BottomConstraint = make.bottom.equalTo(self.amountsContainer.mas_bottom).offset(16);
        self.card1HeightConstraint = make.height.mas_equalTo(0);
    }];
    [self.card1HeightConstraint uninstall];

    self.accountCard = [self LZ_darkCard];
    [self.contentView addSubview:self.accountCard];
    [self.accountCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.contentView).inset(16.0);
        self.accountCardTopConstraint = make.top.equalTo(self.card1.mas_bottom).offset(12);
    }];

    self.accountTitleLabel = [[UILabel alloc] init];
    self.accountTitleLabel.text = @"Select receiving account";
    self.accountTitleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    self.accountTitleLabel.textColor = [LoanZen_Color kycFormLabel];
    [self.accountCard addSubview:self.accountTitleLabel];
    [self.accountTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.accountCard).offset(16);
        make.top.equalTo(self.accountCard).offset(16);
    }];

    self.accountRow = [[UIView alloc] init];
    self.accountRow.backgroundColor = [LoanZen_Color kycFormInputFill];
    self.accountRow.layer.cornerRadius = 12;
    self.accountRow.layer.borderWidth = 1;
    self.accountRow.layer.borderColor = [LoanZen_Color kycFormInputBorder].CGColor;
    self.accountRow.clipsToBounds = YES;
    [self.accountRow addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(LZ_tapBank)]];
    [self.accountCard addSubview:self.accountRow];
    [self.accountRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.accountCard).inset(16);
        make.top.equalTo(self.accountTitleLabel.mas_bottom).offset(8);
        make.height.mas_equalTo(48);
        make.bottom.equalTo(self.accountCard).offset(-16);
    }];

    UIImageView *bankIcon = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:@"lz_loan_bankk"]];
    bankIcon.contentMode = UIViewContentModeScaleAspectFit;
    self.accountValueLabel = [[UILabel alloc] init];
    self.accountValueLabel.text = @"Please add a receiving account";
    self.accountValueLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    self.accountValueLabel.textColor = [LoanZen_Color kycFormPlaceholder];
    UIImageView *bankChevron = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:@"lz_loan_bankjt"]];
    bankChevron.contentMode = UIViewContentModeScaleAspectFit;
    [self.accountRow addSubview:bankIcon];
    [self.accountRow addSubview:self.accountValueLabel];
    [self.accountRow addSubview:bankChevron];
    [bankIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.accountRow).offset(12);
        make.centerY.equalTo(self.accountRow);
        make.width.height.mas_equalTo(20);
    }];
    [self.accountValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(bankIcon.mas_right).offset(10);
        make.centerY.equalTo(self.accountRow);
        make.right.lessThanOrEqualTo(bankChevron.mas_left).offset(-8);
    }];
    [bankChevron mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.accountRow).offset(-12);
        make.centerY.equalTo(self.accountRow);
        make.width.height.mas_equalTo(16);
    }];

    self.detailCard = [self LZ_darkCard];
    [self.contentView addSubview:self.detailCard];
    [self.detailCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.contentView).inset(16.0);
        make.top.equalTo(self.accountCard.mas_bottom).offset(12);
    }];

    self.multiTermRow = [[UIView alloc] init];
    [self.multiTermRow addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(LZ_tapTermRow)]];
    [self.detailCard addSubview:self.multiTermRow];
    [self.multiTermRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.detailCard).inset(16);
        make.top.equalTo(self.detailCard).offset(16);
        self.multiTermRowHeightConstraint = make.height.mas_equalTo(34);
    }];

    self.multiTermTitleLabel = [[UILabel alloc] init];
    self.multiTermTitleLabel.text = @"Select the loan term";
    self.multiTermTitleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    self.multiTermTitleLabel.textColor = [LoanZen_Color kycFormLabel];
    [self.multiTermRow addSubview:self.multiTermTitleLabel];

    self.multiTermPill = [[UIView alloc] init];
    self.multiTermPill.layer.cornerRadius = 17;
    self.multiTermPill.clipsToBounds = YES;
    self.multiTermPill.userInteractionEnabled = NO;
    [self.multiTermRow addSubview:self.multiTermPill];
    self.multiTermPillLabel = [[UILabel alloc] init];
    self.multiTermPillLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    self.multiTermPillLabel.textColor = [LoanZen_Color accent];
    self.multiTermPillLabel.text = @"—";
    self.multiTermChevron = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:@"lz_loan_jexl"]];
    self.multiTermChevron.contentMode = UIViewContentModeScaleAspectFit;
    [self.multiTermRow addSubview:self.multiTermChevron];
    [self.multiTermPill addSubview:self.multiTermPillLabel];
    [self.multiTermTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.centerY.equalTo(self.multiTermRow);
        make.right.lessThanOrEqualTo(self.multiTermPill.mas_left).offset(-12);
    }];
    [self.multiTermChevron mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.centerY.equalTo(self.multiTermRow);
        make.width.height.mas_equalTo(14);
    }];
    [self.multiTermPill mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.multiTermChevron.mas_left).offset(-6);
        make.centerY.equalTo(self.multiTermRow);
        make.height.mas_equalTo(34);
    }];
    [self.multiTermPillLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.multiTermPill).offset(14);
        make.right.equalTo(self.multiTermPill).offset(-14);
        make.centerY.equalTo(self.multiTermPill);
    }];

    self.multiTermDivider = [[UIView alloc] init];
    self.multiTermDivider.backgroundColor = [LoanZen_Color kycFormInputBorder];
    [self.detailCard addSubview:self.multiTermDivider];
    [self.multiTermDivider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.detailCard).inset(16);
        make.top.equalTo(self.multiTermRow.mas_bottom).offset(12);
        self.multiTermDividerHeightConstraint = make.height.mas_equalTo(1);
    }];

    self.termRow = [[UIView alloc] init];
    [self.termRow addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(LZ_tapTermRow)]];
    [self.detailCard addSubview:self.termRow];
    [self.termRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.detailCard).inset(16);
        make.top.equalTo(self.detailCard).offset(16);
        self.termRowHeightConstraint = make.height.mas_equalTo(34);
    }];
    self.singleTermTitleLabel = [[UILabel alloc] init];
    self.singleTermTitleLabel.text = @"Loan term";
    self.singleTermTitleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.singleTermTitleLabel.textColor = [LoanZen_Color kycFormLabel];
    [self.termRow addSubview:self.singleTermTitleLabel];
    self.termValuePill = [[UIView alloc] init];
    self.termValuePill.layer.cornerRadius = 17;
    self.termValuePill.clipsToBounds = YES;
    self.termValuePill.userInteractionEnabled = NO;
    [self.termRow addSubview:self.termValuePill];
    self.termValueLabel = [[UILabel alloc] init];
    self.termValueLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    self.termValueLabel.textColor = [LoanZen_Color accent];
    self.termValueLabel.text = @"—";
    self.singleTermChevron = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:@"lz_loan_jexl"]];
    self.singleTermChevron.contentMode = UIViewContentModeScaleAspectFit;
    [self.termRow addSubview:self.singleTermChevron];
    [self.termValuePill addSubview:self.termValueLabel];
    [self.singleTermTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) { make.left.centerY.equalTo(self.termRow); }];
    [self.singleTermChevron mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.centerY.equalTo(self.termRow);
        make.width.height.mas_equalTo(14);
    }];
    [self.termValuePill mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.singleTermChevron.mas_left).offset(-6);
        make.centerY.equalTo(self.termRow);
        make.height.mas_equalTo(34);
    }];
    [self.termValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.termValuePill).offset(14);
        make.right.equalTo(self.termValuePill).offset(-14);
        make.centerY.equalTo(self.termValuePill);
    }];
    self.singleTermChevron.hidden = YES;

    self.detailContainer = [[UIView alloc] init];
    [self.detailCard addSubview:self.detailContainer];
    [self.detailContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.detailCard).inset(16);
        self.detailContainerTopConstraint = make.top.equalTo(self.multiTermDivider.mas_bottom).offset(12);
        make.bottom.equalTo(self.detailCard).offset(-16);
    }];
    self.detailPairsStack = [[UIStackView alloc] init];
    self.detailPairsStack.axis = UILayoutConstraintAxisVertical;
    self.detailPairsStack.spacing = 10;
    [self.detailContainer addSubview:self.detailPairsStack];
    [self.detailPairsStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.detailContainer);
        self.detailPairsTopConstraint = make.top.equalTo(self.detailContainer);
    }];

    self.repaymentCard = [self LZ_darkCard];
    [self.contentView addSubview:self.repaymentCard];
    [self.repaymentCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.contentView).inset(16.0);
        make.top.equalTo(self.detailCard.mas_bottom).offset(12);
        self.repaymentCardHeightConstraint = make.height.mas_equalTo(180);
    }];

    UILabel *repayTitle = [[UILabel alloc] init];
    repayTitle.text = @"Repayment plan";
    repayTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    repayTitle.textColor = [LoanZen_Color kycFormValue];
    self.repaymentToggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.repaymentToggleButton setImage:[LoanZen_Asset imageNamed:@"lz_loan_sq"] forState:UIControlStateNormal];
    self.repaymentToggleButton.hidden = YES;
    [self.repaymentToggleButton addTarget:self action:@selector(LZ_toggleRepayment) forControlEvents:UIControlEventTouchUpInside];
    UIStackView *repayHeader = [[UIStackView alloc] initWithArrangedSubviews:@[repayTitle, [[UIView alloc] init], self.repaymentToggleButton]];
    repayHeader.axis = UILayoutConstraintAxisHorizontal;
    repayHeader.alignment = UIStackViewAlignmentCenter;
    [self.repaymentCard addSubview:repayHeader];
    [repayHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.repaymentCard).inset(16);
        make.top.equalTo(self.repaymentCard).offset(16);
        make.height.mas_equalTo(24);
    }];
    [self.repaymentToggleButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(20);
    }];

    self.repaymentRowsStack = [[UIStackView alloc] init];
    self.repaymentRowsStack.axis = UILayoutConstraintAxisVertical;
    self.repaymentRowsStack.spacing = 0;
    [self.repaymentCard addSubview:self.repaymentRowsStack];
    [self.repaymentRowsStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.repaymentCard).inset(16);
        make.top.equalTo(self.repaymentCard).offset(48);
    }];

    self.repaymentHintLabel = [[UILabel alloc] init];
    self.repaymentHintLabel.numberOfLines = 0;
    self.repaymentHintLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
    self.repaymentHintLabel.textColor = [LoanZen_Color kycFormPlaceholder];
    self.repaymentHintLabel.text = @"If you repay the first amount due on time, the remaining balance will be automatically reset to zero for you.";
    [self.repaymentCard addSubview:self.repaymentHintLabel];
    [self.repaymentHintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.repaymentCard).inset(16);
        make.top.equalTo(self.repaymentRowsStack.mas_bottom).offset(10);
        make.bottom.equalTo(self.repaymentCard).offset(-14);
    }];

    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.repaymentCard.mas_bottom).offset(24);
    }];
}

- (UIView *)LZ_darkCard {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [LoanZen_Color kycFormCardFill];
    card.layer.cornerRadius = 16;
    card.layer.borderWidth = 1;
    card.layer.borderColor = [LoanZen_Color kycFormCardBorder].CGColor;
    card.clipsToBounds = YES;
    return card;
}

- (UIView *)LZ_buildAgreementBar {
    UIView *bar = [[UIView alloc] init];
    bar.backgroundColor = [LoanZen_Color background];

    self.agreementCheckButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.agreementCheckButton addTarget:self action:@selector(LZ_toggleAgreement) forControlEvents:UIControlEventTouchUpInside];
    [self LZ_refreshAgreementCheck];

    UITextView *terms = [[UITextView alloc] init];
    terms.backgroundColor = UIColor.clearColor;
    terms.editable = NO;
    terms.scrollEnabled = NO;
    terms.delegate = self;
    terms.textContainerInset = UIEdgeInsetsZero;
    terms.textContainer.lineFragmentPadding = 0;
    NSString *full = @"I have read and agreed with the Terms Of The Loan";
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:full attributes:@{
        NSFontAttributeName: [UIFont systemFontOfSize:12 weight:UIFontWeightRegular],
        NSForegroundColorAttributeName: [LoanZen_Color kycFormLabel],
    }];
    NSRange range = [full rangeOfString:@"Terms Of The Loan"];
    if (range.location != NSNotFound) {
        [attr addAttributes:@{
            NSLinkAttributeName: @"lz://terms",
            NSForegroundColorAttributeName: [LoanZen_Color accent],
            NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
        } range:range];
    }
    terms.attributedText = attr;
    terms.linkTextAttributes = @{ NSForegroundColorAttributeName: [LoanZen_Color accent] };

    UIStackView *agreementRow = [[UIStackView alloc] initWithArrangedSubviews:@[self.agreementCheckButton, terms]];
    agreementRow.axis = UILayoutConstraintAxisHorizontal;
    agreementRow.spacing = 10;
    agreementRow.alignment = UIStackViewAlignmentTop;
    [self.agreementCheckButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(20);
    }];

    self.submitButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.submitButton.backgroundColor = [LoanZen_Color accent];
    self.submitButton.layer.cornerRadius = 24;
    self.submitButton.clipsToBounds = YES;
    [self.submitButton setTitle:@"Apply Now" forState:UIControlStateNormal];
    [self.submitButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.submitButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.submitButton addTarget:self action:@selector(LZ_submit) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[agreementRow, self.submitButton]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 16;
    [bar addSubview:stack];
    [stack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(bar).inset(16);
        make.top.equalTo(bar).offset(12);
    }];
    [self.submitButton mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(48); }];
    return bar;
}

#pragma mark - Tab bar

- (void)LZ_refreshMainTabBarVisibility {
    UIResponder *responder = self.nextResponder;
    while (responder) {
        if ([responder isKindOfClass:[LoanZen_MainTabController class]]) {
            [(LoanZen_MainTabController *)responder LZ_refreshBottomBarIfNeeded];
            return;
        }
        responder = responder.nextResponder;
    }
}

#pragma mark - Data helpers

- (NSArray<NSDictionary *> *)LZ_normalizedAmountDetailsFromData:(NSDictionary *)data {
    id raw = data[LZAPIFieldAmountDetailList];
    if ([raw isKindOfClass:[NSArray class]]) return raw;
    if ([raw isKindOfClass:[NSDictionary class]]) return [(NSDictionary *)raw allValues];
    return @[];
}

- (NSArray<NSDictionary *> *)LZ_sortedAmountDetails {
    NSArray *list = self.amountDetails ?: @[];
    return [list sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        double va = [self LZ_parseAmountValue:a[LZAPIFieldLoanAmount]];
        double vb = [self LZ_parseAmountValue:b[LZAPIFieldLoanAmount]];
        if (va == vb) return NSOrderedSame;
        return va > vb ? NSOrderedAscending : NSOrderedDescending;
    }];
}

- (double)LZ_parseAmountValue:(id)value {
    NSString *raw = [NSString stringWithFormat:@"%@", value ?: @""];
    raw = [[raw stringByReplacingOccurrencesOfString:@"₱" withString:@""] stringByReplacingOccurrencesOfString:@"," withString:@""];
    return [raw doubleValue];
}

- (NSString *)LZ_formatPeso:(id)value {
    NSString *raw = [NSString stringWithFormat:@"%@", value ?: @""];
    raw = [[raw stringByReplacingOccurrencesOfString:@"₱" withString:@""] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (raw.length == 0) return @"—";
    if ([raw containsString:@"-"]) return [NSString stringWithFormat:@"₱%@", raw];
    NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
    fmt.numberStyle = NSNumberFormatterDecimalStyle;
    fmt.groupingSeparator = @",";
    fmt.maximumFractionDigits = 0;
    NSNumber *num = @([raw doubleValue]);
    NSString *grouped = [fmt stringFromNumber:num] ?: raw;
    return [NSString stringWithFormat:@"₱%@", grouped];
}

- (NSDictionary *)LZ_currentAmountItem {
    NSArray *details = [self LZ_sortedAmountDetails];
    if (self.selectedAmountIndex < details.count) return details[self.selectedAmountIndex];
    return details.firstObject ?: @{};
}

- (NSArray<NSDictionary *> *)LZ_termListForAmount:(NSDictionary *)amount {
    id raw = amount[LZAPIFieldTermDetailList];
    if ([raw isKindOfClass:[NSArray class]]) return raw;
    if ([raw isKindOfClass:[NSDictionary class]]) return [(NSDictionary *)raw allValues];
    return @[];
}

- (NSArray<NSDictionary *> *)LZ_currentTermList {
    return [self LZ_termListForAmount:[self LZ_currentAmountItem]];
}

- (NSDictionary *)LZ_currentTermDetail {
    NSArray *terms = [self LZ_currentTermList];
    if (self.selectedTermIndex < terms.count) return terms[self.selectedTermIndex];
    return terms.firstObject ?: @{};
}

- (NSString *)LZ_termOptionTitleFromTerm:(NSDictionary *)term {
    if (![term isKindOfClass:[NSDictionary class]]) return @"—";
    id raw = term[LZAPIFieldShowTerm];
    if (raw == nil || raw == [NSNull null]) raw = term[LZAPIFieldLoanTerm];
    if (raw == nil || raw == [NSNull null]) return @"—";
    NSString *show = [NSString stringWithFormat:@"%@", raw];
    if (show.length == 0) return @"—";
    if ([show rangeOfString:@"Day" options:NSCaseInsensitiveSearch].location != NSNotFound) return show;
    return [NSString stringWithFormat:@"%@ Days", show];
}

- (NSString *)LZ_rawTermNumber {
    return [self LZ_termOptionTitleFromTerm:[self LZ_currentTermDetail]];
}

- (NSString *)LZ_multiModeTermText {
    return [self LZ_termOptionTitleFromTerm:[self LZ_currentTermDetail]];
}

- (NSString *)LZ_singleModeTermText {
    NSDictionary *term = [self LZ_currentTermDetail];
    if (![term isKindOfClass:[NSDictionary class]]) return @"—";
    id raw = term[LZAPIFieldShowTerm];
    if (raw == nil || raw == [NSNull null]) raw = term[LZAPIFieldLoanTerm];
    if (raw == nil || raw == [NSNull null]) return @"—";
    NSString *show = [NSString stringWithFormat:@"%@", raw];
    if (show.length == 0) return @"—";
    NSString *number = [[show stringByReplacingOccurrencesOfString:@" Days" withString:@""]
                        stringByReplacingOccurrencesOfString:@" (Days)" withString:@""];
    if ([number rangeOfString:@"Day" options:NSCaseInsensitiveSearch].location != NSNotFound) return number;
    return [NSString stringWithFormat:@"%@ (Days)", number];
}

- (CGFloat)LZ_amountButtonWidth {
    CGFloat cardWidth = UIScreen.mainScreen.bounds.size.width - 16.0 * 2 - 32;
    return floor((cardWidth - 10.0 * 2) / 3.0);
}

#pragma mark - Rebuild UI

- (void)LZ_applyTermData:(NSDictionary *)data {
    self.termData = data;
    self.amountDetails = [self LZ_normalizedAmountDetailsFromData:data];
    self.selectedAmountIndex = 0;
    self.selectedTermIndex = 0;
    self.isRepaymentExpanded = NO;
    [self LZ_refreshProductHeader];
    [self LZ_rebuildAmountButtons];
    [self LZ_rebuildTermButtons];
    [self LZ_rebuildDetailPairs];
    [self LZ_rebuildRepaymentRows];
    [self LZ_updateProductDetailMode];
}

- (NSString *)LZ_stringFromDictionary:(NSDictionary *)dict keys:(NSArray<NSString *> *)keys {
    if (![dict isKindOfClass:[NSDictionary class]]) return @"";
    for (NSString *key in keys) {
        id value = dict[key];
        if ([value isKindOfClass:[NSString class]]) {
            NSString *text = [(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (text.length > 0) return text;
        } else if ([value isKindOfClass:[NSNumber class]]) {
            return [(NSNumber *)value stringValue];
        }
    }
    return @"";
}

- (void)LZ_showProductLogoFallback {
    [self.productIconView sd_cancelCurrentImageLoad];
    self.productLogoFallbackLabel.hidden = YES;
    self.productIconView.hidden = NO;
    self.productIconView.image = [LoanZen_Asset imageNamed:[LoanZen_Asset loginLogo]];
    self.productIconContainer.backgroundColor = UIColor.clearColor;
}

- (void)LZ_refreshProductHeader {
    NSString *name = [self LZ_stringFromDictionary:self.termData keys:@[LZAPIFieldProductName, @"productname"]];
    if (name.length == 0) name = @"Product";
    self.productNameLabel.text = name;

    NSString *logoURL = [self LZ_stringFromDictionary:self.termData keys:@[LZAPIFieldProductLogo, @"productlogo", @"plain"]];
    [self.productIconView sd_cancelCurrentImageLoad];
    self.productIconView.image = nil;
    if (logoURL.length == 0) {
        [self LZ_showProductLogoFallback];
        return;
    }

    NSURL *url = [NSURL URLWithString:logoURL];
    if (!url) {
        NSString *encoded = [logoURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
        url = encoded.length > 0 ? [NSURL URLWithString:encoded] : nil;
    }
    if (!url) {
        [self LZ_showProductLogoFallback];
        return;
    }

    self.productLogoFallbackLabel.hidden = YES;
    self.productIconView.hidden = NO;
    self.productIconContainer.backgroundColor = [LoanZen_Color accent];
    __weak typeof(self) weakSelf = self;
    [self.productIconView sd_setImageWithURL:url
                            placeholderImage:[LoanZen_Asset imageNamed:[LoanZen_Asset loginLogo]]
                                     options:SDWebImageRetryFailed
                                   completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (image) {
            self.productIconView.hidden = NO;
            self.productLogoFallbackLabel.hidden = YES;
            self.productIconContainer.backgroundColor = UIColor.clearColor;
        } else {
            [self LZ_showProductLogoFallback];
        }
    }];
}

- (void)LZ_rebuildAmountButtons {
    NSArray *details = [self LZ_sortedAmountDetails];
    self.selectedAmountIndex = MIN(self.selectedAmountIndex, MAX(0, (NSInteger)details.count - 1));
    NSDictionary *current = [self LZ_currentAmountItem];
    self.amountHeadlineLabel.text = [self LZ_formatPeso:current[LZAPIFieldLoanAmount]];

    for (UIView *v in self.amountsContainer.subviews) [v removeFromSuperview];
    if (details.count == 0) {
        [self.amountsContainerHeightConstraint setOffset:0];
        return;
    }
    NSInteger columns = 3;
    CGFloat btnW = [self LZ_amountButtonWidth];
    for (NSInteger index = 0; index < details.count; index++) {
        NSString *title = [self LZ_formatPeso:details[index][LZAPIFieldLoanAmount]];
        BOOL selected = index == self.selectedAmountIndex;
        UIButton *btn = [self LZ_amountButtonWithTitle:title selected:selected tag:index];
        [self.amountsContainer addSubview:btn];
        NSInteger row = index / columns;
        NSInteger col = index % columns;
        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.amountsContainer).offset(col * (btnW + 10.0));
            make.top.equalTo(self.amountsContainer).offset(row * (36.0 + 10.0));
            make.width.mas_equalTo(btnW);
            make.height.mas_equalTo(36.0);
        }];
    }
    NSInteger rows = MAX(1, (NSInteger)ceil((double)details.count / (double)columns));
    CGFloat height = rows * 36.0 + (rows - 1) * 10.0;
    [self.amountsContainerHeightConstraint setOffset:height];
}

- (void)LZ_rebuildTermButtons {
    NSArray *terms = [self LZ_currentTermList];
    self.selectedTermIndex = MIN(self.selectedTermIndex, MAX(0, (NSInteger)terms.count - 1));
    [self LZ_updateTermRowPresentation];
}

- (BOOL)LZ_canSelectTerm {
    return [self LZ_currentTermList].count > 1;
}

- (void)LZ_updateTermRowPresentation {
    BOOL canSelect = [self LZ_canSelectTerm];
    NSString *title = canSelect ? @"Select the loan term" : @"Loan term";
    NSString *pillText = canSelect ? [self LZ_multiModeTermText] : [self LZ_singleModeTermText];

    self.multiTermTitleLabel.text = title;
    self.singleTermTitleLabel.text = title;
    self.multiTermPillLabel.text = pillText;
    self.termValueLabel.text = pillText;

    self.multiTermChevron.hidden = !canSelect;
    self.singleTermChevron.hidden = !canSelect;
    self.multiTermRow.userInteractionEnabled = canSelect;
    self.termRow.userInteractionEnabled = canSelect;
    [self.multiTermChevron mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(canSelect ? 14 : 0);
    }];
    [self.singleTermChevron mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(canSelect ? 14 : 0);
    }];
}

- (UIButton *)LZ_amountButtonWithTitle:(NSString *)title selected:(BOOL)selected tag:(NSInteger)tag {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.tag = kLZAmountButtonBaseTag + tag;
    [btn setTitle:title forState:UIControlStateNormal];
    [LoanZen_ColorUtils LZ_styleLoanAmountChipButton:btn selected:selected cornerRadius:8];
    [btn addTarget:self action:@selector(LZ_tapAmount:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)LZ_refreshTermPillStyle {
    [LoanZen_ColorUtils LZ_applyTermSelectionPillStyleToView:self.termValuePill];
    [LoanZen_ColorUtils LZ_applyTermSelectionPillStyleToView:self.multiTermPill];
}

- (void)LZ_rebuildDetailPairs {
    for (UIView *v in self.detailPairsStack.arrangedSubviews) {
        [self.detailPairsStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    NSDictionary *term = [self LZ_currentTermDetail];
    NSArray *pairs = @[
        @[@"Amount received", [self LZ_formatPeso:term[LZAPIFieldArrivalAmount]], @"The actual amount you receive is calculated by deducting the service fee from the loan amount."],
        @[@"Service fee", [self LZ_formatPeso:term[LZAPIFieldFeeAmount]], @"This is the fee charged by the financial institution for providing loan services."],
        @[@"Interest", [self LZ_formatPeso:term[@"interestAmount"]], @"Calculated based on your loan amount, loan term, and the interest rate of the current product."],
        @[@"Date of application", term[LZAPIFieldBorrowingDate] ?: @"—", @""],
        @[@"Due date", term[LZAPIFieldRepaymentDate] ?: @"—", @""],
    ];
    for (NSArray *pair in pairs) {
        NSString *tip = pair[2];
        [self.detailPairsStack addArrangedSubview:[self LZ_detailPairRowWithTitle:pair[0] value:pair[1] tipMessage:tip.length > 0 ? tip : nil]];
    }
}

- (UIView *)LZ_detailPairRowWithTitle:(NSString *)title value:(NSString *)value tipMessage:(NSString *)tipMessage {
    UIView *row = [[UIView alloc] init];
    [row mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(22); }];
    UIStackView *leftStack = [[UIStackView alloc] init];
    leftStack.axis = UILayoutConstraintAxisHorizontal;
    leftStack.spacing = 4;
    leftStack.alignment = UIStackViewAlignmentCenter;
    UILabel *left = [[UILabel alloc] init];
    left.text = title;
    left.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    left.textColor = [LoanZen_Color kycFormLabel];
    [leftStack addArrangedSubview:left];
    if (tipMessage.length > 0) {
        UIImageView *info = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:@"lz_loan_sm"]];
        info.contentMode = UIViewContentModeScaleAspectFit;
        info.userInteractionEnabled = YES;
        info.accessibilityHint = tipMessage;
        [info addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(LZ_tapFieldTip:)]];
        [info mas_makeConstraints:^(MASConstraintMaker *make) { make.width.height.mas_equalTo(14); }];
        [leftStack addArrangedSubview:info];
    }
    UILabel *right = [[UILabel alloc] init];
    right.text = value;
    right.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    right.textColor = [LoanZen_Color kycFormValue];
    right.textAlignment = NSTextAlignmentRight;
    [row addSubview:leftStack];
    [row addSubview:right];
    [leftStack mas_makeConstraints:^(MASConstraintMaker *make) { make.left.centerY.equalTo(row); }];
    [right mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.centerY.equalTo(row);
        make.left.greaterThanOrEqualTo(leftStack.mas_right).offset(12);
    }];
    return row;
}

- (void)LZ_tapFieldTip:(UITapGestureRecognizer *)gesture {
    NSString *message = gesture.view.accessibilityHint;
    if (message.length == 0) return;
    UIView *host = self.view.window ?: self.view;
    [LoanZen_PopupHelper LZ_showTapToDismissMessage:message onView:host];
}

- (UIView *)LZ_repaymentHeaderRow {
    UIView *row = [[UIView alloc] init];
    [row mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(18); }];
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
    [left mas_makeConstraints:^(MASConstraintMaker *make) { make.left.centerY.equalTo(row); }];
    [right mas_makeConstraints:^(MASConstraintMaker *make) { make.right.centerY.equalTo(row); }];
    return row;
}

- (UIView *)LZ_repaymentDataRowWithDueDate:(NSString *)dueDate amountDue:(NSString *)amountDue {
    UIView *row = [[UIView alloc] init];
    [row mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(36); }];
    UILabel *left = [[UILabel alloc] init];
    left.text = dueDate;
    left.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    left.textColor = [LoanZen_Color kycFormValue];
    UILabel *right = [[UILabel alloc] init];
    right.text = amountDue;
    right.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    right.textColor = [LoanZen_ColorUtils LZ_orderStatusSuccess];
    right.textAlignment = NSTextAlignmentRight;
    [row addSubview:left];
    [row addSubview:right];
    [left mas_makeConstraints:^(MASConstraintMaker *make) { make.left.centerY.equalTo(row); }];
    [right mas_makeConstraints:^(MASConstraintMaker *make) { make.right.centerY.equalTo(row); }];
    return row;
}

- (void)LZ_rebuildRepaymentRows {
    for (UIView *v in self.repaymentRowsStack.arrangedSubviews) {
        [self.repaymentRowsStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    NSArray *items = [self LZ_currentTermDetail][LZAPIFieldProductTermItemList];
    if (![items isKindOfClass:[NSArray class]]) items = @[];
    NSMutableArray<NSDictionary *> *normalized = [NSMutableArray array];
    for (NSDictionary *item in items) {
        if (![item isKindOfClass:[NSDictionary class]]) continue;
        NSString *due = item[LZAPIFieldExpirationDate] ?: @"";
        NSString *amount = item[LZAPIFieldRepaymentAmount] ?: @"";
        if (due.length == 0 && amount.length == 0) continue;
        NSString *displayAmount = [amount containsString:@"₱"] ? amount : [self LZ_formatPeso:amount];
        [normalized addObject:@{LZAPIFieldDueDate: due.length > 0 ? due : @"—", LZAPIFieldAmount: displayAmount}];
    }
    NSArray *rows = normalized;
    if (normalized.count > 1 && !self.isRepaymentExpanded) rows = @[normalized.firstObject];
    if (rows.count == 0) rows = @[@{LZAPIFieldDueDate: @"—", LZAPIFieldAmount: @"—"}];

    [self.repaymentRowsStack addArrangedSubview:[self LZ_repaymentHeaderRow]];
    for (NSDictionary *row in rows) {
        [self.repaymentRowsStack addArrangedSubview:[self LZ_repaymentDataRowWithDueDate:row[LZAPIFieldDueDate] amountDue:row[LZAPIFieldAmount]]];
    }
    self.repaymentToggleButton.hidden = normalized.count <= 1;
    [self.repaymentToggleButton setImage:[LoanZen_Asset imageNamed:self.isRepaymentExpanded ? @"lz_loan_sq" : @"lz_loan_zk"] forState:UIControlStateNormal];
    CGFloat rowsHeight = 18 + MAX(1, rows.count) * 36.0 + (rows.count > 0 ? 8 : 0);
    [self.repaymentCardHeightConstraint setOffset:rowsHeight + 48 + 10 + 34 + 14];
}

- (void)LZ_updateProductDetailMode {
    NSArray *details = [self LZ_sortedAmountDetails];
    BOOL isMultiAmount = details.count > 1;

    self.tipsLabel.hidden = !isMultiAmount;
    self.amountsContainer.hidden = !isMultiAmount;
    self.card1.hidden = !isMultiAmount;
    if (isMultiAmount) {
        [self.card1HeightConstraint uninstall];
        [self.card1BottomConstraint install];
    } else {
        [self.card1BottomConstraint uninstall];
        [self.card1HeightConstraint install];
    }
    self.multiTermRow.hidden = !isMultiAmount;
    self.multiTermDivider.hidden = !isMultiAmount;
    self.termRow.hidden = isMultiAmount;
    self.singleAmountBlock.hidden = isMultiAmount;

    [self LZ_placeProductIdentityMultiAmount:isMultiAmount];
    if (isMultiAmount) {
        [self.singleAmountBlockHeightConstraint install];
        [self.singleAmountBlockHeightConstraint setOffset:0];
    } else {
        [self.singleAmountBlockHeightConstraint uninstall];
    }
    if (!isMultiAmount) {
        [self.amountsContainerHeightConstraint setOffset:0];
    }
    [self.multiTermRowHeightConstraint setOffset:isMultiAmount ? 34 : 0];
    [self.multiTermDividerHeightConstraint setOffset:isMultiAmount ? 1 : 0];
    [self.termRowHeightConstraint setOffset:isMultiAmount ? 0 : 34];

    [self.card1TopConstraint uninstall];
    [self.card1 mas_updateConstraints:^(MASConstraintMaker *make) {
        if (isMultiAmount) {
            self.card1TopConstraint = make.top.equalTo(self.creditTipView.mas_bottom).offset(12);
        } else {
            self.card1TopConstraint = make.top.equalTo(self.singleAmountBlock.mas_bottom).offset(12);
        }
    }];

    [self.accountCardTopConstraint uninstall];
    [self.accountCard mas_updateConstraints:^(MASConstraintMaker *make) {
        if (isMultiAmount) {
            self.accountCardTopConstraint = make.top.equalTo(self.card1.mas_bottom).offset(12);
        } else {
            self.accountCardTopConstraint = make.top.equalTo(self.singleAmountBlock.mas_bottom).offset(12);
        }
    }];

    [self.detailContainerTopConstraint uninstall];
    [self.detailPairsTopConstraint uninstall];
    [self.detailContainer mas_updateConstraints:^(MASConstraintMaker *make) {
        if (isMultiAmount) {
            self.detailContainerTopConstraint = make.top.equalTo(self.multiTermDivider.mas_bottom).offset(12);
        } else {
            self.detailContainerTopConstraint = make.top.equalTo(self.termRow.mas_bottom).offset(12);
        }
    }];
    [self.detailPairsStack mas_updateConstraints:^(MASConstraintMaker *make) {
        self.detailPairsTopConstraint = make.top.equalTo(self.detailContainer);
    }];
    [self.view layoutIfNeeded];
}

#pragma mark - Actions

- (void)LZ_refreshAgreementCheck {
    NSString *imageName = self.agreementAccepted ? @"lz_dx_u" : @"lz_dx_n";
    UIImage *image = [LoanZen_Asset imageNamed:imageName];
    [self.agreementCheckButton setImage:image forState:UIControlStateNormal];
}

- (void)LZ_toggleAgreement {
    self.agreementAccepted = !self.agreementAccepted;
    [self LZ_refreshAgreementCheck];
}

- (void)LZ_toggleRepayment {
    self.isRepaymentExpanded = !self.isRepaymentExpanded;
    [self LZ_rebuildRepaymentRows];
}

- (NSString *)LZ_resolvedTermsURLString {
    return [LoanZen_AppConfigStore LZ_resolvedTermsURL];
}

- (void)LZ_openTermsDocument {
    NSString *url = [self LZ_resolvedTermsURLString];
    if (url.length == 0) {
        [LoanZen_HUD LZ_showError:@"Document link is not available yet. Please try again later."];
        return;
    }
    [self.navigationController pushViewController:[[LoanZen_WebDocumentViewController alloc] initWithURLString:url title:@"Terms of Loan"] animated:YES];
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    if ([URL.absoluteString isEqualToString:@"lz://terms"]) {
        [self LZ_openTermsDocument];
        return NO;
    }
    return YES;
}

- (void)LZ_handleBackTapped {
    if (self.isHandlingBack) return;
    self.isHandlingBack = YES;
    if (self.embeddedInKYCFlow) {
        [LoanZen_PopupHelper LZ_showConfirmOn:self title:@"Confirm to return?" message:@"Do you want to pause the authentication and return to the homepage?" confirmTitle:@"Confirm" cancelTitle:@"Cancel" onConfirm:^{
            [LoanZen_AppRouter LZ_showMainInterfaceInWindow:self.view.window];
        }];
        self.isHandlingBack = NO;
        return;
    }
    if (self.productId.length == 0) {
        [self.navigationController popViewControllerAnimated:YES];
        self.isHandlingBack = NO;
        return;
    }
    [self LZ_proceedToBackConfirmOrPop];
}

- (void)LZ_proceedToBackConfirmOrPop {
    if (!self.isViewLoaded || !self.view.window || ![self.navigationController.viewControllers containsObject:self]) {
        self.isHandlingBack = NO;
        return;
    }
    if (self.hasShownBackConfirm) {
        [self.navigationController popViewControllerAnimated:YES];
        self.isHandlingBack = NO;
        return;
    }
    __weak typeof(self) weakSelf = self;
    self.hasShownBackConfirm = YES;
    [LoanZen_PopupHelper LZ_showFrame:LoanZen_PopupFrameConfirmReturn on:self title:@"Confrm to return" message:@"It's a pity to leave. There is still a lot of loan credits waiting for you to withdraw, so think about it!" actions:@[
        @{@"title": @"Cancel", @"style": @(LoanZen_ModalActionStyleCancel), @"handler": ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            self.hasShownBackConfirm = NO;
            self.isHandlingBack = NO;
        }},
        @{@"title": @"Confirm", @"style": @(LoanZen_ModalActionStylePrimary), @"handler": ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            [self.navigationController popViewControllerAnimated:YES];
            self.isHandlingBack = NO;
        }},
    ]];
}

- (void)LZ_tapAmount:(UIButton *)sender {
    self.selectedAmountIndex = sender.tag - kLZAmountButtonBaseTag;
    self.selectedTermIndex = 0;
    self.isRepaymentExpanded = NO;
    [self LZ_rebuildAmountButtons];
    [self LZ_rebuildTermButtons];
    [self LZ_rebuildDetailPairs];
    [self LZ_rebuildRepaymentRows];
    [self LZ_updateProductDetailMode];
}

- (void)LZ_tapTermRow {
    NSArray *terms = [self LZ_currentTermList];
    if (terms.count <= 1) return;

    NSMutableArray<NSString *> *options = [NSMutableArray arrayWithCapacity:terms.count];
    for (NSDictionary *term in terms) {
        [options addObject:[self LZ_termOptionTitleFromTerm:term]];
    }

    __weak typeof(self) weakSelf = self;
    [LoanZen_PopupHelper LZ_showBottomPickerOn:self
                                         title:@"Select the loan term"
                                       options:options
                                 selectedIndex:self.selectedTermIndex
                                    onSelected:^(NSInteger index, NSString *value) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.selectedTermIndex = index;
        self.isRepaymentExpanded = NO;
        [self LZ_rebuildTermButtons];
        [self LZ_rebuildDetailPairs];
        [self LZ_rebuildRepaymentRows];
    }];
}

- (void)LZ_loadTerm {
    [LoanZen_ProductService LZ_fetchProductTermEnvelopeWithProductId:self.productId showLoading:YES completion:^(NSDictionary *json, NSError *error) {
        if (error) {
            [LoanZen_PopupHelper LZ_showFrame:LoanZen_PopupFrameError on:self title:@"Product term" message:error.localizedDescription actions:@[@{@"title": @"OK", @"style": @(LoanZen_ModalActionStylePrimary)}]];
            return;
        }
        BOOL handled = [LoanZen_TermBusinessHelper LZ_handleTermResponse:json controller:self productId:self.productId onSuccess:^(NSDictionary *data) {
            [self LZ_applyTermData:data];
        }];
        if (!handled) {
            NSString *msg = json[@"message"] ?: json[LZAPIResponseResultMsg];
            if (msg.length > 0) {
                [LoanZen_PopupHelper LZ_showFrame:LoanZen_PopupFrameError on:self title:@"Product term" message:msg actions:@[@{@"title": @"OK", @"style": @(LoanZen_ModalActionStylePrimary)}]];
            }
        }
    }];
}

- (NSString *)LZ_accountNoTextForBankAccount:(NSDictionary *)acc {
    NSString *accountNo = acc[LZAPIFieldAccountNo];
    if ([accountNo isKindOfClass:[NSString class]] && accountNo.length > 0) return accountNo;
    NSString *encrypted = acc[@"accountNoEncrypt"];
    if ([encrypted isKindOfClass:[NSString class]] && encrypted.length > 0) return encrypted;
    return @"Bank account";
}

- (void)LZ_refreshSelectedBankUI {
    NSDictionary *selected = nil;
    for (NSDictionary *acc in self.payAccounts) {
        NSString *bindId = [NSString stringWithFormat:@"%@", acc[@"bankCardBindId"] ?: acc[@"recordId"] ?: @""];
        if ([bindId isEqualToString:self.selectedBankBindId ?: @""]) {
            selected = acc;
            break;
        }
    }
    if (selected) {
        self.accountValueLabel.text = [self LZ_accountNoTextForBankAccount:selected];
        self.accountValueLabel.textColor = [LoanZen_Color kycFormValue];
    } else if (self.payAccounts.count == 0) {
        self.accountValueLabel.text = @"Please add a receiving account";
        self.accountValueLabel.textColor = [LoanZen_Color kycFormPlaceholder];
    }
}

- (void)LZ_loadBanks {
    NSString *previousBindId = self.selectedBankBindId;
    [LoanZen_PayAccountService LZ_fetchPayAccountList:^(NSArray<NSDictionary *> *list, NSError *error) {
        self.payAccounts = list ?: @[];
        if (previousBindId.length > 0) {
            for (NSDictionary *acc in self.payAccounts) {
                NSString *bindId = [NSString stringWithFormat:@"%@", acc[@"bankCardBindId"] ?: acc[@"recordId"] ?: @""];
                if ([bindId isEqualToString:previousBindId]) {
                    self.selectedBankBindId = previousBindId;
                    [self LZ_refreshSelectedBankUI];
                    return;
                }
            }
        }
        self.selectedBankBindId = nil;
        for (NSDictionary *acc in self.payAccounts) {
            if ([acc[@"defaultFlag"] intValue] == 1 || [acc[@"defaultFlag"] isEqual:@"1"]) {
                self.selectedBankBindId = [NSString stringWithFormat:@"%@", acc[@"bankCardBindId"] ?: acc[@"recordId"] ?: @""];
                break;
            }
        }
        if (self.payAccounts.count > 0 && self.selectedBankBindId.length == 0) {
            NSDictionary *acc = self.payAccounts.firstObject;
            self.selectedBankBindId = [NSString stringWithFormat:@"%@", acc[@"bankCardBindId"] ?: acc[@"recordId"] ?: @""];
        }
        [self LZ_refreshSelectedBankUI];
    }];
}

- (void)LZ_openAddBankForm {
    LoanZen_BankFormViewController *form = [[LoanZen_BankFormViewController alloc] init];
    __weak typeof(self) weakSelf = self;
    form.onSubmissionSucceeded = ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        UINavigationController *nav = self.navigationController;
        if (nav && [nav.viewControllers containsObject:self]) {
            [nav popToViewController:self animated:YES];
        } else {
            [nav popViewControllerAnimated:YES];
        }
        [self LZ_loadBanks];
    };
    [self.navigationController pushViewController:form animated:YES];
}

- (void)LZ_tapBank {
    // 对齐 LoanBase 下单页：无卡直接去添加；有卡可自由切换；添加成功直接回本页，不进银行卡列表
    if (self.payAccounts.count == 0) {
        [self LZ_openAddBankForm];
        return;
    }
    NSMutableArray<NSString *> *titles = [NSMutableArray array];
    for (NSDictionary *acc in self.payAccounts) {
        [titles addObject:[self LZ_accountNoTextForBankAccount:acc]];
    }
    [titles addObject:@"Add bank account"];

    NSInteger selectedIndex = 0;
    for (NSInteger i = 0; i < (NSInteger)self.payAccounts.count; i++) {
        NSDictionary *acc = self.payAccounts[i];
        NSString *bindId = [NSString stringWithFormat:@"%@", acc[@"bankCardBindId"] ?: acc[@"recordId"] ?: @""];
        if ([bindId isEqualToString:self.selectedBankBindId ?: @""]) {
            selectedIndex = i;
            break;
        }
    }

    __weak typeof(self) weakSelf = self;
    [LoanZen_PopupHelper LZ_showBottomPickerOn:self
                                         title:@"Bank Account"
                                       options:titles
                                 selectedIndex:selectedIndex
                                    onSelected:^(NSInteger index, NSString *value) {
        if (index >= (NSInteger)weakSelf.payAccounts.count) {
            [weakSelf LZ_openAddBankForm];
            return;
        }
        NSDictionary *acc = weakSelf.payAccounts[index];
        weakSelf.selectedBankBindId = [NSString stringWithFormat:@"%@", acc[@"bankCardBindId"] ?: acc[@"recordId"] ?: @""];
        [weakSelf LZ_refreshSelectedBankUI];
    }];
}

- (NSString *)LZ_selectedShowTerm {
    NSDictionary *term = [self LZ_currentTermDetail];
    id raw = term[LZAPIFieldShowTerm];
    if (raw == nil || raw == [NSNull null]) raw = term[LZAPIFieldLoanTerm];
    if (raw == nil || raw == [NSNull null]) return @"";
    return [NSString stringWithFormat:@"%@", raw];
}

- (void)LZ_submit {
    if (self.isSubmitting) return;
    if (!self.agreementAccepted) {
        [LoanZen_HUD LZ_showError:@"Please read and accept Terms of the Loan."];
        return;
    }
    if (self.selectedBankBindId.length == 0) {
        [LoanZen_HUD LZ_showError:@"Select receiving account"];
        return;
    }
    NSDictionary *item = [self LZ_currentAmountItem];
    NSString *amount = item[LZAPIFieldLoanAmount] ?: @"0";
    NSString *term = [self LZ_selectedShowTerm];
    BOOL forceMode = [LoanZen_AppConfigStore LZ_isStrongDataCollectionRequired];
    self.isSubmitting = YES;
    self.submitButton.enabled = NO;

    __weak typeof(self) weakSelf = self;
    [[LoanZen_LocationManager shared] LZ_requestLocationForOrderWithForceMode:forceMode presenter:self completion:^(NSString *longitude, NSString *latitude, BOOL shouldCancelOrder) {
        __strong typeof(self) self = weakSelf;
        if (!self) return;
        if (shouldCancelOrder) {
            self.isSubmitting = NO;
            self.submitButton.enabled = YES;
            return;
        }
        if (forceMode && [longitude isEqualToString:@"-360"] && [latitude isEqualToString:@"-360"]) {
            self.isSubmitting = NO;
            self.submitButton.enabled = YES;
            return;
        }
        [self LZ_showOrderSubmitMask];
        [LoanZen_ProductService LZ_submitOrderWithProductId:self.productId loanAmount:amount showTerm:term bankCardBindId:self.selectedBankBindId longitude:longitude latitude:latitude showLoading:NO completion:^(NSDictionary *data, NSError *error) {
            if (error) {
                self.orderSubmitMaskView.hidden = YES;
                self.isSubmitting = NO;
                self.submitButton.enabled = YES;
                [LoanZen_PopupHelper LZ_showFrame:LoanZen_PopupFrameError on:self title:@"Submit failed" message:error.localizedDescription actions:@[@{@"title": @"OK", @"style": @(LoanZen_ModalActionStylePrimary)}]];
                return;
            }
            [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventOrderApplySubmit];
            NSString *orderId = [NSString stringWithFormat:@"%@", data[LZAPIFieldOrderId] ?: @""];
            if (orderId.length == 0) {
                self.orderSubmitMaskView.hidden = YES;
                self.isSubmitting = NO;
                self.submitButton.enabled = YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:LZ_NotificationOrderListShouldRefresh object:nil];
                [LoanZen_PopupHelper LZ_showOrderApplySuccessOn:self onConfirm:^{
                    [self LZ_finishAfterOrderSuccess];
                }];
                return;
            }
            [LoanZen_OrderPostSubmitCoordinator LZ_processOrderId:orderId presenter:self maskView:self.orderSubmitMaskView completion:^(BOOL success, BOOL contactsBlocked) {
                self.orderSubmitMaskView.hidden = YES;
                self.isSubmitting = NO;
                self.submitButton.enabled = YES;
                if (success) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:LZ_NotificationOrderListShouldRefresh object:nil];
                    [LoanZen_PopupHelper LZ_showOrderApplySuccessOn:self onConfirm:^{
                        [self LZ_finishAfterOrderSuccess];
                    }];
                    return;
                }
                if (contactsBlocked) {
                    [self LZ_handleContactsCollectionBlocked];
                }
            }];
        }];
    }];
}

- (void)LZ_handleContactsCollectionBlocked {
    /// 系统弹窗点不允许、二次引导点去设置（或取消）后退出产品详情页，并刷新首页。
    [[NSNotificationCenter defaultCenter] postNotificationName:LZ_NotificationHomeShouldRefresh object:nil];
    [self LZ_exitAfterContactsBlocked];
}

- (void)LZ_exitAfterContactsBlocked {
    if (self.embeddedInKYCFlow) {
        [LoanZen_AppRouter LZ_showMainInterfaceInWindow:self.view.window];
        return;
    }
    if (self.navigationController && [self.navigationController.viewControllers containsObject:self]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)LZ_finishAfterOrderSuccess {
    if (self.embeddedInKYCFlow) {
        [[NSNotificationCenter defaultCenter] postNotificationName:LZ_NotificationHomeShouldRefresh object:nil];
        [LoanZen_AppRouter LZ_showMainInterfaceInWindow:self.view.window];
        return;
    }
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
