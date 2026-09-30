#import "LoanZen_KYCFourContactViewController.h"
#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_ScreenScaffoldView.h"
#import "LoanZen_KYCFourProgressView.h"
#import "LoanZen_KYCFourService.h"
#import "LoanZen_KYCFourFlowStore.h"
#import "LoanZen_KYCFourFlowNavigator.h"
#import "LoanZen_KYCItemHelper.h"
#import "LoanZen_PenRadioPickerViewController.h"
#import "LoanZen_PopupHelper.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_HUD.h"
#import "LoanZen_AppRouter.h"
#import "LoanZen_PhilippineMobile.h"
#import "LoanZen_BuryReporter.h"
#import <ContactsUI/ContactsUI.h>
@import Masonry;

@interface LoanZen_KYCFourContactViewController () <UITextFieldDelegate, CNContactPickerDelegate>
@property (nonatomic, strong) LoanZen_ScreenScaffoldView *scaffold;
@property (nonatomic, strong) LoanZen_KYCFourProgressView *progressView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *contentStack;
@property (nonatomic, strong) UIButton *continueButton;
@property (nonatomic, copy) NSArray<NSDictionary *> *searchItems;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UITextField *> *fieldBindings;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UIButton *> *selectorButtons;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *selectorValues;
@property (nonatomic, assign) NSInteger currentContactPickerSlot;
@end

@implementation LoanZen_KYCFourContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [LoanZen_Color background];
    self.fieldBindings = [NSMutableDictionary dictionary];
    self.selectorButtons = [NSMutableDictionary dictionary];
    self.selectorValues = [NSMutableDictionary dictionary];
    self.navigationController.navigationBarHidden = YES;

    self.scaffold = [[LoanZen_ScreenScaffoldView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.scaffold];
    [self.scaffold mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.view); }];
    [self.scaffold LZ_useKYCStyle];
    [self.scaffold LZ_setHeaderTitle:@"Emergency Contact"];
    __weak typeof(self) weakSelf = self;
    [self.scaffold LZ_setBackAction:^{ [weakSelf LZ_confirmExit]; }];

    self.progressView = [[LoanZen_KYCFourProgressView alloc] init];
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.contentStack = [[UIStackView alloc] init];
    self.contentStack.axis = UILayoutConstraintAxisVertical;
    self.contentStack.spacing = 12;

    [self.scaffold.contentView addSubview:self.progressView];
    [self.scaffold.contentView addSubview:self.scrollView];
    [self.scrollView addSubview:self.contentStack];

    UIView *bottomBar = [[UIView alloc] init];
    bottomBar.backgroundColor = [LoanZen_Color background];
    [self.view addSubview:bottomBar];
    self.continueButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.continueButton.backgroundColor = [LoanZen_Color accent];
    self.continueButton.layer.cornerRadius = 24;
    self.continueButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.continueButton setTitle:@"Continue" forState:UIControlStateNormal];
    [self.continueButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.continueButton.enabled = NO;
    [self.continueButton addTarget:self action:@selector(LZ_tapContinue) forControlEvents:UIControlEventTouchUpInside];
    [bottomBar addSubview:self.continueButton];

    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.scaffold.contentView).offset(16);
        make.left.right.equalTo(self.scaffold.contentView).inset(16);
    }];
    [bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.mas_equalTo(95);
    }];
    [self.continueButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(bottomBar).inset(16);
        make.top.equalTo(bottomBar).offset(13);
        make.height.mas_equalTo(48);
    }];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.progressView.mas_bottom).offset(16);
        make.left.right.equalTo(self.scaffold.contentView);
        make.bottom.equalTo(bottomBar.mas_top);
    }];
    [self.contentStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView).insets(UIEdgeInsetsMake(0, 16, 16, 16));
        make.width.equalTo(self.scrollView).offset(-32);
    }];

    if (LoanZen_KYCFourFlowStore.shared.currentStepNumber.integerValue == 3) {
        [self LZ_applyStepUI];
        NSArray *cached = LoanZen_KYCFourFlowStore.shared.searchItems;
        if (cached.count > 0) {
            self.searchItems = cached;
            [self LZ_rebuildContent];
        } else {
            [self LZ_fetchSearchItemsAfterStatus];
        }
    } else {
        [self LZ_refreshStatus];
    }
}

