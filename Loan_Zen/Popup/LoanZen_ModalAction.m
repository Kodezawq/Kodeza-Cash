#import "LoanZen_ModalAction.h"

@implementation LoanZen_ModalAction

+ (instancetype)LZ_actionWithTitle:(NSString *)title style:(LoanZen_ModalActionStyle)style handler:(void (^)(void))handler {
    LoanZen_ModalAction *a = [[LoanZen_ModalAction alloc] init];
    a.title = title;
    a.style = style;
    a.handler = handler;
    return a;
}

@end
