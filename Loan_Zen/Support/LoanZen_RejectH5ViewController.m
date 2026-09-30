#import "LoanZen_RejectH5ViewController.h"
#import "LoanZen_ScreenScaffoldView.h"
#import "LoanZen_HUD.h"
#import "LoanZen_APIConfig.h"
#import "LoanZen_CredentialStore.h"
#import "LoanZen_DeviceIdentity.h"
#import "LoanZen_DeviceHardwareCollector.h"
#import "LoanZen_HTTPClient.h"
#import "LoanZen_DesignSystem.h"
@import WebKit;
@import Masonry;

static NSString * const kLZRejectScriptHandler = @"iosHandler";

@interface LoanZen_RejectH5WeakScriptHandler : NSObject <WKScriptMessageHandler>
@property (nonatomic, weak) id<WKScriptMessageHandler> target;
@end

@implementation LoanZen_RejectH5WeakScriptHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    [self.target userContentController:userContentController didReceiveScriptMessage:message];
}
@end

@interface LoanZen_RejectH5ViewController () <WKNavigationDelegate, WKScriptMessageHandler>
@property (nonatomic, strong) NSURL *pageURL;
@property (nonatomic, strong) LoanZen_ScreenScaffoldView *scaffold;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) LoanZen_RejectH5WeakScriptHandler *scriptBridge;
@property (nonatomic, assign) BOOL pageLoadingHUDVisible;
@end

@implementation LoanZen_RejectH5ViewController

