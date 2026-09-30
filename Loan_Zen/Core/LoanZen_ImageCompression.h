#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_ImageCompression : NSObject
/// JPEG Base64；优先等比缩小尺寸，质量不低于约 0.72，避免拉伸/过度降质失真。
+ (nullable NSString *)LZ_jpegBase64FromImage:(UIImage *)image quality:(CGFloat)quality maxBytes:(NSUInteger)maxBytes;
/// 横拍证件图提交前逆时针旋转 90°，用于 KYC 竖屏回显与上传。
+ (nullable UIImage *)LZ_imageRotatedMinus90:(UIImage *)image;
@end

NS_ASSUME_NONNULL_END
