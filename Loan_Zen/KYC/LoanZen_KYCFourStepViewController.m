#import "LoanZen_KYCFourStepViewController.h"
#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_ScreenScaffoldView.h"
#import "LoanZen_KYCFourProgressView.h"
#import "LoanZen_KYCFourFormCell.h"
#import "LoanZen_KYCFourService.h"
#import "LoanZen_KYCFourFlowStore.h"
#import "LoanZen_KYCFourFlowNavigator.h"
#import "LoanZen_KYCItemHelper.h"
#import "LoanZen_PopupHelper.h"
#import "LoanZen_PenRadioPickerViewController.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_HUD.h"
#import "LoanZen_BuryReporter.h"
#import "LoanZen_AppRouter.h"
#import "LoanZen_PhilippineMobile.h"
@import Masonry;

@interface LoanZen_KYCFourStepViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@property (nonatomic, assign) NSInteger step;
@property (nonatomic, strong) LoanZen_ScreenScaffoldView *scaffold;
@property (nonatomic, strong) LoanZen_KYCFourProgressView *progressView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *formCard;
@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UIButton *continueButton;
@property (nonatomic, copy) NSArray<NSDictionary *> *formRows;
@property (nonatomic, copy) NSArray<NSDictionary *> *searchItems;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *fieldValues;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *displayLabels;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UITextField *> *fieldBindings;
@property (nonatomic, copy) NSArray<NSDictionary *> *provinceOptionsCache;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSArray<NSDictionary *> *> *cityOptionsCache;
@property (nonatomic, assign) BOOL isFetchingProvince;
@property (nonatomic, copy) NSString *regionCountryId;
@property (nonatomic, assign) BOOL suppressAutoAdvanceFromText;
@property (nonatomic, copy, nullable) NSString *pendingTextAdvanceCode;
@end

@implementation LoanZen_KYCFourStepViewController

- (instancetype)initWithStep:(NSInteger)step {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _step = step;
        _fieldValues = [NSMutableDictionary dictionary];
        _displayLabels = [NSMutableDictionary dictionary];
        _fieldBindings = [NSMutableDictionary dictionary];
        _cityOptionsCache = [NSMutableDictionary dictionary];
        _regionCountryId = @"63";
    }
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
    [self.scaffold LZ_setHeaderTitle:[self LZ_titleForStep:self.step]];
    __weak typeof(self) weakSelf = self;
    [self.scaffold LZ_setBackAction:^{ [weakSelf LZ_confirmExit]; }];

    self.progressView = [[LoanZen_KYCFourProgressView alloc] init];
    [self.scaffold.contentView addSubview:self.progressView];

    self.bottomBar = [[UIView alloc] init];
    self.bottomBar.backgroundColor = [LoanZen_Color background];
    [self.view addSubview:self.bottomBar];

    self.continueButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.continueButton.backgroundColor = [LoanZen_Color accent];
    self.continueButton.layer.cornerRadius = 24;
    self.continueButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.continueButton setTitle:@"Continue" forState:UIControlStateNormal];
    [self.continueButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.continueButton.enabled = NO;
    [self.continueButton addTarget:self action:@selector(LZ_tapContinue) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.continueButton];

    self.formCard = [[UIView alloc] init];
    self.formCard.backgroundColor = [LoanZen_Color kycFormCardFill];
    self.formCard.layer.cornerRadius = 16;
    self.formCard.layer.borderWidth = 1;
    self.formCard.layer.borderColor = [LoanZen_Color kycFormCardBorder].CGColor;
    self.formCard.clipsToBounds = YES;
    [self.scaffold.contentView addSubview:self.formCard];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.scrollEnabled = YES;
    self.tableView.alwaysBounceVertical = YES;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.estimatedRowHeight = 120;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 8, 0);
    [self.tableView registerClass:[LoanZen_KYCFourFormTextCell class] forCellReuseIdentifier:LZ_KYCFourFormTextCellId];
    [self.tableView registerClass:[LoanZen_KYCFourFormSelectCell class] forCellReuseIdentifier:LZ_KYCFourFormSelectCellId];
    [self.formCard addSubview:self.tableView];

    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.scaffold.contentView).offset(16);
        make.left.right.equalTo(self.scaffold.contentView).inset(16);
    }];
    [self.bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.mas_equalTo(95);
    }];
    [self.continueButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.bottomBar).inset(16);
        make.top.equalTo(self.bottomBar).offset(13);
        make.height.mas_equalTo(48);
    }];
    [self.formCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.progressView.mas_bottom).offset(16);
        make.left.right.equalTo(self.scaffold.contentView).inset(16);
        make.bottom.equalTo(self.bottomBar.mas_top);
    }];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.formCard);
    }];

    if (LoanZen_KYCFourFlowStore.shared.currentStepNumber.integerValue == self.step) {
        [self LZ_applyStepUI];
        NSArray *cached = LoanZen_KYCFourFlowStore.shared.searchItems;
        if (cached.count > 0) {
            self.searchItems = cached;
            [self LZ_rebuildFormContent];
        } else {
            [self LZ_fetchSearchItemsAfterStatus];
        }
    } else {
        [self LZ_refreshStatus];
    }
}

