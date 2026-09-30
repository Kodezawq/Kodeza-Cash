#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LoanZen_MeRootViewDelegate <NSObject>
- (void)LZ_meRootViewDidTapBankAccount:(UIView *)view;
- (void)LZ_meRootView:(UIView *)view didSelectMenuAction:(NSString *)actionKey;
- (void)LZ_meRootViewDidTapSignOut:(UIView *)view;
@end

@interface LoanZen_MeRootView : UIView
@property (nonatomic, weak, nullable) id<LoanZen_MeRootViewDelegate> delegate;
- (void)LZ_renderWithName:(NSString *)name phone:(NSString *)phone menuItems:(NSArray<NSDictionary *> *)menuItems;
@end

NS_ASSUME_NONNULL_END
