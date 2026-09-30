#import "LoanZen_BankListViewController.h"
#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_ScreenScaffoldView.h"
#import "LoanZen_PayAccountService.h"
#import "LoanZen_BankFormViewController.h"
#import "LoanZen_KYCFourService.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_ColorUtils.h"
#import "LoanZen_HUD.h"
@import Masonry;

static NSString * const kLZBankKYCRequiredMessage = @"For security reasons, please complete KYC first.";
static NSString * const kLZBankCannotEditMessage = @"This bank account cannot be modified at the moment";

static BOOL LZ_accountCanEdit(NSDictionary *account) {
    NSString *editFlag = [[account[@"editFlag"] description] lowercaseString];
    return [editFlag isEqualToString:@"1"] || [editFlag isEqualToString:@"true"] || [editFlag isEqualToString:@"on"];
}

@interface LoanZen_BankCardView : UIControl
- (instancetype)initWithAccount:(NSDictionary *)account
                groupedCardNo:(NSString *(^)(NSString *))formatter
                      canEdit:(BOOL)canEdit
                       onEdit:(void (^)(void))onEdit
                   onSelect:(void (^)(void))onSelect;
@end

@implementation LoanZen_BankCardView

- (instancetype)initWithAccount:(NSDictionary *)account
                  groupedCardNo:(NSString *(^)(NSString *))formatter
                        canEdit:(BOOL)canEdit
                         onEdit:(void (^)(void))onEdit
                       onSelect:(void (^)(void))onSelect {
    
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        
        BOOL isDefault = [[account[@"defaultFlag"] description] isEqualToString:@"1"];
        
        self.layer.cornerRadius = 16;
        self.clipsToBounds = YES;

        UIImageView *bg = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:@"lz_bank_bg"]];
        
        bg.contentMode = UIViewContentModeScaleAspectFill;
        
        bg.clipsToBounds = YES;
        bg.userInteractionEnabled = NO;
        [self addSubview:bg];
        
        [bg mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self); }];

        UILabel *bankNameLabel = [[UILabel alloc] init];
        bankNameLabel.text = account[LZAPIFieldBankName] ?: @"Bank Card";
        bankNameLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
        bankNameLabel.textColor = UIColor.whiteColor;

        UIView *defaultPill = [[UIView alloc] init];
        
        defaultPill.userInteractionEnabled = NO;
        defaultPill.layer.cornerRadius = 14.0;
        defaultPill.clipsToBounds = YES;
        
        if (isDefault) {
            
            defaultPill.backgroundColor = [[LoanZen_Color accent] colorWithAlphaComponent:0.28];
            defaultPill.layer.borderWidth = 1;
            defaultPill.layer.borderColor = [[LoanZen_Color accent] colorWithAlphaComponent:0.65].CGColor;
            
        } else {
            
            defaultPill.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.08];
            defaultPill.layer.borderWidth = 1;
            defaultPill.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.14].CGColor;
            
        }

        UIImageView *defaultIcon = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:isDefault ? @"lz_bank_mr_u" : @"lz_bank_mr_n"]];
        
        defaultIcon.contentMode = UIViewContentModeScaleAspectFit;
        
        UILabel *defaultLabel = [[UILabel alloc] init];
        
        defaultLabel.text = @"Default";
        
        defaultLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
        defaultLabel.textColor = isDefault ? UIColor.whiteColor : [LoanZen_Color kycFormPlaceholder];
        [defaultPill addSubview:defaultIcon];
        [defaultPill addSubview:defaultLabel];
        
        [defaultIcon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(defaultPill).offset(8);
            make.centerY.equalTo(defaultPill);
            make.width.height.mas_equalTo(16);
        }];
        
        [defaultLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(defaultIcon.mas_right).offset(6);
            make.right.equalTo(defaultPill).offset(-10);
            make.centerY.equalTo(defaultPill);
        }];
        
        [defaultPill mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(28);
        }];

        UILabel *numberLabel = [[UILabel alloc] init];
        numberLabel.text = formatter(account[@"accountNoEncrypt"] ?: account[LZAPIFieldAccountNo]);
        numberLabel.font = [UIFont monospacedDigitSystemFontOfSize:20 weight:UIFontWeightSemibold];
        numberLabel.textColor = UIColor.whiteColor;
        numberLabel.adjustsFontSizeToFitWidth = YES;
        numberLabel.minimumScaleFactor = 0.75;
        numberLabel.numberOfLines = 1;

        UILabel *holderLabel = [[UILabel alloc] init];
        holderLabel.text = account[LZAPIFieldAccountName] ?: @"user name";
        holderLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        holderLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.85];

        UIButton *editButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [editButton setImage:[LoanZen_Asset imageNamed:@"lz_bank_edit"] forState:UIControlStateNormal];
        editButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        editButton.hidden = !canEdit;
        if (canEdit && onEdit) {
            [editButton addAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
                onEdit();
            }] forControlEvents:UIControlEventTouchUpInside];
        }

        [self addSubview:bankNameLabel];
        [self addSubview:defaultPill];
        [self addSubview:numberLabel];
        [self addSubview:holderLabel];
        [self addSubview:editButton];

        [bankNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(16);
            make.left.equalTo(self).offset(20);
            make.right.lessThanOrEqualTo(defaultPill.mas_left).offset(-12);
        }];
        [defaultPill mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(bankNameLabel);
            make.right.equalTo(self).offset(-16);
        }];
        [numberLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(20);
            make.right.equalTo(self).offset(-20);
            make.centerY.equalTo(self).offset(6);
        }];
        [holderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(20);
            make.bottom.equalTo(self).offset(-18);
            if (canEdit) {
                make.right.lessThanOrEqualTo(editButton.mas_left).offset(-12);
            } else {
                make.right.equalTo(self).offset(-20);
            }
        }];
        [editButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-18);
            make.bottom.equalTo(self).offset(-18);
            make.width.height.mas_equalTo(32);
        }];

        if (onSelect && !isDefault) {
            [self addAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
                onSelect();
            }] forControlEvents:UIControlEventTouchUpInside];
        }
    }
    return self;
}

