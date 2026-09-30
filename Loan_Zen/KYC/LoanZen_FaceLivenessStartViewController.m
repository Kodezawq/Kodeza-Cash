#import "LoanZen_FaceLivenessStartViewController.h"
#import "LoanZen_ScreenScaffoldView.h"
#import "LoanZen_ImageCompression.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_ColorUtils.h"
#import "LoanZen_HUD.h"
#import "LoanZen_BuryReporter.h"
@import AVFoundation;
@import Masonry;

static NSString * const kLZFaceHint = @"Make sure your face fits in the frame,\nthen take a photo.";

@interface LoanZen_FaceLivenessStartViewController () <AVCapturePhotoCaptureDelegate>
@property (nonatomic, copy) void (^onConfirmed)(NSString *base64, UIImage *preview);
@property (nonatomic, strong) LoanZen_ScreenScaffoldView *scaffold;
@property (nonatomic, strong) UIView *faceFrame;
@property (nonatomic, strong) UIView *cameraPreviewContainer;
@property (nonatomic, strong) UIImageView *faceGuideView;
@property (nonatomic, strong) UIImageView *capturedResultView;
@property (nonatomic, strong) UILabel *bodyLabel;
@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UIButton *takePhotoButton;
@property (nonatomic, strong) UIStackView *actionRow;
@property (nonatomic, strong) UIButton *restartButton;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCapturePhotoOutput *photoOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) UIImage *capturedImage;
@property (nonatomic, copy) NSString *pendingBase64;
@property (nonatomic, assign) BOOL isReviewingCapturedPhoto;
@property (nonatomic, assign) BOOL isCapturingPhoto;
@end

@implementation LoanZen_FaceLivenessStartViewController

