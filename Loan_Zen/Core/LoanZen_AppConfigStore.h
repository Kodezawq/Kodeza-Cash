#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_AppConfigStore : NSObject

+ (void)LZ_applyAppConfig:(NSDictionary * _Nullable)config;
+ (void)LZ_applySuphomeData:(NSDictionary * _Nullable)suphome;

+ (BOOL)LZ_isStrongDataCollectionRequired;
+ (NSInteger)LZ_contactMaxCount;
+ (NSInteger)LZ_contactBatchSize;

/// 本地写死的协议 H5 / 官网 / 客服邮箱（不再从 `/app/v3/app/config` 读取）
+ (NSString *)LZ_resolvedPrivacyPolicyURL;
+ (NSString *)LZ_resolvedServiceAgreementURL;
+ (NSString *)LZ_resolvedTermsURL;
+ (NSString *)LZ_resolvedOfficialWebsiteURL;
+ (NSString *)LZ_resolvedSupportEmail;
+ (nullable NSString *)LZ_resolvedContactHrefURL;
+ (nullable NSString *)LZ_resolvedAboutURL;
/// 拒量推荐 H5（`/app/v3/app/config`：顶层 `rejectH5` 或 `dynamicParameter.rejectH5`）
+ (nullable NSString *)LZ_resolvedRejectH5URL;

/// HopeLoan `feedbackGuidance`：0 关闭，2 时 `appUserType == 1` 不展示。
+ (NSInteger)LZ_feedbackGuidance;

@end

NS_ASSUME_NONNULL_END
