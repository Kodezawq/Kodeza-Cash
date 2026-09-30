#import "LoanZen_BankFormViewController.h"
#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_ScreenScaffoldView.h"
#import "LoanZen_PayAccountService.h"
#import "LoanZen_UserService.h"
#import "LoanZen_SessionStore.h"
#import "LoanZen_SupHomeParser.h"
#import "LoanZen_PopupHelper.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_ColorUtils.h"
#import "LoanZen_HUD.h"
#import "LoanZen_KYCItemHelper.h"
@import Masonry;

static NSString *gLZCachedProfileName;
static const NSInteger kLZAccountNoDefaultMaxLength = 20;

static NSString *LZ_stringFromJSONValue(id value) {
    if (!value || value == [NSNull null]) return @"";
    if ([value isKindOfClass:[NSString class]]) {
        NSString *text = [(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        return [text isEqualToString:@"(null)"] ? @"" : text;
    }
    return [[value description] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static NSInteger LZ_maxLengthFromRegexPattern(NSString *pattern) {
    if (pattern.length == 0) return 0;
    NSError *error = nil;
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"\\{(\\d+)(?:,(\\d+))?\\}"
                                                                        options:0
                                                                          error:&error];
    if (error || !re) return 0;
    __block NSInteger maxLen = 0;
    [re enumerateMatchesInString:pattern
                         options:0
                           range:NSMakeRange(0, pattern.length)
                      usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        if (result.numberOfRanges < 2) return;
        NSRange firstRange = [result rangeAtIndex:1];
        if (firstRange.location == NSNotFound || NSMaxRange(firstRange) > pattern.length) return;
        NSString *first = [pattern substringWithRange:firstRange];
        NSString *second = @"";
        if (result.numberOfRanges >= 3) {
            NSRange secondRange = [result rangeAtIndex:2];
            if (secondRange.location != NSNotFound && NSMaxRange(secondRange) <= pattern.length) {
                second = [pattern substringWithRange:secondRange];
            }
        }
        NSInteger val = second.length > 0 ? second.integerValue : first.integerValue;
        if (val > maxLen) maxLen = val;
    }];
    return maxLen;
}

@interface LoanZen_BankFormViewController () <UITextFieldDelegate>
@property (nonatomic, copy, nullable) NSDictionary *editingAccount;
@property (nonatomic, strong) LoanZen_ScreenScaffoldView *scaffold;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UITextField *nameField;
@property (nonatomic, copy) NSString *holderName;
@property (nonatomic, strong) UITextField *accountTypeField;
@property (nonatomic, strong) UITextField *bankNameField;
@property (nonatomic, strong) UITextField *accountNoField;
@property (nonatomic, strong) UIButton *defaultCheckButton;
@property (nonatomic, strong) UIButton *submitButton;
@property (nonatomic, assign) BOOL isDefault;
@property (nonatomic, assign) BOOL payItemListLoaded;
@property (nonatomic, assign) BOOL isLoadingBankOptions;
@property (nonatomic, copy, nullable) NSString *selectedAccountTypeKey;
@property (nonatomic, copy, nullable) NSString *selectedBankKey;
@property (nonatomic, copy, nullable) NSDictionary *accountNoItem;
@property (nonatomic, assign) NSInteger accountNoMaxLength;
@property (nonatomic, copy) NSArray<NSDictionary *> *accountTypeOptions;
@property (nonatomic, copy) NSArray<NSDictionary *> *bankNameOptions;
@property (nonatomic, copy) NSArray<NSDictionary *> *bankNameFallbackOptions;
@end

@implementation LoanZen_BankFormViewController

- (instancetype)initWithEditingAccount:(NSDictionary *)account {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _editingAccount = account.copy;
        _isDefault = account ? [[account[@"defaultFlag"] description] isEqualToString:@"1"] : NO;
        _accountTypeOptions = @[];
        _bankNameOptions = @[];
        _bankNameFallbackOptions = @[];
        _accountNoMaxLength = kLZAccountNoDefaultMaxLength;
    }
    return self;
}

- (instancetype)init {
    return [self initWithEditingAccount:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;

    self.scaffold = [[LoanZen_ScreenScaffoldView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.scaffold];
    [self.scaffold mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.view); }];
    [self.scaffold LZ_useProfilePageStyle];
    [self.scaffold LZ_setHeaderTitle:self.editingAccount ? @"Change Bank Account" : @"Bank Account"];
    __weak typeof(self) weakSelf = self;
    [self.scaffold LZ_setBackAction:^{ [weakSelf.navigationController popViewControllerAnimated:YES]; }];

    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.scaffold.contentView addSubview:self.scrollView];

    self.nameField = [self LZ_makeFieldWithPlaceholder:@""];
    self.nameField.enabled = NO;
    self.accountTypeField = [self LZ_makeFieldWithPlaceholder:@"Please choose"];
    self.bankNameField = [self LZ_makeFieldWithPlaceholder:@"Please choose"];
    self.accountNoField = [self LZ_makeFieldWithPlaceholder:@"Please enter"];
    self.accountNoField.keyboardType = UIKeyboardTypeNumberPad;
    self.accountNoField.delegate = self;
    self.accountTypeField.enabled = NO;
    self.bankNameField.enabled = NO;

    UIStackView *formStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        [self LZ_fieldBlock:@"Name" field:self.nameField],
        [self LZ_fieldBlock:@"Account Type" field:self.accountTypeField showsChevron:YES tap:@selector(LZ_tapAccountType)],
        [self LZ_fieldBlock:@"Bank Name" field:self.bankNameField showsChevron:YES tap:@selector(LZ_tapBankName)],
        [self LZ_fieldBlock:@"Bank Account" field:self.accountNoField],
    ]];
    formStack.axis = UILayoutConstraintAxisVertical;
    formStack.spacing = 12;

    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.08];

    UIView *toggleCard = [[UIView alloc] init];
    toggleCard.backgroundColor = [LoanZen_Color kycFormInputFill];
    toggleCard.layer.cornerRadius = 12;
    toggleCard.layer.borderWidth = 1;
    toggleCard.layer.borderColor = [LoanZen_Color kycFormInputBorder].CGColor;
    toggleCard.clipsToBounds = YES;

    UIControl *toggleRow = [[UIControl alloc] init];
    [toggleRow addTarget:self action:@selector(LZ_toggleDefault) forControlEvents:UIControlEventTouchUpInside];

    self.defaultCheckButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.defaultCheckButton.userInteractionEnabled = NO;
    UILabel *defaultLabel = [[UILabel alloc] init];
    defaultLabel.text = @"Set as default receiving method";
    defaultLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    defaultLabel.textColor = [LoanZen_Color kycFormLabel];
    defaultLabel.numberOfLines = 0;
    [toggleRow addSubview:self.defaultCheckButton];
    [toggleRow addSubview:defaultLabel];
    [toggleCard addSubview:toggleRow];
    [self.defaultCheckButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(toggleRow).offset(14);
        make.centerY.equalTo(toggleRow);
        make.width.height.mas_equalTo(20);
    }];
    [defaultLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.defaultCheckButton.mas_right).offset(12);
        make.right.equalTo(toggleRow).offset(-14);
        make.top.bottom.equalTo(toggleRow).inset(14);
    }];
    [toggleRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(toggleCard);
    }];
    [separator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(1.0 / UIScreen.mainScreen.scale);
    }];
    [self LZ_refreshDefaultCheck];

    UIStackView *contentStack = [[UIStackView alloc] initWithArrangedSubviews:@[formStack, separator, toggleCard]];
    contentStack.axis = UILayoutConstraintAxisVertical;
    contentStack.spacing = 16;
    [self.scrollView addSubview:contentStack];
    [contentStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView).insets(UIEdgeInsetsMake(12, 16, 16, 16));
        make.width.equalTo(self.scrollView).offset(-32);
    }];

    self.submitButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.submitButton.backgroundColor = [LoanZen_Color accent];
    self.submitButton.layer.cornerRadius = 12;
    self.submitButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.submitButton setTitle:@"Submit" forState:UIControlStateNormal];
    [self.submitButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.submitButton addTarget:self action:@selector(LZ_save) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.submitButton];
    [self.submitButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view).inset(16);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-12);
        make.height.mas_equalTo(48);
    }];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.scaffold.contentView);
        make.bottom.equalTo(self.submitButton.mas_top).offset(-12);
    }];

    if (self.editingAccount) {
        self.holderName = LZ_stringFromJSONValue(self.editingAccount[LZAPIFieldAccountName]);
        self.nameField.text = self.holderName;
        self.accountNoField.text = [self LZ_digitsOnlyString:self.editingAccount[LZAPIFieldAccountNo]];
        self.selectedAccountTypeKey = LZ_stringFromJSONValue(self.editingAccount[LZAPIFieldAccountType]);
        self.selectedBankKey = LZ_stringFromJSONValue(self.editingAccount[LZAPIFieldBankCode]);
        NSString *accountTypeLabel = LZ_stringFromJSONValue(self.editingAccount[@"accountTypeName"]);
        if (accountTypeLabel.length == 0) {
            accountTypeLabel = self.selectedAccountTypeKey;
        }
        self.accountTypeField.text = accountTypeLabel;
        self.bankNameField.text = LZ_stringFromJSONValue(self.editingAccount[LZAPIFieldBankName]);
    } else {
        [self LZ_prefillProfileNameIfNeeded];
    }

    [self LZ_loadItemList];
}

