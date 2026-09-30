#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, LoanZen_ModalActionStyle) {
    LoanZen_ModalActionStylePrimary = 0,
    LoanZen_ModalActionStyleSecondary,
    LoanZen_ModalActionStyleCancel,
    LoanZen_ModalActionStyleDestructive,
};

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_ModalAction : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) LoanZen_ModalActionStyle style;
@property (nonatomic, copy, nullable) void (^handler)(void);
+ (instancetype)LZ_actionWithTitle:(NSString *)title style:(LoanZen_ModalActionStyle)style handler:(void (^ _Nullable)(void))handler;
@end

NS_ASSUME_NONNULL_END
