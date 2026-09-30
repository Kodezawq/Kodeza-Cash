#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_ViewModel : NSObject

@property (nonatomic, copy, nullable) void (^onStateChanged)(void);
@property (nonatomic, copy, nullable) void (^onErrorMessage)(NSString *message);
@property (nonatomic, copy, nullable) void (^onSuccessMessage)(NSString *message);

- (void)LZ_notifyStateChanged;
- (void)LZ_notifyError:(NSString *)message;
- (void)LZ_notifySuccess:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