- (void)LZ_applyHolderName:(NSString *)name {
    NSString *trimmed = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) return;
    self.holderName = trimmed;
    self.nameField.text = trimmed;
}

- (void)LZ_prefillProfileNameIfNeeded {
    NSString *cached = [gLZCachedProfileName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (cached.length > 0) {
        [self LZ_applyHolderName:cached];
        return;
    }
    NSString *sessionName = [LoanZen_SessionStore.shared.userName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (sessionName.length > 0 && ![sessionName isEqualToString:@"User name"]) {
        [self LZ_applyHolderName:sessionName];
    }
    [LoanZen_UserService LZ_fetchUserInfoWithCompletion:^(NSDictionary *user, NSError *error) {
        NSString *name = [LoanZen_SupHomeParser LZ_displayNameFromData:user];
        if (name.length == 0) return;
        gLZCachedProfileName = name;
        if (self.editingAccount == nil && self.holderName.length == 0) {
            [self LZ_applyHolderName:name];
        }
    }];
}

- (UITextField *)LZ_makeFieldWithPlaceholder:(NSString *)placeholder {
    UITextField *field = [[UITextField alloc] init];
    field.placeholder = placeholder;
    field.backgroundColor = UIColor.clearColor;
    field.borderStyle = UITextBorderStyleNone;
    field.textColor = [LoanZen_Color kycFormValue];
    field.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    field.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder ?: @""
                                                                  attributes:@{NSForegroundColorAttributeName: [LoanZen_Color kycFormPlaceholder]}];
    field.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14, 1)];
    field.leftViewMode = UITextFieldViewModeAlways;
    return field;
}

