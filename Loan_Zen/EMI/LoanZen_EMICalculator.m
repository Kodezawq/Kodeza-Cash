#import "LoanZen_EMICalculator.h"

@implementation LoanZen_EMIInput
@end

@implementation LoanZen_EMIResult
@end

@implementation LoanZen_EMICalculator

+ (LoanZen_EMIResult *)LZ_computeWithInput:(LoanZen_EMIInput *)input {
    double P = MAX(1, input.amount);
    NSInteger years = MAX(1, input.years);
    double r = input.annualRatePercent / 100.0 / 12.0;
    double n = years * 12.0;
    double monthly;
    if (r < 1e-9) {
        monthly = P / n;
    } else {
        monthly = P * r * pow(1 + r, n) / (pow(1 + r, n) - 1);
    }
    double totalPay = monthly * n;
    double interest = totalPay - P;

    // 对齐 EasyFund：结果金额四舍五入为整数后再展示
    monthly = round(monthly);
    totalPay = round(totalPay);
    interest = round(interest);

    NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
    nf.minimumFractionDigits = 0;
    nf.maximumFractionDigits = 0;
    nf.numberStyle = NSNumberFormatterDecimalStyle;
    nf.groupingSeparator = @",";
    nf.usesGroupingSeparator = YES;

    LoanZen_EMIResult *result = [[LoanZen_EMIResult alloc] init];
    result.input = input;
    result.totalPayment = [nf stringFromNumber:@(totalPay)] ?: [NSString stringWithFormat:@"%.0f", totalPay];
    result.monthlyEMI = [nf stringFromNumber:@(monthly)] ?: [NSString stringWithFormat:@"%.0f", monthly];
    result.totalInterest = [nf stringFromNumber:@(interest)] ?: [NSString stringWithFormat:@"%.0f", interest];
    return result;
}

@end