- (instancetype)initWithOnConfirmed:(void (^)(NSString *, UIImage *))onConfirmed {
    self = [super initWithNibName:nil bundle:nil];
    if (self) _onConfirmed = [onConfirmed copy];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [LoanZen_Color background];
    self.navigationController.navigationBarHidden = YES;

    self.scaffold = [[LoanZen_ScreenScaffoldView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.scaffold];
    [self.scaffold mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.view); }];
    [self.scaffold LZ_useKYCStyle];
    [self.scaffold LZ_setHeaderTitle:@"Face identification"];
    __weak typeof(self) weakSelf = self;
    [self.scaffold LZ_setBackAction:^{ [weakSelf.navigationController popViewControllerAnimated:YES]; }];

    self.faceFrame = [[UIView alloc] init];
    self.faceFrame.backgroundColor = [LoanZen_ColorUtils LZ_kycFormInputFill];
    self.faceFrame.layer.cornerRadius = 16;
    self.faceFrame.clipsToBounds = YES;
    [self.scaffold.contentView addSubview:self.faceFrame];

    self.cameraPreviewContainer = [[UIView alloc] init];
    self.cameraPreviewContainer.backgroundColor = UIColor.clearColor;
    self.cameraPreviewContainer.clipsToBounds = YES;
    [self.faceFrame addSubview:self.cameraPreviewContainer];

    self.capturedResultView = [[UIImageView alloc] init];
    self.capturedResultView.contentMode = UIViewContentModeScaleAspectFit;
    self.capturedResultView.clipsToBounds = YES;
    self.capturedResultView.hidden = YES;
    [self.cameraPreviewContainer addSubview:self.capturedResultView];

    UIImage *guideImage = [LoanZen_Asset imageNamed:@"lz_face_ckx"];
    self.faceGuideView = [[UIImageView alloc] initWithImage:guideImage];
    self.faceGuideView.contentMode = UIViewContentModeScaleAspectFit;
    self.faceGuideView.userInteractionEnabled = NO;
    self.faceGuideView.hidden = (guideImage == nil);
    [self.faceFrame addSubview:self.faceGuideView];

    self.bodyLabel = [[UILabel alloc] init];
    self.bodyLabel.numberOfLines = 0;
    self.bodyLabel.textAlignment = NSTextAlignmentCenter;
    self.bodyLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    self.bodyLabel.textColor = [LoanZen_Color secondaryText];
    self.bodyLabel.text = kLZFaceHint;
    [self.scaffold.contentView addSubview:self.bodyLabel];

    self.bottomBar = [[UIView alloc] init];
    self.bottomBar.backgroundColor = UIColor.clearColor;
    [self.scaffold addSubview:self.bottomBar];

    self.takePhotoButton = [self LZ_makePrimaryButtonWithTitle:@"Take a photo"];
    [self.takePhotoButton addTarget:self action:@selector(LZ_capture) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.takePhotoButton];

    self.restartButton = [self LZ_makeRestartButton];
    [self.restartButton addTarget:self action:@selector(LZ_restart) forControlEvents:UIControlEventTouchUpInside];

    self.confirmButton = [self LZ_makePrimaryButtonWithTitle:@"Confirm"];
    [self.confirmButton addTarget:self action:@selector(LZ_confirm) forControlEvents:UIControlEventTouchUpInside];

    self.actionRow = [[UIStackView alloc] initWithArrangedSubviews:@[self.restartButton, self.confirmButton]];
    self.actionRow.axis = UILayoutConstraintAxisHorizontal;
    self.actionRow.spacing = 12;
    self.actionRow.distribution = UIStackViewDistributionFillEqually;
    self.actionRow.alignment = UIStackViewAlignmentFill;
    self.actionRow.hidden = YES;
    [self.bottomBar addSubview:self.actionRow];

    [self.faceFrame mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.scaffold.contentView).offset(24);
        make.centerX.equalTo(self.scaffold.contentView);
        make.width.lessThanOrEqualTo(@343);
        make.left.greaterThanOrEqualTo(self.scaffold.contentView).offset(16);
        make.right.lessThanOrEqualTo(self.scaffold.contentView).offset(-16);
        make.height.equalTo(self.faceFrame.mas_width);
    }];
    [self.cameraPreviewContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.faceFrame);
    }];
    [self.capturedResultView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.cameraPreviewContainer);
    }];
    [self.faceGuideView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.faceFrame);
        make.width.height.lessThanOrEqualTo(self.faceFrame).offset(-40);
    }];
    [self.bodyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.faceFrame.mas_bottom).offset(20);
        make.centerX.equalTo(self.scaffold.contentView);
        make.left.greaterThanOrEqualTo(self.scaffold.contentView).offset(16);
        make.right.lessThanOrEqualTo(self.scaffold.contentView).offset(-16);
        make.width.lessThanOrEqualTo(@343);
    }];
    [self.bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.scaffold);
        make.bottom.equalTo(self.scaffold.mas_safeAreaLayoutGuideBottom);
        make.height.mas_equalTo(61);
    }];
    [self.takePhotoButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.bottomBar).inset(16);
        make.bottom.equalTo(self.bottomBar);
        make.height.mas_equalTo(48);
    }];
    [self.actionRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.bottomBar).inset(16);
        make.bottom.equalTo(self.bottomBar);
        make.height.mas_equalTo(48);
    }];
    [self.scaffold bringSubviewToFront:self.bottomBar];
}

#pragma mark - Button factories

- (UIButton *)LZ_makePrimaryButtonWithTitle:(NSString *)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [LoanZen_Color accent];
    button.layer.cornerRadius = 24;
    button.clipsToBounds = YES;
    button.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    return button;
}

- (UIButton *)LZ_makeRestartButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [LoanZen_ColorUtils LZ_glassFill08];
    button.layer.cornerRadius = 24;
    button.layer.borderWidth = 1;
    button.layer.borderColor = [LoanZen_ColorUtils LZ_glassBorder16].CGColor;
    button.clipsToBounds = YES;
    button.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [button setTitle:@"Restart" forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    UIImage *icon = [LoanZen_Asset imageNamed:@"lz_restart"];
    if (icon) {
        [button setImage:icon forState:UIControlStateNormal];
        button.imageEdgeInsets = UIEdgeInsetsMake(0, -6, 0, 6);
        button.titleEdgeInsets = UIEdgeInsetsMake(0, 6, 0, -6);
    }
    return button;
}

#pragma mark - Lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [LoanZen_BuryReporter LZ_trackEvent:LZAnalyticsEventLivenessStart];
    if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusAuthorized) {
        [self LZ_setupFrontCameraIfNeeded];
        [self LZ_schedulePreviewStart];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self LZ_stopSession];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.previewLayer.frame = self.cameraPreviewContainer.bounds;
}

#pragma mark - Camera

