#import "LoanZen_ViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_MeViewModel : LoanZen_ViewModel
@property (nonatomic, copy, readonly) NSString *userName;
@property (nonatomic, copy, readonly) NSString *mobileDisplay;
@property (nonatomic, copy, readonly) NSArray<NSDictionary *> *menuItems;
- (void)LZ_loadProfile;
- (void)LZ_refreshUserInfo;
- (void)LZ_logout;
@end

NS_ASSUME_NONNULL_END
