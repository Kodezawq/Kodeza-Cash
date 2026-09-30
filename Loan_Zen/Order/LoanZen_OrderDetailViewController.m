#import "LoanZen_OrderDetailViewController.h"
#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_ScreenScaffoldView.h"
#import "LoanZen_OrderService.h"
#import "LoanZen_OrderDetailRootView.h"
#import "LoanZen_OrderWithdrawalRootView.h"
#import "LoanZen_OrderStatusPresentation.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_HUD.h"
#import "LoanZen_PopupHelper.h"
#import "LoanZen_WebDocumentViewController.h"
#import "LoanZen_Notifications.h"
#import "LoanZen_OrderPostSubmitCoordinator.h"
#import "LoanZen_OrderSubmitMaskView.h"
#import "LoanZen_PayAccountService.h"
#import "LoanZen_BankFormViewController.h"
#import "LoanZen_BankListViewController.h"
@import Masonry;

@interface LoanZen_OrderDetailViewController () <LoanZen_OrderWithdrawalRootViewDelegate>
@property (nonatomic, copy) NSString *orderId;
@property (nonatomic, copy) NSString *productId;
@property (nonatomic, assign) BOOL preferWithdrawal;
@property (nonatomic, strong) LoanZen_ScreenScaffoldView *scaffold;
@property (nonatomic, strong) LoanZen_OrderDetailRootView *detailRootView;
@property (nonatomic, strong) LoanZen_OrderWithdrawalRootView *withdrawRootView;
@property (nonatomic, copy) NSDictionary *withdrawData;
@property (nonatomic, copy) NSArray<NSDictionary *> *amountDetails;
@property (nonatomic, assign) NSInteger selectedAmountIndex;
@property (nonatomic, assign) NSInteger selectedTermIndex;
@property (nonatomic, copy) NSString *payAccountNumber;
@property (nonatomic, copy) NSString *displayPayAccountNumber;
@property (nonatomic, copy) NSString *detailPlainPayAccountNumber;
@property (nonatomic, copy) NSDictionary *lastBankCard;
@property (nonatomic, copy) NSString *orderBankBindId;
@property (nonatomic, assign) BOOL didAppearOnce;
@property (nonatomic, strong) LoanZen_OrderSubmitMaskView *orderSubmitMaskView;
@end

@implementation LoanZen_OrderDetailViewController

- (instancetype)initWithOrderId:(NSString *)orderId productId:(NSString *)productId {
    return [self initWithOrderId:orderId productId:productId preferWithdrawal:NO];
}

- (instancetype)initWithOrderId:(NSString *)orderId productId:(NSString *)productId preferWithdrawal:(BOOL)preferWithdrawal {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _orderId = orderId.copy;
        _productId = productId.copy;
        _preferWithdrawal = preferWithdrawal;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;

    self.scaffold = [[LoanZen_ScreenScaffoldView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.scaffold];
    [self.scaffold mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.view); }];
    [self.scaffold LZ_setHeaderTitle:@"Credit information"];
    __weak typeof(self) weakSelf = self;
    [self.scaffold LZ_setBackAction:^{ [weakSelf.navigationController popViewControllerAnimated:YES]; }];

    self.detailRootView = [[LoanZen_OrderDetailRootView alloc] init];
    self.withdrawRootView = [[LoanZen_OrderWithdrawalRootView alloc] init];
    self.withdrawRootView.delegate = self;
    self.withdrawRootView.hidden = YES;

    [self.scaffold.contentView addSubview:self.detailRootView];
    [self.scaffold.contentView addSubview:self.withdrawRootView];
    [self.detailRootView mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.scaffold.contentView); }];
    [self.withdrawRootView mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.scaffold.contentView); }];

    [self.detailRootView LZ_setRepayAction:^{ [weakSelf LZ_repay]; }];
    [self.detailRootView LZ_setDeferAction:^{ [weakSelf LZ_extension]; }];

    self.orderSubmitMaskView = [[LoanZen_OrderSubmitMaskView alloc] init];
    self.orderSubmitMaskView.hidden = YES;
    [self.view addSubview:self.orderSubmitMaskView];
    [self.orderSubmitMaskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    // mask 挂在当前页 view 最底层遮罩之上、各类弹窗（定位/通讯录/复借）之下
    [self.view insertSubview:self.orderSubmitMaskView aboveSubview:self.scaffold];

    [self LZ_loadDetail];
}

- (LoanZen_OrderSubmitMaskView *)LZ_orderSubmitMaskView {
    return self.orderSubmitMaskView;
}

- (void)LZ_showOrderSubmitMask {
    self.orderSubmitMaskView.hidden = NO;
    [self.view insertSubview:self.orderSubmitMaskView aboveSubview:self.scaffold];
}

- (void)LZ_hideOrderSubmitMask {
    self.orderSubmitMaskView.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.didAppearOnce) {
        [self LZ_loadDetail];
    }
    self.didAppearOnce = YES;
}

#pragma mark - Loading

