#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_FeedbackService : NSObject

+ (void)LZ_uploadImageData:(NSData *)imageData
               showLoading:(BOOL)showLoading
                completion:(void (^)(NSString * _Nullable src, NSError * _Nullable error))completion;

+ (void)LZ_submitProblemFeedbackWithDescription:(NSString *)description
                                     pictureUrl:(nullable NSString *)pictureUrl
                                    showLoading:(BOOL)showLoading
                                     completion:(void (^)(NSError * _Nullable error))completion;

+ (nullable NSData *)LZ_compressedJPEGDataFromImage:(UIImage *)image maxBytes:(NSUInteger)maxBytes;

@end

NS_ASSUME_NONNULL_END