- (NSString *)LZ_titleForStep:(NSInteger)step {
    switch (step) {
        case 1: return @"Personal Information";
        case 2: return @"Financial Information";
        default: return @"KYC";
    }
}

- (void)LZ_applyStepUI {
    self.progressView.currentStep = LoanZen_KYCFourFlowStore.shared.currentStepNumber ?: @(self.step);
    [self.scaffold LZ_setHeaderTitle:[self LZ_titleForStep:self.step]];
}

- (void)LZ_refreshStatus {
    self.continueButton.enabled = NO;
    [LoanZen_KYCFourService LZ_fetchFourStatusWithLoading:NO completion:^(NSNumber *step, NSError *error) {
        if (error) {
            [LoanZen_HUD LZ_showError:error.localizedDescription];
            [self LZ_rebuildFormContent];
            return;
        }
        if (step.integerValue == -1) {
            [LoanZen_AppRouter LZ_showMainInterfaceInWindow:self.view.window];
            return;
        }
        if (step.integerValue != self.step) {
            [LoanZen_KYCFourFlowNavigator LZ_syncNavigationToCurrentStepFrom:self animated:NO];
            return;
        }
        [self LZ_applyStepUI];
        [self LZ_fetchSearchItemsAfterStatus];
    }];
}

- (void)LZ_fetchSearchItemsAfterStatus {
    [LoanZen_KYCFourService LZ_fetchSearchItemsForStep:self.step showLoading:NO completion:^(NSArray<NSDictionary *> *list, NSError *error) {
        if (error) {
            [LoanZen_HUD LZ_showError:error.localizedDescription];
            self.searchItems = @[];
        } else {
            self.searchItems = list ?: @[];
        }
        [self LZ_rebuildFormContent];
    }];
}

- (void)LZ_rebuildFormContent {
    if (LoanZen_KYCFourFlowStore.shared.currentStepNumber.integerValue != self.step) {
        self.continueButton.enabled = NO;
        self.formRows = @[];
        [self.tableView reloadData];
        return;
    }
    self.formRows = [LoanZen_KYCItemHelper LZ_buildFormRowsFromItems:self.searchItems];
    self.continueButton.enabled = self.formRows.count > 0;
    [self.fieldBindings removeAllObjects];
    [self.tableView reloadData];
}

- (void)LZ_confirmExit {
    [LoanZen_KYCFourFlowNavigator LZ_confirmExitFrom:self];
}

