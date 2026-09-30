#import "LoanZen_ScreenScaffoldView.h"
#import "LoanZen_DesignSystem.h"
@import Masonry;

@interface LoanZen_ScreenScaffoldView ()
@property (nonatomic, strong) UIImageView *backgroundView;
@property (nonatomic, copy) void (^backAction)(void);
@end

@implementation LoanZen_ScreenScaffoldView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [LoanZen_Color background];

        _backgroundView = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:[LoanZen_Asset pageBackground]]];
        _backgroundView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_backgroundView];

        _headerView = [[UIView alloc] init];
        _headerView.backgroundColor = UIColor.clearColor;
        [self addSubview:_headerView];

        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setImage:[LoanZen_Asset imageNamed:[LoanZen_Asset backArrow]] forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(LZ_tapBack) forControlEvents:UIControlEventTouchUpInside];
        [_headerView addSubview:_backButton];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [LoanZen_Font title2];
        _titleLabel.textColor = [LoanZen_Color primaryText];
        _titleLabel.textAlignment = NSTextAlignmentRight;
        [_headerView addSubview:_titleLabel];

        _contentView = [[UIView alloc] init];
        [self addSubview:_contentView];

        [_backgroundView mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self); }];
        [_headerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.mas_safeAreaLayoutGuideTop);
            make.left.right.equalTo(self);
            make.height.mas_equalTo(44);
        }];
        [_backButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_headerView).offset(8);
            make.centerY.equalTo(_headerView);
            make.width.height.mas_equalTo(44);
        }];
        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(_headerView).offset(-LZ_SizePageInset);
            make.centerY.equalTo(_headerView);
            make.left.greaterThanOrEqualTo(_backButton.mas_right).offset(8);
        }];
        [_contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_headerView.mas_bottom);
            make.left.right.bottom.equalTo(self);
        }];
    }
    return self;
}

- (void)LZ_setHeaderTitle:(NSString *)title { self.titleLabel.text = title; }
- (void)LZ_setBackAction:(void (^)(void))action { self.backAction = action; }

- (void)LZ_useKYCStyle {
    UIImage *img = [LoanZen_Asset imageNamed:[LoanZen_Asset kycBackArrow]];
    if (img) [self.backButton setImage:img forState:UIControlStateNormal];
    self.titleLabel.textColor = [LoanZen_Color primaryText];
    self.backgroundView.hidden = NO;
    self.backgroundColor = [LoanZen_Color background];
    self.contentView.backgroundColor = UIColor.clearColor;
    self.opaque = YES;
}

- (void)LZ_useLoanDetailAccentStyle {
    UIImage *img = [[LoanZen_Asset imageNamed:[LoanZen_Asset backArrow]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.backButton setImage:img forState:UIControlStateNormal];
    self.backButton.tintColor = UIColor.whiteColor;
    self.titleLabel.textColor = UIColor.whiteColor;
    self.backgroundView.hidden = YES;
    self.backgroundColor = UIColor.clearColor;
}

- (void)LZ_useLoanConfirmationStyle {
    [self LZ_useKYCStyle];
    self.backgroundView.hidden = NO;
    self.backgroundColor = [LoanZen_Color background];
}

- (void)LZ_useProfilePageStyle {
    [self LZ_useLoanConfirmationStyle];
}

- (void)LZ_tapBack { if (self.backAction) self.backAction(); }

@end
