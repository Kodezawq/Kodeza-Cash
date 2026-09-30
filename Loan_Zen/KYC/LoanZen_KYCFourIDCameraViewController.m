#import "LoanZen_KYCFourIDCameraViewController.h"
#import "LoanZen_ImageCompression.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_ColorUtils.h"
#import "LoanZen_BuryReporter.h"
#import "LoanZen_HUD.h"
@import AVFoundation;
@import Masonry;

@interface LoanZen_KYCFourIDCameraViewController () <AVCapturePhotoCaptureDelegate>
@property (nonatomic, assign) LoanZen_KYCIDCaptureSide side;
@property (nonatomic, copy) void (^onConfirmed)(NSString *code, NSString *base64, UIImage *preview);
@property (nonatomic, strong) UIView *previewContainer;
@property (nonatomic, strong) UIImageView *capturedImageView;
@property (nonatomic, strong) UIImageView *guideOverlay;
@property (nonatomic, strong) UIView *hintWrap;
@property (nonatomic, strong) UIImageView *hintImageView;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *shutterButton;
@property (nonatomic, strong) UIStackView *actionRow;
@property (nonatomic, strong) UIButton *retakeButton;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCapturePhotoOutput *photoOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) UIImage *capturedImage;
@property (nonatomic, assign) BOOL isCapturingPhoto;
@end

@implementation LoanZen_KYCFourIDCameraViewController

- (instancetype)initWithSide:(LoanZen_KYCIDCaptureSide)side onConfirmed:(void (^)(NSString *, NSString *, UIImage *))onConfirmed {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _side = side;
        _onConfirmed = [onConfirmed copy];
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

#pragma mark - Orientation

- (BOOL)shouldAutorotate { return NO; }

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [LoanZen_ColorUtils LZ_cameraBackground];
    self.navigationController.navigationBarHidden = YES;
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.extendedLayoutIncludesOpaqueBars = YES;

    [self LZ_buildUI];
    [self LZ_setupCameraIfAuthorized];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.side == LoanZen_KYCIDCaptureSideFront) {
        [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventKYCIdentityOpenCameraFront];
    }
    [self LZ_startSessionIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (!self.capturedImage && self.side == LoanZen_KYCIDCaptureSideFront) {
        [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventKYCIdentityCancelCameraFront];
    }
    [self LZ_stopSession];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.previewLayer.frame = self.previewContainer.bounds;
}

#pragma mark - UI（竖屏：顶返回 | 中取景框 | 底拍摄/拍后按钮）

- (void)LZ_buildUI {
    self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.backButton setImage:[LoanZen_Asset imageNamed:@"lz_sfz_fh"] forState:UIControlStateNormal];
    self.backButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.25];
    self.backButton.layer.cornerRadius = 20;
    self.backButton.clipsToBounds = YES;
    [self.backButton addTarget:self action:@selector(LZ_pop) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.backButton];

    self.shutterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.shutterButton setImage:[LoanZen_Asset imageNamed:@"lz_pz_pz"] forState:UIControlStateNormal];
    [self.shutterButton addTarget:self action:@selector(LZ_capture) forControlEvents:UIControlEventTouchUpInside];

    self.retakeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.retakeButton setImage:[LoanZen_Asset imageNamed:@"lz_pz_cw"] forState:UIControlStateNormal];
    [self.retakeButton addTarget:self action:@selector(LZ_retake) forControlEvents:UIControlEventTouchUpInside];

    self.confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.confirmButton setImage:[LoanZen_Asset imageNamed:@"lz_pz_zq"] forState:UIControlStateNormal];
    [self.confirmButton addTarget:self action:@selector(LZ_confirm) forControlEvents:UIControlEventTouchUpInside];

    self.actionRow = [[UIStackView alloc] initWithArrangedSubviews:@[self.retakeButton, self.confirmButton]];
    self.actionRow.axis = UILayoutConstraintAxisHorizontal;
    self.actionRow.alignment = UIStackViewAlignmentCenter;
    self.actionRow.distribution = UIStackViewDistributionFillEqually;
    self.actionRow.spacing = 52;
    self.actionRow.hidden = YES;
    [self.view addSubview:self.actionRow];

    self.previewContainer = [[UIView alloc] init];
    self.previewContainer.backgroundColor = [LoanZen_ColorUtils LZ_cameraBackground];
    self.previewContainer.layer.cornerRadius = 20;
    self.previewContainer.clipsToBounds = YES;
    [self.view addSubview:self.previewContainer];

    [self.view addSubview:self.shutterButton];

    self.capturedImageView = [[UIImageView alloc] init];
    self.capturedImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.capturedImageView.clipsToBounds = YES;
    self.capturedImageView.hidden = YES;
    [self.previewContainer addSubview:self.capturedImageView];

    UIImage *guideImage = [LoanZen_Asset imageNamed:@"lz_ckx"];
    self.guideOverlay = [[UIImageView alloc] initWithImage:guideImage];
    self.guideOverlay.contentMode = UIViewContentModeScaleToFill;
    self.guideOverlay.userInteractionEnabled = NO;
    [self.view addSubview:self.guideOverlay];

    self.hintWrap = [[UIView alloc] init];
    self.hintWrap.backgroundColor = UIColor.clearColor;
    self.hintWrap.clipsToBounds = YES;
    [self.view addSubview:self.hintWrap];

    self.hintImageView = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:@"lz_container_2"]];
    self.hintImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.hintImageView.userInteractionEnabled = NO;
    [self.hintWrap addSubview:self.hintImageView];

    [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(10);
        make.centerX.equalTo(self.view);
        make.width.height.mas_equalTo(40);
    }];
    [self.shutterButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-15);
        make.width.height.mas_equalTo(72);
    }];
    [self.actionRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-15);
        make.width.mas_equalTo(180);
        make.height.mas_equalTo(72);
    }];
    [self.retakeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(72);
    }];
    [self.confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(72);
    }];
    [self.guideOverlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view).inset(25);
        make.top.equalTo(self.backButton.mas_bottom).offset(51);
        make.bottom.equalTo(self.shutterButton.mas_top).offset(-51);
    }];
    [self.previewContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.guideOverlay);
    }];
    [self.capturedImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.previewContainer);
    }];
    [self.hintWrap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.guideOverlay).offset(10);
        make.top.equalTo(self.guideOverlay).offset(10);
        make.bottom.equalTo(self.guideOverlay).offset(-10);
        make.width.mas_equalTo(33);
    }];
    [self.hintImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.hintWrap);
    }];
}

