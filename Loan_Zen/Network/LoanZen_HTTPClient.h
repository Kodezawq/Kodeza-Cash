#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_HTTPClient : NSObject

+ (void)LZ_postWithPath:(NSString *)path
             dataParams:(NSDictionary<NSString *, id> *)dataParams
             showLoading:(BOOL)showLoading
             completion:(void (^)(NSDictionary * _Nullable json, NSError * _Nullable error))completion;

/// signParams 与 dataParams 分离（orderId 签名 + 含 list 等复杂 data）
+ (void)LZ_postWithPath:(NSString *)path
             signParams:(NSDictionary<NSString *, id> *)signParams
             dataParams:(NSDictionary<NSString *, id> *)dataParams
            showLoading:(BOOL)showLoading
             completion:(void (^)(NSDictionary * _Nullable json, NSError * _Nullable error))completion;

/// multipart 上传（如 `/app/v3/sys/upload`），signParams 为空时 data 也为空
+ (void)LZ_uploadMultipartWithPath:(NSString *)path
                          fileData:(NSData *)fileData
                          fileName:(NSString *)fileName
                          mimeType:(NSString *)mimeType
                       showLoading:(BOOL)showLoading
                        completion:(void (^)(NSDictionary * _Nullable json, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
