#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_AdjustManager : NSObject
+ (void)LZ_configureIfNeeded;
+ (void)LZ_fetchAdid:(void (^)(NSString * _Nullable adid))completion;
@end

NS_ASSUME_NONNULL_END
