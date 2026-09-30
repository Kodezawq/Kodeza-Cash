#import <UIKit/UIKit.h>
#import "LoanZen_ModalAction.h"

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_ModalCardViewController : UIViewController

@property (nonatomic, copy) NSString *modalTitle;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy, nullable) NSString *iconName;
@property (nonatomic, copy) NSArray<LoanZen_ModalAction *> *actions;
@property (nonatomic, assign) BOOL allowsDimTapDismiss;
@property (nonatomic, assign) BOOL centersHeaderContent;
@property (nonatomic, assign) CGFloat buttonHeight;
@property (nonatomic, assign) CGFloat buttonCornerRadius;
@property (nonatomic, assign) CGFloat contentCornerRadius;

+ (instancetype)LZ_presentFrom:(UIViewController *)host
                         title:(NSString *)title
                       message:(nullable NSString *)message
                       actions:(NSArray<LoanZen_ModalAction *> *)actions;

+ (instancetype)LZ_presentFrom:(UIViewController *)host
                         title:(NSString *)title
                       message:(nullable NSString *)message
                      iconName:(nullable NSString *)iconName
                       actions:(NSArray<LoanZen_ModalAction *> *)actions;

+ (instancetype)LZ_presentFrom:(UIViewController *)host
                         title:(NSString *)title
                       message:(nullable NSString *)message
                      iconName:(nullable NSString *)iconName
                       actions:(NSArray<LoanZen_ModalAction *> *)actions
                  buttonHeight:(CGFloat)buttonHeight
            buttonCornerRadius:(CGFloat)buttonCornerRadius
           contentCornerRadius:(CGFloat)contentCornerRadius;

@end

NS_ASSUME_NONNULL_END
