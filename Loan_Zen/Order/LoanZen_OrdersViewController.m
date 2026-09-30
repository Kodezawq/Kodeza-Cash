#import "LoanZen_OrdersViewController.h"
#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_OrdersRootView.h"
#import "LoanZen_OrdersViewModel.h"
#import "LoanZen_OrderListCell.h"
#import "LoanZen_OrderListCardView.h"
#import "LoanZen_PopupHelper.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_Notifications.h"
#import "LoanZen_OrderDetailViewController.h"
#import "LoanZen_OrderStatusPresentation.h"
#import "LoanZen_RejectH5Navigator.h"
@import Masonry;

@interface LoanZen_OrdersViewController () <LoanZen_OrdersRootViewDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) LoanZen_OrdersRootView *rootView;
@property (nonatomic, strong) LoanZen_OrdersViewModel *ordersViewModel;
@property (nonatomic, strong) id orderRefreshObserver;
@end

@implementation LoanZen_OrdersViewController

- (void)loadView {
    self.rootView = [[LoanZen_OrdersRootView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.view = self.rootView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.ordersViewModel = [[LoanZen_OrdersViewModel alloc] init];
    self.viewModel = self.ordersViewModel;
    [self LZ_bindViewModel];
    self.rootView.delegate = self;
    self.rootView.tableView.dataSource = self;
    self.rootView.tableView.delegate = self;
    [self.rootView.tableView registerClass:[LoanZen_OrderListCell class] forCellReuseIdentifier:[LoanZen_OrderListCell LZ_reuseIdentifier]];
    [self.rootView LZ_renderTabs:self.ordersViewModel.LZ_tabTitles selectedIndex:self.ordersViewModel.selectedTabIndex];

    __weak typeof(self) weakSelf = self;
    self.orderRefreshObserver = [NSNotificationCenter.defaultCenter addObserverForName:LZ_NotificationOrderListShouldRefresh object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
        [weakSelf.ordersViewModel LZ_loadOrdersWithLoading:NO];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self.ordersViewModel LZ_loadOrdersWithLoading:NO];
}

- (void)dealloc {
    if (self.orderRefreshObserver) {
        [NSNotificationCenter.defaultCenter removeObserver:self.orderRefreshObserver];
    }
}

- (void)LZ_switchToTabWithRequestStatus:(NSInteger)requestStatus {
    NSInteger tabIndex = 0;
    switch (requestStatus) {
        case 10: tabIndex = 1; break;
        case 20: tabIndex = 0; break;
        case 30: tabIndex = 2; break;
        case 40: tabIndex = 3; break;
        default: tabIndex = 0; break;
    }
    [self.ordersViewModel LZ_selectTabIndex:tabIndex];
    [self.rootView LZ_renderTabs:self.ordersViewModel.LZ_tabTitles selectedIndex:tabIndex];
}

- (void)LZ_onViewModelStateChanged {
    [self.rootView LZ_reloadCards:self.ordersViewModel.displayCards];
}

- (void)LZ_onViewModelError:(NSString *)message {
    [LoanZen_PopupHelper LZ_showFrame:LoanZen_PopupFrameError on:self title:@"Orders" message:message actions:@[
        @{@"title": @"OK", @"style": @(LoanZen_ModalActionStylePrimary)},
    ]];
}

#pragma mark - LoanZen_OrdersRootViewDelegate

- (void)LZ_ordersRootView:(LoanZen_OrdersRootView *)view didSelectTabIndex:(NSInteger)index {
    [self.ordersViewModel LZ_selectTabIndex:index];
}

- (void)LZ_ordersRootView:(LoanZen_OrdersRootView *)view didSelectOrderAtIndex:(NSInteger)index {
    if (index >= self.ordersViewModel.displayCards.count) return;
    NSDictionary *card = self.ordersViewModel.displayCards[index];
    NSNumber *orderStatus = card[LZAPIFieldOrderStatus];
    if ([LoanZen_OrderStatusPresentation LZ_isRejectedStatus:orderStatus] && [LoanZen_RejectH5Navigator LZ_hasURL]) {
        [LoanZen_RejectH5Navigator LZ_openFrom:self message:nil];
        return;
    }
    NSString *orderId = card[LZAPIFieldOrderId];
    if (orderId.length == 0) return;
    LoanZen_OrderDetailViewController *detail = [[LoanZen_OrderDetailViewController alloc] initWithOrderId:orderId productId:card[@"productId"]];
    [self.navigationController pushViewController:detail animated:YES];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MAX(1, (NSInteger)self.ordersViewModel.displayCards.count);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LoanZen_OrderListCell *cell = [tableView dequeueReusableCellWithIdentifier:[LoanZen_OrderListCell LZ_reuseIdentifier] forIndexPath:indexPath];
    if (self.ordersViewModel.displayCards.count == 0) {
        [cell LZ_configureEmptyState];
        return cell;
    }

    NSDictionary *item = self.ordersViewModel.displayCards[indexPath.row];
    NSString *imageName = item[@"statusBarImageName"];
    UIImage *statusImage = imageName.length > 0 ? [LoanZen_Asset imageNamed:imageName] : nil;
    UIView *card = [LoanZen_OrderListCardView LZ_cardWithProduct:item[LZAPIFieldProductName]
                                                          amount:item[LZAPIFieldAmount]
                                                  statusBarImage:statusImage
                                                       leftTitle:item[@"leftTitle"]
                                                       leftValue:item[@"leftValue"]
                                                      rightTitle:item[@"rightTitle"]
                                                      rightValue:item[@"rightValue"]];
    [cell LZ_configureWithCard:card];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.ordersViewModel.displayCards.count == 0) return;
    [self LZ_ordersRootView:self.rootView didSelectOrderAtIndex:indexPath.row];
}

@end