@end

@interface LoanZen_BankListViewController ()
@property (nonatomic, strong) LoanZen_ScreenScaffoldView *scaffold;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *contentStack;
@property (nonatomic, strong) UIStackView *cardsStack;
@property (nonatomic, strong) UIView *emptyView;
@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, copy) NSArray<NSDictionary *> *accounts;
@end

@implementation LoanZen_BankListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;

    self.scaffold = [[LoanZen_ScreenScaffoldView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.scaffold];
    [self.scaffold mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.view); }];
    [self.scaffold LZ_useProfilePageStyle];
    [self.scaffold LZ_setHeaderTitle:@"Bank Account"];
    __weak typeof(self) weakSelf = self;
    [self.scaffold LZ_setBackAction:^{ [weakSelf.navigationController popViewControllerAnimated:YES]; }];

    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.scaffold.contentView addSubview:self.scrollView];

    self.contentStack = [[UIStackView alloc] init];
    self.contentStack.axis = UILayoutConstraintAxisVertical;
    self.contentStack.spacing = 12;

    self.cardsStack = [[UIStackView alloc] init];
    self.cardsStack.axis = UILayoutConstraintAxisVertical;
    self.cardsStack.spacing = 12;

    UIView *tipCard = [self LZ_tipCard];
    [self.contentStack addArrangedSubview:tipCard];
    [self.contentStack addArrangedSubview:self.cardsStack];
    [self.scrollView addSubview:self.contentStack];

    self.emptyView = [self LZ_emptyView];
    [self.scaffold.contentView addSubview:self.emptyView];

    self.addButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.addButton.backgroundColor = [LoanZen_Color accent];
    self.addButton.layer.cornerRadius = 12;
    self.addButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.addButton setTitle:@"+ Add" forState:UIControlStateNormal];
    [self.addButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.addButton addTarget:self action:@selector(LZ_add) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.addButton];

    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.scaffold.contentView);
        make.bottom.equalTo(self.addButton.mas_top).offset(-12);
    }];
    [self.contentStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView).insets(UIEdgeInsetsMake(12, 16, 16, 16));
        make.width.equalTo(self.scrollView).offset(-32);
    }];
    [self.emptyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.scaffold.contentView);
        make.top.equalTo(self.scaffold.contentView).offset(120);
        make.bottom.equalTo(self.addButton.mas_top);
    }];
    [self.addButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view).inset(16);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-12);
        make.height.mas_equalTo(48);
    }];

    [self LZ_reload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self LZ_reload];
}

#pragma mark - UI

- (UIView *)LZ_tipCard {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [[LoanZen_Color accent] colorWithAlphaComponent:0.08];
    card.layer.cornerRadius = 12;
    card.layer.borderWidth = 1;
    card.layer.borderColor = [[LoanZen_Color accent] colorWithAlphaComponent:0.35].CGColor;
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    label.textColor = [LoanZen_Color kycFormLabel];
    label.text = @"You can add multiple receiving methods. If your default method encounters an issue during the transfer, we will automatically switch to your backup account for disbursement.";
    [card addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(card).insets(UIEdgeInsetsMake(13, 14, 13, 14));
    }];
    return card;
}

- (UIView *)LZ_emptyView {
    UIView *container = [[UIView alloc] init];
    container.hidden = YES;
    UIImageView *icon = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:@"lz_bank_kzt"]];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    UILabel *label = [[UILabel alloc] init];
    label.text = @"No bank account";
    label.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    label.textColor = [LoanZen_Color secondaryText];
    label.textAlignment = NSTextAlignmentCenter;
    [container addSubview:icon];
    [container addSubview:label];
    [icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(container);
        make.top.equalTo(container).offset(80);
        make.width.height.mas_equalTo(80);
    }];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(icon.mas_bottom).offset(14);
        make.centerX.equalTo(container);
    }];
    return container;
}

