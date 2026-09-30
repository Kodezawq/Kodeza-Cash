#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 下单通讯录上传：AddressBook 批量读取（与 KYC 选人无关）。
@interface LoanZen_OrderContactBookReader : NSObject

+ (NSArray<NSDictionary *> *)LZ_readPersonEntriesWithLimit:(NSInteger)limit;

@end

NS_ASSUME_NONNULL_END
