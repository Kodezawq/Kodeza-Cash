#import <UIKit/UIKit.h>
#import "LoanZen_ModalAction.h"

typedef NS_ENUM(NSInteger, LoanZen_PopupFrame) {
    LoanZen_PopupFrameConfirmReturn = 1,
    LoanZen_PopupFramePermission,
    LoanZen_PopupFrameError,
    LoanZen_PopupFrameTips,
    LoanZen_PopupFrameContacts,
    LoanZen_PopupFrameFailed,
    LoanZen_PopupFrameAttachment,
    LoanZen_PopupFrameSelect,
    LoanZen_PopupFrameError1,
    LoanZen_PopupFrameError2,
    LoanZen_PopupFrameError3,
    LoanZen_PopupFrameClose,
    LoanZen_PopupFrameDropdown,
    LoanZen_PopupFrameUpdate,
    LoanZen_PopupFrameSuccess,
    LoanZen_PopupFrameWithdraw,
    LoanZen_PopupFrameSignOut,
    LoanZen_PopupFrameDeleteAccount,
};

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_PopupHelper : NSObject

+ (nullable NSString *)LZ_iconNameForFrame:(LoanZen_PopupFrame)frame;
+ (void)LZ_showFrame:(LoanZen_PopupFrame)frame
                  on:(UIViewController *)controller
               title:(NSString *)title
             message:(nullable NSString *)message
             actions:(NSArray<NSDictionary *> *)actions;

+ (void)LZ_showFrame:(LoanZen_PopupFrame)frame
                  on:(UIViewController *)controller
               title:(NSString *)title
             message:(nullable NSString *)message
            iconName:(nullable NSString *)iconName
             actions:(NSArray<NSDictionary *> *)actions;

+ (void)LZ_showConfirmOn:(UIViewController *)controller
                   title:(NSString *)title
                 message:(nullable NSString *)message
            confirmTitle:(NSString *)confirmTitle
             cancelTitle:(nullable NSString *)cancelTitle
              onConfirm:(void (^)(void))onConfirm;

+ (void)LZ_showConfirmOn:(UIViewController *)controller
                   title:(NSString *)title
                 message:(nullable NSString *)message
            confirmTitle:(NSString *)confirmTitle
             cancelTitle:(nullable NSString *)cancelTitle
                iconName:(nullable NSString *)iconName
               onConfirm:(void (^)(void))onConfirm;

+ (void)LZ_showBottomPickerOn:(UIViewController *)controller
                        title:(NSString *)title
                      options:(NSArray<NSString *> *)options
                   onSelected:(void (^)(NSInteger index, NSString *value))onSelected;

+ (void)LZ_showBottomPickerOn:(UIViewController *)controller
                        title:(NSString *)title
                      options:(NSArray<NSString *> *)options
                selectedIndex:(NSInteger)selectedIndex
                   onSelected:(void (^)(NSInteger index, NSString *value))onSelected;

/// LoanBase/CMD 下单成功：Success + 审核文案 + Confirm
+ (void)LZ_showOrderApplySuccessOn:(UIViewController *)controller
                         onConfirm:(void (^ _Nullable)(void))onConfirm;

/// 感叹号提示：点击任意处消失，不自动延时关闭（对齐 Kiva showMessageThree）
+ (void)LZ_showTapToDismissMessage:(NSString *)message onView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