- (void)LZ_applyStepUI {
    self.progressView.currentStep = LoanZen_KYCFourFlowStore.shared.currentStepNumber ?: @3;
}

- (void)LZ_refreshStatus {
    self.continueButton.enabled = NO;
    [LoanZen_KYCFourService LZ_fetchFourStatusWithLoading:NO completion:^(NSNumber *step, NSError *error) {
        if (error) {
            [LoanZen_HUD LZ_showError:error.localizedDescription];
            return;
        }
        if (step.integerValue == -1) {
            [LoanZen_AppRouter LZ_showMainInterfaceInWindow:self.view.window];
            return;
        }
        if (step.integerValue != 3) {
            [LoanZen_KYCFourFlowNavigator LZ_syncNavigationToCurrentStepFrom:self animated:NO];
            return;
        }
        [self LZ_applyStepUI];
        [self LZ_fetchSearchItemsAfterStatus];
    }];
}

- (void)LZ_fetchSearchItemsAfterStatus {
    [LoanZen_KYCFourService LZ_fetchSearchItemsForStep:3 showLoading:NO completion:^(NSArray<NSDictionary *> *list, NSError *error) {
        if (error) {
            [LoanZen_HUD LZ_showError:error.localizedDescription];
            self.searchItems = @[];
        } else {
            self.searchItems = list ?: @[];
        }
        [self LZ_rebuildContent];
    }];
}

- (void)LZ_rebuildContent {
    for (UIView *view in self.contentStack.arrangedSubviews) {
        [self.contentStack removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    [self.fieldBindings removeAllObjects];
    [self.selectorButtons removeAllObjects];

    if (LoanZen_KYCFourFlowStore.shared.currentStepNumber.integerValue != 3) {
        self.continueButton.enabled = NO;
        return;
    }

    [self.contentStack addArrangedSubview:[self LZ_makeContactBlock:1]];
    [self.contentStack addArrangedSubview:[self LZ_makeContactBlock:2]];
    [self.contentStack addArrangedSubview:[self LZ_makeContactBlock:3]];
    [self.contentStack addArrangedSubview:[self LZ_makeEmailCard]];
    self.continueButton.enabled = YES;
}

- (UIView *)LZ_cardContainer {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [LoanZen_Color kycFormCardFill];
    card.layer.cornerRadius = 16;
    card.layer.borderWidth = 1;
    card.layer.borderColor = [LoanZen_Color kycFormCardBorder].CGColor;
    card.clipsToBounds = YES;
    return card;
}

- (UIView *)LZ_inputWrap {
    UIView *wrap = [[UIView alloc] init];
    wrap.backgroundColor = [LoanZen_Color kycFormInputFill];
    wrap.layer.cornerRadius = 10;
    wrap.layer.borderWidth = 1;
    wrap.layer.borderColor = [LoanZen_Color kycFormInputBorder].CGColor;
    wrap.clipsToBounds = YES;
    return wrap;
}

- (UILabel *)LZ_titleLabel:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    label.textColor = [LoanZen_Color kycFormLabel];
    label.text = text;
    return label;
}

- (UITextField *)LZ_textFieldWithCode:(NSString *)code placeholder:(NSString *)placeholder readOnly:(BOOL)readOnly {
    UITextField *field = [[UITextField alloc] init];
    field.borderStyle = UITextBorderStyleNone;
    field.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    field.textColor = [LoanZen_Color kycFormValue];
    field.autocorrectionType = UITextAutocorrectionTypeNo;
    field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field.accessibilityIdentifier = code;
    field.delegate = self;
    field.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder ?: @"Please enter" attributes:@{
        NSForegroundColorAttributeName: [LoanZen_Color kycFormPlaceholder],
        NSFontAttributeName: [UIFont systemFontOfSize:14 weight:UIFontWeightRegular],
    }];
    if (readOnly) {
        field.userInteractionEnabled = NO;
        field.tintColor = UIColor.clearColor;
    }
    if ([LoanZen_PhilippineMobile LZ_shouldApplyPhilippineMsisdnRulesForItemCode:code]) {
        field.keyboardType = UIKeyboardTypeNumberPad;
        if (!readOnly) {
            [field addTarget:self action:@selector(LZ_phoneFieldChanged:) forControlEvents:UIControlEventEditingChanged];
        }
    }
    if ([code isEqualToString:@"email"]) {
        field.keyboardType = UIKeyboardTypeEmailAddress;
        [field addTarget:self action:@selector(LZ_emailFieldDidEndEditing:) forControlEvents:UIControlEventEditingDidEnd];
    }
    self.fieldBindings[code] = field;
    return field;
}

