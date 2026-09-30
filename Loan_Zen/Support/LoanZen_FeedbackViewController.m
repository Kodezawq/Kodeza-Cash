#import "LoanZen_FeedbackViewController.h"
#import "LoanZen_ScreenScaffoldView.h"
#import "LoanZen_DesignSystem.h"
#import "LoanZen_ColorUtils.h"
#import "LoanZen_HUD.h"
#import "LoanZen_PopupHelper.h"
#import "LoanZen_FeedbackService.h"
@import Masonry;

static const NSInteger kLZFeedbackMaxImageCount = 3;
static const NSInteger kLZFeedbackMaxTextLength = 1000;
static const int64_t kLZFeedbackMaxImageBytes = 800000;

@interface LZFeedbackImageItem : NSObject
@property (nonatomic, strong) UIImage *preview;
@property (nonatomic, copy, nullable) NSString *uploadedURL;
@property (nonatomic, assign) BOOL isUploading;
@end

@implementation LZFeedbackImageItem
@end

@interface LoanZen_FeedbackViewController () <UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) LoanZen_ScreenScaffoldView *scaffold;
@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, strong) UILabel *uploadCountLabel;
@property (nonatomic, strong) UIStackView *uploadStack;
@property (nonatomic, strong) UIButton *submitButton;
@property (nonatomic, strong) NSMutableArray<LZFeedbackImageItem *> *imageItems;
@property (nonatomic, copy) NSArray<UIControl *> *uploadSlots;
@property (nonatomic, assign) BOOL isPresentingPicker;
@property (nonatomic, assign) BOOL isSubmitting;
@property (nonatomic, assign) NSInteger activeImageUploadCount;
@property (nonatomic, assign) CGRect LZ_lastSubmitButtonBounds;
@end

@implementation LoanZen_FeedbackViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageItems = [NSMutableArray array];
    self.navigationController.navigationBarHidden = YES;

    self.scaffold = [[LoanZen_ScreenScaffoldView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.scaffold];
    [self.scaffold mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.view); }];
    [self.scaffold LZ_useProfilePageStyle];
    [self.scaffold LZ_setHeaderTitle:@"Feedback"];
    __weak typeof(self) weakSelf = self;
    [self.scaffold LZ_setBackAction:^{ [weakSelf.navigationController popViewControllerAnimated:YES]; }];

    self.bottomBar = [self LZ_buildBottomBar];
    [self.view addSubview:self.bottomBar];
    [self.bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.submitButton.mas_top).offset(-12);
    }];
    [self.submitButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.bottomBar).inset(16);
        make.height.mas_equalTo(48);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-12);
    }];

    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.scaffold.contentView addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.scaffold.contentView);
        make.bottom.equalTo(self.bottomBar.mas_top);
    }];

    UIView *content = [[UIView alloc] init];
    [self.scrollView addSubview:content];
    [content mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];
    [self LZ_buildContentInView:content];
    [self.view bringSubviewToFront:self.bottomBar];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (!CGRectEqualToRect(self.submitButton.bounds, self.LZ_lastSubmitButtonBounds)) {
        self.LZ_lastSubmitButtonBounds = self.submitButton.bounds;
        [LoanZen_ColorUtils LZ_applyBrandGradientToView:self.submitButton cornerRadius:24];
    }
}

#pragma mark - Layout

- (UIView *)LZ_darkCard {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [LoanZen_Color kycFormCardFill];
    card.layer.cornerRadius = 16;
    card.layer.borderWidth = 1;
    card.layer.borderColor = [LoanZen_Color kycFormCardBorder].CGColor;
    card.clipsToBounds = YES;
    return card;
}

- (UIView *)LZ_tipCardWithText:(NSString *)text {
    UIView *card = [self LZ_darkCard];
    card.backgroundColor = [[LoanZen_Color accent] colorWithAlphaComponent:0.10];
    card.layer.borderColor = [[LoanZen_Color accent] colorWithAlphaComponent:0.35].CGColor;
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    label.textColor = [LoanZen_Color kycFormLabel];
    label.text = text;
    [card addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(card).insets(UIEdgeInsetsMake(14, 16, 14, 16));
    }];
    return card;
}