- (nullable NSString *)LZ_valueForCode:(NSString *)code {
    NSString *value = [self.fieldValues[code] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return value.length > 0 ? value : nil;
}

- (NSInteger)LZ_rowIndexForCode:(NSString *)code {
    for (NSInteger i = 0; i < (NSInteger)self.formRows.count; i++) {
        if ([self.formRows[i][LZKYCFormRowCodeKey] isEqualToString:code]) return i;
    }
    return NSNotFound;
}

- (void)LZ_reloadSelectRowForCode:(NSString *)code {
    NSInteger row = [self LZ_rowIndexForCode:code];
    if (row == NSNotFound) return;

    NSDictionary *rowModel = self.formRows[row];
    NSDictionary *item = rowModel[LZKYCFormRowItemKey];
    NSString *display = [LoanZen_KYCItemHelper LZ_displayTitleForSelectItem:item
                                                                        code:code
                                                                       value:self.fieldValues[code]
                                                                displayLabel:self.displayLabels[code]];
    NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
    LoanZen_KYCFourFormSelectCell *cell = [self.tableView cellForRowAtIndexPath:path];
    if ([cell isKindOfClass:[LoanZen_KYCFourFormSelectCell class]]) {
        [cell LZ_updateDisplayTitle:display];
        return;
    }
    [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
}

- (nullable NSString *)LZ_payloadValueForCode:(NSString *)code {
    NSString *raw = [self LZ_valueForCode:code];
    if (raw.length == 0) return @"";
    if ([LoanZen_PhilippineMobile LZ_shouldApplyPhilippineMsisdnRulesForItemCode:code]) {
        return [LoanZen_PhilippineMobile LZ_normalizedNational10ForAPI:raw] ?: raw;
    }
    return raw;
}

- (NSArray<NSString *> *)LZ_defaultValidationCodes {
    if (self.step == 2) {
        return @[@"work_type", @"company_work_years", @"income_amount_monthly", @"number_loans", @"total_borrowings", @"overdue_days", @"has_overdue"];
    }
    return @[@"province", @"city", @"address", @"zip_code", @"education", @"marital_status", @"child_count", @"live_type"];
}

- (NSArray<NSString *> *)LZ_validationCodes {
    NSMutableArray<NSString *> *codes = [NSMutableArray array];
    for (NSDictionary *row in self.formRows) {
        NSString *code = row[LZKYCFormRowCodeKey];
        if (code.length > 0) [codes addObject:code];
    }
    return codes.count > 0 ? codes.copy : [self LZ_defaultValidationCodes];
}

- (BOOL)LZ_validateBeforeSubmit {
    NSArray<NSDictionary *> *items = self.searchItems;
    for (NSString *code in [self LZ_validationCodes]) {
        NSDictionary *item = [LoanZen_KYCItemHelper LZ_itemForCode:code inItems:items];
        NSString *displayName = item[LZAPIFieldItemName];
        if (![displayName isKindOfClass:[NSString class]] || displayName.length == 0) displayName = @"Field";
        NSInteger itemType = item ? [item[LZAPIFieldItemType] integerValue] : 1;
        BOOL required = item ? [LoanZen_KYCItemHelper LZ_isRequiredForItem:item] : YES;
        NSString *value = [self LZ_valueForCode:code] ?: @"";
        if (required && value.length == 0) {
            [LoanZen_HUD LZ_showError:(itemType == 1 || itemType == 2) ? [NSString stringWithFormat:@"Please enter %@", displayName] : [NSString stringWithFormat:@"Please choose %@", displayName]];
            return NO;
        }
        NSString *effective = value;
        if (value.length > 0 && [LoanZen_PhilippineMobile LZ_shouldApplyPhilippineMsisdnRulesForItemCode:code]) {
            NSString *normalized = [LoanZen_PhilippineMobile LZ_normalizedNational10ForAPI:value];
            if (!normalized) {
                [LoanZen_HUD LZ_showError:[NSString stringWithFormat:@"%@ format is incorrect", displayName]];
                return NO;
            }
            effective = normalized;
        }
        if ((itemType == 1 || itemType == 2) && effective.length > 0) {
            NSString *pattern = [item[LZAPIFieldRegularExpression] isKindOfClass:[NSString class]] ? [item[LZAPIFieldRegularExpression] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] : @"";
            if (pattern.length > 0) {
                NSError *regexError = nil;
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&regexError];
                if (regex && [regex numberOfMatchesInString:effective options:0 range:NSMakeRange(0, effective.length)] == 0) {
                    [LoanZen_HUD LZ_showError:[NSString stringWithFormat:@"%@ format is incorrect", displayName]];
                    return NO;
                }
            }
        }
    }
    return YES;
}

- (NSDictionary *)LZ_buildSubmitPayload {
    if (self.step == 1) {
        return @{
            @"province": [self LZ_payloadValueForCode:@"province"] ?: @"",
            @"city": [self LZ_payloadValueForCode:@"city"] ?: @"",
            @"address": [self LZ_payloadValueForCode:@"address"] ?: @"",
            @"zip_code": [self LZ_payloadValueForCode:@"zip_code"] ?: @"",
            @"education": [self LZ_payloadValueForCode:@"education"] ?: @"",
            @"marital_status": [self LZ_payloadValueForCode:@"marital_status"] ?: @"",
            @"child_count": [self LZ_payloadValueForCode:@"child_count"] ?: @"",
            @"live_type": [self LZ_payloadValueForCode:@"live_type"] ?: @"",
        };
    }
    return @{
        @"work_type": [self LZ_payloadValueForCode:@"work_type"] ?: @"",
        @"company_work_years": [self LZ_payloadValueForCode:@"company_work_years"] ?: @"",
        @"income_amount_monthly": [self LZ_payloadValueForCode:@"income_amount_monthly"] ?: @"",
        @"number_loans": [self LZ_payloadValueForCode:@"number_loans"] ?: @"",
        @"total_borrowings": [self LZ_payloadValueForCode:@"total_borrowings"] ?: @"",
        @"overdue_days": [self LZ_payloadValueForCode:@"overdue_days"] ?: @"",
        @"has_overdue": [self LZ_payloadValueForCode:@"has_overdue"] ?: @"",
    };
}

- (void)LZ_tapContinue {
    self.suppressAutoAdvanceFromText = YES;
    self.pendingTextAdvanceCode = nil;
    [self.view endEditing:YES];

    if (self.searchItems.count == 0) {
        [LoanZen_HUD LZ_showError:@"No KYC items loaded. Please pull to refresh or try again later."];
        return;
    }
    if (![self LZ_validateBeforeSubmit]) return;
    [self LZ_trackSubmit];
    NSDictionary *payload = [self LZ_buildSubmitPayload];
    [LoanZen_KYCFourService LZ_submitStep:self.step fields:payload completion:^(NSError *error) {
        if (error) { [LoanZen_HUD LZ_showError:error.localizedDescription]; return; }
        [LoanZen_KYCFourFlowNavigator LZ_advanceFrom:self pushNext:NO animated:YES];
    }];
}

- (void)LZ_trackSubmit {
    if (self.step == 1) {
        [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventKYCPersonalSubmit];
    } else if (self.step == 2) {
        [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventKYCWorkSubmit];
    }
}

#pragma mark - Region pickers

- (void)LZ_fetchProvinceOptions:(void (^)(NSArray<NSDictionary *> *pairs))completion {
    if (self.provinceOptionsCache.count > 0) {
        completion(self.provinceOptionsCache);
        return;
    }
    if (self.isFetchingProvince) return;
    self.isFetchingProvince = YES;
    [LoanZen_KYCFourService LZ_fetchProvinceListWithCountryId:self.regionCountryId completion:^(NSArray<NSDictionary *> *pairs, NSError *error) {
        self.isFetchingProvince = NO;
        if (error) {
            [LoanZen_HUD LZ_showError:error.localizedDescription];
            completion(@[]);
            return;
        }
        self.provinceOptionsCache = pairs ?: @[];
        completion(self.provinceOptionsCache);
    }];
}

- (void)LZ_fetchCityOptionsForProvince:(NSString *)provinceId completion:(void (^)(NSArray<NSDictionary *> *pairs))completion {
    NSArray *cached = self.cityOptionsCache[provinceId];
    if (cached.count > 0) {
        completion(cached);
        return;
    }
    [LoanZen_KYCFourService LZ_fetchCityListWithCountryId:self.regionCountryId provinceId:provinceId completion:^(NSArray<NSDictionary *> *pairs, NSError *error) {
        if (error) {
            [LoanZen_HUD LZ_showError:error.localizedDescription];
            completion(@[]);
            return;
        }
        self.cityOptionsCache[provinceId] = pairs ?: @[];
        completion(pairs ?: @[]);
    }];
}

- (void)LZ_presentPickerWithItem:(NSDictionary *)item code:(NSString *)code pairs:(NSArray<NSDictionary *> *)pairs row:(NSInteger)row {
    NSMutableArray<NSString *> *options = [NSMutableArray array];
    NSMutableArray<NSString *> *values = [NSMutableArray array];
    for (NSDictionary *pair in pairs) {
        [options addObject:pair[@"label"] ?: @""];
        [values addObject:pair[@"value"] ?: @""];
    }
    if (options.count == 0) {
        [LoanZen_HUD LZ_showError:@"No options available yet."];
        return;
    }
    NSString *current = self.fieldValues[code] ?: @"";
    NSInteger selected = [values indexOfObject:current];
    if (selected == NSNotFound) selected = 0;
    __weak typeof(self) weakSelf = self;
    [LoanZen_PenRadioPickerViewController LZ_presentFrom:self
                                                   title:item[LZAPIFieldItemName] ?: @"Choose"
                                                 options:options
                                           selectedIndex:selected
                                               onConfirm:^(NSInteger index) {
        if (index < 0 || index >= values.count) return;
        weakSelf.fieldValues[code] = values[index];
        weakSelf.displayLabels[code] = options[index];
        if ([code isEqualToString:@"province"]) {
            weakSelf.fieldValues[@"city"] = nil;
            weakSelf.displayLabels[@"city"] = nil;
            [weakSelf LZ_reloadSelectRowForCode:@"province"];
            [weakSelf LZ_reloadSelectRowForCode:@"city"];
        } else {
            [weakSelf LZ_reloadSelectRowForCode:code];
        }
        [weakSelf LZ_focusNextFieldAfterCode:code];
    }];
}

- (BOOL)LZ_hasSelectedValueForCode:(NSString *)code {
    NSString *value = [self.fieldValues[code] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return value.length > 0;
}

- (void)LZ_focusNextFieldAfterCode:(NSString *)code {
    NSInteger row = [self LZ_rowIndexForCode:code];
    if (row == NSNotFound) return;

    for (NSInteger nextRow = row + 1; nextRow < (NSInteger)self.formRows.count; nextRow++) {
        NSDictionary *nextModel = self.formRows[nextRow];
        NSString *nextCode = nextModel[LZKYCFormRowCodeKey];
        NSString *nextKind = nextModel[LZKYCFormRowKindKey];

        /// 已选过的选择项跳过，不自动弹窗。
        if ([nextKind isEqualToString:LZKYCFormRowKindSelect] && [self LZ_hasSelectedValueForCode:nextCode]) {
            continue;
        }

        BOOL isLastRow = (nextRow == (NSInteger)self.formRows.count - 1);
        if (isLastRow || [nextKind isEqualToString:LZKYCFormRowKindText]) {
            UIEdgeInsets inset = self.tableView.contentInset;
            CGFloat minBottom = isLastRow ? 260.0 : 120.0;
            if (inset.bottom < minBottom) {
                inset.bottom = minBottom;
                self.tableView.contentInset = inset;
                self.tableView.verticalScrollIndicatorInsets = inset;
            }
        }

        NSIndexPath *path = [NSIndexPath indexPathForRow:nextRow inSection:0];
        [self.tableView layoutIfNeeded];
        UITableViewScrollPosition position = isLastRow ? UITableViewScrollPositionBottom : UITableViewScrollPositionMiddle;
        [self.tableView scrollToRowAtIndexPath:path atScrollPosition:position animated:YES];

        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.28 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf LZ_activateFocusAtRow:nextRow code:nextCode kind:nextKind retriesLeft:3];
        });
        return;
    }
}

