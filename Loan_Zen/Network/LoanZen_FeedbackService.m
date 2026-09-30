#import "LoanZen_FeedbackService.h"
#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_HTTPClient.h"
#import "LoanZen_JSONParser.h"

@implementation LoanZen_FeedbackService

+ (void)LZ_uploadImageData:(NSData *)imageData
               showLoading:(BOOL)showLoading
                completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    [LoanZen_HTTPClient LZ_uploadMultipartWithPath:@"/app/v3/sys/upload"
                                          fileData:imageData
                                          fileName:@"image.jpg"
                                          mimeType:@"image/jpeg"
                                       showLoading:showLoading
                                        completion:^(NSDictionary *json, NSError *error) {
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        NSDictionary *data = [json[LZAPIResponseData] isKindOfClass:[NSDictionary class]] ? json[LZAPIResponseData] : nil;
        id rawSrc = data[LZAPIFieldSrc];
        NSString *src = nil;
        if ([rawSrc isKindOfClass:[NSString class]]) {
            src = [(NSString *)rawSrc stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        } else if (rawSrc && rawSrc != [NSNull null]) {
            src = [[rawSrc description] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        }
        if (src.length == 0) {
            if (completion) completion(nil, [NSError errorWithDomain:@"LoanZen_FeedbackService" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Upload response missing image URL."}]);
            return;
        }
        if (completion) completion(src, nil);
    }];
}

+ (void)LZ_submitProblemFeedbackWithDescription:(NSString *)description
                                     pictureUrl:(NSString *)pictureUrl
                                    showLoading:(BOOL)showLoading
                                     completion:(void (^)(NSError * _Nullable))completion {
    NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObject:description ?: @"" forKey:@"description"];
    if (pictureUrl.length > 0) data[@"pictureUrl"] = pictureUrl;
    [LoanZen_HTTPClient LZ_postWithPath:@"/app/v3/user/problemFeedback"
                             signParams:@{}
                             dataParams:data
                            showLoading:showLoading
                             completion:^(NSDictionary *json, NSError *error) {
        if (completion) completion(error);
    }];
}

+ (NSData *)LZ_compressedJPEGDataFromImage:(UIImage *)image maxBytes:(NSUInteger)maxBytes {
    if (!image) return nil;
    CGFloat quality = 0.9;
    NSData *data = UIImageJPEGRepresentation(image, quality);
    while (data.length > maxBytes && quality > 0.1) {
        quality -= 0.1;
        data = UIImageJPEGRepresentation(image, quality);
    }
    if (data.length <= maxBytes) return data;

    CGFloat scale = sqrt((CGFloat)maxBytes / (CGFloat)MAX(data.length, 1));
    CGSize newSize = CGSizeMake(MAX(image.size.width * scale, 1), MAX(image.size.height * scale, 1));
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *resized = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return UIImageJPEGRepresentation(resized, 0.8);
}

@end
