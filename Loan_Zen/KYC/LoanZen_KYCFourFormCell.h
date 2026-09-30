#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const LZ_KYCFourFormTextCellId;
FOUNDATION_EXPORT NSString * const LZ_KYCFourFormSelectCellId;

@interface LoanZen_KYCFourFormTextCell : UITableViewCell
@property (nonatomic, strong, readonly) UITextField *inputField;
- (void)LZ_configureWithTitle:(NSString *)title
                  placeholder:(NSString *)placeholder
                         text:(nullable NSString *)text
                     isFirstRow:(BOOL)isFirstRow
                      isLastRow:(BOOL)isLastRow;
@end

@interface LoanZen_KYCFourFormSelectCell : UITableViewCell
@property (nonatomic, copy, nullable) void (^onTapChoose)(void);
- (void)LZ_configureWithTitle:(NSString *)title
                  displayTitle:(NSString *)displayTitle
                     isFirstRow:(BOOL)isFirstRow
                      isLastRow:(BOOL)isLastRow;
- (void)LZ_updateDisplayTitle:(NSString *)displayTitle;
@end

NS_ASSUME_NONNULL_END
