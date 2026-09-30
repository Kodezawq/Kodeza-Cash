#import "LoanZen_ViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_LoginViewModel : LoanZen_ViewModel

@property (nonatomic, assign, readonly) BOOL agreementAccepted;
@property (nonatomic, assign, readonly) NSInteger otpRemainingSeconds;
@property (nonatomic, assign, readonly) BOOL otpHasCompletedOnce;

- (void)LZ_setAgreementAccepted:(BOOL)accepted;
- (void)LZ_requestOTPWithMobile:(NSString *)mobile;
- (void)LZ_signInWithMobile:(NSString *)mobile otp:(NSString *)otp;

@end

NS_ASSUME_NONNULL_END