- (UIView *)LZ_fieldBlock:(NSString *)title field:(UITextField *)field {
    return [self LZ_fieldBlock:title field:field showsChevron:NO tap:NULL];
}

- (UIView *)LZ_fieldBlock:(NSString *)title field:(UITextField *)field showsChevron:(BOOL)chevron tap:(SEL)tap {
    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    label.textColor = [LoanZen_Color kycFormLabel];

    UIView *shell = [[UIView alloc] init];
    shell.backgroundColor = [LoanZen_Color kycFormInputFill];
    shell.layer.cornerRadius = 10;
    shell.layer.borderWidth = 1;
    shell.layer.borderColor = [LoanZen_Color kycFormInputBorder].CGColor;
    shell.clipsToBounds = YES;
    [shell mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(44); }];

    [shell addSubview:field];
    [field mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(shell);
        make.right.equalTo(shell).offset(chevron ? -36 : 0);
    }];

    if (chevron) {
        UIImage *chevronImage = [[LoanZen_Asset imageNamed:[LoanZen_Asset expandChevron]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIImageView *arrow = [[UIImageView alloc] initWithImage:chevronImage ?: [UIImage systemImageNamed:@"chevron.down"]];
        arrow.tintColor = [LoanZen_Color kycFormPlaceholder];
        arrow.contentMode = UIViewContentModeScaleAspectFit;
        [shell addSubview:arrow];
        [arrow mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(shell).offset(-14);
            make.centerY.equalTo(shell);
            make.width.height.mas_equalTo(16);
        }];
        if (tap) {
            UIControl *tapControl = [[UIControl alloc] init];
            [tapControl addTarget:self action:tap forControlEvents:UIControlEventTouchUpInside];
            [shell addSubview:tapControl];
            [tapControl mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(shell); }];
        }
    }

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[label, shell]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 8;
    return stack;
}

