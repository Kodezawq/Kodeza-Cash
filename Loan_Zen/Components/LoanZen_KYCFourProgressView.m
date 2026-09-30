#import "LoanZen_KYCFourProgressView.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_ColorUtils.h"
@import Masonry;

static NSString * const LZ_KYCProgressGradientLayerName = @"LZ_kycProgressGradient";

@implementation LoanZen_KYCFourProgressView {
    NSArray<UIView *> *_segments;
    UILabel *_stepLabel;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIStackView *barRow = [[UIStackView alloc] init];
        barRow.axis = UILayoutConstraintAxisHorizontal;
        barRow.distribution = UIStackViewDistributionFillEqually;
        barRow.spacing = 8;
        barRow.alignment = UIStackViewAlignmentFill;
        [self addSubview:barRow];

        _stepLabel = [[UILabel alloc] init];
        _stepLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
        _stepLabel.textColor = [LoanZen_Color kycFormLabel];
        _stepLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_stepLabel];

        NSMutableArray *segments = [NSMutableArray array];
        for (NSInteger i = 0; i < 4; i++) {
            UIView *seg = [[UIView alloc] init];
            seg.layer.cornerRadius = 2.5;
            seg.clipsToBounds = YES;
            [seg mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(5); }];
            [segments addObject:seg];
            [barRow addArrangedSubview:seg];
        }
        _segments = segments;

        [barRow mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(self);
            make.height.mas_equalTo(5);
        }];
        [_stepLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(barRow.mas_bottom).offset(8);
            make.left.right.equalTo(self);
            make.bottom.equalTo(self);
            make.height.mas_equalTo(18);
        }];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self LZ_applyCurrentStepGradientIfNeeded];
}

- (void)setCurrentStep:(NSNumber *)currentStep {
    _currentStep = currentStep;
    NSInteger step = currentStep.integerValue;
    BOOL allDone = step == -1;
    NSInteger displayStep = allDone ? 4 : MAX(1, MIN(step, 4));
    _stepLabel.text = [NSString stringWithFormat:@"Step %ld / 4", (long)displayStep];

    for (NSInteger i = 0; i < 4; i++) {
        NSInteger state = 0;
        if (allDone) {
            state = 2;
        } else if (step > i + 1) {
            state = 2;
        } else if (step == i + 1) {
            state = 1;
        }
        [self LZ_styleSegment:_segments[i] state:state];
    }
    [self setNeedsLayout];
}

- (void)LZ_styleSegment:(UIView *)seg state:(NSInteger)state {
    [self LZ_removeProgressGradientFromSegment:seg];
    if (state == 1) {
        seg.backgroundColor = [LoanZen_ColorUtils LZ_brandAccent];
    } else if (state == 2) {
        seg.backgroundColor = [LoanZen_ColorUtils LZ_kycProgressFilled];
    } else {
        seg.backgroundColor = [LoanZen_Color kycProgressInactive];
    }
}

- (void)LZ_removeProgressGradientFromSegment:(UIView *)seg {
    for (CALayer *layer in [seg.layer.sublayers copy]) {
        if ([layer.name isEqualToString:LZ_KYCProgressGradientLayerName]) {
            [layer removeFromSuperlayer];
        }
    }
}

- (void)LZ_applyCurrentStepGradientIfNeeded {
    NSInteger step = _currentStep.integerValue;
    if (step == -1 || step < 1 || step > 4) return;

    UIView *seg = _segments[step - 1];
    if (CGRectIsEmpty(seg.bounds)) return;

    [self LZ_removeProgressGradientFromSegment:seg];
    CAGradientLayer *gradient = [LoanZen_ColorUtils LZ_horizontalGradientLayerWithColors:[LoanZen_ColorUtils LZ_kycProgressGradientColors]
                                                                                   frame:seg.bounds
                                                                            cornerRadius:2.5];
    gradient.name = LZ_KYCProgressGradientLayerName;
    [seg.layer insertSublayer:gradient atIndex:0];
}

@end
