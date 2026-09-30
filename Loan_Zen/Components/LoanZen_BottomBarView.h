#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, LoanZen_BottomTab) {
    LoanZen_BottomTabLoan = 0,
    LoanZen_BottomTabOrder = 1,
    LoanZen_BottomTabEMI = 2,
    LoanZen_BottomTabMe = 3,
};

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_BottomBarView : UIView

@property (nonatomic, assign) LoanZen_BottomTab selectedTab;
@property (nonatomic, copy, nullable) void (^onSelectTab)(LoanZen_BottomTab tab);

@end

NS_ASSUME_NONNULL_END
