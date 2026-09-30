#import "LoanZen_BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_BankFormViewController : LoanZen_BaseViewController

@property (nonatomic, copy, nullable) void (^onSubmissionSucceeded)(void);
- (instancetype)initWithEditingAccount:(nullable NSDictionary *)account;
@end

NS_ASSUME_NONNULL_END
