#import "LoanZen_OrderListCardView.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_ColorUtils.h"
@import Masonry;

@implementation LoanZen_OrderListCardView

+ (instancetype)LZ_cardWithProduct:(NSString *)product
                            amount:(NSString *)amount
                    statusBarImage:(UIImage *)statusBarImage
                         leftTitle:(NSString *)leftTitle
                         leftValue:(NSString *)leftValue
                        rightTitle:(NSString *)rightTitle
                        rightValue:(NSString *)rightValue {
    LoanZen_OrderListCardView *card = [[LoanZen_OrderListCardView alloc] init];
    card.backgroundColor = [LoanZen_ColorUtils LZ_glassFill08];
    card.layer.cornerRadius = 16;
    card.layer.borderWidth = 1;
    card.layer.borderColor = [LoanZen_ColorUtils LZ_glassBorder14].CGColor;
    card.clipsToBounds = YES;

    UILabel *productLabel = [[UILabel alloc] init];
    productLabel.text = product.length > 0 ? product : @"—";
    productLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    productLabel.textColor = [LoanZen_Color primaryText];
    productLabel.numberOfLines = 1;

    UILabel *amountLabel = [[UILabel alloc] init];
    amountLabel.text = amount.length > 0 ? amount : @"—";
    amountLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    amountLabel.textColor = [LoanZen_Color accent];
    amountLabel.textAlignment = NSTextAlignmentRight;
    amountLabel.adjustsFontSizeToFitWidth = YES;
    amountLabel.minimumScaleFactor = 0.8;

    UIStackView *headerRow = [[UIStackView alloc] initWithArrangedSubviews:@[productLabel, amountLabel]];
    headerRow.axis = UILayoutConstraintAxisHorizontal;
    headerRow.alignment = UIStackViewAlignmentCenter;
    headerRow.spacing = 8;
    [amountLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [productLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

    UIImageView *statusBar = [[UIImageView alloc] initWithImage:statusBarImage];
    statusBar.contentMode = UIViewContentModeScaleAspectFit;
    statusBar.hidden = statusBarImage == nil;

    UIStackView *leftMetric = [self LZ_metricColumnWithTitle:leftTitle.length > 0 ? leftTitle : @"Date of application"
                                                      value:leftValue
                                                 alignRight:NO];
    UIStackView *rightMetric = [self LZ_metricColumnWithTitle:rightTitle.length > 0 ? rightTitle : @"Due date"
                                                       value:rightValue
                                                  alignRight:YES];
    UIStackView *metricRow = [[UIStackView alloc] initWithArrangedSubviews:@[leftMetric, rightMetric]];
    metricRow.axis = UILayoutConstraintAxisHorizontal;
    metricRow.distribution = UIStackViewDistributionFillEqually;
    metricRow.alignment = UIStackViewAlignmentTop;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[headerRow, statusBar, metricRow]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;
    stack.alignment = UIStackViewAlignmentFill;
    [card addSubview:stack];

    [stack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(card).insets(UIEdgeInsetsMake(16, 16, 16, 16));
    }];
    if (statusBarImage) {
        [statusBar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(34);
        }];
    } else {
        [statusBar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(0);
        }];
    }
    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(343);
    }];
    return card;
}

+ (UIStackView *)LZ_metricColumnWithTitle:(NSString *)title value:(NSString *)value alignRight:(BOOL)alignRight {
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
    titleLabel.textColor = [LoanZen_Color secondaryText];
    titleLabel.textAlignment = alignRight ? NSTextAlignmentRight : NSTextAlignmentLeft;

    UILabel *valueLabel = [[UILabel alloc] init];
    valueLabel.text = value.length > 0 ? value : @"—";
    valueLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    valueLabel.textColor = [LoanZen_Color primaryText];
    valueLabel.textAlignment = alignRight ? NSTextAlignmentRight : NSTextAlignmentLeft;
    valueLabel.numberOfLines = 2;

    UIStackView *col = [[UIStackView alloc] initWithArrangedSubviews:@[titleLabel, valueLabel]];
    col.axis = UILayoutConstraintAxisVertical;
    col.spacing = 4;
    col.alignment = alignRight ? UIStackViewAlignmentTrailing : UIStackViewAlignmentLeading;
    return col;
}

@end
