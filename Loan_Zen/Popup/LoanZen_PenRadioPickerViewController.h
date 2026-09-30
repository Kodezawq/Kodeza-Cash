#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_PenRadioPickerViewController : UIViewController

+ (void)LZ_presentFrom:(UIViewController *)host
                 title:(NSString *)title
               options:(NSArray<NSString *> *)options
         selectedIndex:(NSInteger)selectedIndex
             onConfirm:(void (^)(NSInteger index))onConfirm;

@end

NS_ASSUME_NONNULL_END
