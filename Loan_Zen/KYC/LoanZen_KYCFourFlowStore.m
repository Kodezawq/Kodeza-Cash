#import "LoanZen_KYCFourFlowStore.h"

@implementation LoanZen_KYCFourFlowStore

+ (LoanZen_KYCFourFlowStore *)shared {
    static LoanZen_KYCFourFlowStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ store = [[LoanZen_KYCFourFlowStore alloc] init]; });
    return store;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _searchItems = @[];
        _flowOrigin = LoanZen_KYCFlowOriginDefault;
    }
    return self;
}

- (void)LZ_applyStatusStep:(NSInteger)step { self.currentStepNumber = @(step); }
- (void)LZ_applySearchItems:(NSArray<NSDictionary *> *)items { self.searchItems = items ?: @[]; }
- (void)LZ_applyStageKycId:(NSString *)kycId { self.stageKycId = kycId; }
- (void)LZ_resetFlowOrigin { self.flowOrigin = LoanZen_KYCFlowOriginDefault; }

@end
