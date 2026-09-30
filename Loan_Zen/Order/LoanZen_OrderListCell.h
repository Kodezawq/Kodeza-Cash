#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_OrderListCell : UITableViewCell

+ (NSString *)LZ_reuseIdentifier;
- (void)LZ_configureWithCard:(UIView *)cardView;
- (void)LZ_configureEmptyState;

@end

NS_ASSUME_NONNULL_END
