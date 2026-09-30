#import "LoanZen_OrderDetailBankCardView.h"
#import "LoanZen_DesignSystem.h"
@import Masonry;

@interface LoanZen_OrderDetailBankCardView ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *cardContainer;
@property (nonatomic, strong) UILabel *numberLabel;
@property (nonatomic, strong) UIImageView *iconView;
@end

@implementation LoanZen_OrderDetailBankCardView

+ (BOOL)LZ_hasDisplayableCardNumber:(NSString *)maskedCardNumber {
    if (maskedCardNumber.length == 0) return NO;
    NSString *trimmed = [maskedCardNumber stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) return NO;
    return ![trimmed isEqualToString:@"—"] && ![trimmed isEqualToString:@"-"];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self LZ_buildUI];
    }
    return self;
}

- (void)LZ_buildUI {
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"Bank Account";
    self.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    self.titleLabel.textColor = [LoanZen_Color kycFormLabel];

    self.cardContainer = [[UIView alloc] init];
    self.cardContainer.backgroundColor = [LoanZen_Color kycFormInputFill];
    self.cardContainer.layer.cornerRadius = 12;
    self.cardContainer.layer.borderWidth = 1;
    self.cardContainer.layer.borderColor = [[LoanZen_Color accent] colorWithAlphaComponent:0.45].CGColor;

    self.numberLabel = [[UILabel alloc] init];
    self.numberLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.numberLabel.textColor = [LoanZen_Color primaryText];

    self.iconView = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:@"lz_loan_bank"]];
    self.iconView.contentMode = UIViewContentModeScaleAspectFit;

    [self addSubview:self.titleLabel];
    [self addSubview:self.cardContainer];
    [self.cardContainer addSubview:self.numberLabel];
    [self.cardContainer addSubview:self.iconView];

    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
    }];
    [self.cardContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.left.right.bottom.equalTo(self);
        make.height.mas_equalTo(48);
    }];
    [self.numberLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.cardContainer).offset(14);
        make.centerY.equalTo(self.cardContainer);
        make.right.lessThanOrEqualTo(self.iconView.mas_left).offset(-10);
    }];
    [self.iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.cardContainer).offset(-14);
        make.centerY.equalTo(self.cardContainer);
        make.width.height.mas_equalTo(22);
    }];
}

- (void)LZ_configureWithMaskedCardNumber:(NSString *)maskedCardNumber {
    BOOL showsCard = [LoanZen_OrderDetailBankCardView LZ_hasDisplayableCardNumber:maskedCardNumber];
    self.hidden = !showsCard;
    if (!showsCard) return;
    self.numberLabel.text = maskedCardNumber;
}

@end
