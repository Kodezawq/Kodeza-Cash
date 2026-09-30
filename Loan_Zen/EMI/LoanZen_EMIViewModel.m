#import "LoanZen_EMIViewModel.h"

@implementation LoanZen_EMIViewModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _amount = 50000;
        _years = 5;
        _rate = 3;
    }
    return self;
}

- (void)LZ_normalizeFields {
    if (self.amount < 1) self.amount = 1;
    if (self.amount > 10000000) self.amount = 10000000;
    if (self.years < 1) self.years = 1;
    if (self.years > 25) self.years = 25;
    if (self.rate < 1) self.rate = 1;
    if (self.rate > 22) self.rate = 22;
    [self LZ_notifyStateChanged];
}

- (LoanZen_EMIResult *)LZ_submitResult {
    [self LZ_normalizeFields];
    LoanZen_EMIInput *input = [[LoanZen_EMIInput alloc] init];
    input.amount = self.amount;
    input.years = self.years;
    input.annualRatePercent = self.rate;
    return [LoanZen_EMICalculator LZ_computeWithInput:input];
}

@end
