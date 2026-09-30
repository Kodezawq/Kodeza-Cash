#import "LoanZen_PopupHelper.h"
#import "LoanZen_ModalCardViewController.h"
#import "LoanZen_PenRadioPickerViewController.h"
#import "LoanZen_DesignSystem.h"

@implementation LoanZen_PopupHelper

+ (NSString *)LZ_iconNameForFrame:(LoanZen_PopupFrame)frame {
    switch (frame) {
        case LoanZen_PopupFrameConfirmReturn: return @"lz_tk_fh";
        case LoanZen_PopupFramePermission: return @"lz_tk_ts";
        case LoanZen_PopupFrameError: return @"lz_tk_sb";
        case LoanZen_PopupFrameTips: return @"lz_tk_fjts";
        case LoanZen_PopupFrameContacts: return @"lz_tk_txl";
        case LoanZen_PopupFrameFailed: return @"lz_tk_sb";
        case LoanZen_PopupFrameAttachment: return @"lz_tk_xj";
        case LoanZen_PopupFrameSelect: return @"lz_tk_xz_u";
        case LoanZen_PopupFrameError1: return @"lz_tk_cwts1";
        case LoanZen_PopupFrameError2: return @"lz_tk_cwts2";
        case LoanZen_PopupFrameError3: return @"lz_tk_cwts3";
        case LoanZen_PopupFrameClose: return @"lz_tk_x";
        case LoanZen_PopupFrameDropdown: return @"lz_tk_xl";
        case LoanZen_PopupFrameUpdate: return @"lz_tk_gx";
        case LoanZen_PopupFrameSuccess: return @"lz_tk_cg";
        case LoanZen_PopupFrameWithdraw: return @"lz_tk_tx";
        case LoanZen_PopupFrameSignOut: return @"lz_tk_tc";
        case LoanZen_PopupFrameDeleteAccount: return @"lz_tk_sczh";
    }
    return @"lz_tk_fjts";
}

+ (void)LZ_showFrame:(LoanZen_PopupFrame)frame on:(UIViewController *)controller title:(NSString *)title message:(NSString *)message actions:(NSArray<NSDictionary *> *)actions {
    [self LZ_showFrame:frame on:controller title:title message:message iconName:nil actions:actions];
}

+ (void)LZ_showFrame:(LoanZen_PopupFrame)frame on:(UIViewController *)controller title:(NSString *)title message:(NSString *)message iconName:(nullable NSString *)iconName actions:(NSArray<NSDictionary *> *)actions {
    NSMutableArray<LoanZen_ModalAction *> *modalActions = [NSMutableArray array];
    for (NSDictionary *item in actions) {
        LoanZen_ModalActionStyle style = (LoanZen_ModalActionStyle)[item[@"style"] integerValue];
        void (^handler)(void) = item[@"handler"];
        [modalActions addObject:[LoanZen_ModalAction LZ_actionWithTitle:item[@"title"] style:style handler:handler]];
    }
    NSString *resolvedIcon = iconName.length > 0 ? iconName : [self LZ_iconNameForFrame:frame];
    [LoanZen_ModalCardViewController LZ_presentFrom:controller
                                              title:title
                                            message:message
                                           iconName:resolvedIcon
                                            actions:modalActions
                                       buttonHeight:48
                                 buttonCornerRadius:12
                                contentCornerRadius:16];
}

+ (void)LZ_showConfirmOn:(UIViewController *)controller title:(NSString *)title message:(NSString *)message confirmTitle:(NSString *)confirmTitle cancelTitle:(NSString *)cancelTitle onConfirm:(void (^)(void))onConfirm {
    [self LZ_showConfirmOn:controller title:title message:message confirmTitle:confirmTitle cancelTitle:cancelTitle iconName:nil onConfirm:onConfirm];
}

+ (void)LZ_showConfirmOn:(UIViewController *)controller title:(NSString *)title message:(NSString *)message confirmTitle:(NSString *)confirmTitle cancelTitle:(NSString *)cancelTitle iconName:(nullable NSString *)iconName onConfirm:(void (^)(void))onConfirm {
    [self LZ_showFrame:LoanZen_PopupFrameConfirmReturn on:controller title:title ?: @"Confirm" message:message iconName:iconName actions:@[
        @{@"title": confirmTitle ?: @"Confirm", @"style": @(LoanZen_ModalActionStyleCancel), @"handler": onConfirm ?: ^{}},
        @{@"title": cancelTitle ?: @"Cancel", @"style": @(LoanZen_ModalActionStylePrimary)},
    ]];
}

+ (void)LZ_showBottomPickerOn:(UIViewController *)controller title:(NSString *)title options:(NSArray<NSString *> *)options onSelected:(void (^)(NSInteger, NSString *))onSelected {
    [self LZ_showBottomPickerOn:controller title:title options:options selectedIndex:0 onSelected:onSelected];
}

+ (void)LZ_showBottomPickerOn:(UIViewController *)controller title:(NSString *)title options:(NSArray<NSString *> *)options selectedIndex:(NSInteger)selectedIndex onSelected:(void (^)(NSInteger, NSString *))onSelected {
    [LoanZen_PenRadioPickerViewController LZ_presentFrom:controller title:title options:options selectedIndex:selectedIndex onConfirm:^(NSInteger index) {
        if (onSelected && index >= 0 && index < (NSInteger)options.count) {
            onSelected(index, options[index]);
        }
    }];
}

+ (void)LZ_showOrderApplySuccessOn:(UIViewController *)controller onConfirm:(void (^)(void))onConfirm {
    NSString *message = @"Your application is under review. Once approved, the money will be credited to your bank account.";
    [self LZ_showFrame:LoanZen_PopupFrameSuccess
                    on:controller
                 title:@"Success"
               message:message
                actions:@[
        @{@"title": @"Confirm", @"style": @(LoanZen_ModalActionStylePrimary), @"handler": onConfirm ?: ^{}},
    ]];
}

+ (void)LZ_showTapToDismissMessage:(NSString *)message onView:(UIView *)view {
    if (message.length == 0 || !view) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        static NSInteger const kLZTipOverlayTag = 8822601;
        UIView *existing = [view viewWithTag:kLZTipOverlayTag];
        [existing removeFromSuperview];

        UIView *overlay = [[UIView alloc] initWithFrame:view.bounds];
        overlay.tag = kLZTipOverlayTag;
        overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.15];
        overlay.userInteractionEnabled = YES;

        UILabel *label = [[UILabel alloc] init];
        label.text = message;
        label.textColor = UIColor.whiteColor;
        label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.9];
        label.layer.cornerRadius = 12;
        label.clipsToBounds = YES;

        CGFloat maxWidth = MIN(CGRectGetWidth(view.bounds) - 64.0, 280.0);
        CGSize textSize = [label sizeThatFits:CGSizeMake(maxWidth - 40.0, CGFLOAT_MAX)];
        CGFloat bubbleW = MIN(maxWidth, MAX(200.0, textSize.width + 40.0));
        CGFloat bubbleH = MAX(50.0, textSize.height + 30.0);
        label.frame = CGRectMake((CGRectGetWidth(view.bounds) - bubbleW) * 0.5,
                                 (CGRectGetHeight(view.bounds) - bubbleH) * 0.5,
                                 bubbleW,
                                 bubbleH);
        label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin
            | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [overlay addSubview:label];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(LZ_dismissTipOverlay:)];
        [overlay addGestureRecognizer:tap];
        [view addSubview:overlay];
    });
}

+ (void)LZ_dismissTipOverlay:(UITapGestureRecognizer *)gesture {
    [gesture.view removeFromSuperview];
}

@end