- (void)LZ_refreshDefaultCheck {
    NSString *imageName = self.isDefault ? @"lz_dx_u" : @"lz_dx_n";
    UIImage *image = [LoanZen_Asset imageNamed:imageName];
    [self.defaultCheckButton setImage:image forState:UIControlStateNormal];
}

- (void)LZ_toggleDefault {
    self.isDefault = !self.isDefault;
    [self LZ_refreshDefaultCheck];
}

- (void)LZ_loadItemList {
    [LoanZen_PayAccountService LZ_fetchPayAccountItemListWithShowLoading:NO completion:^(NSArray<NSDictionary *> *items, NSError *error) {
        self.payItemListLoaded = YES;
        if (error) {
            [LoanZen_HUD LZ_showError:error.localizedDescription];
            return;
        }
        if (!items) return;
        NSArray *sorted = [LoanZen_KYCItemHelper LZ_sortedSearchItems:items];
        for (NSDictionary *item in sorted) {
            if (![item isKindOfClass:[NSDictionary class]]) continue;
            NSString *code = LZ_stringFromJSONValue([LoanZen_KYCItemHelper LZ_resolvedItemCodeForItem:item]);
            if ([code isEqualToString:@"account_no"]) {
                self.accountNoItem = item;
                [self LZ_refreshAccountNoInputRules];
            }
            if ([code isEqualToString:@"account_type"]) {
                NSArray *buttons = [item[LZAPIFieldButtonList] isKindOfClass:[NSArray class]] ? item[LZAPIFieldButtonList] : item[@"buttonList"];
                self.accountTypeOptions = [self LZ_optionsFromButtons:buttons];
            }
            if ([code isEqualToString:@"bank_name"]) {
                NSArray *buttons = [item[LZAPIFieldButtonList] isKindOfClass:[NSArray class]] ? item[LZAPIFieldButtonList] : item[@"buttonList"];
                self.bankNameFallbackOptions = [self LZ_optionsFromButtons:buttons];
            }
        }
        if (self.selectedAccountTypeKey.length > 0) {
            for (NSDictionary *opt in self.accountTypeOptions) {
                if ([LZ_stringFromJSONValue(opt[@"key"]) isEqualToString:self.selectedAccountTypeKey]) {
                    self.accountTypeField.text = LZ_stringFromJSONValue(opt[@"label"]);
                    break;
                }
            }
            [self LZ_loadBankOptionsForAccountType:self.selectedAccountTypeKey preselectKey:self.selectedBankKey];
        } else if (!self.editingAccount) {
            [self LZ_prefillProfileNameIfNeeded];
        }
    }];
}

