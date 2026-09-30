#import "LoanZen_ImageCompression.h"

@implementation LoanZen_ImageCompression

+ (UIImage *)LZ_imageRotatedMinus90:(UIImage *)image {
    if (!image) return nil;
    CGSize size = image.size;
    CGSize rotatedSize = CGSizeMake(size.height, size.width);
    UIGraphicsBeginImageContextWithOptions(rotatedSize, NO, image.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        UIGraphicsEndImageContext();
        return image;
    }
    CGContextTranslateCTM(context, rotatedSize.width / 2.0, rotatedSize.height / 2.0);
    CGContextRotateCTM(context, -M_PI_2);
    CGContextTranslateCTM(context, -size.width / 2.0, -size.height / 2.0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *rotated = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return rotated ?: image;
}

/// 等比缩放，保持宽高比，避免拉伸失真。
+ (UIImage *)LZ_imageByScaling:(UIImage *)image toMaxPixelSide:(CGFloat)maxSide {
    if (!image || maxSide <= 0) return image;
    CGFloat w = image.size.width;
    CGFloat h = image.size.height;
    if (w <= 0 || h <= 0) return image;
    CGFloat longSide = MAX(w, h);
    if (longSide <= maxSide) return image;
    CGFloat scale = maxSide / longSide;
    CGSize target = CGSizeMake(floor(w * scale), floor(h * scale));
    if (target.width < 1 || target.height < 1) return image;
    UIGraphicsBeginImageContextWithOptions(target, NO, 1.0);
    [image drawInRect:CGRectMake(0, 0, target.width, target.height)];
    UIImage *scaled = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaled ?: image;
}

+ (NSString *)LZ_jpegBase64FromImage:(UIImage *)image quality:(CGFloat)quality maxBytes:(NSUInteger)maxBytes {
    if (!image || maxBytes == 0) return nil;

    // 优先保画质：高 JPEG 质量 + 等比缩小尺寸，避免靠大幅降质导致糊/失真。
    CGFloat q = MAX(0.72, MIN(quality > 0 ? quality : 0.92, 0.95));
    UIImage *working = image;
    NSData *data = UIImageJPEGRepresentation(working, q);

    // 长边从原图逐步缩小（保持比例），直到 ≤ maxBytes 或缩到合理下限。
    CGFloat longSide = MAX(working.size.width * working.scale, working.size.height * working.scale);
    if (longSide <= 0) longSide = MAX(working.size.width, working.size.height);
    NSInteger guard = 0;
    while (data.length > maxBytes && longSide > 720 && guard < 10) {
        longSide *= 0.85;
        working = [self LZ_imageByScaling:image toMaxPixelSide:longSide];
        data = UIImageJPEGRepresentation(working, q);
        guard += 1;
    }

    // 仍超限时轻微降质，不低于 0.72，避免明显失真。
    while (data.length > maxBytes && q > 0.72) {
        q -= 0.04;
        data = UIImageJPEGRepresentation(working, q);
    }

    // 极端情况下再缩一轮尺寸（仍等比）。
    guard = 0;
    while (data.length > maxBytes && longSide > 480 && guard < 6) {
        longSide *= 0.8;
        working = [self LZ_imageByScaling:image toMaxPixelSide:longSide];
        data = UIImageJPEGRepresentation(working, q);
        guard += 1;
    }

    return data.length > 0 ? [data base64EncodedStringWithOptions:0] : nil;
}

@end
