#import "LoanZen_FaceLivenessCaptureViewController.h"
#import "LoanZen_ImageCompression.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_ColorUtils.h"
@import AVFoundation;
@import Masonry;

@interface LoanZen_FaceLivenessCaptureViewController () <AVCapturePhotoCaptureDelegate>
@property (nonatomic, copy) void (^onConfirmed)(NSString *base64, UIImage *preview);
@property (nonatomic, strong) UIView *previewContainer;
@property (nonatomic, strong) UIImageView *capturedView;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCapturePhotoOutput *photoOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) UIImage *capturedImage;
@property (nonatomic, strong) UIButton *confirmButton;
@end

@implementation LoanZen_FaceLivenessCaptureViewController

- (instancetype)initWithOnConfirmed:(void (^)(NSString *, UIImage *))onConfirmed {
    self = [super initWithNibName:nil bundle:nil];
    if (self) _onConfirmed = [onConfirmed copy];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [LoanZen_ColorUtils LZ_cameraBackground];
    self.navigationController.navigationBarHidden = YES;

    self.previewContainer = [[UIView alloc] init];
    self.previewContainer.layer.cornerRadius = 16;
    self.previewContainer.clipsToBounds = YES;
    [self.view addSubview:self.previewContainer];

    self.capturedView = [[UIImageView alloc] init];
    self.capturedView.hidden = YES;
    self.capturedView.contentMode = UIViewContentModeScaleAspectFit;
    [self.previewContainer addSubview:self.capturedView];

    UIImageView *guide = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:@"lz_pz_zq"]];
    guide.contentMode = UIViewContentModeScaleAspectFit;
    [self.previewContainer addSubview:guide];

    UIButton *shutter = [UIButton buttonWithType:UIButtonTypeCustom];
    shutter.backgroundColor = UIColor.whiteColor;
    shutter.layer.cornerRadius = 36;
    [shutter addTarget:self action:@selector(LZ_capture) forControlEvents:UIControlEventTouchUpInside];

    self.confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.confirmButton.backgroundColor = [LoanZen_Color accent];
    self.confirmButton.layer.cornerRadius = 12;
    [self.confirmButton setTitle:@"Confirm" forState:UIControlStateNormal];
    self.confirmButton.hidden = YES;
    [self.confirmButton addTarget:self action:@selector(LZ_confirm) forControlEvents:UIControlEventTouchUpInside];

    UIButton *retry = [UIButton buttonWithType:UIButtonTypeSystem];
    [retry setTitle:@"Retake" forState:UIControlStateNormal];
    [retry setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    retry.hidden = YES;
    retry.tag = 99;
    [retry addTarget:self action:@selector(LZ_retake) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:shutter];
    [self.view addSubview:self.confirmButton];
    [self.view addSubview:retry];

    [self.previewContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(24);
        make.left.right.equalTo(self.view).inset(24);
        make.height.equalTo(self.previewContainer.mas_width);
    }];
    [self.capturedView mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.previewContainer); }];
    [guide mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.previewContainer).insets(UIEdgeInsetsMake(12, 12, 12, 12)); }];
    [shutter mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-24);
        make.width.height.mas_equalTo(72);
    }];
    [self.confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view).inset(24);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-24);
        make.height.mas_equalTo(48);
    }];
    [retry mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.confirmButton.mas_top).offset(-12);
    }];

    [self LZ_setupCamera];
}

- (void)LZ_setupCamera {
    self.session = [[AVCaptureSession alloc] init];
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
    if (!device) device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!device) return;
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (!error && [self.session canAddInput:input]) [self.session addInput:input];
    self.photoOutput = [[AVCapturePhotoOutput alloc] init];
    if ([self.session canAddOutput:self.photoOutput]) [self.session addOutput:self.photoOutput];
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.previewContainer.layer insertSublayer:self.previewLayer atIndex:0];
    if (self.previewLayer.connection.isVideoMirroringSupported) {
        self.previewLayer.connection.automaticallyAdjustsVideoMirroring = NO;
        self.previewLayer.connection.videoMirrored = YES;
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.previewLayer.frame = self.previewContainer.bounds;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.session && !self.session.isRunning) [self.session startRunning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.session.isRunning) [self.session stopRunning];
}

- (void)LZ_capture {
    if (!self.photoOutput) return;
    [self.photoOutput capturePhotoWithSettings:[AVCapturePhotoSettings photoSettings] delegate:self];
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error {
    if (error || !photo) return;
    UIImage *image = [UIImage imageWithData:[photo fileDataRepresentation]];
    self.capturedImage = image;
    self.capturedView.image = image;
    self.capturedView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    self.capturedView.hidden = NO;
    self.confirmButton.hidden = NO;
    [self.view viewWithTag:99].hidden = NO;
}

- (void)LZ_retake {
    self.capturedImage = nil;
    self.capturedView.image = nil;
    self.capturedView.transform = CGAffineTransformIdentity;
    self.capturedView.hidden = YES;
    self.confirmButton.hidden = YES;
    [self.view viewWithTag:99].hidden = YES;
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

- (void)LZ_confirm {
    NSString *b64 = [LoanZen_ImageCompression LZ_jpegBase64FromImage:self.capturedImage quality:0.92 maxBytes:400000];
    UIImage *preview = [self LZ_horizontallyMirroredImage:self.capturedImage] ?: self.capturedImage;
    if (b64.length > 0 && self.onConfirmed) self.onConfirmed(b64, preview);
    [self.navigationController popViewControllerAnimated:YES];
}

@end
