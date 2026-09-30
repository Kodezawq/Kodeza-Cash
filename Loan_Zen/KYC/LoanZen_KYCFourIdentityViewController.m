#import "LoanZen_KYCFourIdentityViewController.h"
#import "LoanZen_KYCVerificationFailedViewController.h"
#import "LoanZen_ImageCompression.h"
#import "LoanZen_ScreenScaffoldView.h"
#import "LoanZen_KYCFourProgressView.h"
#import "LoanZen_KYCFourService.h"
#import "LoanZen_KYCFourFlowStore.h"
#import "LoanZen_KYCFourFlowNavigator.h"
#import "LoanZen_KYCFourIDCameraViewController.h"
#import "LoanZen_FaceLivenessStartViewController.h"
#import "LoanZen_PopupHelper.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_ColorUtils.h"
#import "LoanZen_HUD.h"
#import "LoanZen_AppRouter.h"
#import "LoanZen_BuryReporter.h"
#import "LoanZen_PermissionHelper.h"
@import Masonry;

static NSString * const kLZDashedBorderLayerName = @"LZ_kycDashedBorder";

@interface LoanZen_KYCDashedUploadBox : UIView
@property (nonatomic, strong, readonly) UIImageView *placeholderView;
@property (nonatomic, strong, readonly) UIImageView *previewView;
@end

@implementation LoanZen_KYCDashedUploadBox

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [LoanZen_Color kycFormInputFill];
        self.layer.cornerRadius = 12;
        self.clipsToBounds = YES;

        _placeholderView = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:@"lz_sfzrz"]];
        _placeholderView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_placeholderView];

        _previewView = [[UIImageView alloc] init];
        _previewView.contentMode = UIViewContentModeScaleAspectFill;
        _previewView.clipsToBounds = YES;
        _previewView.hidden = YES;
        [self addSubview:_previewView];

        [_placeholderView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.width.height.mas_equalTo(72);
        }];
        [_previewView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    for (CALayer *layer in [self.layer.sublayers copy]) {
        if ([layer.name isEqualToString:kLZDashedBorderLayerName]) {
            [layer removeFromSuperlayer];
        }
    }
    CAShapeLayer *border = [CAShapeLayer layer];
    border.name = kLZDashedBorderLayerName;
    border.strokeColor = [LoanZen_Color kycFormInputBorder].CGColor;
    border.fillColor = UIColor.clearColor.CGColor;
    border.lineDashPattern = @[@6, @4];
    border.lineWidth = 1;
    border.path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, 0.5, 0.5) cornerRadius:12].CGPath;
    border.frame = self.bounds;
    [self.layer insertSublayer:border atIndex:0];
}

- (void)LZ_setPreviewImage:(UIImage *)image {
    self.previewView.image = image;
    self.previewView.hidden = (image == nil);
    self.placeholderView.hidden = (image != nil);
}

@end

@interface LoanZen_KYCFaceUploadBox : UIView
@property (nonatomic, strong, readonly) UIImageView *placeholderView;
@property (nonatomic, strong, readonly) UIImageView *previewView;
@end

@implementation LoanZen_KYCFaceUploadBox

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = UIColor.clearColor;

        _placeholderView = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:@"lz_rlsb"]];
        _placeholderView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_placeholderView];

        _previewView = [[UIImageView alloc] init];
        _previewView.contentMode = UIViewContentModeScaleAspectFit;
        _previewView.clipsToBounds = YES;
        _previewView.layer.cornerRadius = 12;
        _previewView.hidden = YES;
        [self addSubview:_previewView];

        [_placeholderView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        [_previewView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self).insets(UIEdgeInsetsMake(12, 12, 12, 12));
        }];
    }
    return self;
}

- (void)LZ_setPreviewImage:(UIImage *)image {
    self.previewView.image = image;
    self.previewView.hidden = (image == nil);
    self.placeholderView.hidden = (image != nil);
}

@end

@interface LoanZen_KYCFourIdentityViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) LoanZen_ScreenScaffoldView *scaffold;
@property (nonatomic, strong) LoanZen_KYCFourProgressView *progressView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *contentStack;
@property (nonatomic, strong) LoanZen_KYCDashedUploadBox *frontUploadBox;
@property (nonatomic, strong) LoanZen_KYCFaceUploadBox *faceUploadBox;
@property (nonatomic, strong) UIButton *frontClearButton;
@property (nonatomic, strong) UIButton *faceClearButton;
@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UIButton *continueButton;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *fieldValues;
@end

@implementation LoanZen_KYCFourIdentityViewController