- (instancetype)initWithURL:(NSURL *)url {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _pageURL = url;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    self.view.backgroundColor = [LoanZen_Color background];

    self.scaffold = [[LoanZen_ScreenScaffoldView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.scaffold];
    [self.scaffold mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.view); }];
    [self.scaffold LZ_setHeaderTitle:@"Accurate Recommendation"];
    __weak typeof(self) weakSelf = self;
    [self.scaffold LZ_setBackAction:^{
        UINavigationController *nav = weakSelf.navigationController;
        if (nav.viewControllers.count <= 1) {
            [nav dismissViewControllerAnimated:YES completion:nil];
        } else {
            [nav popViewControllerAnimated:YES];
        }
    }];

    self.navigationController.interactivePopGestureRecognizer.enabled = NO;

    self.scriptBridge = [[LoanZen_RejectH5WeakScriptHandler alloc] init];
    self.scriptBridge.target = self;
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.dataDetectorTypes = WKDataDetectorTypeNone;
    [config.userContentController addScriptMessageHandler:self.scriptBridge name:kLZRejectScriptHandler];

    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    self.webView.opaque = NO;
    self.webView.backgroundColor = [LoanZen_Color background];
    self.webView.navigationDelegate = self;
    self.webView.allowsBackForwardNavigationGestures = NO;
    [self.scaffold.contentView addSubview:self.webView];
    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.scaffold.contentView); }];

    [self LZ_showPageLoadingIfNeeded];
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.pageURL]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isMovingFromParentViewController || self.isBeingDismissed) {
        [self.webView.configuration.userContentController removeScriptMessageHandlerForName:kLZRejectScriptHandler];
        [self.webView stopLoading];
        self.webView.navigationDelegate = nil;
        [self LZ_hidePageLoadingIfNeeded];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

#pragma mark - Loading

- (void)LZ_showPageLoadingIfNeeded {
    if (self.pageLoadingHUDVisible) return;
    self.pageLoadingHUDVisible = YES;
    [LoanZen_HUD LZ_showBlockingLoading];
}

- (void)LZ_hidePageLoadingIfNeeded {
    if (!self.pageLoadingHUDVisible) return;
    self.pageLoadingHUDVisible = NO;
    [LoanZen_HUD LZ_hideBlockingLoading];
}

#pragma mark - Inject

- (NSString *)LZ_userAgentString {
    NSString *appId = LoanZen_APIConfig.appId ?: @"";
    NSString *version = [LoanZen_DeviceIdentity LZ_appVersion] ?: @"1.0";
    NSString *model = [LoanZen_DeviceHardwareCollector LZ_deviceModelName] ?: @"iPhone";
    NSString *system = UIDevice.currentDevice.systemVersion ?: @"";
    return [NSString stringWithFormat:@"%@/%@(Apple;Mobile;%@;iOS %@;)", appId, version, model, system];
}

- (void)LZ_injectRejectData {
    NSDictionary *payload = @{
        @"appId": LoanZen_APIConfig.appId ?: @"",
        @"salt": LoanZen_APIConfig.signSalt ?: @"",
        @"mobile": LoanZen_CredentialStore.mobileDigits ?: @"",
        @"baseUrl": [LoanZen_APIConfig LZ_normalizedBaseURLString] ?: @"",
        @"userId": LoanZen_CredentialStore.userId ?: @"",
        @"token": LoanZen_CredentialStore.token ?: @"",
        @"UA": [self LZ_userAgentString] ?: @"",
        @"deviceId": [LoanZen_DeviceIdentity LZ_deviceId] ?: @"",
        @"clientVersion": [LoanZen_DeviceIdentity LZ_appVersion] ?: @"",
    };
    if (![NSJSONSerialization isValidJSONObject:payload]) return;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    if (jsonData.length == 0) return;
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    if (jsonString.length == 0) return;
    NSString *sanitized = [[[[jsonString stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"]
                             stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]
                            stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"]
                           stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    NSString *js = [NSString stringWithFormat:@"rejectData('%@')", sanitized];
    [self.webView evaluateJavaScript:js completionHandler:nil];
}

+ (NSDictionary<NSString *, NSString *> *)LZ_parseQueryStyleMessage:(NSString *)message {
    if (message.length == 0) return @{};
    NSString *wrapped = [NSString stringWithFormat:@"http://127.0.0.1/lz-reject?%@", message];
    NSURLComponents *components = [NSURLComponents componentsWithString:wrapped];
    NSMutableDictionary *out = [NSMutableDictionary dictionary];
    for (NSURLQueryItem *item in components.queryItems ?: @[]) {
        if (item.name.length == 0) continue;
        NSString *raw = item.value ?: @"";
        out[item.name] = raw.stringByRemovingPercentEncoding ?: raw;
    }
    return out;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self LZ_hidePageLoadingIfNeeded];
    [self LZ_injectRejectData];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (error.code == NSURLErrorCancelled) return;
    [self LZ_hidePageLoadingIfNeeded];
    [LoanZen_HUD LZ_showError:error.localizedDescription];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (error.code == NSURLErrorCancelled) return;
    [self LZ_hidePageLoadingIfNeeded];
    [LoanZen_HUD LZ_showError:error.localizedDescription];
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:kLZRejectScriptHandler]) return;
    NSString *raw = [message.body isKindOfClass:[NSString class]] ? message.body : [NSString stringWithFormat:@"%@", message.body];
    if (![raw hasPrefix:@"thirdUrl"]) return;
    NSDictionary *dict = [self.class LZ_parseQueryStyleMessage:raw];
    NSString *thirdURLString = [dict[@"thirdUrl"] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
    NSString *type = [dict[@"type"] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/bury/record"
                             signParams:@{
                                 @"eventCode": @"502",
                                 @"eventContent": @"NULL",
                                 @"remark1": @"NULL",
                                 @"remark2": type.length > 0 ? type : @"NULL",
                                 @"remark3": @"NULL",
                             }
                             dataParams:@{
                                 @"eventCode": @"502",
                                 @"eventContent": @"NULL",
                                 @"remark1": @"NULL",
                                 @"remark2": type.length > 0 ? type : @"NULL",
                                 @"remark3": @"NULL",
                             }
                            showLoading:NO
                             completion:nil];
    if (thirdURLString.length == 0) return;
    NSURL *url = [NSURL URLWithString:thirdURLString];
    if (!url) return;
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

@end
