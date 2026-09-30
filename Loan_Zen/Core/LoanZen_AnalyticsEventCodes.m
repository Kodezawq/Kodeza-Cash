#import "LoanZen_AnalyticsEventCodes.h"

NSString *LZAnalyticsEventCodeString(LZAnalyticsEvent event) {
    switch (event) {
        case LZAnalyticsEventFirstOpenApp: return @"0";
        case LZAnalyticsEventLaunchApp: return @"1";
        case LZAnalyticsEventOpenPrivacyPolicy: return @"2";
        case LZAnalyticsEventOpenUserAgreement: return @"3";
        case LZAnalyticsEventClickSendOTP: return @"4";
        case LZAnalyticsEventClickLogin: return @"5";
        case LZAnalyticsEventClickHomePageButton: return @"7";
        case LZAnalyticsEventCameraPermissionSuccess: return @"11";
        case LZAnalyticsEventCameraPermissionFailure: return @"12";
        case LZAnalyticsEventAlbumPermissionSuccess: return @"13";
        case LZAnalyticsEventAlbumPermissionFailure: return @"14";
        case LZAnalyticsEventLocationPermissionSuccess: return @"15";
        case LZAnalyticsEventLocationPermissionFailure: return @"16";
        case LZAnalyticsEventIDFAPermissionSuccess: return @"17";
        case LZAnalyticsEventIDFAPermissionFailure: return @"18";
        case LZAnalyticsEventContactsPermissionSuccess: return @"19";
        case LZAnalyticsEventContactsPermissionFailure: return @"20";
        case LZAnalyticsEventContactsPermissionPartial: return @"198";
        case LZAnalyticsEventKYCValidationError: return @"29";
        case LZAnalyticsEventKYCPersonalSubmit: return @"30";
        case LZAnalyticsEventKYCWorkSubmit: return @"31";
        case LZAnalyticsEventKYCEmergencySubmit: return @"32";
        case LZAnalyticsEventKYCEmergencyRelationSelect: return @"33";
        case LZAnalyticsEventKYCQuestionnaireSubmit: return @"34";
        case LZAnalyticsEventLivenessStart: return @"35";
        case LZAnalyticsEventLivenessFailShow: return @"37";
        case LZAnalyticsEventLivenessCertificateInvalid: return @"38";
        case LZAnalyticsEventLivenessCaptureFace: return @"39";
        case LZAnalyticsEventKYCPanSubmit: return @"40";
        case LZAnalyticsEventKYCIdentitySelectPhotoFront: return @"50";
        case LZAnalyticsEventKYCIdentitySelectCameraFront: return @"51";
        case LZAnalyticsEventKYCIdentitySelectAlbumFront: return @"52";
        case LZAnalyticsEventKYCIdentityOpenCameraFront: return @"53";
        case LZAnalyticsEventKYCIdentityCapturePhotoFront: return @"54";
        case LZAnalyticsEventKYCIdentityConfirmPhotoFront: return @"55";
        case LZAnalyticsEventKYCIdentityCancelCameraFront: return @"56";
        case LZAnalyticsEventKYCIdentityAlbumSelectFront: return @"57";
        case LZAnalyticsEventKYCIdentitySubmit: return @"66";
        case LZAnalyticsEventBindCardSubmit: return @"67";
        case LZAnalyticsEventOrderApplySubmit: return @"68";
        case LZAnalyticsEventOrderAutoSubmit: return @"72";
    }
    return @"";
}
