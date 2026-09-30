#import <Foundation/Foundation.h>
#import "LoanZen_JSONParser.h"

NS_ASSUME_NONNULL_BEGIN

@interface LoanZen_LoginResult : NSObject <LoanZen_JSONMappable>

@property (nonatomic, copy, readonly) NSString *token;
@property (nonatomic, copy, readonly, nullable) NSString *userId;
@property (nonatomic, copy, readonly, nullable) NSString *mobile;

@end

NS_ASSUME_NONNULL_END