- (void)LZ_loadDetail {
    [LoanZen_OrderService LZ_fetchOrderDetailWithOrderId:self.orderId productId:self.productId completion:^(NSDictionary *data, NSError *error) {
        if (error) {
            [LoanZen_PopupHelper LZ_showFrame:LoanZen_PopupFrameError on:self title:@"Order detail" message:error.localizedDescription actions:@[@{@"title": @"OK", @"style": @(LoanZen_ModalActionStylePrimary)}]];
            return;
        }
        NSDictionary *detail = [data[LZAPIFieldOrderDetail] isKindOfClass:[NSDictionary class]] ? data[LZAPIFieldOrderDetail] : data;
        NSDictionary *product = [data[LZAPIFieldProduct] isKindOfClass:[NSDictionary class]] ? data[LZAPIFieldProduct] : nil;
        NSDictionary *bankCard = [self LZ_bankCardFromOrderDetailData:data detail:detail];
        self.lastBankCard = bankCard;
        self.orderBankBindId = [self LZ_bindIdFromBankCard:bankCard];
        self.detailPlainPayAccountNumber = [self LZ_plainPayAccountNumberFromOrderDetailBankCard:bankCard];
        [self LZ_applyDisplayPayAccountFromBankCard:bankCard];
        [self LZ_syncOrderIdFromDetail:detail];
        [self LZ_syncProductIdFromDetail:detail product:product];

        NSInteger status = [detail[LZAPIFieldOrderStatus] intValue];
        if (status == 32 || self.preferWithdrawal) {
            [self LZ_loadWithdrawalDetail];
            return;
        }
        self.withdrawRootView.hidden = YES;
        self.detailRootView.hidden = NO;
        [self LZ_applyCreditDetail:detail product:product bankCard:bankCard message:data[@"message"]];
    }];
}

