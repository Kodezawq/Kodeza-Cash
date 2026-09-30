#import <Foundation/Foundation.h>
#import "LoanZen_AnalyticsEventCodes.h"

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_BuryReporter : NSObject

+ (void)LZ_trackEvent:(LZAnalyticsEvent)event;
+ (void)LZ_trackEvent:(LZAnalyticsEvent)event content:(NSString *)content;
+ (void)LZ_trackEvent:(LZAnalyticsEvent)event
              content:(NSString *)content
               remark1:(NSString *)remark1
               remark2:(NSString *)remark2
               remark3:(NSString *)remark3;

@end

NS_ASSUME_NONNULL_END