static NSSet<NSNumber *> *LZ_unclearPhotoBusinessCodes(void) {
    static NSSet<NSNumber *> *codes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        codes = [NSSet setWithObjects:@6212009, @6212011, nil];
    });
    return codes;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [LoanZen_Color background];
    self.fieldValues = [NSMutableDictionary dictionary];
    self.navigationController.navigationBarHidden = YES;

    self.scaffold = [[LoanZen_ScreenScaffoldView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.scaffold];
    [self.scaffold mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.view); }];
    [self.scaffold LZ_useKYCStyle];
    [self.scaffold LZ_setHeaderTitle:@"ID Information"];
    __weak typeof(self) weakSelf = self;
    [self.scaffold LZ_setBackAction:^{ [weakSelf LZ_confirmExit]; }];

    self.progressView = [[LoanZen_KYCFourProgressView alloc] init];
    self.progressView.currentStep = @4;

    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.showsVerticalScrollIndicator = NO;

    self.contentStack = [[UIStackView alloc] init];
    self.contentStack.axis = UILayoutConstraintAxisVertical;
    self.contentStack.spacing = 16;

    [self.scaffold.contentView addSubview:self.progressView];
    [self.scaffold.contentView addSubview:self.scrollView];
    [self.scrollView addSubview:self.contentStack];

    [self.contentStack addArrangedSubview:[self LZ_buildInfoBanner]];
    [self.contentStack addArrangedSubview:[self LZ_buildFrontSection]];
    [self.contentStack addArrangedSubview:[self LZ_buildFaceSection]];

    self.bottomBar = [[UIView alloc] init];
    self.bottomBar.backgroundColor = [LoanZen_Color background];
    [self.view addSubview:self.bottomBar];

    self.continueButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.continueButton.backgroundColor = [LoanZen_Color accent];
    self.continueButton.layer.cornerRadius = 24;
    self.continueButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.continueButton setTitle:@"Continue" forState:UIControlStateNormal];
    [self.continueButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.continueButton addTarget:self action:@selector(LZ_submit) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.continueButton];

    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.scaffold.contentView).offset(16);
        make.left.right.equalTo(self.scaffold.contentView).inset(16);
    }];
    [self.bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.mas_equalTo(95);
    }];
    [self.continueButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.bottomBar).inset(16);
        make.top.equalTo(self.bottomBar).offset(13);
        make.height.mas_equalTo(48);
    }];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.progressView.mas_bottom).offset(16);
        make.left.right.equalTo(self.scaffold.contentView);
        make.bottom.equalTo(self.bottomBar.mas_top);
    }];
    [self.contentStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView).insets(UIEdgeInsetsMake(0, 16, 16, 16));
        make.width.equalTo(self.scrollView).offset(-32);
    }];

    if (LoanZen_KYCFourFlowStore.shared.currentStepNumber.integerValue == 4) {
        self.continueButton.enabled = YES;
        if (LoanZen_KYCFourFlowStore.shared.searchItems.count == 0) {
            [LoanZen_KYCFourService LZ_fetchSearchItemsForStep:4 showLoading:NO completion:nil];
        }
    } else {
        self.continueButton.enabled = NO;
        [self LZ_refreshStatus];
    }
}

#pragma mark - UI Builders

- (UIView *)LZ_buildInfoBanner {
    UIView *banner = [[UIView alloc] init];
    banner.backgroundColor = [LoanZen_ColorUtils LZ_glassFill06];
    banner.layer.cornerRadius = 12;
    banner.layer.borderWidth = 1;
    banner.layer.borderColor = [LoanZen_ColorUtils LZ_glassBorder10].CGColor;

    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    label.textColor = [[LoanZen_Color accent] colorWithAlphaComponent:0.88];
    label.text = @"Please upload one valid ID. Supported IDs include UMID, National ID, SSS, TIN, Passport, Driver's License, Postal ID, Voter ID, or Health Card.";
    [banner addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(banner).insets(UIEdgeInsetsMake(14, 14, 14, 14));
    }];
    return banner;
}

- (UIView *)LZ_buildSectionCardWithTitle:(NSString *)title contentBuilder:(void (^)(UIView *card, UIStackView *stack))builder {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [LoanZen_Color kycFormCardFill];
    card.layer.cornerRadius = 16;
    card.layer.borderWidth = 1;
    card.layer.borderColor = [LoanZen_Color kycFormCardBorder].CGColor;
    card.clipsToBounds = YES;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    titleLabel.textColor = [LoanZen_Color kycFormValue];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[titleLabel]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;
    [card addSubview:stack];
    [stack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(card).insets(UIEdgeInsetsMake(16, 16, 16, 16));
    }];
    if (builder) builder(card, stack);
    return card;
}

