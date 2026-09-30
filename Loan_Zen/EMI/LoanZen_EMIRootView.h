#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class LoanZen_EMIRootView;

@protocol LoanZen_EMIRootViewDelegate <NSObject>
- (void)LZ_emiRootViewDidSubmit:(LoanZen_EMIRootView *)view;
- (void)LZ_emiRootView:(LoanZen_EMIRootView *)view didChangeAmount:(double)amount years:(NSInteger)years rate:(double)rate;
@end

@interface LoanZen_EMIRootView : UIView

@property (nonatomic, weak, nullable) id<LoanZen_EMIRootViewDelegate> delegate;

- (void)LZ_renderAmount:(double)amount years:(NSInteger)years rate:(double)rate;

@end

NS_ASSUME_NONNULL_END
