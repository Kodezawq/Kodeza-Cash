#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_EMIInput : NSObject
@property (nonatomic, assign) double amount;
@property (nonatomic, assign) NSInteger years;
@property (nonatomic, assign) double annualRatePercent;
@end

@interface LoanZen_EMIResult : NSObject
@property (nonatomic, copy) NSString *totalPayment;
@property (nonatomic, copy) NSString *monthlyEMI;
@property (nonatomic, copy) NSString *totalInterest;
@property (nonatomic, strong) LoanZen_EMIInput *input;
@end

@interface LoanZen_EMICalculator : NSObject
+ (LoanZen_EMIResult *)LZ_computeWithInput:(LoanZen_EMIInput *)input;
@end

NS_ASSUME_NONNULL_END
