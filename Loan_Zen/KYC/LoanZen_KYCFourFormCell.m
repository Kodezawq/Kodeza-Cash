#import "LoanZen_KYCFourFormCell.h"
#import "LoanZen_DesignSystem.h"
@import Masonry;

NSString * const LZ_KYCFourFormTextCellId = @"LZ_KYCFourFormTextCell";
NSString * const LZ_KYCFourFormSelectCellId = @"LZ_KYCFourFormSelectCell";

static void LZ_applyKYCInputChrome(UIView *wrap) {
    wrap.backgroundColor = [LoanZen_Color kycFormInputFill];
    wrap.layer.cornerRadius = 10;
    wrap.layer.borderWidth = 1;
    wrap.layer.borderColor = [LoanZen_Color kycFormInputBorder].CGColor;
    wrap.clipsToBounds = YES;
}

@interface LoanZen_KYCFourFormTextCell ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *inputWrap;
@property (nonatomic, strong, readwrite) UITextField *inputField;
@end

@implementation LoanZen_KYCFourFormTextCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.clearColor;
        self.contentView.backgroundColor = UIColor.clearColor;

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
        _titleLabel.textColor = [LoanZen_Color kycFormLabel];
        _titleLabel.numberOfLines = 0;

        _inputWrap = [[UIView alloc] init];
        LZ_applyKYCInputChrome(_inputWrap);

        _inputField = [[UITextField alloc] init];
        _inputField.borderStyle = UITextBorderStyleNone;
        _inputField.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        _inputField.textColor = [LoanZen_Color kycFormValue];
        _inputField.autocorrectionType = UITextAutocorrectionTypeNo;
        _inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _inputField.tintColor = [LoanZen_Color accent];

        [self.contentView addSubview:_titleLabel];
        [self.contentView addSubview:_inputWrap];
        [_inputWrap addSubview:_inputField];
        [_inputField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(_inputWrap).inset(14);
            make.centerY.equalTo(_inputWrap);
            make.height.mas_equalTo(22);
        }];
    }
    return self;
}

- (void)LZ_applyPlaceholder:(NSString *)placeholder {
    if (placeholder.length == 0) placeholder = @"Please enter";
    self.inputField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:@{
        NSForegroundColorAttributeName: [LoanZen_Color kycFormPlaceholder],
        NSFontAttributeName: [UIFont systemFontOfSize:14 weight:UIFontWeightRegular],
    }];
}

- (void)LZ_configureWithTitle:(NSString *)title placeholder:(NSString *)placeholder text:(NSString *)text isFirstRow:(BOOL)isFirstRow isLastRow:(BOOL)isLastRow {
    self.titleLabel.text = title;
    [self LZ_applyPlaceholder:placeholder];
    self.inputField.text = text;
    CGFloat titleTop = isFirstRow ? 16 : 24;
    CGFloat bottomPad = isLastRow ? 16 : 0;
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(titleTop);
        make.left.right.equalTo(self.contentView).inset(16);
    }];
    [self.inputWrap mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.left.right.equalTo(self.contentView).inset(16);
        make.bottom.equalTo(self.contentView).offset(-bottomPad);
        make.height.mas_equalTo(48);
    }];
}

@end

@interface LoanZen_KYCFourFormSelectCell ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *inputWrap;
@property (nonatomic, strong) UIButton *chooseButton;
@property (nonatomic, strong) UIImageView *chevronView;
@end

@implementation LoanZen_KYCFourFormSelectCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.clearColor;
        self.contentView.backgroundColor = UIColor.clearColor;

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
        _titleLabel.textColor = [LoanZen_Color kycFormLabel];
        _titleLabel.numberOfLines = 0;

        _inputWrap = [[UIView alloc] init];
        LZ_applyKYCInputChrome(_inputWrap);

        _chooseButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _chooseButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _chooseButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        _chooseButton.contentEdgeInsets = UIEdgeInsetsMake(0, 14, 0, 36);
        [_chooseButton addTarget:self action:@selector(LZ_tapChoose) forControlEvents:UIControlEventTouchUpInside];

        UIImage *chevron = [[LoanZen_Asset imageNamed:[LoanZen_Asset expandChevron]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _chevronView = [[UIImageView alloc] initWithImage:chevron ?: [UIImage systemImageNamed:@"chevron.down"]];
        _chevronView.tintColor = [LoanZen_Color kycFormPlaceholder];
        _chevronView.contentMode = UIViewContentModeScaleAspectFit;

        [self.contentView addSubview:_titleLabel];
        [self.contentView addSubview:_inputWrap];
        [_inputWrap addSubview:_chooseButton];
        [_inputWrap addSubview:_chevronView];
        [_chooseButton mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(_inputWrap); }];
        [_chevronView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(_inputWrap);
            make.right.equalTo(_inputWrap).offset(-14);
            make.width.height.mas_equalTo(16);
        }];
    }
    return self;
}

- (void)LZ_configureWithTitle:(NSString *)title displayTitle:(NSString *)displayTitle isFirstRow:(BOOL)isFirstRow isLastRow:(BOOL)isLastRow {
    self.titleLabel.text = title;
    [self LZ_applyDisplayTitle:displayTitle];

    CGFloat titleTop = isFirstRow ? 16 : 24;
    CGFloat bottomPad = isLastRow ? 16 : 0;
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(titleTop);
        make.left.right.equalTo(self.contentView).inset(16);
    }];
    [self.inputWrap mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.left.right.equalTo(self.contentView).inset(16);
        make.bottom.equalTo(self.contentView).offset(-bottomPad);
        make.height.mas_equalTo(48);
    }];
}

- (void)LZ_updateDisplayTitle:(NSString *)displayTitle {
    [self LZ_applyDisplayTitle:displayTitle];
}

- (void)LZ_applyDisplayTitle:(NSString *)displayTitle {
    NSString *text = displayTitle.length > 0 ? displayTitle : @"Please choose";
    BOOL placeholder = [text isEqualToString:@"Please choose"];
    [self.chooseButton setTitle:text forState:UIControlStateNormal];
    UIColor *color = placeholder ? [LoanZen_Color kycFormPlaceholder] : [LoanZen_Color kycFormValue];
    [self.chooseButton setTitleColor:color forState:UIControlStateNormal];
}

- (void)LZ_tapChoose {
    if (self.onTapChoose) self.onTapChoose();
}

@end
