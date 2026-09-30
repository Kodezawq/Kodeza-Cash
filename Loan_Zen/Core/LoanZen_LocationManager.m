#import "LoanZen_LocationManager.h"
#import "LoanZen_PermissionHelper.h"
#import "LoanZen_BuryReporter.h"
#import <UIKit/UIKit.h>

@interface LoanZen_LocationManager () <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *manager;
@property (nonatomic, copy) void (^orderCompletion)(NSString *, NSString *, BOOL);
@property (nonatomic, weak) UIViewController *orderPresenter;
@property (nonatomic, assign) BOOL orderForceMode;
@property (nonatomic, assign) BOOL isRequestingOrderLocation;
@property (nonatomic, assign) BOOL shouldHandleAuthorizationChange;
@property (nonatomic, assign) BOOL isTrackingLocation;
@property (nonatomic, assign) CLAuthorizationStatus cachedAuthorizationStatus;
@property (nonatomic, copy, readwrite) NSString *longitude;
@property (nonatomic, copy, readwrite) NSString *latitude;
@end

@implementation LoanZen_LocationManager

+ (instancetype)shared {
    static LoanZen_LocationManager *mgr;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ mgr = [[LoanZen_LocationManager alloc] init]; });
    return mgr;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _cachedAuthorizationStatus = kCLAuthorizationStatusNotDetermined;
        _manager = [[CLLocationManager alloc] init];
        _manager.delegate = self;
        _manager.desiredAccuracy = kCLLocationAccuracyBest;
        _manager.distanceFilter = 50;
        _longitude = @"-360";
        _latitude = @"-360";
    }
    return self;
}

- (CLAuthorizationStatus)authorizationStatus {
    return self.cachedAuthorizationStatus;
}

- (void)LZ_requestLocationForOrderWithForceMode:(BOOL)forceMode
                                       presenter:(UIViewController *)presenter
                                      completion:(void (^)(NSString *, NSString *, BOOL))completion {
    if (self.isRequestingOrderLocation) {
        completion(@"-360", @"-360", NO);
        return;
    }
    self.isRequestingOrderLocation = YES;
    self.shouldHandleAuthorizationChange = NO;
    self.isTrackingLocation = NO;
    self.orderForceMode = forceMode;
    self.orderPresenter = presenter;
    self.orderCompletion = completion;
    self.longitude = @"-360";
    self.latitude = @"-360";

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        BOOL servicesEnabled = [CLLocationManager locationServicesEnabled];
        CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.isRequestingOrderLocation) return;

            self.cachedAuthorizationStatus = status;
            if (!servicesEnabled) {
                [self LZ_handlePreviouslyDeniedLocationAccess];
                return;
            }
            [self LZ_processAuthorizationStatus:status fromDelegate:NO];
        });
    });
}

#pragma mark - HopeLoan-aligned branches

/// 首次系统弹窗之前：已拒绝 / 受限 / 定位服务关闭
- (void)LZ_handlePreviouslyDeniedLocationAccess {
    [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventLocationPermissionFailure];
    if (self.orderForceMode) {
        if (self.orderPresenter) {
            __weak typeof(self) weakSelf = self;
            void (^finishBlocked)(void) = ^{
                [weakSelf LZ_finishOrderLocationWithLongitude:@"-360" latitude:@"-360" shouldCancel:YES];
            };
            [LoanZen_PermissionHelper LZ_showSettingsGuideOn:self.orderPresenter
                                                       title:@"Location"
                                             permissionTitle:@"Location"
                                                    onCancel:finishBlocked
                                           onConfirmSettings:finishBlocked];
        } else {
            [self LZ_finishOrderLocationWithLongitude:@"-360" latitude:@"-360" shouldCancel:YES];
        }
        return;
    }
    [self LZ_finishOrderLocationWithLongitude:@"-360" latitude:@"-360" shouldCancel:NO];
}

/// 系统弹窗点拒绝后：强抓不弹二次引导，直接结束；非强抓用 -360 继续
- (void)LZ_handleSystemPromptDeniedLocationAccess {
    [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventLocationPermissionFailure];
    if (self.orderForceMode) {
        [self LZ_finishOrderLocationWithLongitude:@"-360" latitude:@"-360" shouldCancel:YES];
        return;
    }
    [self LZ_finishOrderLocationWithLongitude:@"-360" latitude:@"-360" shouldCancel:NO];
}

- (void)LZ_processAuthorizationStatus:(CLAuthorizationStatus)status fromDelegate:(BOOL)fromDelegate {
    if (!self.isRequestingOrderLocation) return;

    switch (status) {
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            self.shouldHandleAuthorizationChange = NO;
            [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventLocationPermissionSuccess];
            [self LZ_beginLocationTracking];
            break;
        case kCLAuthorizationStatusNotDetermined:
            if (!fromDelegate) {
                self.shouldHandleAuthorizationChange = YES;
                [self.manager requestWhenInUseAuthorization];
            }
            break;
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted:
            self.shouldHandleAuthorizationChange = NO;
            if (fromDelegate) {
                [self LZ_handleSystemPromptDeniedLocationAccess];
            } else {
                [self LZ_handlePreviouslyDeniedLocationAccess];
            }
            break;
        default:
            self.shouldHandleAuthorizationChange = NO;
            [self LZ_finishOrderLocationWithLongitude:@"-360" latitude:@"-360" shouldCancel:NO];
            break;
    }
}

- (void)LZ_beginLocationTracking {
    self.isTrackingLocation = YES;
    self.manager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    [self.manager startUpdatingLocation];
}

- (void)LZ_finishOrderLocationWithLongitude:(NSString *)longitude latitude:(NSString *)latitude shouldCancel:(BOOL)shouldCancel {
    if (!self.isRequestingOrderLocation) return;
    [self.manager stopUpdatingLocation];
    self.isTrackingLocation = NO;
    self.shouldHandleAuthorizationChange = NO;
    void (^cb)(NSString *, NSString *, BOOL) = self.orderCompletion;
    self.orderCompletion = nil;
    self.isRequestingOrderLocation = NO;
    self.orderForceMode = NO;
    self.orderPresenter = nil;
    if (cb) cb(longitude, latitude, shouldCancel);
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager {
    self.cachedAuthorizationStatus = manager.authorizationStatus;
    if (!self.isRequestingOrderLocation) return;
    if (!self.shouldHandleAuthorizationChange) return;
    [self LZ_processAuthorizationStatus:manager.authorizationStatus fromDelegate:YES];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (!self.isRequestingOrderLocation || !self.isTrackingLocation) return;
    CLLocation *loc = locations.lastObject;
    if (!loc) return;

    [manager stopUpdatingLocation];
    self.isTrackingLocation = NO;
    self.latitude = [NSString stringWithFormat:@"%.6f", loc.coordinate.latitude];
    self.longitude = [NSString stringWithFormat:@"%.6f", loc.coordinate.longitude];

    if (self.orderForceMode) {
        [self LZ_finishOrderLocationWithLongitude:self.longitude latitude:self.latitude shouldCancel:NO];
    } else {
        [self LZ_finishOrderLocationWithLongitude:@"-360" latitude:@"-360" shouldCancel:NO];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if (!self.isRequestingOrderLocation || !self.isTrackingLocation) return;
    [manager stopUpdatingLocation];
    self.isTrackingLocation = NO;

    if (self.orderForceMode) {
        [self LZ_finishOrderLocationWithLongitude:@"-360" latitude:@"-360" shouldCancel:YES];
    } else {
        [self LZ_finishOrderLocationWithLongitude:@"-360" latitude:@"-360" shouldCancel:NO];
    }
}

@end
