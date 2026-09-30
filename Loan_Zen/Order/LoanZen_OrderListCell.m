#import "LoanZen_OrderListCell.h"
#import "LoanZen_DesignSystem.h"
@import Masonry;

@interface LoanZen_OrderListCell ()
@property (nonatomic, strong) UIView *cardContainer;
@property (nonatomic, strong) UIView *embeddedCard;
@end

@implementation LoanZen_OrderListCell

+ (NSString *)LZ_reuseIdentifier { return @"LoanZen_OrderListCell"; }

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.clearColor;
        self.contentView.backgroundColor = UIColor.clearColor;

        self.cardContainer = [[UIView alloc] init];
        self.cardContainer.backgroundColor = UIColor.clearColor;
        [self.contentView addSubview:self.cardContainer];

        CGFloat halfGap = 6;
        [self.cardContainer mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.contentView).inset(LZ_SizePageInset);
            make.top.equalTo(self.contentView).offset(halfGap);
            make.bottom.equalTo(self.contentView).offset(-halfGap);
        }];
    }
    return self;
}

- (void)LZ_configureWithCard:(UIView *)cardView {
    [self.embeddedCard removeFromSuperview];
    self.embeddedCard = cardView;
    if (!cardView) return;
    [self.cardContainer addSubview:cardView];
    [cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.cardContainer);
    }];
}

- (void)LZ_configureEmptyState {
    [self.embeddedCard removeFromSuperview];
    self.embeddedCard = nil;

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 16;
    stack.alignment = UIStackViewAlignmentCenter;

    UIImage *icon = [LoanZen_Asset imageNamed:@"lz_order_kzt"];
    UIImageView *iconView = [[UIImageView alloc] initWithImage:icon];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    if (icon) {
        [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(120);
        }];
    }

    UILabel *label = [[UILabel alloc] init];
    label.text = @"No orders";
    label.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    label.textColor = [LoanZen_Color primaryText];
    label.textAlignment = NSTextAlignmentCenter;

    if (icon) [stack addArrangedSubview:iconView];
    [stack addArrangedSubview:label];

    self.embeddedCard = stack;
    [self.cardContainer addSubview:stack];
    [stack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.cardContainer);
        make.top.greaterThanOrEqualTo(self.cardContainer).offset(48);
        make.bottom.lessThanOrEqualTo(self.cardContainer).offset(-48);
    }];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.embeddedCard removeFromSuperview];
    self.embeddedCard = nil;
}

@end