- (UIView *)LZ_bankCardForAccount:(NSDictionary *)account {
    BOOL canEdit = LZ_accountCanEdit(account);
    __weak typeof(self) weakSelf = self;
    LoanZen_BankCardView *row = [[LoanZen_BankCardView alloc] initWithAccount:account
                                                                groupedCardNo:^NSString *(NSString *raw) {
        return [weakSelf LZ_groupedCardNo:raw];
    } canEdit:canEdit onEdit:canEdit ? ^{
        [weakSelf LZ_openEditForAccount:account];
    } : nil onSelect:^{
        [weakSelf LZ_setDefaultAccount:account];
    }];
    [row mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(159.5);
    }];
    return row;
}

#pragma mark - Data

- (void)LZ_reload {
    [LoanZen_PayAccountService LZ_fetchPayAccountList:^(NSArray<NSDictionary *> *list, NSError *error) {
        if (error) {
            [LoanZen_HUD LZ_showError:error.localizedDescription];
            return;
        }
        self.accounts = list ?: @[];
        [self LZ_rebuildCards];
    }];
}

- (void)LZ_rebuildCards {
    for (UIView *view in self.cardsStack.arrangedSubviews) {
        [self.cardsStack removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    BOOL isEmpty = self.accounts.count == 0;
    self.emptyView.hidden = !isEmpty;
    self.scrollView.hidden = isEmpty;
    self.contentStack.hidden = isEmpty;
    if (isEmpty) return;
    for (NSDictionary *account in self.accounts) {
        [self.cardsStack addArrangedSubview:[self LZ_bankCardForAccount:account]];
    }
}

- (NSString *)LZ_groupedCardNo:(NSString *)raw {
    NSString *s = [[raw ?: @"" stringByReplacingOccurrencesOfString:@" " withString:@""]
                     stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (s.length == 0) return @"—";
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    for (NSUInteger i = 0; i < s.length; i += 4) {
        NSUInteger len = MIN(4, s.length - i);
        [parts addObject:[s substringWithRange:NSMakeRange(i, len)]];
    }
    return [parts componentsJoinedByString:@" "];
}

#pragma mark - Actions

- (void)LZ_add {
    // 对齐 LoanBase：添加银行卡前需四步 KYC 已完成（step == -1）
    __weak typeof(self) weakSelf = self;
    [LoanZen_HUD LZ_showBlockingLoading];
    [LoanZen_KYCFourService LZ_fetchFourStatusWithLoading:NO completion:^(NSNumber *step, NSError *error) {
        [LoanZen_HUD LZ_hideBlockingLoading];
        __strong typeof(self) self = weakSelf;
        if (!self) return;
        if (error) {
            [LoanZen_HUD LZ_showError:error.localizedDescription];
            return;
        }
        if (step == nil || step.integerValue != -1) {
            [LoanZen_HUD LZ_showError:kLZBankKYCRequiredMessage];
            return;
        }
        [self.navigationController pushViewController:[[LoanZen_BankFormViewController alloc] init] animated:YES];
    }];
}

- (void)LZ_openEditForAccount:(NSDictionary *)account {
    // 对齐 LoanBase：仅 editFlag 为 1/true 时可编辑
    if (!LZ_accountCanEdit(account)) {
        [LoanZen_HUD LZ_showError:kLZBankCannotEditMessage];
        return;
    }
    [self.navigationController pushViewController:[[LoanZen_BankFormViewController alloc] initWithEditingAccount:account] animated:YES];
}

/// 对齐 LoanEase：点击非默认卡 → update defaultFlag=1（commits 空）→ 刷新列表
- (void)LZ_setDefaultAccount:(NSDictionary *)account {
    if ([[account[@"defaultFlag"] description] isEqualToString:@"1"]) return;
    NSString *recordId = [[account[@"recordId"] description] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (recordId.length == 0 || [recordId isEqualToString:@"(null)"]) {
        recordId = [[account[@"bankCardBindId"] description] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    if (recordId.length == 0 || [recordId isEqualToString:@"(null)"]) {
        [LoanZen_HUD LZ_showError:@"Missing bank account record, please try again."];
        return;
    }
    __weak typeof(self) weakSelf = self;
    [LoanZen_PayAccountService LZ_updatePayAccountWithRecordId:recordId
                                                  defaultFlag:@"1"
                                                      commits:@[]
                                                   completion:^(NSError *error) {
        if (error) {
            [LoanZen_HUD LZ_showError:error.localizedDescription];
            return;
        }
        [weakSelf LZ_reload];
    }];
}

@end
