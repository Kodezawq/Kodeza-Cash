#import "LoanZen_AppConfigStore.h"
#import "LoanZen_APIFieldKeys.h"

static NSString * const kLZConfigStorageKey = @"LZ.appConfig.v1";
static NSString * const kLZRetrieveMobileContactKey = @"LZ.retrieveMobileContact";

static NSDictionary *_lzCachedConfig;
static NSInteger _lzRetrieveMobileContact = NSNotFound;

@implementation LoanZen_AppConfigStore

+ (NSInteger)LZ_flexibleIntFromValue:(id)value {
    if ([value isKindOfClass:[NSNumber class]]) return [(NSNumber *)value integerValue];
    if ([value isKindOfClass:[NSString class]]) return [(NSString *)value integerValue];
    return NSNotFound;
}

+ (NSInteger)LZ_pickIntFromDict:(NSDictionary *)dict keys:(NSArray<NSString *> *)keys {
    for (NSString *key in keys) {
        NSInteger v = [self LZ_flexibleIntFromValue:dict[key]];
        if (v != NSNotFound) return v;
    }
    return NSNotFound;
}

+ (NSString *)LZ_pickStringFromDict:(NSDictionary *)dict keys:(NSArray<NSString *> *)keys {
    for (NSString *key in keys) {
        id value = dict[key];
        if ([value isKindOfClass:[NSString class]]) {
            NSString *trimmed = [(NSString *)value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            if (trimmed.length > 0) return trimmed;
        } else if ([value isKindOfClass:[NSNumber class]]) {
            return [(NSNumber *)value stringValue];
        }
    }
    return nil;
}

+ (NSString *)LZ_resolvedStringForKeys:(NSArray<NSString *> *)keys {
    return [self LZ_pickStringFromDict:[self LZ_loadedConfig] keys:keys];
}

+ (void)LZ_persistRetrieveMobileContact:(NSInteger)value {
    _lzRetrieveMobileContact = value;
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:kLZRetrieveMobileContactKey];
}

+ (void)LZ_applyAppConfig:(NSDictionary *)config {
    if (![config isKindOfClass:[NSDictionary class]]) return;
    _lzCachedConfig = config;
    NSData *data = [NSJSONSerialization dataWithJSONObject:config options:0 error:nil];
    if (data) [[NSUserDefaults standardUserDefaults] setObject:data forKey:kLZConfigStorageKey];
    NSInteger retrieveFlag = [self LZ_pickIntFromDict:config keys:@[LZAPIFieldRetrieveMobileContact, @"ready"]];
    if (retrieveFlag != NSNotFound) [self LZ_persistRetrieveMobileContact:retrieveFlag];
}

+ (void)LZ_applySuphomeData:(NSDictionary *)suphome {
    if (![suphome isKindOfClass:[NSDictionary class]]) return;
    NSInteger ready = [self LZ_pickIntFromDict:suphome keys:@[LZAPIFieldRetrieveMobileContact, @"ready"]];
    if (ready != NSNotFound) [self LZ_persistRetrieveMobileContact:ready];
}

+ (NSDictionary *)LZ_loadedConfig {
    if (_lzCachedConfig) return _lzCachedConfig;
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:kLZConfigStorageKey];
    if (!data) return nil;
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if ([json isKindOfClass:[NSDictionary class]]) _lzCachedConfig = json;
    return _lzCachedConfig;
}

+ (NSInteger)LZ_currentRetrieveMobileContact {
    if (_lzRetrieveMobileContact != NSNotFound) return _lzRetrieveMobileContact;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kLZRetrieveMobileContactKey]) {
        _lzRetrieveMobileContact = [[NSUserDefaults standardUserDefaults] integerForKey:kLZRetrieveMobileContactKey];
        return _lzRetrieveMobileContact;
    }
    return NSNotFound;
}

+ (BOOL)LZ_isStrongDataCollectionRequired {
    NSInteger flag = [self LZ_currentRetrieveMobileContact];
    return flag == 1;
}

+ (NSInteger)LZ_contactMaxCount {
    NSDictionary *config = [self LZ_loadedConfig];
    NSInteger famine = [self LZ_pickIntFromDict:config keys:@[@"famine", @"pushMaxCount"]];
    return MAX(famine == NSNotFound ? 400 : famine, 1);
}

+ (NSInteger)LZ_contactBatchSize {
    NSDictionary *config = [self LZ_loadedConfig];
    NSInteger vacuum = [self LZ_pickIntFromDict:config keys:@[LZAPIFieldPushPerCount, LZAPIFieldPushPerCount]];
    return vacuum == NSNotFound ? 100 : vacuum;
}

+ (NSString *)LZ_resolvedPrivacyPolicyURL {
    return @"https://site.kodezaph.com/site/PrivacyPolicy.html";
}

+ (NSString *)LZ_resolvedServiceAgreementURL {
    return @"https://site.kodezaph.com/site/ServiceAgreement.html";
}

+ (NSString *)LZ_resolvedTermsURL {
    return @"https://site.kodezaph.com/site/loanContract.html";
}

+ (NSString *)LZ_resolvedOfficialWebsiteURL {
    return @"https://www.kodezaph.com/";
}

+ (NSString *)LZ_resolvedSupportEmail {
    return @"contactus@kodezaph.com";
}

+ (NSString *)LZ_resolvedContactHrefURL {
    return [self LZ_resolvedStringForKeys:@[@"contactHref", @"contact_href"]];
}

+ (NSString *)LZ_resolvedAboutURL {
    return [self LZ_resolvedStringForKeys:@[LZAPIFieldAboutHref, @"about_href"]];
}

+ (NSString *)LZ_resolvedRejectH5URL {
    // 对齐 LoanEase：先读顶层，再读 dynamicParameter.rejectH5
    NSString *top = [self LZ_resolvedStringForKeys:@[@"rejectH5", @"reject_h5"]];
    if (top.length > 0) return top;
    NSDictionary *config = [self LZ_loadedConfig];
    id dyn = config[@"dynamicParameter"] ?: config[@"dywogpe"];
    if ([dyn isKindOfClass:[NSDictionary class]]) {
        return [self LZ_pickStringFromDict:(NSDictionary *)dyn keys:@[@"rejectH5", @"reject_h5"]];
    }
    if ([dyn isKindOfClass:[NSArray class]]) {
        for (id item in (NSArray *)dyn) {
            if (![item isKindOfClass:[NSDictionary class]]) continue;
            NSString *url = [self LZ_pickStringFromDict:(NSDictionary *)item keys:@[@"rejectH5", @"reject_h5"]];
            if (url.length > 0) return url;
        }
    }
    return nil;
}

+ (NSInteger)LZ_feedbackGuidance {
    NSDictionary *config = [self LZ_loadedConfig];
    return [self LZ_pickIntFromDict:config keys:@[LZAPIFieldFeedbackGuidance, @"feedback_guidance"]];
}

@end