- (void)LZ_refreshAccountNoInputRules {
    NSInteger fromItem = [LoanZen_KYCItemHelper LZ_maxInputLengthForItem:self.accountNoItem defaultLength:0];
    if (fromItem > 0) {
        self.accountNoMaxLength = fromItem;
        return;
    }
    NSString *pattern = [self.accountNoItem[LZAPIFieldRegularExpression] isKindOfClass:[NSString class]]
        ? [self.accountNoItem[LZAPIFieldRegularExpression] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
        : @"";
    NSInteger fromRegex = LZ_maxLengthFromRegexPattern(pattern);
    self.accountNoMaxLength = fromRegex > 0 ? fromRegex : kLZAccountNoDefaultMaxLength;
}

- (NSString *)LZ_digitsOnlyString:(id)raw {
    NSString *text = [raw isKindOfClass:[NSString class]] ? raw : [raw description];
    if (text.length == 0 || [text isEqualToString:@"(null)"]) return @"";
    NSMutableString *digits = [NSMutableString string];
    NSCharacterSet *set = [NSCharacterSet decimalDigitCharacterSet];
    for (NSUInteger i = 0; i < text.length; i++) {
        unichar c = [text characterAtIndex:i];
        if ([set characterIsMember:c]) {
            [digits appendFormat:@"%C", c];
        }
    }
    if (digits.length == 0) return @"";
    NSInteger maxLen = self.accountNoMaxLength > 0 ? self.accountNoMaxLength : kLZAccountNoDefaultMaxLength;
    if (digits.length > (NSUInteger)maxLen) {
        return [digits substringToIndex:(NSUInteger)maxLen];
    }
    return digits.copy;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField != self.accountNoField) return YES;
    if (string.length > 0) {
        NSCharacterSet *digits = [NSCharacterSet decimalDigitCharacterSet];
        if ([string rangeOfCharacterFromSet:[digits invertedSet]].location != NSNotFound) return NO;
    }
    NSString *current = textField.text ?: @"";
    NSString *next = [current stringByReplacingCharactersInRange:range withString:string];
    NSInteger maxLen = self.accountNoMaxLength > 0 ? self.accountNoMaxLength : kLZAccountNoDefaultMaxLength;
    return next.length <= (NSUInteger)maxLen;
}

- (NSArray<NSDictionary *> *)LZ_optionsFromButtons:(NSArray *)buttons {
    if (![buttons isKindOfClass:[NSArray class]]) return @[];
    NSMutableArray *result = [NSMutableArray array];
    for (NSDictionary *btn in buttons) {
        if (![btn isKindOfClass:[NSDictionary class]]) continue;
        NSString *key = LZ_stringFromJSONValue(btn[LZAPIFieldButtonKey]);
        if (key.length == 0) key = LZ_stringFromJSONValue(btn[@"buttonValue"]);
        if (key.length == 0) key = LZ_stringFromJSONValue(btn[@"buttonKey"]);
        NSString *label = LZ_stringFromJSONValue(btn[LZAPIFieldButtonLabel]);
        if (label.length == 0) label = LZ_stringFromJSONValue(btn[@"buttonLabel"]);
        if (key.length == 0) continue;
        [result addObject:@{@"key": key, @"label": label.length > 0 ? label : key}];
    }
    return result;
}

- (void)LZ_tapAccountType {
    if (self.accountTypeOptions.count == 0) {
        [LoanZen_HUD LZ_showError:@"No options available."];
        return;
    }
    NSArray *labels = [self.accountTypeOptions valueForKey:@"label"];
    __weak typeof(self) weakSelf = self;
    [LoanZen_PopupHelper LZ_showBottomPickerOn:self title:@"Account Type" options:labels onSelected:^(NSInteger index, NSString *value) {
        if (index >= weakSelf.accountTypeOptions.count) return;
        NSDictionary *opt = weakSelf.accountTypeOptions[index];
        weakSelf.selectedAccountTypeKey = opt[@"key"];
        weakSelf.accountTypeField.text = opt[@"label"];
        weakSelf.selectedBankKey = nil;
        weakSelf.bankNameField.text = nil;
        [weakSelf LZ_loadBankOptionsForAccountType:opt[@"key"] preselectKey:nil];
    }];
}