- (void)LZ_applyCreditDetail:(NSDictionary *)detail product:(NSDictionary *)product bankCard:(NSDictionary *)bankCard message:(NSString *)message {
    [self LZ_syncOrderIdFromDetail:detail];
    NSNumber *status = detail[LZAPIFieldOrderStatus];
    [self LZ_applyDisplayPayAccountFromBankCard:bankCard];

    BOOL showRepay = [LoanZen_OrderStatusPresentation LZ_showsRepayButtonForStatus:status];
    BOOL showDefer = [LoanZen_OrderStatusPresentation LZ_showsExtensionButtonForStatus:status ifExtension:[self LZ_stringFromValue:detail[LZAPIFieldIfExtension]]];
    [self.detailRootView LZ_setActionVisibilityShowRepay:showRepay showDefer:showDefer];

    NSString *primaryTitle = [LoanZen_OrderStatusPresentation LZ_primaryActionTitleForStatus:status];
    if (primaryTitle.length > 0) {
        __weak typeof(self) weakSelf = self;
        [self.detailRootView LZ_setPrimaryActionWithTitle:primaryTitle action:^{
            [weakSelf LZ_handlePrimaryActionForStatus:status.intValue];
        }];
    } else {
        [self.detailRootView LZ_setPrimaryActionWithTitle:nil action:nil];
    }

    NSString *productName = [self LZ_stringFromValue:product[LZAPIFieldProductName]] ?: [self LZ_stringFromValue:detail[LZAPIFieldProductName]] ?: @"—";
    NSString *loanAmount = [self LZ_formatPeso:detail[LZAPIFieldLoanAmount] fallback:@"—"];
    NSString *showTerm = [self LZ_stringFromValue:detail[LZAPIFieldShowTerm]] ?: [self LZ_stringFromValue:detail[LZAPIFieldLoanTerm]];
    NSString *loanTermText = showTerm.length > 0 ? [NSString stringWithFormat:@"%@ (Days)", showTerm] : @"—";
    NSString *scheduleDueDate = [self LZ_stringFromValue:detail[LZAPIFieldRepaymentDate]].length > 0 ? [self LZ_stringFromValue:detail[LZAPIFieldRepaymentDate]] : [self LZ_stringFromValue:detail[LZAPIFieldDueDate]] ?: @"—";
    NSString *scheduleAmountDue = [self LZ_formatPeso:[self LZ_resolvedShouldRepayAmountFromDetail:detail] fallback:@"—"];
    NSInteger statusCode = status.integerValue;
    BOOL isSettled = (statusCode == 40 || statusCode == 70 || statusCode == 71);
    NSArray *apiSchedule = [detail[LZAPIFieldProductTermItemList] isKindOfClass:[NSArray class]] ? detail[LZAPIFieldProductTermItemList] : nil;
    NSArray<NSDictionary *> *scheduleItems = @[];
    if (isSettled && apiSchedule.count == 0) {
        // 结清且接口未返回还款计划：不展示计划区
        scheduleItems = @[];
    } else {
        scheduleItems = [self LZ_scheduleItemsFromDetail:detail
                                        fallbackDueDate:scheduleDueDate
                                      fallbackAmountDue:scheduleAmountDue];
    }
    NSString *maskedCard = [self LZ_maskedCardNumber:self.displayPayAccountNumber];

    NSMutableArray<LoanZen_OrderDetailPenRow *> *rows = [NSMutableArray array];
    LoanZen_OrderDetailPenRow *termRow = [LoanZen_OrderDetailPenRow LZ_rowWithTitle:@"Loan term" value:loanTermText];
    termRow.valueIsAccentTerm = YES;
    [rows addObject:termRow];

    NSString *feeRaw = [self LZ_stringFromValue:detail[LZAPIFieldFeeAmount]];
    [rows addObject:[self LZ_infoRowWithTitle:@"Service fee"
                                        value:[self LZ_formatPeso:feeRaw fallback:@"—"]
                                          tip:@"This is the fee charged by the financial institution for providing loan services."]];

    NSString *interestRaw = [self LZ_stringFromValue:detail[LZAPIFieldTaxAmount]];
    if (interestRaw.length == 0) interestRaw = [self LZ_stringFromValue:detail[@"interestAmount"]];
    [rows addObject:[self LZ_infoRowWithTitle:@"Interest"
                                        value:[self LZ_formatPeso:interestRaw fallback:@"—"]
                                          tip:@"Calculated based on your loan amount, loan term, and the interest rate of the current product."]];

    NSString *receivedRaw = [self LZ_stringFromValue:detail[LZAPIFieldReceiptAmount]];
    if (receivedRaw.length == 0) receivedRaw = [self LZ_stringFromValue:detail[LZAPIFieldArrivalAmount]];
    [rows addObject:[self LZ_infoRowWithTitle:@"Amount received"
                                        value:[self LZ_formatPeso:receivedRaw fallback:@"—"]
                                          tip:@"The actual amount you receive is calculated by deducting the service fee from the loan amount."]];

    NSString *payoutDate = [self LZ_stringFromValue:detail[LZAPIFieldPayoutDate]];
    BOOL isDisbursed = payoutDate.length > 0;

    
    BOOL isRepaymentPhase = isDisbursed
        || statusCode == 60 || statusCode == 61 || statusCode == 63
        || statusCode == 70 || statusCode == 71;

    if (!isRepaymentPhase) {
        NSString *applyDate = [self LZ_stringFromValue:detail[LZAPIFieldApplyDate]];
        if (applyDate.length == 0) applyDate = [self LZ_stringFromValue:detail[LZAPIFieldBorrowingDate]];
        [rows addObject:[LoanZen_OrderDetailPenRow LZ_rowWithTitle:@"Date of application" value:applyDate.length > 0 ? applyDate : @"—"]];
    }

    NSString *dueDateValue = [self LZ_stringFromValue:detail[LZAPIFieldDueDate]];
    [rows addObject:[LoanZen_OrderDetailPenRow LZ_rowWithTitle:@"Due date" value:dueDateValue.length > 0 ? dueDateValue : @"—"]];

    if (isRepaymentPhase) {
        
        if (payoutDate.length > 0) {
            
            [rows addObject:[LoanZen_OrderDetailPenRow LZ_rowWithTitle:@"Payment date" value:payoutDate]];
        }

        NSString *penaltyRaw = [self LZ_stringFromValue:detail[LZAPIFieldPenaltyAmount]];
        if (penaltyRaw.length == 0) penaltyRaw = [self LZ_stringFromValue:detail[@"penalty_amount"]];
        if ([self LZ_hasPositiveAmount:penaltyRaw]) {
            [rows addObject:[LoanZen_OrderDetailPenRow LZ_rowWithTitle:@"Late charge"
                                                                value:[self LZ_formatPeso:penaltyRaw fallback:@"—"]]];
        }

        NSString *totalRaw = [self LZ_stringFromValue:detail[LZAPIFieldTotalRepaymentAmount]];
        if (totalRaw.length == 0) totalRaw = [self LZ_stringFromValue:detail[LZAPIFieldRepaymentAmount]];
        LoanZen_OrderDetailPenRow *total = [LoanZen_OrderDetailPenRow LZ_rowWithTitle:@"Total repayment"
                                                                               value:[self LZ_formatPeso:totalRaw fallback:@"—"]];
        total.valueIsSuccess = YES;
        [rows addObject:total];

        // c. reductionAmount：仅整数；无值不展示
        NSString *reductionRaw = [self LZ_stringFromValue:detail[LZAPIFieldReductionAmount]];
        BOOL hasReduction = [self LZ_hasPositiveAmount:reductionRaw];
        if (hasReduction) {
            LoanZen_OrderDetailPenRow *deduction = [LoanZen_OrderDetailPenRow LZ_rowWithTitle:@"Amount of deduction"
                                                                                       value:[self LZ_formatIntegerPeso:reductionRaw]];
            deduction.valueIsSuccess = YES;
            [rows addObject:deduction];
        }

        // d. alreadyRepaymentAmount：仅整数；无值不展示
        NSString *repaidRaw = [self LZ_stringFromValue:detail[LZAPIFieldAlreadyRepaymentAmount]];
        BOOL hasRepaid = [self LZ_hasPositiveAmount:repaidRaw];
        if (hasRepaid) {
            LoanZen_OrderDetailPenRow *repaid = [LoanZen_OrderDetailPenRow LZ_rowWithTitle:@"Amount repaid"
                                                                                    value:[self LZ_formatIntegerPeso:repaidRaw]];
            repaid.valueIsSuccess = YES;
            [rows addObject:repaid];
        }

        // e. 剩余未还：取接口 shouldRepaymentAmount；减免与已还都无值则不展示；仅整数
        if (hasReduction || hasRepaid) {
            NSString *dueRaw = [self LZ_stringFromValue:detail[LZAPIFieldShouldRepaymentAmount]];
            if (dueRaw.length == 0) dueRaw = @"0";
            LoanZen_OrderDetailPenRow *due = [LoanZen_OrderDetailPenRow LZ_rowWithTitle:@"Amount due"
                                                                                 value:[self LZ_formatIntegerPeso:dueRaw]];
            due.valueIsSuccess = YES;
            [rows addObject:due];
        }

        if (statusCode == 70) {
            NSString *repaymentDate = [self LZ_stringFromValue:detail[LZAPIFieldRepaymentDate]];
            if (repaymentDate.length > 0) {
                [rows addObject:[LoanZen_OrderDetailPenRow LZ_rowWithTitle:@"Repayment date" value:repaymentDate]];
            }
        }
    }

    NSString *tip = [LoanZen_OrderStatusPresentation LZ_bottomTipForStatus:status];
    if (tip.length == 0 && message.length > 0) tip = message;

    [self.detailRootView LZ_configureWithTipMessage:tip ?: @""
                                        productName:productName
                                         loanAmount:loanAmount
                                 statusBarImageName:[LoanZen_OrderStatusPresentation LZ_listStatusBarImageNameForStatus:status]
                                         detailRows:rows
                                      scheduleItems:scheduleItems
                                   maskedCardNumber:maskedCard];
}