- (void)LZ_activateFocusAtRow:(NSInteger)row code:(NSString *)code kind:(NSString *)kind retriesLeft:(NSInteger)retriesLeft {
    if (row < 0 || row >= (NSInteger)self.formRows.count) return;
    if ([kind isEqualToString:LZKYCFormRowKindSelect]) {
        if ([self LZ_hasSelectedValueForCode:code]) {
            [self LZ_focusNextFieldAfterCode:code];
            return;
        }
        [self.view endEditing:YES];
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self || self.presentedViewController) {
                if (retriesLeft > 0) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [weakSelf LZ_activateFocusAtRow:row code:code kind:kind retriesLeft:retriesLeft - 1];
                    });
                }
                return;
            }
            if ([self LZ_hasSelectedValueForCode:code]) {
                [self LZ_focusNextFieldAfterCode:code];
                return;
            }
            [self LZ_tapSelectAtRow:row];
        });
        return;
    }

    NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
    BOOL isLastRow = (row == (NSInteger)self.formRows.count - 1);
    UITableViewScrollPosition position = isLastRow ? UITableViewScrollPositionBottom : UITableViewScrollPositionMiddle;
    [self.tableView scrollToRowAtIndexPath:path atScrollPosition:position animated:NO];
    [self.tableView layoutIfNeeded];

    UITextField *field = nil;
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
    if ([cell isKindOfClass:[LoanZen_KYCFourFormTextCell class]]) {
        field = [(LoanZen_KYCFourFormTextCell *)cell inputField];
    }
    if (!field) field = self.fieldBindings[code];
    if (field.window == nil || !field.userInteractionEnabled) field = nil;

    if (field && [field becomeFirstResponder]) {
        /// 键盘弹出后再贴一次底部，避免最后一行被挡住。
        if (isLastRow) {
            __weak typeof(self) weakSelf = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.12 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) return;
                [self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            });
        }
        return;
    }

    if (retriesLeft <= 0) return;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.16 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf LZ_activateFocusAtRow:row code:code kind:kind retriesLeft:retriesLeft - 1];
    });
}