- (void)LZ_tapBankName {
    if (self.selectedAccountTypeKey.length == 0) {
        [LoanZen_HUD LZ_showError:@"Please choose Account Type first."];
        return;
    }
    if (self.isLoadingBankOptions) {
        [LoanZen_HUD LZ_showError:@"Loading bank options, please wait."];
        return;
    }
    if (self.bankNameOptions.count == 0) {
        [LoanZen_HUD LZ_showError:@"No bank options available."];
        return;
    }
    NSArray *labels = [self.bankNameOptions valueForKey:@"label"];
    __weak typeof(self) weakSelf = self;
    [LoanZen_PopupHelper LZ_showBottomPickerOn:self title:@"Bank Name" options:labels onSelected:^(NSInteger index, NSString *value) {
        if (index >= weakSelf.bankNameOptions.count) return;
        NSDictionary *opt = weakSelf.bankNameOptions[index];
        weakSelf.selectedBankKey = opt[@"key"];
        weakSelf.bankNameField.text = opt[@"label"];
    }];
}

- (BOOL)LZ_isWalletType:(NSString *)accountType {
    NSString *normalized = accountType.lowercaseString;
    return [normalized containsString:@"wallet"] || [normalized containsString:@"e-wallet"];
}

- (void)LZ_loadBankOptionsForAccountType:(NSString *)accountType preselectKey:(NSString *)preselectKey {
    self.isLoadingBankOptions = YES;
    BOOL wallet = [self LZ_isWalletType:accountType];
    __weak typeof(self) weakSelf = self;
    void (^done)(NSArray *) = ^(NSArray *options) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.isLoadingBankOptions = NO;
        self.bankNameOptions = options.count > 0 ? options : self.bankNameFallbackOptions;
        if (preselectKey.length > 0) {
            for (NSDictionary *opt in self.bankNameOptions) {
                if ([LZ_stringFromJSONValue(opt[@"key"]) isEqualToString:preselectKey]) {
                    self.selectedBankKey = LZ_stringFromJSONValue(opt[@"key"]);
                    self.bankNameField.text = LZ_stringFromJSONValue(opt[@"label"]);
                    break;
                }
            }
            if (self.bankNameField.text.length == 0) {
                self.bankNameField.text = LZ_stringFromJSONValue(self.editingAccount[LZAPIFieldBankName]);
            }
        }
    };
    if (wallet) {
        [LoanZen_PayAccountService LZ_fetchWalletListWithShowLoading:NO completion:^(NSArray<NSDictionary *> *list, NSError *error) {
            done([weakSelf LZ_mapSysOptions:list]);
        }];
    } else {
        [LoanZen_PayAccountService LZ_fetchBankListWithShowLoading:NO completion:^(NSArray<NSDictionary *> *list, NSError *error) {
            done([weakSelf LZ_mapSysOptions:list]);
        }];
    }
}

- (NSArray<NSDictionary *> *)LZ_mapSysOptions:(NSArray<NSDictionary *> *)list {
    NSMutableArray *result = [NSMutableArray array];
    for (NSDictionary *item in list) {
        if (![item isKindOfClass:[NSDictionary class]]) continue;
        NSString *key = LZ_stringFromJSONValue(item[LZAPIFieldKey]);
        if (key.length == 0) key = LZ_stringFromJSONValue(item[@"key"]);
        if (key.length == 0) continue;
        NSString *label = LZ_stringFromJSONValue(item[LZAPIFieldLabel]);
        if (label.length == 0) label = LZ_stringFromJSONValue(item[@"label"]);
        NSInteger sort = 0;
        if ([item[LZAPIFieldSort] respondsToSelector:@selector(integerValue)]) {
            sort = [item[LZAPIFieldSort] integerValue];
        } else if ([item[@"sort"] respondsToSelector:@selector(integerValue)]) {
            sort = [item[@"sort"] integerValue];
        }
        [result addObject:@{@"key": key, @"label": label.length > 0 ? label : key, @"sort": @(sort)}];
    }
    [result sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        NSInteger sortA = [a[@"sort"] integerValue];
        NSInteger sortB = [b[@"sort"] integerValue];
        if (sortA != sortB) return sortA < sortB ? NSOrderedAscending : NSOrderedDescending;
        return [a[@"label"] localizedCaseInsensitiveCompare:b[@"label"]];
    }];
    return result;
}

