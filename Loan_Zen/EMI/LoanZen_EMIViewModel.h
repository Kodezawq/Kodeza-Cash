#import "LoanZen_ViewModel.h"
#import "LoanZen_EMICalculator.h"

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_EMIViewModel : LoanZen_ViewModel

@property (nonatomic, assign) double amount;
@property (nonatomic, assign) NSInteger years;
@property (nonatomic, assign) double rate;

- (void)LZ_normalizeFields;
- (nullable LoanZen_EMIResult *)LZ_submitResult;

@end

NS_ASSUME_NONNULL_END
