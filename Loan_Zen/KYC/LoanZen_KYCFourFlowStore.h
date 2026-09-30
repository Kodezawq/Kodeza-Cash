#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LoanZen_KYCFlowOrigin) {
    LoanZen_KYCFlowOriginDefault = 0,
    LoanZen_KYCFlowOriginEMIResult,
};

@interface LoanZen_KYCFourFlowStore : NSObject

@property (nonatomic, strong, readonly, class) LoanZen_KYCFourFlowStore *shared;
@property (nonatomic, strong, nullable) NSNumber *currentStepNumber;
@property (nonatomic, copy, nullable) NSString *stageKycId;
@property (nonatomic, copy) NSArray<NSDictionary *> *searchItems;
@property (nonatomic, assign) LoanZen_KYCFlowOrigin flowOrigin;

- (void)LZ_applyStatusStep:(NSInteger)step;
- (void)LZ_applySearchItems:(NSArray<NSDictionary *> *)items;
- (void)LZ_applyStageKycId:(nullable NSString *)kycId;
- (void)LZ_resetFlowOrigin;

@end

NS_ASSUME_NONNULL_END
