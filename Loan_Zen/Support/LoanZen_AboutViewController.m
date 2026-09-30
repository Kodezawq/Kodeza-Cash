#import "LoanZen_AboutViewController.h"
#import "LoanZen_ScreenScaffoldView.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_ColorUtils.h"
#import "LoanZen_PopupHelper.h"
#import "LoanZen_AuthService.h"
#import "LoanZen_SessionStore.h"
#import "LoanZen_SupHomeService.h"
#import "LoanZen_AppRouter.h"
#import "LoanZen_Notifications.h"
@import Masonry;

@interface LoanZen_AboutViewController ()
@property (nonatomic, assign) BOOL lzDeleteFlowBusy;
@end

@implementation LoanZen_AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;

    LoanZen_ScreenScaffoldView *scaffold = [[LoanZen_ScreenScaffoldView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:scaffold];
    [scaffold mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.view); }];
    [scaffold LZ_useProfilePageStyle];
    [scaffold LZ_setHeaderTitle:@"About"];
    __weak typeof(self) weakSelf = self;
    [scaffold LZ_setBackAction:^{ [weakSelf.navigationController popViewControllerAnimated:YES]; }];

    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.alwaysBounceVertical = YES;
    [scaffold.contentView addSubview:scroll];
    [scroll mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(scaffold.contentView); }];

    UIView *content = [[UIView alloc] init];
    [scroll addSubview:content];
    [content mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(scroll);
        make.width.equalTo(scroll);
    }];

    UIImageView *logo = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:@"lz_about_logo"]];
    logo.contentMode = UIViewContentModeScaleAspectFit;
    [content addSubview:logo];

    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"] ?: @"Kodeza Cash";
    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.text = appName;
    nameLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
    nameLabel.textColor = [LoanZen_Color kycFormValue];
    nameLabel.textAlignment = NSTextAlignmentCenter;
    [content addSubview:nameLabel];

    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"1.0";
    UILabel *versionLabel = [[UILabel alloc] init];
    versionLabel.text = [NSString stringWithFormat:@"Version V %@", version];
    versionLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    versionLabel.textColor = [LoanZen_Color kycFormLabel];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    versionLabel.layer.cornerRadius = 12;
    versionLabel.layer.borderWidth = 1;
    versionLabel.layer.borderColor = [LoanZen_Color kycFormInputBorder].CGColor;
    versionLabel.clipsToBounds = YES;
    [content addSubview:versionLabel];

    UIView *descCard = [self LZ_darkCard];
    [content addSubview:descCard];
    UILabel *descLabel = [[UILabel alloc] init];
    descLabel.numberOfLines = 0;
    descLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    descLabel.textColor = [LoanZen_Color kycFormLabel];
    descLabel.text = @"Kodeza Cash offers practical borrowing experiences, combining simplified application flows, open disclosures and steady support.";
    [descCard addSubview:descLabel];
    [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(descCard).insets(UIEdgeInsetsMake(16, 16, 16, 16));
    }];

    UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    deleteButton.backgroundColor = UIColor.clearColor;
    deleteButton.layer.cornerRadius = 24;
    deleteButton.layer.borderWidth = 1;
    deleteButton.layer.borderColor = [LoanZen_Color accent].CGColor;
    [deleteButton setTitle:@"Delete Account" forState:UIControlStateNormal];
    [deleteButton setTitleColor:[LoanZen_Color accent] forState:UIControlStateNormal];
    deleteButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    [deleteButton addTarget:self action:@selector(LZ_tapDeleteAccount) forControlEvents:UIControlEventTouchUpInside];
    [content addSubview:deleteButton];

    [logo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(content).offset(24);
        make.centerX.equalTo(content);
        make.width.height.mas_equalTo(112);
    }];
    [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(logo.mas_bottom).offset(16);
        make.left.right.equalTo(content).inset(24);
    }];
    [versionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(nameLabel.mas_bottom).offset(10);
        make.centerX.equalTo(content);
        make.height.mas_equalTo(24);
        make.width.greaterThanOrEqualTo(@120);
    }];
    [descCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(versionLabel.mas_bottom).offset(24);
        make.left.right.equalTo(content).inset(16);
    }];
    [deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(descCard.mas_bottom).offset(32);
        make.left.right.equalTo(content).inset(16);
        make.height.mas_equalTo(48);
        make.bottom.equalTo(content).offset(-32);
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

- (void)LZ_tapDeleteAccount {
    if (self.lzDeleteFlowBusy) return;

    NSString *message = @"You cannot delete your Kodeza Cash account while a loan is under review or being processed, or if any loan has not been fully repaid. Once deletion is confirmed, the account cannot be recovered. Please proceed carefully.";
    __weak typeof(self) weakSelf = self;
    [LoanZen_PopupHelper LZ_showFrame:LoanZen_PopupFrameDeleteAccount
                                    on:self
                                 title:@"Delete Account"
                               message:message
                                actions:@[
        @{@"title": @"Confirm", @"style": @(LoanZen_ModalActionStyleCancel), @"handler": ^{
            [weakSelf LZ_performDeleteAccount];
        }},
        @{@"title": @"Cancel", @"style": @(LoanZen_ModalActionStylePrimary)},
    ]];
}

- (void)LZ_performDeleteAccount {
    if (self.lzDeleteFlowBusy) return;
    self.lzDeleteFlowBusy = YES;

    __weak typeof(self) weakSelf = self;
    [LoanZen_AuthService LZ_closeAccountWithCompletion:^(NSError *error) {
        weakSelf.lzDeleteFlowBusy = NO;
        if (error) {
            [weakSelf LZ_showDeleteFailure];
            return;
        }
        [LoanZen_SessionStore.shared LZ_clearSession];
        [LoanZen_SupHomeStore LZ_clear];
        [NSNotificationCenter.defaultCenter postNotificationName:LZ_NotificationLogoutDidFinish object:nil];
        [weakSelf LZ_showDeleteSuccess];
    }];
}

- (void)LZ_showDeleteSuccess {
    __weak typeof(self) weakSelf = self;
    [LoanZen_PopupHelper LZ_showFrame:LoanZen_PopupFrameSuccess
                                    on:self
                                 title:@"Success!"
                               message:@"Your Kodeza Cash account has been deleted successfully."
                                actions:@[
        @{@"title": @"Confirm", @"style": @(LoanZen_ModalActionStylePrimary), @"handler": ^{
            [LoanZen_AppRouter LZ_showLoginInterfaceInWindow:weakSelf.view.window];
        }},
    ]];
}

- (void)LZ_showDeleteFailure {
    [LoanZen_PopupHelper LZ_showFrame:LoanZen_PopupFrameFailed
                                    on:self
                                 title:@"Failed!"
                               message:@"Failed to delete your Kodeza Cash account. Please check your loan orders and try again."
                                actions:@[
        @{@"title": @"Confirm", @"style": @(LoanZen_ModalActionStylePrimary)},
    ]];
}

@end