- (UIButton *)LZ_selectorButtonWithCode:(NSString *)code {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    button.contentEdgeInsets = UIEdgeInsetsMake(0, 14, 0, 36);
    button.accessibilityIdentifier = code;
    [button setTitle:@"Please choose" forState:UIControlStateNormal];
    [button setTitleColor:[LoanZen_Color kycFormPlaceholder] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(LZ_tapSelector:) forControlEvents:UIControlEventTouchUpInside];
    self.selectorButtons[code] = button;
    return button;
}

- (UIView *)LZ_makeSelectorWrapWithCode:(NSString *)code {
    UIView *wrap = [self LZ_inputWrap];
    UIButton *button = [self LZ_selectorButtonWithCode:code];
    UIImage *chevron = [[LoanZen_Asset imageNamed:[LoanZen_Asset expandChevron]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *chevronView = [[UIImageView alloc] initWithImage:chevron ?: [UIImage systemImageNamed:@"chevron.down"]];
    chevronView.tintColor = [LoanZen_Color kycFormPlaceholder];
    chevronView.contentMode = UIViewContentModeScaleAspectFit;
    chevronView.userInteractionEnabled = NO;
    [wrap addSubview:button];
    [wrap addSubview:chevronView];
    [button mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(wrap); }];
    [chevronView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(wrap);
        make.right.equalTo(wrap).offset(-14);
        make.width.height.mas_equalTo(16);
    }];
    [wrap mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(48); }];
    return wrap;
}

- (UIView *)LZ_inlineInputRowWithTitle:(NSString *)title placeholder:(NSString *)placeholder code:(NSString *)code {
    UIView *row = [[UIView alloc] init];
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    label.textColor = [LoanZen_Color kycFormPlaceholder];
    label.text = title;
    [row addSubview:label];
    UITextField *field = [self LZ_textFieldWithCode:code placeholder:placeholder readOnly:YES];
    [row addSubview:field];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(row).offset(12);
        make.centerY.equalTo(row);
        make.width.mas_equalTo(44);
    }];
    [field mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(label.mas_right).offset(8);
        make.right.equalTo(row).offset(-10);
        make.centerY.equalTo(row);
    }];
    return row;
}

- (UIView *)LZ_makeNamePhoneComboForIndex:(NSInteger)index {
    NSString *nameCode = [self LZ_nameCodeForSlot:index];
    NSString *phoneCode = [self LZ_phoneCodeForSlot:index];

    UIStackView *row = [[UIStackView alloc] init];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.spacing = 8;
    row.alignment = UIStackViewAlignmentFill;

    UIView *left = [self LZ_inputWrap];
    [left mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(88); }];

    UIView *topRow = [self LZ_inlineInputRowWithTitle:@"Name" placeholder:@"Please choose" code:nameCode];
    UIView *divider = [[UIView alloc] init];
    divider.backgroundColor = [LoanZen_Color kycFormInputBorder];
    UIView *bottomRow = [self LZ_inlineInputRowWithTitle:@"Phone" placeholder:@"Please choose" code:phoneCode];
    [left addSubview:topRow];
    [left addSubview:divider];
    [left addSubview:bottomRow];
    [topRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.equalTo(left);
        make.height.mas_equalTo(44);
    }];
    [divider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(left).inset(10);
        make.top.equalTo(topRow.mas_bottom);
        make.height.mas_equalTo(1);
    }];
    [bottomRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(left);
        make.height.mas_equalTo(43);
    }];

    UIControl *topTap = [[UIControl alloc] init];
    [topTap addTarget:self action:@selector(LZ_tapContactArea:) forControlEvents:UIControlEventTouchUpInside];
    topTap.tag = index;
    [topRow addSubview:topTap];
    [topTap mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(topRow); }];

    UIControl *bottomTap = [[UIControl alloc] init];
    [bottomTap addTarget:self action:@selector(LZ_tapContactArea:) forControlEvents:UIControlEventTouchUpInside];
    bottomTap.tag = index;
    [bottomRow addSubview:bottomTap];
    [bottomTap mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(bottomRow); }];

    UIView *iconWrap = [self LZ_inputWrap];
    [iconWrap mas_makeConstraints:^(MASConstraintMaker *make) { make.width.height.mas_equalTo(88); }];
    UIImageView *icon = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:@"lz_jjlxr"]];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.tintColor = [LoanZen_Color accent];
    [iconWrap addSubview:icon];
    [icon mas_makeConstraints:^(MASConstraintMaker *make) { make.center.equalTo(iconWrap); make.width.height.mas_equalTo(18); }];
    UIControl *iconTap = [[UIControl alloc] init];
    iconTap.tag = index;
    [iconTap addTarget:self action:@selector(LZ_tapContactArea:) forControlEvents:UIControlEventTouchUpInside];
    [iconWrap addSubview:iconTap];
    [iconTap mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(iconWrap); }];

    [row addArrangedSubview:left];
    [row addArrangedSubview:iconWrap];
    return row;
}

