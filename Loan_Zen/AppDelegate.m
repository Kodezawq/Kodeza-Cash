#import "AppDelegate.h"
#import "LoanZen_HUD.h"
#import "LoanZen_AdjustManager.h"
#import "LoanZen_BuryReporter.h"
#import "LoanZen_FeedbackViewController.h"
@import IQKeyboardManager;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [IQKeyboardManager sharedManager].enable = YES;
    [[IQKeyboardManager sharedManager].disabledDistanceHandlingClasses addObject:LoanZen_FeedbackViewController.class];
    [LoanZen_HUD LZ_configureIfNeeded];
    [LoanZen_AdjustManager LZ_configureIfNeeded];
    [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventLaunchApp];
    return YES;
}

#pragma mark - UISceneSession lifecycle

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}

- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
}

@end
