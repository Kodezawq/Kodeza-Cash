#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LoanZen_LoginRootViewDelegate <NSObject>
- (void)LZ_loginRootViewDidTapGetOTP:(UIView *)view;
- (void)LZ_loginRootViewDidTapSignIn:(UIView *)view;
@end

@interface LoanZen_LoginRootView : UIView

@property (nonatomic, weak, nullable) id<LoanZen_LoginRootViewDelegate> delegate;
@property (nonatomic, strong, readonly) UITextField *mobileField;
@property (nonatomic, strong, readonly) UITextField *otpField;
@property (nonatomic, assign, readonly) BOOL agreementAccepted;

@property (nonatomic, copy, nullable) void (^onTapPrivacyPolicy)(void);
@property (nonatomic, copy, nullable) void (^onTapServiceAgreement)(void);

- (void)LZ_setAgreementAccepted:(BOOL)accepted;
- (void)LZ_updateOTPButtonWithRemaining:(NSInteger)seconds completedOnce:(BOOL)completedOnce;

@end

NS_ASSUME_NONNULL_END