#pragma mark - Camera

- (NSString *)LZ_itemCode {
    return self.side == LoanZen_KYCIDCaptureSideFront ? @"identity_front_img" : @"identity_back_img";
}

- (void)LZ_setupCameraIfAuthorized {
    if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] != AVAuthorizationStatusAuthorized) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    [self LZ_setupCamera];
}

- (AVCaptureDevice *)LZ_preferredBackCaptureDevice {
    AVCaptureDevice *ultraWide = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInUltraWideCamera
                                                                    mediaType:AVMediaTypeVideo
                                                                     position:AVCaptureDevicePositionBack];
    if (ultraWide) return ultraWide;
    AVCaptureDevice *wide = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
                                                               mediaType:AVMediaTypeVideo
                                                                position:AVCaptureDevicePositionBack];
    if (wide) return wide;
    return [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
}

- (void)LZ_setupCamera {
    if (self.session) return;
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetPhoto;
    // 对齐 LoanEase：证件拍照优先超广角，不可用再回退广角
    AVCaptureDevice *device = [self LZ_preferredBackCaptureDevice];
    if (!device) return;
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (error || ![self.session canAddInput:input]) return;
    [self.session addInput:input];
    self.photoOutput = [[AVCapturePhotoOutput alloc] init];
    if ([self.session canAddOutput:self.photoOutput]) [self.session addOutput:self.photoOutput];
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.previewContainer.layer insertSublayer:self.previewLayer atIndex:0];
}

- (void)LZ_startSessionIfNeeded {
    if (self.capturedImage || !self.session || self.session.isRunning) return;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [self.session startRunning];
    });
}

- (void)LZ_stopSession {
    if (!self.session.isRunning) return;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [self.session stopRunning];
    });
}

- (UIImage *)LZ_normalizedImage:(UIImage *)image {
    if (!image) return nil;
    if (image.imageOrientation == UIImageOrientationUp) return image;
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    UIImage *normalized = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalized ?: image;
}

#pragma mark - Actions

- (void)LZ_pop {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)LZ_capture {
    if (self.isCapturingPhoto || !self.photoOutput) return;
    if (self.side == LoanZen_KYCIDCaptureSideFront) {
        [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventKYCIdentityCapturePhotoFront];
    }
    self.isCapturingPhoto = YES;
    AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettings];
    [self.photoOutput capturePhotoWithSettings:settings delegate:self];
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error {
    self.isCapturingPhoto = NO;
    if (error || !photo) return;
    UIImage *image = [UIImage imageWithData:[photo fileDataRepresentation]];
    image = [self LZ_normalizedImage:image];
    if (!image) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self LZ_showCaptured:image];
    });
}

- (void)LZ_showCaptured:(UIImage *)image {
    self.capturedImage = image;
    self.capturedImageView.image = image;
    self.capturedImageView.hidden = NO;
    self.previewLayer.hidden = YES;
    self.guideOverlay.hidden = NO;
    self.hintImageView.hidden = NO;
    [self.view bringSubviewToFront:self.guideOverlay];
    [self.view bringSubviewToFront:self.hintWrap];
    [self.view bringSubviewToFront:self.shutterButton];
    [self.view bringSubviewToFront:self.actionRow];
    self.shutterButton.hidden = YES;
    self.actionRow.hidden = NO;
    [self LZ_stopSession];
}

- (void)LZ_retake {
    self.capturedImage = nil;
    self.capturedImageView.image = nil;
    self.capturedImageView.hidden = YES;
    self.previewLayer.hidden = NO;
    self.guideOverlay.hidden = NO;
    self.hintImageView.hidden = NO;
    self.shutterButton.hidden = NO;
    self.actionRow.hidden = YES;
    [self LZ_startSessionIfNeeded];
}

- (void)LZ_confirm {
    if (!self.capturedImage) return;
    if (self.side == LoanZen_KYCIDCaptureSideFront) {
        [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventKYCIdentityConfirmPhotoFront];
    }
    UIImage *portraitImage = [LoanZen_ImageCompression LZ_imageRotatedMinus90:self.capturedImage];
    if (!portraitImage) portraitImage = self.capturedImage;
    NSString *imgBase64 = [LoanZen_ImageCompression LZ_jpegBase64FromImage:portraitImage quality:0.92 maxBytes:400000];
    if (imgBase64.length == 0 || !self.onConfirmed) return;
    self.onConfirmed([self LZ_itemCode], imgBase64, portraitImage);
    [self.navigationController popViewControllerAnimated:YES];
}

@end