- (NSArray<NSDictionary *> *)LZ_scheduleItemsFromDetail:(NSDictionary *)detail
                                        fallbackDueDate:(NSString *)fallbackDueDate
                                      fallbackAmountDue:(NSString *)fallbackAmountDue {
    NSArray *list = [detail[LZAPIFieldProductTermItemList] isKindOfClass:[NSArray class]] ? detail[LZAPIFieldProductTermItemList] : nil;
    if (list.count == 0) {
        return @[@{
            LZAPIFieldDueDate: fallbackDueDate.length > 0 ? fallbackDueDate : @"—",
            LZAPIFieldAmount: fallbackAmountDue.length > 0 ? fallbackAmountDue : @"—",
        }];
    }
    NSMutableArray<NSDictionary *> *items = [NSMutableArray array];
    for (NSDictionary *item in list) {
        if (![item isKindOfClass:[NSDictionary class]]) continue;
        NSString *due = [self LZ_stringFromValue:item[LZAPIFieldExpirationDate]];
        if (due.length == 0) due = [self LZ_stringFromValue:item[LZAPIFieldDueDate]];
        if (due.length == 0) due = [self LZ_stringFromValue:item[LZAPIFieldRepaymentDate]];
        if (due.length == 0) due = fallbackDueDate;
        NSString *rawAmount = [self LZ_stringFromValue:item[LZAPIFieldRepaymentAmount]];
        NSString *amount = rawAmount.length > 0
            ? [self LZ_formatPeso:rawAmount fallback:fallbackAmountDue]
            : (fallbackAmountDue.length > 0 ? fallbackAmountDue : @"—");
        [items addObject:@{
            LZAPIFieldDueDate: due.length > 0 ? due : @"—",
            LZAPIFieldAmount: amount.length > 0 ? amount : @"—",
        }];
    }
    if (items.count == 0) {
        return @[@{
            LZAPIFieldDueDate: fallbackDueDate.length > 0 ? fallbackDueDate : @"—",
            LZAPIFieldAmount: fallbackAmountDue.length > 0 ? fallbackAmountDue : @"—",
        }];
    }
    return items;
}

- (id)LZ_resolvedShouldRepayAmountFromDetail:(NSDictionary *)detail {
    NSString *should = [self LZ_stringFromValue:detail[LZAPIFieldShouldRepaymentAmount]];
    if (should.length > 0) return should;
    NSString *raw = [self LZ_stringFromValue:detail[LZAPIFieldRepaymentAmount]];
    return raw.length > 0 ? raw : detail[LZAPIFieldRepaymentAmount];
}

/// 仅整数金额（₱），用于减免/已还/剩余未还
- (NSString *)LZ_formatIntegerPeso:(id)raw {
    double amount = fabs([self LZ_amountNumber:[self LZ_stringFromValue:raw]]);
    long long integerAmount = llround(amount);
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    f.locale = [NSLocale localeWithLocaleIdentifier:@"en_PH"];
    f.maximumFractionDigits = 0;
    f.minimumFractionDigits = 0;
    NSString *formatted = [f stringFromNumber:@(integerAmount)] ?: [NSString stringWithFormat:@"%lld", integerAmount];
    return [NSString stringWithFormat:@"₱%@", formatted];
}

- (BOOL)LZ_hasPositiveAmount:(NSString *)raw {
    return [self LZ_amountNumber:raw] > 0;
}

- (double)LZ_amountNumber:(NSString *)raw {
    NSString *value = [[[raw ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]
                        stringByReplacingOccurrencesOfString:@"₱" withString:@""]
                       stringByReplacingOccurrencesOfString:@"," withString:@""];
    if (value.length == 0) return 0;
    return value.doubleValue;
}

- (LoanZen_OrderDetailPenRow *)LZ_infoRowWithTitle:(NSString *)title value:(NSString *)value tip:(NSString *)tip {
    LoanZen_OrderDetailPenRow *row = [LoanZen_OrderDetailPenRow LZ_rowWithTitle:title value:value];
    row.showsInfoGlyph = YES;
    row.tipMessage = tip;
    return row;
}

#pragma mark - Withdrawal