- (UIView *)LZ_buildFrontSection {
    __weak typeof(self) weakSelf = self;
    return [self LZ_buildSectionCardWithTitle:@"Front" contentBuilder:^(UIView *card, UIStackView *stack) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;

        UIView *uploadWrap = [[UIView alloc] init];
        self.frontUploadBox = [[LoanZen_KYCDashedUploadBox alloc] init];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(LZ_tapFront)];
        [self.frontUploadBox addGestureRecognizer:tap];

        self.frontClearButton = [self LZ_buildClearButtonWithAction:@selector(LZ_clearFront)];
        [uploadWrap addSubview:self.frontUploadBox];
        [uploadWrap addSubview:self.frontClearButton];
        [self.frontUploadBox mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(uploadWrap);
            make.height.mas_equalTo(160);
        }];
        [self.frontClearButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(uploadWrap).offset(8);
            make.right.equalTo(uploadWrap).offset(-8);
            make.width.height.mas_equalTo(24);
        }];

        UIStackView *instructions = [self LZ_buildNumberedInstructions:@[
            @"Please make sure that the ID card you upload is genuine and valid.",
            @"Please make sure that the uploaded ID card photo is clear and complete, otherwise it will not pass verification.",
        ]];

        [stack addArrangedSubview:uploadWrap];
        [stack addArrangedSubview:instructions];
    }];
}

- (UIView *)LZ_buildFaceSection {
    __weak typeof(self) weakSelf = self;
    return [self LZ_buildSectionCardWithTitle:@"Face identification" contentBuilder:^(UIView *card, UIStackView *stack) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;

        UIView *uploadWrap = [[UIView alloc] init];
        self.faceUploadBox = [[LoanZen_KYCFaceUploadBox alloc] init];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(LZ_tapLiveness)];
        [self.faceUploadBox addGestureRecognizer:tap];

        self.faceClearButton = [self LZ_buildClearButtonWithAction:@selector(LZ_clearFace)];
        [uploadWrap addSubview:self.faceUploadBox];
        [uploadWrap addSubview:self.faceClearButton];
        [self.faceUploadBox mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(uploadWrap);
            make.height.mas_equalTo(180);
        }];
        [self.faceClearButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(uploadWrap).offset(8);
            make.right.equalTo(uploadWrap).offset(-8);
            make.width.height.mas_equalTo(24);
        }];

        UILabel *hint = [[UILabel alloc] init];
        hint.numberOfLines = 0;
        hint.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        hint.textColor = [LoanZen_Color kycFormPlaceholder];
        hint.text = @"Tap the image box to capture or recapture your face photo.";

        [stack addArrangedSubview:uploadWrap];
        [stack addArrangedSubview:hint];
    }];
}

- (UIStackView *)LZ_buildNumberedInstructions:(NSArray<NSString *> *)lines {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 8;
    [lines enumerateObjectsUsingBlock:^(NSString *line, NSUInteger idx, BOOL *stop) {
        UILabel *label = [[UILabel alloc] init];
        label.numberOfLines = 0;
        label.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        label.textColor = [[LoanZen_Color accent] colorWithAlphaComponent:0.92];
        label.text = [NSString stringWithFormat:@"%lu. %@", (unsigned long)(idx + 1), line];
        [stack addArrangedSubview:label];
    }];
    return stack;
}

