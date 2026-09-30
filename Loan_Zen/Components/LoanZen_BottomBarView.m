#import "LoanZen_BottomBarView.h"
#import "LoanZen_DesignSystem.h"
@import Masonry;

@interface LoanZen_BottomBarItem : UIButton
@end

@implementation LoanZen_BottomBarItem

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.adjustsImageWhenHighlighted = NO;
        [self mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(LZ_SizeBottomBarHeight);
        }];
    }
    return self;
}

@end

@interface LoanZen_BottomBarView ()
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, LoanZen_BottomBarItem *> *items;
@end

@implementation LoanZen_BottomBarView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _selectedTab = LoanZen_BottomTabLoan;
        _items = [NSMutableDictionary dictionary];
        self.backgroundColor = UIColor.clearColor;

        _stackView = [[UIStackView alloc] init];
        _stackView.axis = UILayoutConstraintAxisHorizontal;
        _stackView.alignment = UIStackViewAlignmentFill;
        _stackView.distribution = UIStackViewDistributionFillEqually;
        _stackView.spacing = 0;
        [self addSubview:_stackView];
        [_stackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
            make.height.mas_equalTo(LZ_SizeBottomBarHeight);
        }];

        for (NSInteger i = LoanZen_BottomTabLoan; i <= LoanZen_BottomTabMe; i++) {
            LoanZen_BottomBarItem *button = [self LZ_makeItemForTab:(LoanZen_BottomTab)i];
            self.items[@(i)] = button;
            [_stackView addArrangedSubview:button];
        }
        [self LZ_updateSelectionAnimated:NO];
    }
    return self;
}

- (LoanZen_BottomBarItem *)LZ_makeItemForTab:(LoanZen_BottomTab)tab {
    LoanZen_BottomBarItem *button = [[LoanZen_BottomBarItem alloc] initWithFrame:CGRectZero];
    button.tag = tab;
    [button addTarget:self action:@selector(LZ_tapItem:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)LZ_tapItem:(UIButton *)sender {
    self.selectedTab = (LoanZen_BottomTab)sender.tag;
    if (self.onSelectTab) self.onSelectTab(self.selectedTab);
}

- (void)setSelectedTab:(LoanZen_BottomTab)selectedTab {
    if (_selectedTab == selectedTab) return;
    _selectedTab = selectedTab;
    [self LZ_updateSelectionAnimated:YES];
}

- (NSString *)LZ_assetForTab:(LoanZen_BottomTab)tab selected:(BOOL)selected {
    switch (tab) {
        case LoanZen_BottomTabLoan: return selected ? [LoanZen_Asset tabHomeSelected] : [LoanZen_Asset tabHomeNormal];
        case LoanZen_BottomTabOrder: return selected ? [LoanZen_Asset tabOrderSelected] : [LoanZen_Asset tabOrderNormal];
        case LoanZen_BottomTabEMI: return selected ? [LoanZen_Asset tabEMISelected] : [LoanZen_Asset tabEMINormal];
        case LoanZen_BottomTabMe: return selected ? [LoanZen_Asset tabMeSelected] : [LoanZen_Asset tabMeNormal];
    }
    return @"";
}

- (void)LZ_updateSelectionAnimated:(BOOL)animated {
    void (^updates)(void) = ^{
        [self.items enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, LoanZen_BottomBarItem *button, BOOL *stop) {
            LoanZen_BottomTab tab = (LoanZen_BottomTab)key.integerValue;
            BOOL selected = tab == self.selectedTab;
            NSString *asset = [self LZ_assetForTab:tab selected:selected];
            UIImage *image = [LoanZen_Asset imageNamed:asset];
            [button setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
        }];
    };
    if (animated) {
        [UIView animateWithDuration:0.18 delay:0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState animations:updates completion:nil];
    } else {
        updates();
    }
}

@end
