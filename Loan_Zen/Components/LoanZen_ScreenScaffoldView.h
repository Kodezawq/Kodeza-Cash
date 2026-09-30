#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_ScreenScaffoldView : UIView

@property (nonatomic, strong, readonly) UIView *contentView;
@property (nonatomic, strong, readonly) UIView *headerView;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UIButton *backButton;

- (void)LZ_setHeaderTitle:(NSString *)title;
- (void)LZ_setBackAction:(void (^)(void))action;
- (void)LZ_useKYCStyle;
- (void)LZ_useLoanDetailAccentStyle;
- (void)LZ_useLoanConfirmationStyle;
- (void)LZ_useProfilePageStyle;

@end

NS_ASSUME_NONNULL_END
