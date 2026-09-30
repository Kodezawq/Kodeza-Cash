#import "LoanZen_LoginViewModel.h"
#import "LoanZen_PhilippineMobile.h"
#import "LoanZen_AuthService.h"
#import "LoanZen_APIConfig.h"
#import "LoanZen_SessionStore.h"
#import "LoanZen_Notifications.h"
#import "LoanZen_HUD.h"
#import "LoanZen_DeviceUploadService.h"
#import "LoanZen_AppConfigRefresher.h"
#import "LoanZen_SupHomeService.h"
#import "LoanZen_AdjustUserInfoSync.h"

@interface LoanZen_LoginViewModel ()
@property (nonatomic, assign, readwrite) BOOL agreementAccepted;
@property (nonatomic, assign, readwrite) NSInteger otpRemainingSeconds;
@property (nonatomic, assign, readwrite) BOOL otpHasCompletedOnce;
@property (nonatomic, strong, nullable) NSTimer *otpTimer;
@end

@implementation LoanZen_LoginViewModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _agreementAccepted = YES;
    }
    return self;
}

- (void)dealloc {
    [self.otpTimer invalidate];
}

- (void)LZ_setAgreementAccepted:(BOOL)accepted {
    self.agreementAccepted = accepted;
    [self LZ_notifyStateChanged];
}

- (void)LZ_startOTPTimer {
    [self.otpTimer invalidate];
    self.otpRemainingSeconds = 60;
    [self LZ_notifyStateChanged];
    __weak typeof(self) weakSelf = self;
    self.otpTimer = [NSTimer timerWithTimeInterval:1 repeats:YES block:^(NSTimer *timer) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            [timer invalidate];
            return;
        }
        self.otpRemainingSeconds -= 1;
        if (self.otpRemainingSeconds <= 0) {
            self.otpRemainingSeconds = 0;
            self.otpHasCompletedOnce = YES;
            [timer invalidate];
            self.otpTimer = nil;
        }
        [self LZ_notifyStateChanged];
    }];
    [[NSRunLoop mainRunLoop] addTimer:self.otpTimer forMode:NSRunLoopCommonModes];
}

- (void)LZ_requestOTPWithMobile:(NSString *)mobile {
    NSString *digits = [LoanZen_PhilippineMobile LZ_digitsOnly:mobile];
    if (digits.length == 0) {
        [self LZ_notifyError:@"Please enter mobile number"];
        return;
    }
    NSString *national10 = [LoanZen_PhilippineMobile LZ_normalizedNational10ForAPI:mobile];
    if (!national10) {
        [self LZ_notifyError:@"Please enter correct mobile number"];
        return;
    }
    if (!LoanZen_APIConfig.hasSigningProfile) {
        [self LZ_startOTPTimer];
        [self LZ_notifySuccess:@"OTP has been sent"];
        return;
    }
    [LoanZen_AuthService LZ_sendOTPWithMobileDigits:national10 completion:^(NSError *error) {
        if (error) {
            [self LZ_notifyError:error.localizedDescription];
            return;
        }
        [self LZ_startOTPTimer];
        [self LZ_notifySuccess:@"OTP has been sent"];
    }];
}

- (void)LZ_signInWithMobile:(NSString *)mobile otp:(NSString *)otp {
    if (!self.agreementAccepted) {
        [self LZ_notifyError:@"Please read and accept Privacy Policy and Service Agreement"];
        return;
    }
    NSString *national10 = [LoanZen_PhilippineMobile LZ_normalizedNational10ForAPI:mobile];
    if (!national10) {
        [self LZ_notifyError:@"Please enter correct mobile number"];
        return;
    }
    NSString *otpDigits = [LoanZen_PhilippineMobile LZ_digitsOnly:otp];
    if (otpDigits.length == 0) {
        [self LZ_notifyError:@"Enter OTP"];
        return;
    }
    if (otpDigits.length != 6) {
        [self LZ_notifyError:@"Please enter correct OTP"];
        return;
    }
    if (!LoanZen_APIConfig.hasSigningProfile) {
        [LoanZen_SessionStore.shared LZ_applyDemoLoginWithMobileDigits:national10];
        [[NSNotificationCenter defaultCenter] postNotificationName:LZ_NotificationLoginDidSucceed object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:LZ_NotificationHomeShouldRefresh object:nil];
        return;
    }
    [LoanZen_AuthService LZ_registerOrLoginWithMobileDigits:national10 verifyCode:otpDigits completion:^(LoanZen_LoginResult *result, NSError *error) {
        if (error) {
            // 业务错误已在 HTTPClient 中弹窗，避免重复提示。
            BOOL businessErrorAlreadyShown = [error.domain isEqualToString:@"LoanZen_HTTPClient"] && error.code > 0;
            if (!businessErrorAlreadyShown) {
                NSString *msg = error.localizedDescription;
                if (msg.length > 0) [self LZ_notifyError:msg];
            }
            return;
        }
        if (!result) {
            [self LZ_notifyError:@"Login response is invalid, please try again."];
            return;
        }
        [LoanZen_SessionStore.shared LZ_applyLoginResult:result fallbackMobileDigits:national10];
        [LoanZen_AppConfigRefresher LZ_refreshIfPossible];
        [LoanZen_SupHomeService LZ_refreshIfLoggedInWithShowLoading:NO completion:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:LZ_NotificationLoginDidSucceed object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:LZ_NotificationHomeShouldRefresh object:nil];
        [LoanZen_AdjustUserInfoSync LZ_scheduleUserInfoReport];
        [LoanZen_DeviceUploadService LZ_registerDeviceWithCompletion:nil];
    }];
}

@end
