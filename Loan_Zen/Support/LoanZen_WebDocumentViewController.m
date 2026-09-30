#import "LoanZen_WebDocumentViewController.h"
#import "LoanZen_ScreenScaffoldView.h"
#import "LoanZen_HUD.h"
@import WebKit;
@import Masonry;

@interface LoanZen_WebDocumentViewController () <WKNavigationDelegate>
@property (nonatomic, copy) NSString *urlString;
@property (nonatomic, strong) LoanZen_ScreenScaffoldView *scaffold;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, assign) BOOL pageLoadingHUDVisible;
@end

@implementation LoanZen_WebDocumentViewController

- (instancetype)initWithURLString:(NSString *)urlString title:(NSString *)title {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _urlString = urlString.copy;
        self.title = title;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    self.scaffold = [[LoanZen_ScreenScaffoldView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.scaffold];
    [self.scaffold mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.view); }];
    [self.scaffold LZ_setHeaderTitle:self.title ?: @"Document"];
    __weak typeof(self) weakSelf = self;
    [self.scaffold LZ_setBackAction:^{ [weakSelf.navigationController popViewControllerAnimated:YES]; }];

    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero];
    self.webView.navigationDelegate = self;
    [self.scaffold.contentView addSubview:self.webView];
    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.scaffold.contentView); }];
    NSURL *url = [NSURL URLWithString:self.urlString];
    if (url) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    } else {
        [LoanZen_HUD LZ_showError:@"Invalid link"];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self LZ_hidePageLoadingIfNeeded];
}

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

- (BOOL)LZ_shouldIgnoreWebNavigationError:(NSError *)error {
    return !error || error.code == NSURLErrorCancelled;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [self LZ_showPageLoadingIfNeeded];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self LZ_hidePageLoadingIfNeeded];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if ([self LZ_shouldIgnoreWebNavigationError:error]) return;
    [self LZ_hidePageLoadingIfNeeded];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if ([self LZ_shouldIgnoreWebNavigationError:error]) return;
    [self LZ_hidePageLoadingIfNeeded];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    if (!url) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
    NSString *absolute = url.absoluteString ?: @"";
    if ([absolute hasPrefix:@"http"]) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
        if (!success) {
            [LoanZen_HUD LZ_showError:@"Please install the app first."];
        }
    }];
    decisionHandler(WKNavigationActionPolicyCancel);
}

@end
