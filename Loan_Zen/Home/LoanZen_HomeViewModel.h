#import "LoanZen_ViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_HomeViewModel : LoanZen_ViewModel
@property (nonatomic, copy, readonly) NSString *welcomeText;
@property (nonatomic, copy, readonly) NSString *kycHint;
@property (nonatomic, copy, readonly) NSArray<NSDictionary *> *products;
@property (nonatomic, assign, readonly) NSInteger userStatus;
@property (nonatomic, copy, readonly, nullable) NSString *withdrawalOrderId;
@property (nonatomic, assign, readonly) BOOL kycJumpEnabled;
@property (nonatomic, assign, readonly) BOOL pendingKyc;
@property (nonatomic, assign, readonly) BOOL hideCenterAndApply;
@property (nonatomic, assign, readonly) NSInteger checkInCompletedDays;
@property (nonatomic, assign, readonly) BOOL hasCheckedInToday;

- (void)LZ_loadHomeData;
- (void)LZ_showGuestHome;
- (void)LZ_refreshWithLoading:(BOOL)loading;
/// 应用 `SupHomeStore` 最新缓存并刷新产品区（不再请求 suphome）。
- (void)LZ_reloadFromCachedSuphome;
- (BOOL)LZ_performCheckIn;
- (void)LZ_refreshCheckInState;
@end

NS_ASSUME_NONNULL_END
