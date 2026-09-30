#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 下单通讯录：菲律宾号规范化、去重、分组切片，生成 `/mobile/contact` 上传 payload。
@interface LoanZen_OrderContactSliceBuilder : NSObject

/// 读取通讯录并生成首包上传切片（itemCap 为总上限，partitionSize 为分组粒度，首包取第一组）。
+ (NSArray<NSDictionary *> *)LZ_prepareInitialUploadSliceWithItemCap:(NSInteger)itemCap
                                                      partitionSize:(NSInteger)partitionSize;

+ (NSArray<NSArray<NSDictionary *> *> *)LZ_buildPartitionedSlicesWithItemCap:(NSInteger)itemCap
                                                              partitionSize:(NSInteger)partitionSize;

+ (void)LZ_logSlicePhones:(NSArray<NSDictionary *> *)items context:(NSString *)context;

+ (void)LZ_logContactUploadPayload:(NSArray<NSDictionary *> *)items
                           orderId:(NSString *)orderId
                           context:(NSString *)context;

@end

NS_ASSUME_NONNULL_END
