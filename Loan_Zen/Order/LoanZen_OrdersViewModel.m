#import "LoanZen_OrdersViewModel.h"
#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_OrderService.h"
#import "LoanZen_OrderStatusPresentation.h"
#import "LoanZen_CredentialStore.h"

typedef NS_ENUM(NSInteger, LoanZen_OrderTab) {
    LoanZen_OrderTabPendingRepayment = 0,
    LoanZen_OrderTabSubmitApplication = 1,
    LoanZen_OrderTabProcessing = 2,
    LoanZen_OrderTabCompleted = 3,
};

@interface LoanZen_OrdersViewModel ()
@property (nonatomic, assign, readwrite) NSInteger selectedTabIndex;
@property (nonatomic, copy, readwrite) NSArray<NSDictionary *> *displayCards;
@end

@implementation LoanZen_OrdersViewModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _selectedTabIndex = LoanZen_OrderTabPendingRepayment;
        _displayCards = @[];
    }
    return self;
}

- (NSArray<NSString *> *)LZ_tabTitles {
    return @[@"Pending Repayment", @"Submit Application", @"Processing", @"Completed"];
}

- (NSInteger)LZ_requestStatusForTabIndex:(NSInteger)index {
    switch (index) {
        case LoanZen_OrderTabSubmitApplication: return 10;
        case LoanZen_OrderTabPendingRepayment: return 20;
        case LoanZen_OrderTabProcessing: return 30;
        case LoanZen_OrderTabCompleted: return 40;
        default: return 20;
    }
}

- (void)LZ_selectTabIndex:(NSInteger)index {
    self.selectedTabIndex = index;
    [self LZ_loadOrdersWithLoading:YES];
}

- (void)LZ_loadOrdersWithLoading:(BOOL)showLoading {
    if (LoanZen_CredentialStore.token.length == 0) {
        self.displayCards = @[];
        [self LZ_notifyStateChanged];
        return;
    }
    NSInteger status = [self LZ_requestStatusForTabIndex:self.selectedTabIndex];
    [LoanZen_OrderService LZ_fetchOrderListWithStatus:status showLoading:showLoading completion:^(NSArray<NSDictionary *> *list, NSError *error) {
        if (error) {
            self.displayCards = @[];
            if (showLoading) [self LZ_notifyError:error.localizedDescription];
            [self LZ_notifyStateChanged];
            return;
        }
        NSMutableArray *cards = [NSMutableArray array];
        for (NSDictionary *item in list ?: @[]) {
            NSNumber *orderStatus = item[LZAPIFieldOrderStatus];
            NSString *statusImageName = [LoanZen_OrderStatusPresentation LZ_listStatusBarImageNameForStatus:orderStatus];
            NSDictionary *dateMetrics = [LoanZen_OrderStatusPresentation LZ_listDateMetricsForStatus:orderStatus
                                                                                          applyDate:item[LZAPIFieldApplyDate]
                                                                                            dueDate:item[LZAPIFieldDueDate]
                                                                                         payoutDate:item[LZAPIFieldPayoutDate]
                                                                                           loanDate:item[LZAPIFieldLoanDate]
                                                                                      repaymentDate:item[LZAPIFieldRepaymentDate]
                                                                                          repayDate:item[LZAPIFieldRepayDate]];
            [cards addObject:@{
                LZAPIFieldProductName: item[LZAPIFieldProductName] ?: @"—",
                LZAPIFieldAmount: [self LZ_formatPeso:item[LZAPIFieldLoanAmount]],
                @"statusBarImageName": statusImageName ?: @"",
                @"leftTitle": dateMetrics[@"leftTitle"] ?: @"Date of application",
                @"leftValue": dateMetrics[@"leftValue"] ?: @"—",
                @"rightTitle": dateMetrics[@"rightTitle"] ?: @"Due date",
                @"rightValue": dateMetrics[@"rightValue"] ?: @"—",
                LZAPIFieldOrderId: item[LZAPIFieldOrderId] ?: @"",
                LZAPIFieldOrderStatus: orderStatus ?: @0,
                @"productId": item[LZAPIFieldProductId] ?: @"",
            }];
        }
        self.displayCards = cards;
        [self LZ_notifyStateChanged];
    }];
}

- (NSString *)LZ_formatPeso:(NSString *)raw {
    NSString *s = [[raw ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] copy];
    if (s.length == 0) return @"—";
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

@end