- (void)LZ_buildContentInView:(UIView *)content {
    UIView *tipCard = [self LZ_tipCardWithText:@"You can describe the problem you encounter in detail on this page, or send your problem to our email, leave your contact information, and we will contact you as soon as possible!"];
    [content addSubview:tipCard];
    [tipCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(content).offset(12);
        make.left.right.equalTo(content).inset(16);
    }];

    UIView *questionCard = [self LZ_darkCard];
    [content addSubview:questionCard];
    [questionCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tipCard.mas_bottom).offset(16);
        make.left.right.equalTo(content).inset(16);
    }];

    UILabel *questionTitle = [[UILabel alloc] init];
    questionTitle.text = @"Your question";
    questionTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    questionTitle.textColor = [LoanZen_Color kycFormValue];
    UILabel *requiredLabel = [[UILabel alloc] init];
    requiredLabel.text = @"* Required";
    requiredLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    requiredLabel.textColor = [LoanZen_Color accent];
    requiredLabel.textAlignment = NSTextAlignmentRight;
    [questionCard addSubview:questionTitle];
    [questionCard addSubview:requiredLabel];
    [questionTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(questionCard).inset(16);
    }];
    [requiredLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(questionTitle);
        make.right.equalTo(questionCard).offset(-16);
        make.left.greaterThanOrEqualTo(questionTitle.mas_right).offset(8);
    }];

    UIView *inputShell = [[UIView alloc] init];
    inputShell.backgroundColor = [LoanZen_Color kycFormInputFill];
    inputShell.layer.cornerRadius = 12;
    inputShell.layer.borderWidth = 1;
    inputShell.layer.borderColor = [LoanZen_Color kycFormInputBorder].CGColor;
    inputShell.clipsToBounds = YES;
    [questionCard addSubview:inputShell];
    [inputShell mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(questionTitle.mas_bottom).offset(12);
        make.left.right.equalTo(questionCard).inset(16);
        make.height.mas_equalTo(160);
        make.bottom.equalTo(questionCard).offset(-16);
    }];

    self.textView = [[UITextView alloc] init];
    self.textView.backgroundColor = UIColor.clearColor;
    self.textView.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.textView.textColor = [LoanZen_Color kycFormValue];
    self.textView.textContainerInset = UIEdgeInsetsMake(12, 12, 28, 12);
    self.textView.delegate = self;
    [inputShell addSubview:self.textView];
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(inputShell); }];

    self.placeholderLabel = [[UILabel alloc] init];
    self.placeholderLabel.text = @"Please enter";
    self.placeholderLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.placeholderLabel.textColor = [LoanZen_Color kycFormPlaceholder];
    [inputShell addSubview:self.placeholderLabel];
    [self.placeholderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(inputShell).offset(16);
        make.top.equalTo(inputShell).offset(13);
    }];

    self.countLabel = [[UILabel alloc] init];
    self.countLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
    self.countLabel.textColor = [LoanZen_Color kycFormPlaceholder];
    self.countLabel.textAlignment = NSTextAlignmentRight;
    self.countLabel.text = @"0 / 1000";
    [inputShell addSubview:self.countLabel];
    [self.countLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(inputShell).offset(-12);
        make.bottom.equalTo(inputShell).offset(-10);
    }];

    UIView *uploadCard = [self LZ_darkCard];
    [content addSubview:uploadCard];
    [uploadCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(questionCard.mas_bottom).offset(12);
        make.left.right.equalTo(content).inset(16);
        make.bottom.equalTo(content).offset(-24);
    }];

    UILabel *uploadTitle = [[UILabel alloc] init];
    uploadTitle.text = @"Upload Pictures";
    uploadTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    uploadTitle.textColor = [LoanZen_Color kycFormValue];
    self.uploadCountLabel = [[UILabel alloc] init];
    self.uploadCountLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
    self.uploadCountLabel.textColor = [LoanZen_Color kycFormPlaceholder];
    self.uploadCountLabel.textAlignment = NSTextAlignmentRight;
    self.uploadCountLabel.text = @"0 / 3";
    [uploadCard addSubview:uploadTitle];
    [uploadCard addSubview:self.uploadCountLabel];
    [uploadTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(uploadCard).inset(16);
        make.height.mas_equalTo(21);
    }];
    [self.uploadCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(uploadTitle);
        make.right.equalTo(uploadCard).offset(-16);
        make.left.greaterThanOrEqualTo(uploadTitle.mas_right).offset(8);
    }];

    self.uploadStack = [[UIStackView alloc] init];
    self.uploadStack.axis = UILayoutConstraintAxisHorizontal;
    self.uploadStack.alignment = UIStackViewAlignmentFill;
    self.uploadStack.distribution = UIStackViewDistributionFillEqually;
    self.uploadStack.spacing = 10;
    [uploadCard addSubview:self.uploadStack];
    [self.uploadStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(uploadCard).inset(16);
        make.top.equalTo(uploadTitle.mas_bottom).offset(12);
        make.bottom.equalTo(uploadCard).offset(-16);
    }];

    NSMutableArray *slots = [NSMutableArray array];
    for (NSInteger idx = 0; idx < kLZFeedbackMaxImageCount; idx++) {
        UIControl *slot = [self LZ_uploadSlotAtIndex:idx];
        [slots addObject:slot];
        [self.uploadStack addArrangedSubview:slot];
    }
    self.uploadSlots = slots.copy;
    [self LZ_refreshUploadSlots];
}

