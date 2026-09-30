#import "LoanZen_BuryReporter.h"
#import "LoanZen_HTTPClient.h"
#import "LoanZen_APIConfig.h"

@implementation LoanZen_BuryReporter

+ (NSString *)LZ_normalizedField:(NSString *)value {
    NSString *trimmed = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return trimmed.length > 0 ? trimmed : @"NULL";
}

+ (void)LZ_trackEvent:(LZAnalyticsEvent)event {
    [self LZ_trackEvent:event content:@"NULL"];
}

+ (void)LZ_trackEvent:(LZAnalyticsEvent)event content:(NSString *)content {
    [self LZ_trackEvent:event content:content remark1:@"NULL" remark2:@"NULL" remark3:@"NULL"];
}

+ (void)LZ_trackEvent:(LZAnalyticsEvent)event
              content:(NSString *)content
               remark1:(NSString *)remark1
               remark2:(NSString *)remark2
               remark3:(NSString *)remark3 {
    if (!LoanZen_APIConfig.hasSigningProfile) return;
    NSString *eventCode = LZAnalyticsEventCodeString(event);
    if (eventCode.length == 0) return;

    NSDictionary *data = @{
        @"eventCode": eventCode,
        @"eventContent": [self LZ_normalizedField:content],
        @"remark1": [self LZ_normalizedField:remark1],
        @"remark2": [self LZ_normalizedField:remark2],
        @"remark3": [self LZ_normalizedField:remark3],
    };
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/bury/record"
                             signParams:data
                             dataParams:data
                            showLoading:NO
                             completion:^(NSDictionary *json, NSError *error) {
        (void)json;
        (void)error;
    }];
}

@end
