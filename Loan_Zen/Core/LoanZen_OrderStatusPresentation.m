#import "LoanZen_OrderStatusPresentation.h"
#import "LoanZen_ColorUtils.h"

@implementation LoanZen_OrderStatusPresentation

+ (BOOL)LZ_isRejectedStatus:(NSNumber *)status {
    if (!status) return NO;
    NSInteger value = status.integerValue;
    return value == 31 || value == 41;
}

+ (NSString *)LZ_listBadgeTitleForStatus:(NSNumber *)status {
    // 对齐 LoanBase：30=Under review，50=Loan processing（下单成功后常见为 30）
    switch (status.intValue) {
        case 10: return @"Unfinished Application";
        case 20: case 36: return @"Change bank account";
        case 30: return @"Under review";
        case 31: return @"Reject";
        case 32: return @"To be withdrawn";
        case 50: return @"Loan processing";
        case 60: case 63: return @"Pending Repayment";
        case 61: return @"Overdue";
        case 40: case 70: case 71: return @"Pay off";
        case 99: return @"Cancel";
        default: return @"Under review";
    }
}

+ (UIColor *)LZ_listBadgeColorForStatus:(NSNumber *)status {
    switch (status.intValue) {
        case 10: return [LoanZen_ColorUtils LZ_orderStatusPending];
        case 20: case 36: return [LoanZen_ColorUtils LZ_orderStatusReview];
        case 30: return [LoanZen_ColorUtils LZ_orderStatusReview];
        case 31: case 99: return [LoanZen_ColorUtils LZ_orderStatusNeutral];
        case 32: return [LoanZen_ColorUtils LZ_orderStatusWarning];
        case 50: return [LoanZen_ColorUtils LZ_orderStatusActive];
        case 40: case 70: case 71: return [LoanZen_ColorUtils LZ_orderStatusSuccess];
        case 60: case 63: return [LoanZen_ColorUtils LZ_orderStatusActive];
        case 61: return [LoanZen_ColorUtils LZ_orderStatusOverdue];
        default: return [LoanZen_ColorUtils LZ_orderStatusReview];
    }
}

+ (NSString *)LZ_listStatusBarImageNameForStatus:(NSNumber *)status {
    switch (status.intValue) {
        case 10: return @"lz_order_una";
        case 20: case 36: return @"lz_order_chb";
        case 30: return @"lz_order_unr";
        case 31: return @"lz_order_rej";
        case 32: return @"lz_order_tbw";
        case 50: return @"lz_order_loap";
        case 40: case 70: case 71: return @"lz_order_pao";
        case 60: case 63: return @"lz_order_per";
        case 61: return @"lz_order_ove";
        case 99: return @"lz_order_cank";
        default: return @"lz_order_unr";
    }
}

+ (NSString *)LZ_normalizedDateDisplay:(NSString *)raw {
    NSString *trimmed = [[raw ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] copy];
    return trimmed.length > 0 ? trimmed : @"—";
}

+ (NSString *)LZ_firstNonEmptyDate:(NSArray<NSString *> *)candidates {
    for (NSString *raw in candidates) {
        NSString *trimmed = [[raw ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] copy];
        if (trimmed.length > 0) return trimmed;
    }
    return @"—";
}

+ (NSDictionary<NSString *, NSString *> *)LZ_listDateMetricsForStatus:(NSNumber *)status
                                                            applyDate:(NSString *)applyDate
                                                              dueDate:(NSString *)dueDate
                                                           payoutDate:(NSString *)payoutDate
                                                             loanDate:(NSString *)loanDate
                                                        repaymentDate:(NSString *)repaymentDate
                                                            repayDate:(NSString *)repayDate {
    NSString *apply = [self LZ_normalizedDateDisplay:applyDate];
    NSString *due = [self LZ_normalizedDateDisplay:dueDate];
    NSString *payment = [self LZ_firstNonEmptyDate:@[loanDate ?: @"", payoutDate ?: @"", repayDate ?: @""]];
    NSString *repaid = [self LZ_firstNonEmptyDate:@[repaymentDate ?: @"", repayDate ?: @""]];

    NSString *leftTitle = @"Date of application";
    NSString *leftValue = apply;
    NSString *rightTitle = @"Due date";
    NSString *rightValue = due;

    switch (status.intValue) {
        case 61:
            leftTitle = @"Payment date";
            leftValue = payment;
            rightTitle = @"Due date";
            rightValue = due;
            break;
        case 40:
        case 70:
        case 71:
            leftTitle = @"Payment date";
            leftValue = payment;
            rightTitle = @"Repayment date";
            rightValue = repaid;
            break;
        case 20:
        case 60:
        case 63:
            leftTitle = @"Payment date";
            leftValue = [payment isEqualToString:@"—"] ? apply : payment;
            rightTitle = @"Due date";
            rightValue = due;
            break;
        default:
            break;
    }

    return @{
        @"leftTitle": leftTitle,
        @"leftValue": leftValue,
        @"rightTitle": rightTitle,
        @"rightValue": rightValue,
    };
}

+ (NSString *)LZ_detailStatusTextForStatus:(NSNumber *)status {
    return [self LZ_listBadgeTitleForStatus:status];
}

+ (BOOL)LZ_showsRepayButtonForStatus:(NSNumber *)status {
    switch (status.intValue) {
        case 60: case 61: case 63: return YES;
        default: return NO;
    }
}

+ (BOOL)LZ_showsExtensionButtonForStatus:(NSNumber *)status ifExtension:(NSString *)ifExtension {
    switch (status.intValue) {
        case 60: case 63: return [ifExtension isEqualToString:@"1"];
        default: return NO;
    }
}

+ (NSString *)LZ_primaryActionTitleForStatus:(NSNumber *)status {
    switch (status.intValue) {
        case 10: return @"Unfinished Application";
        case 36: return @"Change Bank Account";
        default: return nil;
    }
}

+ (NSString *)LZ_bottomTipForStatus:(NSNumber *)status {
    switch (status.intValue) {
        case 10:
            return @"Submit your data to speed up the application process.";
        case 30:
            return @"Your application is currently under review, and the final loan amount depends on the credit assessment. Maintaining a good credit record can enhance the actual loan amount approved.";
        case 31:
            return @"Sorry, your loan qualification review did not receive approval. You may apply again later.";
        case 20: case 36:
            return @"Your bank card information is unable to receive the loan. Please update it promptly to ensure timely disbursement.";
        case 50:
            return @"Your loan application has been approved. The loan will be disbursed to your account shortly. Please keep an eye on your account.";
        case 60:
            return @"Please repay on time according to the repayment date provided by the system. Maintaining good credit will continue to increase your loan limit.";
        case 61:
            return @"This order has not been paid on time, and late fees are accruing daily. Please make the payment as soon as possible.";
        case 63:
            return @"Making repayment on time will improve your credit score and increase loan amount.";
        case 70:
            return @"Your previous order has been settled, and now you can apply for a higher loan amount to meet your greater funding needs.";
        case 71:
            return @"This order has been settled, and we have provided you with a higher loan amount. You can now apply for it.";
        case 99:
            return @"Your order has been cancelled. If you require further assistance, please feel free to contact our Customer Service team.";
        default:
            return nil;
    }
}

@end
