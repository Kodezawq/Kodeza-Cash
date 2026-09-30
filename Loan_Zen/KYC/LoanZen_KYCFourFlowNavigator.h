#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_KYCFourFlowNavigator : NSObject

+ (UIViewController *)LZ_viewControllerForStep:(NSInteger)step;
+ (void)LZ_pushFrom:(UIViewController *)host step:(NSInteger)step animated:(BOOL)animated;
+ (void)LZ_enterFlowFrom:(UIViewController *)host animated:(BOOL)animated;
+ (void)LZ_openStepAfterStatus:(NSInteger)targetStep from:(UIViewController *)host animated:(BOOL)animated;
+ (void)LZ_advanceFrom:(UIViewController *)host pushNext:(BOOL)pushNext animated:(BOOL)animated;
+ (void)LZ_syncNavigationToCurrentStepFrom:(UIViewController *)host animated:(BOOL)animated;
+ (void)LZ_applyStageKycIdFromSearchItems:(NSInteger)step list:(NSArray<NSDictionary *> *)list;
+ (void)LZ_confirmExitFrom:(UIViewController *)host;
+ (void)LZ_exitFlowFrom:(UIViewController *)host completed:(BOOL)completed;

@end

NS_ASSUME_NONNULL_END
