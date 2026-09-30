#import "LoanZen_BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_LoanConfirmationViewController : LoanZen_BaseViewController

@property (nonatomic, assign, readonly) BOOL embeddedInKYCFlow;

- (instancetype)initWithProductId:(NSString *)productId;
- (instancetype)initWithProductId:(NSString *)productId embeddedInKYCFlow:(BOOL)embeddedInKYCFlow;

/// 通讯录强抓失败：退出当前页（KYC 嵌入回主界面，否则 pop）；并刷新首页。
- (void)LZ_handleContactsCollectionBlocked;
- (void)LZ_exitAfterContactsBlocked;

@end

NS_ASSUME_NONNULL_END