- (void)LZ_tapSelectForCode:(NSString *)code {
    NSInteger row = [self LZ_rowIndexForCode:code];
    if (row == NSNotFound) return;
    [self LZ_tapSelectAtRow:row];
}

- (void)LZ_tapSelectAtRow:(NSInteger)row {
    if (row >= self.formRows.count) return;
    NSDictionary *rowModel = self.formRows[row];
    NSDictionary *item = rowModel[LZKYCFormRowItemKey];
    NSString *code = rowModel[LZKYCFormRowCodeKey];
    NSArray *pairs = rowModel[LZKYCFormRowPairsKey];
    if ([code isEqualToString:@"province"]) {
        [self LZ_fetchProvinceOptions:^(NSArray<NSDictionary *> *loaded) {
            [self LZ_presentPickerWithItem:item code:code pairs:loaded row:row];
        }];
        return;
    }
    if ([code isEqualToString:@"city"]) {
        NSString *provinceId = [self.fieldValues[@"province"] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (provinceId.length == 0) {
            [LoanZen_HUD LZ_showError:@"Please choose Province of residence"];
            return;
        }
        [self LZ_fetchCityOptionsForProvince:provinceId completion:^(NSArray<NSDictionary *> *loaded) {
            [self LZ_presentPickerWithItem:item code:code pairs:loaded row:row];
        }];
        return;
    }
    [self LZ_presentPickerWithItem:item code:code pairs:pairs row:row];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.formRows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *rowModel = self.formRows[indexPath.row];
    NSDictionary *item = rowModel[LZKYCFormRowItemKey];
    NSString *code = rowModel[LZKYCFormRowCodeKey];
    BOOL isFirst = indexPath.row == 0;
    BOOL isLast = indexPath.row == self.formRows.count - 1;
    NSString *title = [LoanZen_KYCItemHelper LZ_fieldTitleForItem:item code:code];

    if ([rowModel[LZKYCFormRowKindKey] isEqualToString:LZKYCFormRowKindSelect]) {
        LoanZen_KYCFourFormSelectCell *cell = [tableView dequeueReusableCellWithIdentifier:LZ_KYCFourFormSelectCellId forIndexPath:indexPath];
        NSString *display = [LoanZen_KYCItemHelper LZ_displayTitleForSelectItem:item code:code value:self.fieldValues[code] displayLabel:self.displayLabels[code]];
        [cell LZ_configureWithTitle:title displayTitle:display isFirstRow:isFirst isLastRow:isLast];
        __weak typeof(self) weakSelf = self;
        cell.onTapChoose = ^{ [weakSelf LZ_tapSelectForCode:code]; };
        return cell;
    }

    LoanZen_KYCFourFormTextCell *cell = [tableView dequeueReusableCellWithIdentifier:LZ_KYCFourFormTextCellId forIndexPath:indexPath];
    NSString *text = self.fieldValues[code] ?: @"";
    [cell LZ_configureWithTitle:title placeholder:item[@"placeholder"] text:text isFirstRow:isFirst isLastRow:isLast];
    cell.inputField.accessibilityIdentifier = code;
    cell.inputField.delegate = self;
    BOOL hasNext = !isLast;
    BOOL nextIsSelect = NO;
    if (hasNext) {
        NSDictionary *nextModel = self.formRows[indexPath.row + 1];
        nextIsSelect = [nextModel[LZKYCFormRowKindKey] isEqualToString:LZKYCFormRowKindSelect];
    }
    if ([code isEqualToString:@"child_count"] || [code isEqualToString:@"zip_code"]) {
        cell.inputField.keyboardType = UIKeyboardTypeNumberPad;
    } else if ([item[LZAPIFieldItemType] integerValue] != 2 && [LoanZen_PhilippineMobile LZ_shouldApplyPhilippineMsisdnRulesForItemCode:code]) {
        cell.inputField.keyboardType = UIKeyboardTypeNumberPad;
    } else {
        cell.inputField.keyboardType = UIKeyboardTypeDefault;
    }
    cell.inputField.returnKeyType = hasNext ? UIReturnKeyNext : UIReturnKeyDone;
    cell.inputField.inputAccessoryView = nil;
    if (cell.inputField.keyboardType == UIKeyboardTypeNumberPad && hasNext) {
        cell.inputField.inputAccessoryView = [self LZ_numberPadAccessoryForCode:code nextIsSelect:nextIsSelect];
    }
    [cell.inputField removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [cell.inputField addTarget:self action:@selector(LZ_fieldChanged:) forControlEvents:UIControlEventEditingChanged];
    if ([LoanZen_PhilippineMobile LZ_shouldApplyPhilippineMsisdnRulesForItemCode:code]) {
        [cell.inputField addTarget:self action:@selector(LZ_phoneFieldChanged:) forControlEvents:UIControlEventEditingChanged];
    }
    self.fieldBindings[code] = cell.inputField;
    return cell;
}

- (UIView *)LZ_numberPadAccessoryForCode:(NSString *)code nextIsSelect:(BOOL)nextIsSelect {
    (void)nextIsSelect;
    UIToolbar *bar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 44)];
    bar.barStyle = UIBarStyleDefault;
    UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [nextButton setTitle:@"Next" forState:UIControlStateNormal];
    nextButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    nextButton.accessibilityIdentifier = code;
    [nextButton addTarget:self action:@selector(LZ_tapNumberPadNext:) forControlEvents:UIControlEventTouchUpInside];
    [nextButton sizeToFit];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *next = [[UIBarButtonItem alloc] initWithCustomView:nextButton];
    bar.items = @[flex, next];
    return bar;
}