- (UIView *)LZ_buildBottomBar {
    UIView *bar = [[UIView alloc] init];
    bar.backgroundColor = [LoanZen_Color background];

    self.submitButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.submitButton.backgroundColor = [LoanZen_Color accent];
    self.submitButton.layer.cornerRadius = 24;
    self.submitButton.clipsToBounds = YES;
    [self.submitButton setTitle:@"Submit" forState:UIControlStateNormal];
    [self.submitButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.submitButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.submitButton addTarget:self action:@selector(LZ_submit) forControlEvents:UIControlEventTouchUpInside];
    [bar addSubview:self.submitButton];
    return bar;
}

- (UIControl *)LZ_uploadSlotAtIndex:(NSInteger)index {
    UIControl *slot = [[UIControl alloc] init];
    slot.tag = index;
    slot.clipsToBounds = NO;
    [slot mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(slot.mas_width);
    }];
    [slot addTarget:self action:@selector(LZ_tapUploadSlot:) forControlEvents:UIControlEventTouchUpInside];
    return slot;
}

- (void)LZ_styleEmptyUploadSlot:(UIControl *)slot {
    UIView *wrap = [[UIView alloc] init];
    wrap.backgroundColor = [LoanZen_Color kycFormInputFill];
    wrap.layer.cornerRadius = 12;
    wrap.clipsToBounds = YES;
    wrap.userInteractionEnabled = NO;
    UIImage *cameraImage = [UIImage systemImageNamed:@"camera.fill"];
    UIImageView *camera = [[UIImageView alloc] initWithImage:cameraImage];
    camera.contentMode = UIViewContentModeScaleAspectFit;
    camera.tintColor = [LoanZen_Color kycFormPlaceholder];
    camera.userInteractionEnabled = NO;
    [slot addSubview:wrap];
    [wrap addSubview:camera];
    [wrap mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(slot); }];
    [camera mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(wrap);
        make.width.height.mas_equalTo(24);
    }];
}

