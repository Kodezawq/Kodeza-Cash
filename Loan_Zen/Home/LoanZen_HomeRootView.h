#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LoanZen_HomeRootViewDelegate <NSObject>
- (void)LZ_homeRootViewDidTapApply:(UIView *)view;
- (void)LZ_homeRootViewDidTapKYC:(UIView *)view;
- (void)LZ_homeRootViewDidTapCheckIn:(UIView *)view;
- (void)LZ_homeRootView:(UIView *)view didSelectProductAtIndex:(NSInteger)index;
@end

@interface LoanZen_HomeRootView : UIView
@property (nonatomic, weak, nullable) id<LoanZen_HomeRootViewDelegate> delegate;
- (void)LZ_renderWithWelcome:(NSString *)welcome
                     kycHint:(NSString *)kycHint
                    products:(NSArray<NSDictionary *> *)products
              kycJumpEnabled:(BOOL)kycJumpEnabled
                   pendingKyc:(BOOL)pendingKyc
           hideCenterAndApply:(BOOL)hideCenterAndApply
         checkInCompletedDays:(NSInteger)checkInCompletedDays
            hasCheckedInToday:(BOOL)hasCheckedInToday;
@end

NS_ASSUME_NONNULL_END