- (void)LZ_loadWithdrawalDetail {
    [LoanZen_OrderService LZ_fetchWithdrawalDetailWithOrderId:self.orderId productId:self.productId completion:^(NSDictionary *data, NSError *error) {
        if (error) {
            self.withdrawRootView.hidden = YES;
            self.detailRootView.hidden = NO;
            [LoanZen_HUD LZ_showError:error.localizedDescription];
            return;
        }
        self.withdrawData = data;
        self.amountDetails = [self LZ_sortedAmountDetailsFromList:[self LZ_normalizedAmountDetailsFromData:data]];
        self.selectedAmountIndex = 0;
        self.selectedTermIndex = 0;
        self.detailRootView.hidden = YES;
        self.withdrawRootView.hidden = NO;
        [self LZ_refreshWithdrawalUI];
    }];
}

- (NSDictionary *)LZ_currentAmountDetail {
    if (self.selectedAmountIndex < self.amountDetails.count) return self.amountDetails[self.selectedAmountIndex];
    return self.amountDetails.firstObject;
}

- (NSDictionary *)LZ_currentTermDetail {
    NSArray *terms = [self LZ_currentAmountDetail][LZAPIFieldTermDetailList];
    if ([terms isKindOfClass:[NSArray class]] && self.selectedTermIndex < terms.count) return terms[self.selectedTermIndex];
    return [terms isKindOfClass:[NSArray class]] ? terms.firstObject : nil;
}

- (void)LZ_refreshWithdrawalUI {
    NSDictionary *amountDetail = [self LZ_currentAmountDetail];
    NSDictionary *termDetail = [self LZ_currentTermDetail];
    NSMutableArray *schedule = [NSMutableArray array];
    for (NSDictionary *item in [termDetail[LZAPIFieldProductTermItemList] isKindOfClass:[NSArray class]] ? termDetail[LZAPIFieldProductTermItemList] : @[]) {
        [schedule addObject:@{
            LZAPIFieldDueDate: [self LZ_stringFromValue:item[LZAPIFieldExpirationDate]] ?: @"—",
            LZAPIFieldAmount: [self LZ_formatPeso:item[LZAPIFieldRepaymentAmount] fallback:@"—"],
        }];
    }
    NSString *termRaw = [self LZ_stringFromValue:termDetail[LZAPIFieldShowTerm]] ?: [self LZ_stringFromValue:termDetail[LZAPIFieldLoanTerm]];
    BOOL amountSelectable = self.amountDetails.count > 1;
    NSArray *terms = [amountDetail[LZAPIFieldTermDetailList] isKindOfClass:[NSArray class]] ? amountDetail[LZAPIFieldTermDetailList] : @[];
    BOOL termSelectable = terms.count > 1;
    NSString *termText = [self LZ_withdrawalTermDisplayText:termRaw selectable:termSelectable];
    NSMutableArray *amountOptions = [NSMutableArray array];
    for (NSDictionary *item in self.amountDetails) {
        NSString *amount = [self LZ_formatPeso:item[LZAPIFieldLoanAmount] fallback:nil];
        if (amount.length > 0) [amountOptions addObject:amount];
    }

    [self.withdrawRootView LZ_configureWithProductName:[self LZ_stringFromValue:self.withdrawData[LZAPIFieldProductName]] ?: @"—"
                                                amount:[self LZ_formatPeso:amountDetail[LZAPIFieldLoanAmount] fallback:@"—"]
                                                  term:termText
                                        amountReceived:[self LZ_formatPeso:termDetail[LZAPIFieldArrivalAmount] ?: termDetail[LZAPIFieldReceiptAmount] fallback:@"—"]
                                             serviceFee:[self LZ_formatPeso:termDetail[LZAPIFieldFeeAmount] fallback:@"—"]
                                               interest:[self LZ_formatPeso:termDetail[LZAPIFieldTaxAmount] ?: termDetail[@"interestAmount"] fallback:@"—"]
                                        applicationDate:[self LZ_stringFromValue:termDetail[LZAPIFieldBorrowingDate]] ?: [self LZ_stringFromValue:termDetail[LZAPIFieldApplyDate]] ?: @"—"
                                                dueDate:[self LZ_stringFromValue:termDetail[LZAPIFieldDueDate]].length > 0 ? [self LZ_stringFromValue:termDetail[LZAPIFieldDueDate]] : ([self LZ_stringFromValue:termDetail[LZAPIFieldRepaymentDate]].length > 0 ? [self LZ_stringFromValue:termDetail[LZAPIFieldRepaymentDate]] : @"—")
                                          scheduleItems:schedule
                                       maskedCardNumber:[self LZ_maskedCardNumber:self.displayPayAccountNumber]
                                       amountSelectable:amountSelectable
                                         termSelectable:termSelectable
                                          amountOptions:amountOptions
                                    selectedAmountIndex:self.selectedAmountIndex];
}

#pragma mark - LoanZen_OrderWithdrawalRootViewDelegate

- (void)LZ_withdrawalRootViewDidTapAmount:(UIView *)view {
    if (self.amountDetails.count > 1) return;
    NSMutableArray *options = [NSMutableArray array];
    for (NSDictionary *item in self.amountDetails) {
        NSString *amount = [self LZ_formatPeso:item[LZAPIFieldLoanAmount] fallback:nil];
        if (amount.length > 0) [options addObject:amount];
    }
    __weak typeof(self) weakSelf = self;
    [LoanZen_PopupHelper LZ_showBottomPickerOn:self title:@"Select Amount" options:options selectedIndex:self.selectedAmountIndex onSelected:^(NSInteger index, NSString *value) {
        weakSelf.selectedAmountIndex = index;
        weakSelf.selectedTermIndex = 0;
        [weakSelf LZ_refreshWithdrawalUI];
    }];
}