- (UIView *)LZ_makeContactBlock:(NSInteger)index {
    UIView *card = [self LZ_cardContainer];
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 10;
    stack.layoutMargins = UIEdgeInsetsMake(14, 14, 14, 14);
    stack.layoutMarginsRelativeArrangement = YES;
    [card addSubview:stack];
    [stack mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(card); }];

    UILabel *title = [[UILabel alloc] init];
    title.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    title.textColor = [LoanZen_Color kycFormValue];
    title.text = [NSString stringWithFormat:@"Contact %02ld", (long)index];
    [stack addArrangedSubview:title];

    NSString *relationCode = index == 1 ? @"first_relation" : (index == 2 ? @"second_relation" : @"third_relation");
    [stack addArrangedSubview:[self LZ_titleLabel:@"Relationship"]];
    [stack addArrangedSubview:[self LZ_makeSelectorWrapWithCode:relationCode]];
    [stack addArrangedSubview:[self LZ_makeNamePhoneComboForIndex:index]];
    return card;
}

- (UIView *)LZ_makeEmailCard {
    UIView *card = [self LZ_cardContainer];
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 8;
    stack.layoutMargins = UIEdgeInsetsMake(14, 14, 14, 14);
    stack.layoutMarginsRelativeArrangement = YES;
    [card addSubview:stack];
    [stack mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(card); }];

    [stack addArrangedSubview:[self LZ_titleLabel:@"E-mail"]];
    UIView *wrap = [self LZ_inputWrap];
    UITextField *field = [self LZ_textFieldWithCode:@"email" placeholder:@"Please enter" readOnly:NO];
    [wrap addSubview:field];
    [field mas_makeConstraints:^(MASConstraintMaker *make) { make.left.right.equalTo(wrap).inset(14); make.centerY.equalTo(wrap); make.height.mas_equalTo(22); }];
    [wrap mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(48); }];
    [stack addArrangedSubview:wrap];
    return card;
}

- (NSString *)LZ_nameCodeForSlot:(NSInteger)slot {
    return slot == 1 ? @"first_name" : (slot == 2 ? @"second_name" : @"third_name");
}

- (NSString *)LZ_phoneCodeForSlot:(NSInteger)slot {
    return slot == 1 ? @"first_phone" : (slot == 2 ? @"second_phone" : @"third_phone");
}

- (void)LZ_tapContactArea:(UIControl *)sender {
    [self LZ_presentContactPickerForSlot:sender.tag];
}

