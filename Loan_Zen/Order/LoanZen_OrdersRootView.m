#import "LoanZen_OrdersRootView.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_ColorUtils.h"
@import Masonry;

@interface LoanZen_OrdersRootView ()
@property (nonatomic, strong) UILabel *pageTitleLabel;
@property (nonatomic, strong) UIStackView *tabOuterStack;
@property (nonatomic, strong) UIStackView *tabRow1;
@property (nonatomic, strong) UIStackView *tabRow2;
@property (nonatomic, strong) NSArray<UIButton *> *tabButtons;
@property (nonatomic, strong, readwrite) UITableView *tableView;
@end

@implementation LoanZen_OrdersRootView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [LoanZen_Color background];

        UIImageView *bg = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:[LoanZen_Asset pageBackground]]];
        bg.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:bg];
        [bg mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self); }];

        self.pageTitleLabel = [[UILabel alloc] init];
        self.pageTitleLabel.text = @"Order history";
        self.pageTitleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
        self.pageTitleLabel.textColor = [LoanZen_Color primaryText];
        self.pageTitleLabel.textAlignment = NSTextAlignmentRight;
        [self addSubview:self.pageTitleLabel];

        self.tabOuterStack = [[UIStackView alloc] init];
        self.tabOuterStack.axis = UILayoutConstraintAxisVertical;
        self.tabOuterStack.spacing = 8;
        self.tabOuterStack.alignment = UIStackViewAlignmentFill;

        self.tabRow1 = [[UIStackView alloc] init];
        self.tabRow1.axis = UILayoutConstraintAxisHorizontal;
        self.tabRow1.spacing = 8;
        self.tabRow1.distribution = UIStackViewDistributionFillEqually;

        self.tabRow2 = [[UIStackView alloc] init];
        self.tabRow2.axis = UILayoutConstraintAxisHorizontal;
        self.tabRow2.spacing = 8;
        self.tabRow2.distribution = UIStackViewDistributionFillEqually;

        [self.tabOuterStack addArrangedSubview:self.tabRow1];
        [self.tabOuterStack addArrangedSubview:self.tabRow2];
        [self addSubview:self.tabOuterStack];

        self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        self.tableView.backgroundColor = UIColor.clearColor;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        self.tableView.estimatedRowHeight = 170;
        self.tableView.showsVerticalScrollIndicator = YES;
        if (@available(iOS 15.0, *)) {
            self.tableView.sectionHeaderTopPadding = 0;
        }
        [self addSubview:self.tableView];

        [self.pageTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(8);
            make.right.equalTo(self).offset(-LZ_SizePageInset);
            make.left.greaterThanOrEqualTo(self).offset(LZ_SizePageInset);
        }];
        [self.tabOuterStack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.pageTitleLabel.mas_bottom).offset(20);
            make.left.right.equalTo(self).inset(LZ_SizePageInset);
        }];
        [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.tabOuterStack.mas_bottom).offset(12);
            make.left.right.bottom.equalTo(self);
        }];
    }
    return self;
}

- (void)LZ_renderTabs:(NSArray<NSString *> *)titles selectedIndex:(NSInteger)selectedIndex {
    for (UIView *v in self.tabRow1.arrangedSubviews) {
        [self.tabRow1 removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    for (UIView *v in self.tabRow2.arrangedSubviews) {
        [self.tabRow2 removeArrangedSubview:v];
        [v removeFromSuperview];
    }

    NSMutableArray<UIButton *> *buttons = [NSMutableArray array];
    [titles enumerateObjectsUsingBlock:^(NSString *title, NSUInteger idx, BOOL *stop) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = (NSInteger)idx;
        btn.layer.cornerRadius = 10;
        btn.clipsToBounds = YES;
        btn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        btn.titleLabel.numberOfLines = 2;
        btn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [btn setTitle:title forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(LZ_tapTab:) forControlEvents:UIControlEventTouchUpInside];
        [btn mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(34); }];
        [buttons addObject:btn];
        if (idx < 2) {
            [self.tabRow1 addArrangedSubview:btn];
        } else {
            [self.tabRow2 addArrangedSubview:btn];
        }
    }];
    self.tabButtons = buttons;
    [self LZ_styleTabsWithSelectedIndex:selectedIndex];
}

- (void)LZ_styleTabsWithSelectedIndex:(NSInteger)selectedIndex {
    for (UIButton *btn in self.tabButtons) {
        BOOL selected = btn.tag == selectedIndex;
        btn.backgroundColor = selected ? [LoanZen_Color accent] : [LoanZen_ColorUtils LZ_glassFill06];
        btn.layer.borderWidth = 1;
        btn.layer.borderColor = (selected ? [LoanZen_Color accent] : [LoanZen_ColorUtils LZ_glassBorder14]).CGColor;
        btn.titleLabel.font = [UIFont systemFontOfSize:12 weight:selected ? UIFontWeightSemibold : UIFontWeightRegular];
        [btn setTitleColor:selected ? UIColor.whiteColor : [LoanZen_Color secondaryText] forState:UIControlStateNormal];
    }
}

- (void)LZ_tapTab:(UIButton *)sender {
    [self LZ_styleTabsWithSelectedIndex:sender.tag];
    if ([self.delegate respondsToSelector:@selector(LZ_ordersRootView:didSelectTabIndex:)]) {
        [self.delegate LZ_ordersRootView:self didSelectTabIndex:sender.tag];
    }
}

- (void)LZ_reloadCards:(NSArray<NSDictionary *> *)cards {
    [self.tableView reloadData];
}

@end