- (void)LZ_withdrawalRootView:(LoanZen_OrderWithdrawalRootView *)view didSelectAmountAtIndex:(NSInteger)index {
    self.selectedAmountIndex = index;
    self.selectedTermIndex = 0;
    [self LZ_refreshWithdrawalUI];
}

- (void)LZ_withdrawalRootViewDidTapTerm:(UIView *)view {
    NSArray *terms = [self LZ_currentAmountDetail][LZAPIFieldTermDetailList];
    NSMutableArray *options = [NSMutableArray array];
    for (NSDictionary *t in [terms isKindOfClass:[NSArray class]] ? terms : @[]) {
        NSString *raw = [self LZ_stringFromValue:t[LZAPIFieldShowTerm]] ?: [self LZ_stringFromValue:t[LZAPIFieldLoanTerm]];
        [options addObject:[self LZ_withdrawalTermDisplayText:raw selectable:YES]];
    }
    __weak typeof(self) weakSelf = self;
    [LoanZen_PopupHelper LZ_showBottomPickerOn:self title:@"Select Term" options:options selectedIndex:self.selectedTermIndex onSelected:^(NSInteger index, NSString *value) {
        weakSelf.selectedTermIndex = index;
        [weakSelf LZ_refreshWithdrawalUI];
    }];
}

- (void)LZ_withdrawalRootViewDidTapWithdraw:(UIView *)view {
    NSDictionary *amountDetail = [self LZ_currentAmountDetail];
    NSDictionary *termDetail = [self LZ_currentTermDetail];
    NSString *loanAmount = [self LZ_rawLoanAmountFromValue:amountDetail[LZAPIFieldLoanAmount]];
    NSString *loanTerm = [self LZ_withdrawalTermFromTermDetail:termDetail];
    if (self.orderId.length == 0) {
        [LoanZen_HUD LZ_showError:@"Order ID is missing, please try again."];
        return;
    }
    if (loanAmount.length == 0 || loanTerm.length == 0) {
        [LoanZen_HUD LZ_showError:@"Please select amount and term."];
        return;
    }
    [LoanZen_OrderService LZ_applyWithdrawalWithOrderId:self.orderId loanAmount:loanAmount loanTerm:loanTerm completion:^(NSError *error) {
        if (error) { [LoanZen_HUD LZ_showError:error.localizedDescription]; return; }
        [LoanZen_PopupHelper LZ_showFrame:LoanZen_PopupFrameSuccess on:self title:@"Success" message:@"Withdrawal is successful, the funds will be transferred to your bank account, please check." actions:@[
            @{@"title": @"Confirm", @"style": @(LoanZen_ModalActionStylePrimary), @"handler": ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:LZ_NotificationOrderListShouldRefresh object:nil];
                [self.navigationController popViewControllerAnimated:YES];
            }},
        ]];
    }];
}

#pragma mark - Actions

- (void)LZ_handlePrimaryActionForStatus:(NSInteger)status {
    if (status == 10) {
        NSString *orderId = self.orderId;
        if (orderId.length == 0) return;
        [self LZ_showOrderSubmitMask];
        __weak typeof(self) weakSelf = self;
        [LoanZen_OrderPostSubmitCoordinator LZ_processOrderId:orderId presenter:self maskView:self.orderSubmitMaskView completion:^(BOOL success, BOOL contactsBlocked) {
            __strong typeof(self) self = weakSelf;
            if (!self) return;
            [self LZ_hideOrderSubmitMask];
            if (success) {
                [[NSNotificationCenter defaultCenter] postNotificationName:LZ_NotificationOrderListShouldRefresh object:nil];
                [LoanZen_PopupHelper LZ_showOrderApplySuccessOn:self onConfirm:^{
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }];
                return;
            }
            if (contactsBlocked) {
                [[NSNotificationCenter defaultCenter] postNotificationName:LZ_NotificationOrderListShouldRefresh object:nil];
                [self.navigationController popViewControllerAnimated:YES];
            }
        }];
        return;
    }
    if (status == 36) {
        [self LZ_navigateToEditBankAccountForCurrentOrder];
    }
}

- (void)LZ_navigateToEditBankAccountForCurrentOrder {
    NSString *targetBindId = self.orderBankBindId;
    __weak typeof(self) weakSelf = self;
    [LoanZen_PayAccountService LZ_fetchPayAccountList:^(NSArray<NSDictionary *> *list, NSError *error) {
        __strong typeof(self) self = weakSelf;
        if (!self) return;
        if (error) {
            [LoanZen_HUD LZ_showError:error.localizedDescription];
            return;
        }
        NSDictionary *matched = nil;
        if (targetBindId.length > 0) {
            for (NSDictionary *acc in list ?: @[]) {
                NSString *bindId = [NSString stringWithFormat:@"%@", acc[@"bankCardBindId"] ?: acc[@"recordId"] ?: @""];
                if ([bindId isEqualToString:targetBindId]) {
                    matched = acc;
                    break;
                }
            }
        }
        if (matched) {
            [self.navigationController pushViewController:[[LoanZen_BankFormViewController alloc] initWithEditingAccount:matched] animated:YES];
        } else {
            [self.navigationController pushViewController:[[LoanZen_BankListViewController alloc] init] animated:YES];
        }
    }];
}

