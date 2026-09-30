#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_LocationManager : NSObject

@property (class, nonatomic, readonly) LoanZen_LocationManager *shared;
@property (nonatomic, copy, readonly) NSString *longitude;
@property (nonatomic, copy, readonly) NSString *latitude;
@property (nonatomic, assign, readonly) CLAuthorizationStatus authorizationStatus;

/// 下单流程：获取经纬度。completion(longitude, latitude, shouldCancelOrder)
- (void)LZ_requestLocationForOrderWithForceMode:(BOOL)forceMode
                                       presenter:(UIViewController *)presenter
                                      completion:(void (^)(NSString *longitude, NSString *latitude, BOOL shouldCancelOrder))completion;

@end

NS_ASSUME_NONNULL_END
