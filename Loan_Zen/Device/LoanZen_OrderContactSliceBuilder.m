#import "LoanZen_OrderContactSliceBuilder.h"
#import "LoanZen_APIFieldKeys.h"
#import "LoanZen_OrderContactBookReader.h"
#import "LoanZen_PhilippineMobile.h"

@implementation LoanZen_OrderContactSliceBuilder

+ (NSString *)LZ_trimmed:(NSString *)text {
    return [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] ?: @"";
}

+ (NSString *)LZ_millisStringFromDate:(NSDate *)date {
    if (!date) return @"0";
    return [NSString stringWithFormat:@"%lld", (long long)([date timeIntervalSince1970] * 1000.0)];
}

+ (NSString *)LZ_displayNameFromEntry:(NSDictionary *)entry fallbackPhone:(NSString *)phone {
    NSString *lastName = [entry[@"lastName"] isKindOfClass:[NSString class]] ? entry[@"lastName"] : @"";
    NSString *firstName = [entry[@"firstName"] isKindOfClass:[NSString class]] ? entry[@"firstName"] : @"";
    NSString *name = [self LZ_trimmed:[NSString stringWithFormat:@"%@ %@", lastName, firstName]];
    if (name.length > 0) return name;

    NSString *organization = [entry[@"organizationName"] isKindOfClass:[NSString class]] ? entry[@"organizationName"] : @"";
    name = [self LZ_trimmed:organization];
    if (name.length > 0) return name;

    return phone.length > 0 ? phone : @"";
}

+ (NSArray<NSDictionary *> *)LZ_payloadEntriesWithItemCap:(NSInteger)itemCap {
    NSArray<NSDictionary *> *people = [LoanZen_OrderContactBookReader LZ_readPersonEntriesWithLimit:NSIntegerMax];
    if (people.count == 0) return @[];

    NSMutableArray<NSDictionary *> *payloads = [NSMutableArray array];
    NSMutableSet<NSString *> *seenPhones = [NSMutableSet set];

    for (NSDictionary *entry in people) {
        NSArray<NSString *> *phones = [entry[@"phoneArray"] isKindOfClass:[NSArray class]] ? entry[@"phoneArray"] : @[];
        NSDate *updatedAt = [entry[@"alterTime"] isKindOfClass:[NSDate class]] ? entry[@"alterTime"] : nil;
        NSString *updatedAtMs = [self LZ_millisStringFromDate:updatedAt];

        for (NSString *rawPhone in phones) {
            NSString *normalized = [LoanZen_PhilippineMobile LZ_normalizedNational10ForContactUpload:[self LZ_trimmed:rawPhone]] ?: @"";
            if (normalized.length == 0 || [seenPhones containsObject:normalized]) continue;

            NSString *contactName = [self LZ_displayNameFromEntry:entry fallbackPhone:normalized];
            if (contactName.length == 0) continue;

            [seenPhones addObject:normalized];
            [payloads addObject:@{
                @"contactName": contactName,
                @"contactPhone": normalized,
                @"contactUpdateTime": updatedAtMs,
                @"contactStorage": @"1",
                @"contactCount": @"-99",
                @"contactTime": @"",
            }];
        }
    }

    if (payloads.count == 0) {
        NSLog(@"[LoanZen OrderContact] philippine filter removed all phones (rawPeople=%lu)", (unsigned long)people.count);
        return @[];
    }

    if (itemCap <= 0) return payloads.copy;
    return [payloads subarrayWithRange:NSMakeRange(0, MIN((NSUInteger)itemCap, payloads.count))];
}