- (void)LZ_repay {
    if (self.orderId.length == 0) {
        [LoanZen_HUD LZ_showError:@"Order ID is missing, please try again."];
        return;
    }
    [LoanZen_OrderService LZ_repayConnectWithOrderId:self.orderId payAccountNumber:[self LZ_payAccountNumberForRepayAPI] completion:^(NSString *link, NSError *error) {
        if (error) { [LoanZen_HUD LZ_showError:error.localizedDescription]; return; }
        if (link.length == 0) { [LoanZen_HUD LZ_showError:@"Repay link unavailable"]; return; }
        [self.navigationController pushViewController:[[LoanZen_WebDocumentViewController alloc] initWithURLString:link title:@"Repayment"] animated:YES];
    }];
}

- (void)LZ_extension {
    if (self.orderId.length == 0) {
        [LoanZen_HUD LZ_showError:@"Order ID is missing, please try again."];
        return;
    }
    [LoanZen_OrderService LZ_repayExtensionWithOrderId:self.orderId payAccountNumber:[self LZ_payAccountNumberForRepayAPI] completion:^(NSString *link, NSError *error) {
        if (error) { [LoanZen_HUD LZ_showError:error.localizedDescription]; return; }
        if (link.length == 0) { [LoanZen_HUD LZ_showError:@"Extension link unavailable"]; return; }
        [self.navigationController pushViewController:[[LoanZen_WebDocumentViewController alloc] initWithURLString:link title:@"Deferment"] animated:YES];
    }];
}

#pragma mark - Bank card

- (NSDictionary *)LZ_bankCardFromOrderDetailData:(NSDictionary *)data detail:(NSDictionary *)detail {
    if ([data[LZAPIFieldBankCard] isKindOfClass:[NSDictionary class]]) return data[LZAPIFieldBankCard];
    if ([detail[LZAPIFieldBankCard] isKindOfClass:[NSDictionary class]]) return detail[LZAPIFieldBankCard];
    return nil;
}

/// 订单详情 bankCard.accountNo 明文（延期/还款入参；仅 accountNo，去空格）。
- (NSString *)LZ_plainPayAccountNumberFromOrderDetailBankCard:(NSDictionary *)bankCard {
    if (![bankCard isKindOfClass:[NSDictionary class]]) return @"";
    NSString *raw = [self LZ_stringFromValue:bankCard[LZAPIFieldAccountNo]];
    if (raw.length == 0) raw = [self LZ_stringFromValue:bankCard[@"account_no"]];
    raw = [[raw stringByReplacingOccurrencesOfString:@" " withString:@""]
           stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return raw.length > 0 ? raw : @"";
}

/// 订单详情 UI 展示卡号：优先 accountNoEncrypt（服务端脱敏），否则 accountNo。
- (NSString *)LZ_displayAccountNumberFromBankCard:(NSDictionary *)bankCard {
    if (![bankCard isKindOfClass:[NSDictionary class]]) return @"";
    NSString *encrypted = [self LZ_stringFromValue:bankCard[@"accountNoEncrypt"]];
    if (encrypted.length > 0) return encrypted;
    return [self LZ_stringFromValue:bankCard[LZAPIFieldAccountNo]];
}

- (NSString *)LZ_accountNoTextFromBankCard:(NSDictionary *)bankCard {
    return [self LZ_displayAccountNumberFromBankCard:bankCard];
}

/// 还款/展期入参：订单详情 bankCard.accountNo 明文。
- (NSString *)LZ_payAccountNumberForRepayAPI {
    return self.detailPlainPayAccountNumber ?: @"";
}

- (NSString *)LZ_bindIdFromBankCard:(NSDictionary *)bankCard {
    if (![bankCard isKindOfClass:[NSDictionary class]]) return @"";
    NSString *bindId = [self LZ_stringFromValue:bankCard[LZAPIFieldBindId]];
    if (bindId.length == 0) bindId = [self LZ_stringFromValue:bankCard[@"bankCardBindId"]];
    if (bindId.length == 0) bindId = [self LZ_stringFromValue:bankCard[@"recordId"]];
    return bindId;
}

- (void)LZ_applyDisplayPayAccountFromBankCard:(NSDictionary *)bankCard {
    NSString *display = [self LZ_displayAccountNumberFromBankCard:bankCard];
    if (display.length > 0) {
        self.displayPayAccountNumber = display;
    }
    NSString *plain = [self LZ_plainPayAccountNumberFromOrderDetailBankCard:bankCard];
    if (plain.length > 0) {
        self.payAccountNumber = plain;
        if (self.detailPlainPayAccountNumber.length == 0) {
            self.detailPlainPayAccountNumber = plain;
        }
    }
}

#pragma mark - Withdrawal data

- (NSArray<NSDictionary *> *)LZ_normalizedAmountDetailsFromData:(NSDictionary *)data {
    id raw = data[LZAPIFieldAmountDetailList];
    if ([raw isKindOfClass:[NSArray class]]) return raw;
    if ([raw isKindOfClass:[NSDictionary class]]) return [(NSDictionary *)raw allValues];
    return @[];
}

- (NSArray<NSDictionary *> *)LZ_sortedAmountDetailsFromList:(NSArray<NSDictionary *> *)list {
    return [list sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        double va = [self LZ_parseAmountValue:a[LZAPIFieldLoanAmount]];
        double vb = [self LZ_parseAmountValue:b[LZAPIFieldLoanAmount]];
        if (va == vb) return NSOrderedSame;
        return va > vb ? NSOrderedAscending : NSOrderedDescending;
    }];
}