- (void)LZ_presentContactPickerForSlot:(NSInteger)slot {
    CNContactPickerViewController *picker = [[CNContactPickerViewController alloc] init];
    picker.delegate = self;
    picker.displayedPropertyKeys = @[CNContactPhoneNumbersKey];
    picker.predicateForEnablingContact = [NSPredicate predicateWithFormat:@"phoneNumbers.@count > 0"];
    picker.predicateForSelectionOfContact = [NSPredicate predicateWithValue:NO];
    picker.predicateForSelectionOfProperty = [NSPredicate predicateWithFormat:@"key == %@", CNContactPhoneNumbersKey];
    picker.modalPresentationStyle = UIModalPresentationFormSheet;
    self.currentContactPickerSlot = slot;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContactProperty:(CNContactProperty *)contactProperty {
    NSInteger slot = self.currentContactPickerSlot;
    self.currentContactPickerSlot = 0;
    if (![contactProperty.key isEqualToString:CNContactPhoneNumbersKey]) return;
    CNPhoneNumber *phoneNumber = (CNPhoneNumber *)contactProperty.value;
    if (![phoneNumber isKindOfClass:[CNPhoneNumber class]]) return;
    CNContact *contact = contactProperty.contact;
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    if (contact.givenName.length > 0) [parts addObject:contact.givenName];
    if (contact.middleName.length > 0) [parts addObject:contact.middleName];
    if (contact.familyName.length > 0) [parts addObject:contact.familyName];
    NSString *fullName = [parts componentsJoinedByString:@" "];
    [self LZ_applyPickedContactName:fullName phone:phoneNumber.stringValue slot:slot];
}

- (void)contactPickerDidCancel:(CNContactPickerViewController *)picker {
    self.currentContactPickerSlot = 0;
}

- (void)LZ_applyPickedContactName:(NSString *)name phone:(NSString *)phone slot:(NSInteger)slot {
    NSString *nameCode = [self LZ_nameCodeForSlot:slot];
    NSString *phoneCode = [self LZ_phoneCodeForSlot:slot];
    NSString *trimmedName = [name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmedName.length == 0 || [trimmedName.lowercaseString isEqualToString:@"unnamed"]) {
        [LoanZen_HUD LZ_showError:[NSString stringWithFormat:@"Contact %ld - You can not leave your name section empty", (long)slot]];
        return;
    }
    NSDictionary *nameItem = [LoanZen_KYCItemHelper LZ_itemForCode:nameCode inItems:self.searchItems];
    NSString *namePattern = [nameItem[LZAPIFieldRegularExpression] isKindOfClass:[NSString class]] ? [nameItem[LZAPIFieldRegularExpression] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] : @"";
    if (namePattern.length > 0 && ![LoanZen_KYCItemHelper LZ_matchesRegex:trimmedName pattern:namePattern]) {
        [LoanZen_HUD LZ_showError:[NSString stringWithFormat:@"Contact %ld - Name format is incorrect", (long)slot]];
        return;
    }
    NSString *cleanedPhone = [LoanZen_PhilippineMobile LZ_cleanContactPhoneFromPicker:phone];
    if (cleanedPhone.length != 10 || ![cleanedPhone hasPrefix:@"9"]) {
        [LoanZen_HUD LZ_showError:[NSString stringWithFormat:@"Contact %ld - The contact phone number is invalid, please check", (long)slot]];
        return;
    }
    NSDictionary *phoneItem = [LoanZen_KYCItemHelper LZ_itemForCode:phoneCode inItems:self.searchItems];
    NSString *phonePattern = [phoneItem[LZAPIFieldRegularExpression] isKindOfClass:[NSString class]] ? [phoneItem[LZAPIFieldRegularExpression] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] : @"";
    if (phonePattern.length > 0 && ![LoanZen_KYCItemHelper LZ_matchesRegex:cleanedPhone pattern:phonePattern]) {
        [LoanZen_HUD LZ_showError:[NSString stringWithFormat:@"Contact %ld - The contact phone number is invalid, please check", (long)slot]];
        return;
    }
    if ([self LZ_isPhoneDuplicate:cleanedPhone excluding:phoneCode]) {
        [LoanZen_HUD LZ_showError:[NSString stringWithFormat:@"Contact %ld - The contact has been submitted, please enter another contact", (long)slot]];
        return;
    }
    self.fieldBindings[nameCode].text = trimmedName;
    self.fieldBindings[phoneCode].text = cleanedPhone;
}

- (void)LZ_tapSelector:(UIButton *)button {
    NSString *code = button.accessibilityIdentifier ?: @"";
    NSDictionary *item = [LoanZen_KYCItemHelper LZ_itemForCode:code inItems:self.searchItems];
    NSArray *pairs = [LoanZen_KYCItemHelper LZ_optionPairsFromItem:item ?: @{}];
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
    NSString *current = self.selectorValues[code] ?: @"";
    NSInteger selected = [values indexOfObject:current];
    if (selected == NSNotFound) selected = 0;
    __weak typeof(self) weakSelf = self;
    [LoanZen_PenRadioPickerViewController LZ_presentFrom:self
                                                   title:item[LZAPIFieldItemName] ?: @"Choose"
                                                 options:options
                                           selectedIndex:selected
                                               onConfirm:^(NSInteger index) {
        if (index < 0 || index >= values.count) return;
        weakSelf.selectorValues[code] = values[index];
        [button setTitle:options[index] forState:UIControlStateNormal];
        [button setTitleColor:[LoanZen_Color kycFormValue] forState:UIControlStateNormal];
        [weakSelf LZ_focusNextAfterSelectorCode:code];
    }];
}

- (NSInteger)LZ_contactSlotForRelationCode:(NSString *)code {
    if ([code isEqualToString:@"first_relation"]) return 1;
    if ([code isEqualToString:@"second_relation"]) return 2;
    if ([code isEqualToString:@"third_relation"]) return 3;
    return 0;
}

- (void)LZ_focusNextAfterSelectorCode:(NSString *)code {
    NSInteger slot = [self LZ_contactSlotForRelationCode:code];
    if (slot > 0) {
        NSString *nameCode = [self LZ_nameCodeForSlot:slot];
        UITextField *nameField = self.fieldBindings[nameCode];
        if (nameField) {
            CGRect rect = [nameField convertRect:nameField.bounds toView:self.scrollView];
            [self.scrollView scrollRectToVisible:CGRectInset(rect, 0, -24) animated:YES];
        }
        return;
    }
    UITextField *emailField = self.fieldBindings[@"email"];
    if (emailField) {
        CGRect rect = [emailField convertRect:emailField.bounds toView:self.scrollView];
        [self.scrollView scrollRectToVisible:CGRectInset(rect, 0, -24) animated:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [emailField becomeFirstResponder];
        });
    }
}