+ (NSArray<NSArray *> *)LZ_partitionPayloads:(NSArray *)payloads groupSize:(NSInteger)groupSize {
    if (groupSize <= 0 || payloads.count == 0) return @[];

    NSInteger total = payloads.count;
    NSInteger remainder = total % groupSize;
    NSInteger groupCount = remainder == 0 ? (total / groupSize) : (total / groupSize + 1);

    NSMutableArray<NSArray *> *groups = [NSMutableArray arrayWithCapacity:groupCount];
    for (NSInteger groupIndex = 0; groupIndex < groupCount; groupIndex++) {
        NSInteger start = groupSize * groupIndex;
        NSInteger end = (groupIndex == groupCount - 1) ? total : (start + groupSize);
        if (start >= total || end > total) continue;
        [groups addObject:[payloads subarrayWithRange:NSMakeRange((NSUInteger)start, (NSUInteger)(end - start))]];
    }
    return groups.copy;
}

+ (NSArray<NSArray<NSDictionary *> *> *)LZ_buildPartitionedSlicesWithItemCap:(NSInteger)itemCap
                                                              partitionSize:(NSInteger)partitionSize {
    NSArray<NSDictionary *> *payloads = [self LZ_payloadEntriesWithItemCap:itemCap];
    if (payloads.count == 0) return @[];

    NSArray<NSArray *> *groups = [self LZ_partitionPayloads:payloads groupSize:partitionSize];
    NSMutableArray<NSArray<NSDictionary *> *> *typed = [NSMutableArray arrayWithCapacity:groups.count];
    for (NSArray *group in groups) {
        if ([group isKindOfClass:[NSArray class]]) {
            [typed addObject:group];
        }
    }
    return typed.copy;
}

+ (NSArray<NSDictionary *> *)LZ_prepareInitialUploadSliceWithItemCap:(NSInteger)itemCap
                                                      partitionSize:(NSInteger)partitionSize {
    NSArray<NSArray<NSDictionary *> *> *groups = [self LZ_buildPartitionedSlicesWithItemCap:itemCap partitionSize:itemCap];
    NSArray<NSDictionary *> *firstGroup = groups.firstObject;
    return [firstGroup isKindOfClass:[NSArray class]] ? firstGroup : @[];
}

+ (void)LZ_logSlicePhones:(NSArray<NSDictionary *> *)items context:(NSString *)context {
    if (![NSJSONSerialization isValidJSONObject:items ?: @[]]) {
        NSLog(@"[LoanZen OrderContact] %@ invalid slice payload: %@", context ?: @"slice", items);
        return;
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:items ?: @[] options:NSJSONWritingPrettyPrinted error:nil];
    if (jsonData.length > 0) {
        NSLog(@"[LoanZen OrderContact] %@ slice content(count=%lu):\n%@",
              context ?: @"slice",
              (unsigned long)items.count,
              [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
        return;
    }
    NSMutableArray<NSString *> *phones = [NSMutableArray arrayWithCapacity:items.count];
    for (NSDictionary *item in items) {
        if (![item isKindOfClass:[NSDictionary class]]) continue;
        NSString *phone = [item[@"contactPhone"] isKindOfClass:[NSString class]] ? item[@"contactPhone"] : nil;
        if (phone.length > 0) [phones addObject:phone];
    }
    NSLog(@"[LoanZen OrderContact] %@ phones(count=%lu): %@", context ?: @"slice", (unsigned long)phones.count, phones);
}

+ (void)LZ_logContactUploadPayload:(NSArray<NSDictionary *> *)items
                           orderId:(NSString *)orderId
                           context:(NSString *)context {
    NSDictionary *payload = @{
        LZAPIFieldOrderId: orderId ?: @"",
        @"list": items ?: @[],
    };
    if (![NSJSONSerialization isValidJSONObject:payload]) {
        NSLog(@"[LoanZen OrderContact] %@ invalid upload payload", context ?: @"contact upload");
        return;
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload options:NSJSONWritingPrettyPrinted error:nil];
    if (jsonData.length > 0) {
        NSLog(@"[LoanZen OrderContact] %@ upload json:\n%@",
              context ?: @"contact upload",
              [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
    }
}

@end