- (void)LZ_tapNumberPadNext:(UIButton *)sender {
    NSString *code = sender.accessibilityIdentifier;
    if (code.length == 0) return;
    UITextField *field = self.fieldBindings[code];
    [self LZ_advanceFromTextFieldCode:code resignField:field];
}

- (void)LZ_fieldChanged:(UITextField *)field {
    NSString *code = field.accessibilityIdentifier;
    if (code.length) self.fieldValues[code] = field.text ?: @"";
}

- (void)LZ_phoneFieldChanged:(UITextField *)field {
    NSString *sanitized = [LoanZen_PhilippineMobile LZ_sanitizeFieldDigits:field.text ?: @""];
    if (![sanitized isEqualToString:field.text ?: @""]) field.text = sanitized;
    [self LZ_fieldChanged:field];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *code = textField.accessibilityIdentifier ?: @"";
    [self LZ_advanceFromTextFieldCode:code resignField:textField];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (self.suppressAutoAdvanceFromText) {
        self.suppressAutoAdvanceFromText = NO;
        return;
    }
    NSString *code = textField.accessibilityIdentifier ?: @"";
    if (code.length == 0) return;
    /// 仅当下一行为选择框时，失焦后自动弹出（覆盖数字键盘无 Return 的场景）。
    NSInteger row = [self LZ_rowIndexForCode:code];
    if (row == NSNotFound) return;
    NSInteger nextRow = row + 1;
    if (nextRow >= (NSInteger)self.formRows.count) return;
    if (![self.formRows[nextRow][LZKYCFormRowKindKey] isEqualToString:LZKYCFormRowKindSelect]) return;
    NSString *nextCode = self.formRows[nextRow][LZKYCFormRowCodeKey];
    if ([self LZ_hasSelectedValueForCode:nextCode]) return;

    self.pendingTextAdvanceCode = code;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (![self.pendingTextAdvanceCode isEqualToString:code]) return;
        self.pendingTextAdvanceCode = nil;
        if (self.presentedViewController) return;
        if (self.suppressAutoAdvanceFromText) return;
        UIView *first = [self LZ_findFirstResponderInView:self.view];
        if ([first isKindOfClass:[UITextField class]]) return;
        [self LZ_focusNextFieldAfterCode:code];
    });
}