- (void)LZ_setupFrontCameraIfNeeded {
    if (self.session) return;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
    if (!device) device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!device) return;

    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetPhoto;
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (error || ![self.session canAddInput:input]) return;
    [self.session addInput:input];
    self.photoOutput = [[AVCapturePhotoOutput alloc] init];
    if ([self.session canAddOutput:self.photoOutput]) [self.session addOutput:self.photoOutput];

    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.cameraPreviewContainer.layer insertSublayer:self.previewLayer atIndex:0];
    if (self.previewLayer.connection.isVideoMirroringSupported) {
        self.previewLayer.connection.automaticallyAdjustsVideoMirroring = NO;
        self.previewLayer.connection.videoMirrored = YES;
    }
    [self.faceFrame bringSubviewToFront:self.faceGuideView];
}

- (void)LZ_schedulePreviewStart {
    if (self.isReviewingCapturedPhoto) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view layoutIfNeeded];
        self.previewLayer.frame = self.cameraPreviewContainer.bounds;
        [self LZ_startSessionIfNeeded];
    });
}

- (void)LZ_startSessionIfNeeded {
    if (self.isReviewingCapturedPhoto || !self.session || self.session.isRunning) return;
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

#pragma mark - Capture states

- (void)LZ_capture {
    if (self.isCapturingPhoto || !self.photoOutput) {
        [LoanZen_HUD LZ_showError:@"Camera is not ready."];
        return;
    }
    self.isCapturingPhoto = YES;
    [self.photoOutput capturePhotoWithSettings:[AVCapturePhotoSettings photoSettings] delegate:self];
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error {
    self.isCapturingPhoto = NO;
    if (error || !photo) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [LoanZen_HUD LZ_showError:@"Failed to capture photo."];
        });
        return;
    }
    UIImage *image = [UIImage imageWithData:[photo fileDataRepresentation]];
    NSString *b64 = [LoanZen_ImageCompression LZ_jpegBase64FromImage:image quality:0.92 maxBytes:400000];
    if (!image || b64.length == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [LoanZen_HUD LZ_showError:@"Failed to encode photo."];
        });
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self LZ_enterReviewStateWithImage:image base64:b64];
    });
}

- (void)LZ_enterReviewStateWithImage:(UIImage *)image base64:(NSString *)base64 {
    self.isReviewingCapturedPhoto = YES;
    self.capturedImage = image;
    self.pendingBase64 = base64;
    [self LZ_stopSession];
    self.previewLayer.hidden = YES;
    // 前置摄像头预览默认镜像，回显做水平镜像以与拍摄所见一致；AspectFit 避免裁剪。
    self.capturedResultView.image = image;
    self.capturedResultView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    self.capturedResultView.hidden = NO;
    self.faceGuideView.hidden = YES;
    self.takePhotoButton.hidden = YES;
    self.actionRow.hidden = NO;
}

- (void)LZ_restart {
    self.isReviewingCapturedPhoto = NO;
    self.capturedImage = nil;
    self.pendingBase64 = nil;
    self.capturedResultView.image = nil;
    self.capturedResultView.transform = CGAffineTransformIdentity;
    self.capturedResultView.hidden = YES;
    self.previewLayer.hidden = NO;
    self.faceGuideView.hidden = ([LoanZen_Asset imageNamed:@"lz_face_ckx"] == nil);
    self.takePhotoButton.hidden = NO;
    self.actionRow.hidden = YES;
    [self LZ_schedulePreviewStart];
}

- (void)LZ_confirm {
    if (self.pendingBase64.length == 0 || !self.capturedImage) {
        [LoanZen_HUD LZ_showError:@"No photo to submit."];
        return;
    }
    // 上传用原图；回显给上一页的预览图做镜像，保持与拍摄一致。
    UIImage *preview = [self LZ_horizontallyMirroredImage:self.capturedImage] ?: self.capturedImage;
    if (self.onConfirmed) self.onConfirmed(self.pendingBase64, preview);
    [self.navigationController popViewControllerAnimated:YES];
}

- (UIImage *)LZ_horizontallyMirroredImage:(UIImage *)image {
    if (!image) return nil;
    CGSize size = image.size;
    if (size.width <= 0 || size.height <= 0) return image;
    UIGraphicsBeginImageContextWithOptions(size, NO, image.scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) {
        UIGraphicsEndImageContext();
        return image;
    }
    CGContextTranslateCTM(ctx, size.width, 0);
    CGContextScaleCTM(ctx, -1.0, 1.0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *mirrored = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return mirrored ?: image;
}

@end