- (double)LZ_parseAmountValue:(id)value {
    NSString *raw = [self LZ_stringFromValue:value];
    raw = [[raw stringByReplacingOccurrencesOfString:@"₱" withString:@""] stringByReplacingOccurrencesOfString:@"," withString:@""];
    return [raw doubleValue];
}

#pragma mark - Formatting

- (void)LZ_syncOrderIdFromDetail:(NSDictionary *)detail {
    if (![detail isKindOfClass:[NSDictionary class]]) return;
    NSString *resolved = [self LZ_stringFromValue:detail[LZAPIFieldOrderId]];
    if (resolved.length > 0) self.orderId = resolved;
}

- (void)LZ_syncProductIdFromDetail:(NSDictionary *)detail product:(NSDictionary *)product {
    if (self.productId.length > 0) return;
    NSString *resolved = [self LZ_stringFromValue:product[LZAPIFieldProductId]];
    if (resolved.length == 0) resolved = [self LZ_stringFromValue:detail[LZAPIFieldProductId]];
    if (resolved.length > 0) self.productId = resolved;
}

- (NSString *)LZ_rawLoanAmountFromValue:(id)value {
    NSString *raw = [self LZ_stringFromValue:value];
    raw = [[raw stringByReplacingOccurrencesOfString:@"₱" withString:@""] stringByReplacingOccurrencesOfString:@"," withString:@""];
    return [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)LZ_withdrawalTermFromTermDetail:(NSDictionary *)termDetail {
    if (![termDetail isKindOfClass:[NSDictionary class]]) return @"";
    NSString *loanTerm = [self LZ_stringFromValue:termDetail[LZAPIFieldLoanTerm]];
    if (loanTerm.length > 0 && loanTerm.integerValue != 0) return loanTerm;
    NSString *showTerm = [self LZ_stringFromValue:termDetail[LZAPIFieldShowTerm]];
    if (showTerm.length > 0 && showTerm.integerValue != 0) return showTerm;
    return @"";
}

- (NSString *)LZ_withdrawalTermDisplayText:(NSString *)raw selectable:(BOOL)selectable {
    if (raw.length == 0) return @"—";
    if ([raw rangeOfString:@"Day" options:NSCaseInsensitiveSearch].location != NSNotFound) return raw;
    if (selectable) return [NSString stringWithFormat:@"%@ Days", raw];
    return [NSString stringWithFormat:@"%@ (Days)", raw];
}

- (NSString *)LZ_stringFromValue:(id)value {
    if ([value isKindOfClass:[NSString class]]) return [(NSString *)value copy];
    if (value == nil || value == [NSNull null]) return @"";
    return [[value description] copy];
}

- (NSString *)LZ_formatPeso:(id)raw fallback:(NSString *)fallback {
    NSString *s = [[self LZ_stringFromValue:raw] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (s.length == 0) return fallback ?: @"—";
    NSString *normalized = [[s stringByReplacingOccurrencesOfString:@"₱" withString:@""] stringByReplacingOccurrencesOfString:@"," withString:@""];
    double amount = normalized.doubleValue;
    if (amount == 0 && ![normalized isEqualToString:@"0"]) {
        return [s hasPrefix:@"₱"] ? s : [NSString stringWithFormat:@"₱%@", s];
    }
    BOOL isInteger = fabs(round(amount) - amount) < 0.001;
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    f.locale = [NSLocale localeWithLocaleIdentifier:@"en_PH"];
    f.maximumFractionDigits = isInteger ? 0 : 2;
    f.minimumFractionDigits = 0;
    NSString *formatted = [f stringFromNumber:@(amount)] ?: normalized;
    return [NSString stringWithFormat:@"₱%@", formatted];
}

- (NSString *)LZ_maskedCardNumber:(NSString *)raw {
    NSString *s = [[self LZ_stringFromValue:raw] stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (s.length == 0) return @"—";
    if (s.length >= 8 && s.length % 2 == 0) {
        NSUInteger half = s.length / 2;
        if ([[s substringToIndex:half] isEqualToString:[s substringFromIndex:half]]) {
            s = [s substringToIndex:half];
        }
    }
    if ([s containsString:@"*"]) {
        NSMutableArray *parts = [NSMutableArray array];
        for (NSInteger i = 0; i < (NSInteger)s.length; i += 4) {
            [parts addObject:[s substringWithRange:NSMakeRange((NSUInteger)i, MIN(4, s.length - (NSUInteger)i))]];
        }
        return [parts componentsJoinedByString:@" "];
    }
    NSMutableArray *groups = [NSMutableArray array];
    for (NSInteger i = 0; i < (NSInteger)s.length; i += 4) {
        [groups addObject:[s substringWithRange:NSMakeRange((NSUInteger)i, MIN(4, s.length - (NSUInteger)i))]];
    }
    return [groups componentsJoinedByString:@" "];
}

@end