- (void)LZ_refreshUploadSlots {
    for (NSInteger idx = 0; idx < self.uploadSlots.count; idx++) {
        UIControl *slot = self.uploadSlots[idx];
        for (UIView *sub in slot.subviews) [sub removeFromSuperview];

        slot.hidden = NO;
        slot.userInteractionEnabled = NO;

        if (idx < (NSInteger)self.imageItems.count) {
            LZFeedbackImageItem *item = self.imageItems[idx];
            slot.userInteractionEnabled = YES;
            UIView *previewWrap = [[UIView alloc] init];
            previewWrap.backgroundColor = [LoanZen_Color kycFormInputFill];
            previewWrap.layer.cornerRadius = 12;
            previewWrap.clipsToBounds = YES;
            previewWrap.userInteractionEnabled = NO;
            UIImageView *preview = [[UIImageView alloc] initWithImage:item.preview];
            preview.contentMode = UIViewContentModeScaleAspectFill;
            preview.clipsToBounds = YES;
            [slot addSubview:previewWrap];
            [previewWrap addSubview:preview];
            [previewWrap mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(slot); }];
            [preview mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(previewWrap); }];

            if (item.isUploading) {
                UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
                spinner.color = UIColor.whiteColor;
                [spinner startAnimating];
                [previewWrap addSubview:spinner];
                [spinner mas_makeConstraints:^(MASConstraintMaker *make) { make.center.equalTo(previewWrap); }];
            }

            UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [deleteButton setImage:[LoanZen_Asset imageNamed:@"lz_feedback_delete"] forState:UIControlStateNormal];
            deleteButton.tag = idx;
            deleteButton.enabled = !item.isUploading;
            [deleteButton addTarget:self action:@selector(LZ_deleteImage:) forControlEvents:UIControlEventTouchUpInside];
            [slot addSubview:deleteButton];
            [deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(slot).offset(-4);
                make.right.equalTo(slot).offset(4);
                make.width.height.mas_equalTo(22);
            }];
        } else if (idx == (NSInteger)self.imageItems.count && self.imageItems.count < kLZFeedbackMaxImageCount) {
            slot.userInteractionEnabled = YES;
            UIImageView *addSlot = [[UIImageView alloc] initWithImage:[LoanZen_Asset imageNamed:@"lz_feedback_add"]];
            addSlot.contentMode = UIViewContentModeScaleToFill;
            addSlot.userInteractionEnabled = NO;
            [slot addSubview:addSlot];
            [addSlot mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(slot); }];
        } else {
            [self LZ_styleEmptyUploadSlot:slot];
        }
    }
    self.uploadCountLabel.text = [NSString stringWithFormat:@"%lu / %ld", (unsigned long)self.imageItems.count, (long)kLZFeedbackMaxImageCount];
}

#pragma mark - Actions

- (void)LZ_tapUploadSlot:(UIControl *)sender {
    NSInteger index = sender.tag;
    if (index < (NSInteger)self.imageItems.count) return;
    if (self.imageItems.count >= kLZFeedbackMaxImageCount) return;
    if (index != (NSInteger)self.imageItems.count) return;
    if (self.isPresentingPicker) return;
    [self LZ_presentAlbumPicker];
}

- (void)LZ_deleteImage:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index < 0 || index >= (NSInteger)self.imageItems.count) return;
    LZFeedbackImageItem *item = self.imageItems[index];
    if (item.isUploading) return;
    [self.imageItems removeObjectAtIndex:index];
    [self LZ_refreshUploadSlots];
}

- (void)LZ_beginImageUploadHUD {
    if (self.activeImageUploadCount == 0) {
        [LoanZen_HUD LZ_showBlockingLoading:@"Uploading"];
    }
    self.activeImageUploadCount += 1;
}

- (void)LZ_endImageUploadHUD {
    self.activeImageUploadCount = MAX(0, self.activeImageUploadCount - 1);
    if (self.activeImageUploadCount == 0) {
        [LoanZen_HUD LZ_hideBlockingLoading];
    }
}

- (void)LZ_appendAndUploadImage:(UIImage *)image {
    NSData *data = [LoanZen_FeedbackService LZ_compressedJPEGDataFromImage:image maxBytes:kLZFeedbackMaxImageBytes];
    if (!data) {
        [LoanZen_HUD LZ_showError:@"Failed to process image, please try again."];
        return;
    }

    LZFeedbackImageItem *item = [[LZFeedbackImageItem alloc] init];
    item.preview = image;
    item.isUploading = YES;
    [self.imageItems addObject:item];
    [self LZ_refreshUploadSlots];
    [self LZ_beginImageUploadHUD];

    __weak typeof(self) weakSelf = self;
    __weak LZFeedbackImageItem *weakItem = item;
    [LoanZen_FeedbackService LZ_uploadImageData:data showLoading:NO completion:^(NSString *src, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (self) {
            [self LZ_endImageUploadHUD];
        } else {
            [LoanZen_HUD LZ_hideBlockingLoading];
        }
        if (!self || ![self.imageItems containsObject:weakItem]) return;
        if (error || src.length == 0) {
            [self.imageItems removeObject:weakItem];
            [self LZ_refreshUploadSlots];
            [LoanZen_HUD LZ_showError:@"Failed to upload image, please try again."];
            return;
        }
        weakItem.uploadedURL = src;
        weakItem.isUploading = NO;
        [self LZ_refreshUploadSlots];
    }];
}