- (UIButton *)LZ_buildClearButtonWithAction:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.hidden = YES;
    button.backgroundColor = UIColor.clearColor;
    UIImage *icon = [LoanZen_Asset imageNamed:@"lz_delete"];
    if (icon) {
        [button setImage:[icon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    } else {
        [button setTitle:@"×" forState:UIControlStateNormal];
        [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    }
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

#pragma mark - State

- (void)LZ_refreshStatus {
    self.continueButton.enabled = NO;
    [LoanZen_KYCFourService LZ_fetchFourStatusWithLoading:NO completion:^(NSNumber *step, NSError *error) {
        if (error) {
            [LoanZen_HUD LZ_showError:error.localizedDescription];
            return;
        }
        if (step.integerValue == -1) {
            [LoanZen_AppRouter LZ_showMainInterfaceInWindow:self.view.window];
            return;
        }
        if (step.integerValue != 4) {
            [LoanZen_KYCFourFlowNavigator LZ_syncNavigationToCurrentStepFrom:self animated:NO];
            return;
        }
        self.progressView.currentStep = @4;
        self.continueButton.enabled = YES;
        if (LoanZen_KYCFourFlowStore.shared.searchItems.count == 0) {
            [LoanZen_KYCFourService LZ_fetchSearchItemsForStep:4 showLoading:NO completion:nil];
        }
    }];
}

- (void)LZ_applyFrontPreview:(UIImage *)preview {
    [self.frontUploadBox LZ_setPreviewImage:preview];
    self.frontClearButton.hidden = (preview == nil);
}

- (void)LZ_applyFacePreview:(UIImage *)preview {
    [self.faceUploadBox LZ_setPreviewImage:preview];
    self.faceClearButton.hidden = (preview == nil);
}

#pragma mark - Actions

- (void)LZ_tapFront {
    [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventKYCIdentitySelectPhotoFront];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    [sheet addAction:[UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [LoanZen_PermissionHelper LZ_requestCameraAccessOn:weakSelf granted:^{
            [weakSelf LZ_openIdentityCamera];
        }];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Photo Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [weakSelf LZ_openIdentityAlbum];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *popover = sheet.popoverPresentationController;
    if (popover) {
        popover.sourceView = self.frontUploadBox ?: self.view;
        popover.sourceRect = self.frontUploadBox ? self.frontUploadBox.bounds : CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMaxY(self.view.bounds) - 1, 1, 1);
        popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)LZ_openIdentityCamera {
    [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventKYCIdentitySelectCameraFront];
    __weak typeof(self) weakSelf = self;
    LoanZen_KYCFourIDCameraViewController *cam = [[LoanZen_KYCFourIDCameraViewController alloc] initWithSide:LoanZen_KYCIDCaptureSideFront onConfirmed:^(NSString *code, NSString *base64, UIImage *preview) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.fieldValues[code] = base64;
        [self LZ_applyFrontPreview:preview];
    }];
    [self.navigationController pushViewController:cam animated:YES];
}

- (void)LZ_openIdentityAlbum {
    [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventKYCIdentitySelectAlbumFront];
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    if (!image) {
        [LoanZen_HUD LZ_showError:@"Failed to read photo."];
        return;
    }
    NSString *base64 = [LoanZen_ImageCompression LZ_jpegBase64FromImage:image quality:0.92 maxBytes:400000];
    if (base64.length == 0) {
        [LoanZen_HUD LZ_showError:@"Failed to read photo."];
        return;
    }
    [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventKYCIdentityAlbumSelectFront];
    self.fieldValues[@"identity_front_img"] = base64;
    [self LZ_applyFrontPreview:image];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)LZ_tapLiveness {
    __weak typeof(self) weakSelf = self;
    [LoanZen_PermissionHelper LZ_requestCameraAccessOn:self granted:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self LZ_openFaceLiveness];
    }];
}

- (void)LZ_openFaceLiveness {
    __weak typeof(self) weakSelf = self;
    LoanZen_FaceLivenessStartViewController *start = [[LoanZen_FaceLivenessStartViewController alloc] initWithOnConfirmed:^(NSString *base64, UIImage *preview) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.fieldValues[@"liveness_img"] = base64;
        [self LZ_applyFacePreview:preview];
    }];
    [self.navigationController pushViewController:start animated:YES];
}

- (void)LZ_clearFront {
    [self.fieldValues removeObjectForKey:@"identity_front_img"];
    [self LZ_applyFrontPreview:nil];
}

- (void)LZ_clearFace {
    [self.fieldValues removeObjectForKey:@"liveness_img"];
    [self LZ_applyFacePreview:nil];
}

- (void)LZ_confirmExit {
    [LoanZen_KYCFourFlowNavigator LZ_confirmExitFrom:self];
}

- (void)LZ_submit {
    if (self.fieldValues[@"identity_front_img"].length == 0) {
        [LoanZen_HUD LZ_showError:@"Please upload your ID card"];
        return;
    }
    if (self.fieldValues[@"liveness_img"].length == 0) {
        [LoanZen_HUD LZ_showError:@"Please take a liveness photo"];
        return;
    }
    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    payload[@"card_type"] = [NSNull null];
    payload[@"identity_front_img"] = self.fieldValues[@"identity_front_img"];
    payload[@"identity_back_img"] = [NSNull null];
    payload[@"manual_card_no"] = [NSNull null];
    payload[@"liveness_img"] = self.fieldValues[@"liveness_img"];
    [LoanZen_KYCFourService LZ_submitStep:4 fields:payload completion:^(NSError *error) {
        if (error) {
            [self LZ_handleSubmitError:error];
            return;
        }
        [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventKYCIdentitySubmit];
        [LoanZen_KYCFourFlowNavigator LZ_advanceFrom:self pushNext:NO animated:YES];
    }];
}

- (void)LZ_clearVerificationCaptureData {
    [self LZ_clearFront];
    [self LZ_clearFace];
}

- (void)LZ_handleSubmitError:(NSError *)error {
    if ([LZ_unclearPhotoBusinessCodes() containsObject:@(error.code)]) {
        [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventLivenessFailShow];
        __weak typeof(self) weakSelf = self;
        [LoanZen_KYCVerificationFailedViewController LZ_presentFrom:self onConfirm:^{
            [weakSelf LZ_clearVerificationCaptureData];
        }];
        return;
    }
    [LoanZen_HUD LZ_showError:error.localizedDescription ?: @"Submission failed."];
}

@end