- (void)LZ_phoneFieldChanged:(UITextField *)field {
    NSString *sanitized = [LoanZen_PhilippineMobile LZ_sanitizeFieldDigits:field.text ?: @""];
    if (![sanitized isEqualToString:field.text ?: @""]) field.text = sanitized;
}

- (void)LZ_emailFieldDidEndEditing:(UITextField *)field {
    [self LZ_validateEmailFieldIfNeeded:YES];
}

- (nullable NSString *)LZ_valueForCode:(NSString *)code {
    NSString *selector = [self.selectorValues[code] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (selector.length > 0) return selector;
    NSString *text = [self.fieldBindings[code].text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return text.length > 0 ? text : nil;
}

- (nullable NSString *)LZ_phoneValueForCode:(NSString *)code {
    NSString *raw = [self LZ_valueForCode:code];
    if (raw.length == 0) return nil;
    if ([LoanZen_PhilippineMobile LZ_shouldApplyPhilippineMsisdnRulesForItemCode:code]) {
        NSString *cleaned = [LoanZen_PhilippineMobile LZ_cleanContactPhoneFromPicker:raw];
        if (cleaned.length == 10 && [cleaned hasPrefix:@"9"]) return cleaned;
        return [LoanZen_PhilippineMobile LZ_normalizedNational10ForAPI:raw];
    }
    return raw;
}

- (BOOL)LZ_isPhoneDuplicate:(NSString *)phone excluding:(NSString *)code {
    NSArray *codes = @[@"first_phone", @"second_phone", @"third_phone"];
    for (NSString *other in codes) {
        if ([other isEqualToString:code]) continue;
        NSString *otherPhone = [self LZ_phoneValueForCode:other];
        if (otherPhone.length > 0 && [otherPhone isEqualToString:phone]) return YES;
    }
    return NO;
}

- (BOOL)LZ_validateEmailFieldIfNeeded:(BOOL)showMessage {
    NSString *raw = [self LZ_valueForCode:@"email"];
    if (raw.length == 0) return YES;
    NSDictionary *item = [LoanZen_KYCItemHelper LZ_itemForCode:@"email" inItems:self.searchItems];
    NSString *fieldName = [item[LZAPIFieldItemName] isKindOfClass:[NSString class]] && [item[LZAPIFieldItemName] length] > 0 ? item[LZAPIFieldItemName] : @"E-mail";
    NSString *regex = [item[LZAPIFieldRegularExpression] isKindOfClass:[NSString class]] ? [item[LZAPIFieldRegularExpression] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] : @"";
    if (regex.length == 0) return YES;
    BOOL valid = [LoanZen_KYCItemHelper LZ_matchesRegex:raw pattern:regex];
    if (!valid && showMessage) {
        [LoanZen_HUD LZ_showError:[NSString stringWithFormat:@"%@ format is incorrect", fieldName]];
    }
    return valid;
}

- (NSInteger)LZ_emergencyContactIndexForCode:(NSString *)code {
    NSString *lower = code.lowercaseString;
    if ([lower hasPrefix:@"first_"]) return 1;
    if ([lower hasPrefix:@"second_"]) return 2;
    if ([lower hasPrefix:@"third_"]) return 3;
    return 1;
}

- (NSString *)LZ_cleanedEmergencyFieldTitle:(NSString *)rawTitle stripContactPrefix:(BOOL)stripContactPrefix {
    NSString *title = [rawTitle stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (title.length == 0) return @"Field";
    if (stripContactPrefix) {
        NSError *error = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"Contact\\s*\\d+"
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&error];
        if (regex) {
            title = [regex stringByReplacingMatchesInString:title
                                                      options:0
                                                        range:NSMakeRange(0, title.length)
                                                 withTemplate:@""];
            title = [title stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":- "]];
            title = [title stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        }
    }
    if (title.length == 0) {
        NSString *fallback = [rawTitle stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        return fallback.length > 0 ? fallback : @"Field";
    }
    return title;
}

- (void)LZ_showKYCValidationMessage:(NSString *)message {
    NSString *trimmed = [message stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventKYCValidationError
                                content:@"NULL"
                                 remark1:trimmed.length > 0 ? trimmed : @"NULL"
                                 remark2:@"NULL"
                                 remark3:@"NULL"];
    [LoanZen_HUD LZ_showError:message];
}

- (BOOL)LZ_validateBeforeSubmit {
    NSArray *codes = @[@"email", @"first_phone", @"first_name", @"first_relation", @"second_phone", @"second_name", @"second_relation", @"third_phone", @"third_name", @"third_relation"];
    for (NSString *code in codes) {
        NSDictionary *item = [LoanZen_KYCItemHelper LZ_itemForCode:code inItems:self.searchItems];
        NSString *codeLower = code.lowercaseString;
        BOOL isContactField = [codeLower hasPrefix:@"first_"] || [codeLower hasPrefix:@"second_"] || [codeLower hasPrefix:@"third_"];
        BOOL isName = isContactField && [codeLower containsString:@"name"] && ![codeLower containsString:@"relation"];
        BOOL isEmail = [codeLower isEqualToString:@"email"];
        BOOL isPhone = isContactField && ([codeLower containsString:LZAPIFieldPhone] || [codeLower containsString:@"tel"]);
        BOOL isRelation = isContactField && [codeLower containsString:@"relation"];

        NSString *rawStored = [self LZ_valueForCode:code] ?: @"";
        NSString *valueForRequired = isName ? [rawStored stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] : rawStored;
        NSString *itemNameCleaned = [self LZ_cleanedEmergencyFieldTitle:item[LZAPIFieldItemName] stripContactPrefix:YES];
        NSInteger itemType = item ? [item[LZAPIFieldItemType] integerValue] : 1;
        BOOL required = item ? [LoanZen_KYCItemHelper LZ_isRequiredForItem:item] : YES;

        if (required && valueForRequired.length == 0) {
            NSString *message = nil;
            if (isEmail) {
                message = [NSString stringWithFormat:@"Please enter %@", itemNameCleaned];
            } else if (isContactField && (isName || isPhone || isRelation)) {
                message = [NSString stringWithFormat:@"Please choose Contact %ld %@", (long)[self LZ_emergencyContactIndexForCode:code], itemNameCleaned];
            } else if (itemType == 1) {
                message = isContactField
                    ? [NSString stringWithFormat:@"Please enter Contact %ld %@", (long)[self LZ_emergencyContactIndexForCode:code], itemNameCleaned]
                    : [NSString stringWithFormat:@"Please enter %@", itemNameCleaned];
            } else {
                message = isContactField
                    ? [NSString stringWithFormat:@"Please choose Contact %ld %@", (long)[self LZ_emergencyContactIndexForCode:code], itemNameCleaned]
                    : [NSString stringWithFormat:@"Please choose %@", itemNameCleaned];
            }
            [self LZ_showKYCValidationMessage:message];
            return NO;
        }

        NSString *effective = rawStored;
        if (rawStored.length > 0 && [LoanZen_PhilippineMobile LZ_shouldApplyPhilippineMsisdnRulesForItemCode:code]) {
            NSString *normalized = [LoanZen_PhilippineMobile LZ_normalizedNational10ForAPI:rawStored];
            if (!normalized) {
                NSString *msg = isPhone
                    ? [NSString stringWithFormat:@"Contact %ld - The contact phone number is invalid, please check", (long)[self LZ_emergencyContactIndexForCode:code]]
                    : (isContactField
                        ? [NSString stringWithFormat:@"Contact %ld %@ format is incorrect", (long)[self LZ_emergencyContactIndexForCode:code], itemNameCleaned]
                        : [NSString stringWithFormat:@"%@ format is incorrect", itemNameCleaned]);
                [self LZ_showKYCValidationMessage:msg];
                return NO;
            }
            effective = normalized;
        }

        if (effective.length > 0) {
            NSString *pattern = [item[LZAPIFieldRegularExpression] isKindOfClass:[NSString class]]
                ? [item[LZAPIFieldRegularExpression] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]
                : @"";
            if (pattern.length > 0 && ![LoanZen_KYCItemHelper LZ_matchesRegex:effective pattern:pattern]) {
                NSString *msg = isPhone
                    ? [NSString stringWithFormat:@"Contact %ld - The contact phone number is invalid, please check", (long)[self LZ_emergencyContactIndexForCode:code]]
                    : (isContactField
                        ? [NSString stringWithFormat:@"Contact %ld %@ format is incorrect", (long)[self LZ_emergencyContactIndexForCode:code], itemNameCleaned]
                        : [NSString stringWithFormat:@"%@ format is incorrect", itemNameCleaned]);
                [self LZ_showKYCValidationMessage:msg];
                return NO;
            }
        }
    }

    if ([self LZ_isPhoneDuplicate:[self LZ_phoneValueForCode:@"first_phone"] ?: @"" excluding:@"first_phone"]) {
        [self LZ_showKYCValidationMessage:@"Contact 1 - The contact has been submitted, please enter another contact"];
        return NO;
    }
    if ([self LZ_isPhoneDuplicate:[self LZ_phoneValueForCode:@"second_phone"] ?: @"" excluding:@"second_phone"]) {
        [self LZ_showKYCValidationMessage:@"Contact 2 - The contact has been submitted, please enter another contact"];
        return NO;
    }
    if ([self LZ_isPhoneDuplicate:[self LZ_phoneValueForCode:@"third_phone"] ?: @"" excluding:@"third_phone"]) {
        [self LZ_showKYCValidationMessage:@"Contact 3 - The contact has been submitted, please enter another contact"];
        return NO;
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([textField.accessibilityIdentifier isEqualToString:@"email"]) {
        NSDictionary *item = [LoanZen_KYCItemHelper LZ_itemForCode:@"email" inItems:self.searchItems];
        NSInteger maxLength = [LoanZen_KYCItemHelper LZ_maxInputLengthForItem:item defaultLength:128];
        NSString *current = textField.text ?: @"";
        NSString *next = [current stringByReplacingCharactersInRange:range withString:string];
        return next.length <= maxLength;
    }
    return YES;
}

- (void)LZ_confirmExit {
    [LoanZen_KYCFourFlowNavigator LZ_confirmExitFrom:self];
}

- (void)LZ_tapContinue {
    if (![self LZ_validateBeforeSubmit]) return;
    [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventKYCEmergencySubmit];
    NSDictionary *payload = @{
        @"email": [self LZ_valueForCode:@"email"] ?: @"",
        @"first_phone": [self LZ_phoneValueForCode:@"first_phone"] ?: @"",
        @"first_name": [self LZ_valueForCode:@"first_name"] ?: @"",
        @"first_relation": [self LZ_valueForCode:@"first_relation"] ?: @"",
        @"second_phone": [self LZ_phoneValueForCode:@"second_phone"] ?: @"",
        @"second_name": [self LZ_valueForCode:@"second_name"] ?: @"",
        @"second_relation": [self LZ_valueForCode:@"second_relation"] ?: @"",
        @"third_phone": [self LZ_phoneValueForCode:@"third_phone"] ?: @"",
        @"third_name": [self LZ_valueForCode:@"third_name"] ?: @"",
        @"third_relation": [self LZ_valueForCode:@"third_relation"] ?: @"",
    };
    [LoanZen_KYCFourService LZ_submitStep:3 fields:payload completion:^(NSError *error) {
        if (error) { [LoanZen_HUD LZ_showError:error.localizedDescription]; return; }
        [LoanZen_KYCFourFlowNavigator LZ_advanceFrom:self pushNext:YES animated:YES];
    }];
}

@end
