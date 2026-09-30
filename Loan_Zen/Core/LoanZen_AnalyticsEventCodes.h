#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 与服务端埋点表对齐（数值与 CMDKuan `CMBuryEventCode` / LoanEase `LEAnalyticsEventCode` 一致）。
typedef NS_ENUM(NSInteger, LZAnalyticsEvent) {
    LZAnalyticsEventFirstOpenApp,
    LZAnalyticsEventLaunchApp,
    LZAnalyticsEventOpenPrivacyPolicy,
    LZAnalyticsEventOpenUserAgreement,
    LZAnalyticsEventClickSendOTP,
    LZAnalyticsEventClickLogin,
    LZAnalyticsEventClickHomePageButton,
    LZAnalyticsEventCameraPermissionSuccess,
    LZAnalyticsEventCameraPermissionFailure,
    LZAnalyticsEventAlbumPermissionSuccess,
    LZAnalyticsEventAlbumPermissionFailure,
    LZAnalyticsEventLocationPermissionSuccess,
    LZAnalyticsEventLocationPermissionFailure,
    LZAnalyticsEventIDFAPermissionSuccess,
    LZAnalyticsEventIDFAPermissionFailure,
    LZAnalyticsEventContactsPermissionSuccess,
    LZAnalyticsEventContactsPermissionFailure,
    LZAnalyticsEventContactsPermissionPartial,
    LZAnalyticsEventKYCValidationError,
    LZAnalyticsEventKYCPersonalSubmit,
    LZAnalyticsEventKYCWorkSubmit,
    LZAnalyticsEventKYCEmergencySubmit,
    LZAnalyticsEventKYCEmergencyRelationSelect,
    LZAnalyticsEventKYCQuestionnaireSubmit,
    LZAnalyticsEventLivenessStart,
    LZAnalyticsEventLivenessFailShow,
    LZAnalyticsEventLivenessCertificateInvalid,
    LZAnalyticsEventLivenessCaptureFace,
    LZAnalyticsEventKYCPanSubmit,
    LZAnalyticsEventKYCIdentitySelectPhotoFront,
    LZAnalyticsEventKYCIdentitySelectCameraFront,
    LZAnalyticsEventKYCIdentitySelectAlbumFront,
    LZAnalyticsEventKYCIdentityOpenCameraFront,
    LZAnalyticsEventKYCIdentityCapturePhotoFront,
    LZAnalyticsEventKYCIdentityConfirmPhotoFront,
    LZAnalyticsEventKYCIdentityCancelCameraFront,
    LZAnalyticsEventKYCIdentityAlbumSelectFront,
    LZAnalyticsEventKYCIdentitySubmit,
    LZAnalyticsEventBindCardSubmit,
    LZAnalyticsEventOrderApplySubmit,
    LZAnalyticsEventOrderAutoSubmit,
};

FOUNDATION_EXPORT NSString *LZAnalyticsEventCodeString(LZAnalyticsEvent event);

NS_ASSUME_NONNULL_END