- (NSArray<NSString *> *)LZ_uploadedImageURLs {
    NSMutableArray<NSString *> *urls = [NSMutableArray array];
    for (LZFeedbackImageItem *item in self.imageItems) {
        if (item.uploadedURL.length > 0) {
            [urls addObject:item.uploadedURL];
        }
    }
    return urls.copy;
}

- (BOOL)LZ_hasUploadingImages {
    for (LZFeedbackImageItem *item in self.imageItems) {
        if (item.isUploading) return YES;
    }
    return NO;
}

- (void)LZ_presentAlbumPicker {
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [LoanZen_PopupHelper LZ_showFrame:LoanZen_PopupFrameError on:self title:@"Photo Library" message:@"Photo Library not available" actions:@[@{@"title": @"Confirm", @"style": @(LoanZen_ModalActionStylePrimary)}]];
        return;
    }
    self.isPresentingPicker = YES;
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)textViewDidChange:(UITextView *)textView {
    if (textView.text.length > kLZFeedbackMaxTextLength) {
        textView.text = [textView.text substringToIndex:kLZFeedbackMaxTextLength];
    }
    self.placeholderLabel.hidden = textView.text.length > 0;
    self.countLabel.text = [NSString stringWithFormat:@"%lu / %ld", (unsigned long)textView.text.length, (long)kLZFeedbackMaxTextLength];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:^{
        self.isPresentingPicker = NO;
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *image = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:^{
        self.isPresentingPicker = NO;
        if (!image || self.imageItems.count >= kLZFeedbackMaxImageCount) return;
        [self LZ_appendAndUploadImage:image];
    }];
}

- (void)LZ_submit {
    if (self.isSubmitting) return;
    NSString *description = [self.textView.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (description.length == 0) {
        [LoanZen_HUD LZ_showError:@"Please enter your question."];
        return;
    }
    if ([self LZ_hasUploadingImages]) {
        [LoanZen_HUD LZ_showError:@"Images are still uploading, please wait."];
        return;
    }

    NSArray<NSString *> *urls = [self LZ_uploadedImageURLs];
    NSString *pictureUrl = urls.count > 0 ? [urls componentsJoinedByString:@","] : nil;

    self.isSubmitting = YES;
    self.submitButton.enabled = NO;
    [self LZ_submitFeedbackWithDescription:description pictureUrl:pictureUrl];
}

- (void)LZ_submitFeedbackWithDescription:(NSString *)description pictureUrl:(NSString *)pictureUrl {
    __weak typeof(self) weakSelf = self;
    [LoanZen_FeedbackService LZ_submitProblemFeedbackWithDescription:description pictureUrl:pictureUrl showLoading:YES completion:^(NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.isSubmitting = NO;
        self.submitButton.enabled = YES;
        if (error) {
            [LoanZen_HUD LZ_showError:error.localizedDescription];
            return;
        }
        [LoanZen_PopupHelper LZ_showFrame:LoanZen_PopupFrameSuccess on:self title:@"Thanks" message:@"Thank you for your valuable feedback! Your input is crucial in enhancing our services, and we are committed to continuous improvement." actions:@[
            @{@"title": @"Confirm", @"style": @(LoanZen_ModalActionStylePrimary), @"handler": ^{
                __strong typeof(weakSelf) innerSelf = weakSelf;
                [innerSelf.navigationController popViewControllerAnimated:YES];
            }},
        ]];
    }];
}

@end