- (void)LZ_advanceFromTextFieldCode:(NSString *)code resignField:(UITextField *)field {
    if (code.length == 0) return;
    self.pendingTextAdvanceCode = nil;
    self.suppressAutoAdvanceFromText = YES;
    [field resignFirstResponder];
    NSInteger row = [self LZ_rowIndexForCode:code];
    if (row == NSNotFound) return;
    NSInteger nextRow = row + 1;
    if (nextRow >= (NSInteger)self.formRows.count) return;
    [self LZ_focusNextFieldAfterCode:code];
}

- (UIView *)LZ_findFirstResponderInView:(UIView *)view {
    if (view.isFirstResponder) return view;
    for (UIView *sub in view.subviews) {
        UIView *found = [self LZ_findFirstResponderInView:sub];
        if (found) return found;
    }
    return nil;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *code = textField.accessibilityIdentifier ?: @"";
    if ([code isEqualToString:@"child_count"]) {
        NSCharacterSet *digits = [NSCharacterSet decimalDigitCharacterSet];
        if (string.length > 0 && [string rangeOfCharacterFromSet:[digits invertedSet]].location != NSNotFound) return NO;
        NSString *current = textField.text ?: @"";
        NSString *next = [current stringByReplacingCharactersInRange:range withString:string];
        return next.length <= 3;
    }
    if ([code isEqualToString:@"zip_code"]) {
        NSCharacterSet *digits = [NSCharacterSet decimalDigitCharacterSet];
        if (string.length > 0 && [string rangeOfCharacterFromSet:[digits invertedSet]].location != NSNotFound) return NO;
        NSString *current = textField.text ?: @"";
        NSString *next = [current stringByReplacingCharactersInRange:range withString:string];
        return next.length <= 16;
    }
    return YES;
}

@end