- (nullable NSString *)LZ_resolveKeyFromText:(NSString *)text inOptions:(NSArray<NSDictionary *> *)options {
    NSString *trimmed = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) return nil;
    for (NSDictionary *opt in options) {
        NSString *optKey = LZ_stringFromJSONValue(opt[@"key"]);
        NSString *optLabel = LZ_stringFromJSONValue(opt[@"label"]);
        if ([optLabel caseInsensitiveCompare:trimmed] == NSOrderedSame ||
            [optKey caseInsensitiveCompare:trimmed] == NSOrderedSame) {
            return optKey;
        }
    }
    return nil;
}

- (void)LZ_save {
    NSString *holderName = [self.holderName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *accountNo = [self LZ_digitsOnlyString:self.accountNoField.text];
    NSString *accountTypeText = [self.accountTypeField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *bankNameText = [self.bankNameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (holderName.length == 0) {
        [LoanZen_HUD LZ_showError:@"User name is not available."];
        return;
    }
    if (!self.payItemListLoaded) {
        [LoanZen_HUD LZ_showError:@"Please wait for account options to load."];
        return;
    }

    NSString *accountTypeKey = self.selectedAccountTypeKey.length > 0
        ? self.selectedAccountTypeKey
        : [self LZ_resolveKeyFromText:accountTypeText inOptions:self.accountTypeOptions];
    NSString *bankKey = self.selectedBankKey.length > 0
        ? self.selectedBankKey
        : [self LZ_resolveKeyFromText:bankNameText inOptions:self.bankNameOptions];

    if (accountTypeKey.length == 0 || bankKey.length == 0 || accountNo.length == 0) {
        [LoanZen_HUD LZ_showError:@"Please choose Account Type and Bank Name, then enter Bank Account."];
        return;
    }
    NSString *pattern = [self.accountNoItem[LZAPIFieldRegularExpression] isKindOfClass:[NSString class]]
        ? [self.accountNoItem[LZAPIFieldRegularExpression] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
        : @"";
    if (pattern.length > 0 && ![LoanZen_KYCItemHelper LZ_matchesRegex:accountNo pattern:pattern]) {
        [LoanZen_HUD LZ_showError:@"Bank Account format is invalid."];
        return;
    }

    NSArray *commits = @[
        @{@"itemCode": @"account_name", @"itemValue": holderName, @"itemValueType": @1},
        @{@"itemCode": @"account_type", @"itemValue": accountTypeKey, @"itemValueType": @1},
        @{@"itemCode": @"bank_name", @"itemValue": bankKey, @"itemValueType": @1},
        @{@"itemCode": @"account_no", @"itemValue": accountNo, @"itemValueType": @1},
    ];
    NSString *defaultFlag = self.isDefault ? @"1" : @"0";
    NSString *recordId = LZ_stringFromJSONValue(self.editingAccount[@"recordId"]);
    if (recordId.length == 0) {
        recordId = LZ_stringFromJSONValue(self.editingAccount[@"bankCardBindId"]);
    }

    void (^finish)(NSError *) = ^(NSError *error) {
        if (error) {
            [LoanZen_HUD LZ_showError:error.localizedDescription];
            return;
        }
        [LoanZen_HUD LZ_showSuccess:@"Bank account saved"];
        void (^succeeded)(void) = self.onSubmissionSucceeded;
        if (succeeded) {
            succeeded();
            return;
        }
        [self.navigationController popViewControllerAnimated:YES];
    };

    if (recordId.length > 0) {
        [LoanZen_PayAccountService LZ_updatePayAccountWithRecordId:recordId defaultFlag:defaultFlag commits:commits completion:finish];
    } else {
        [LoanZen_PayAccountService LZ_savePayAccountWithDefaultFlag:defaultFlag commits:commits completion:finish];
    }
}

@end
