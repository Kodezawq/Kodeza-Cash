#import "LoanZen_OrderContactBookReader.h"
#import <AddressBook/AddressBook.h>

@implementation LoanZen_OrderContactBookReader

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

+ (NSArray<NSDictionary *> *)LZ_readPersonEntriesWithLimit:(NSInteger)limit {
    NSMutableArray<NSDictionary *> *entries = [NSMutableArray array];

    ABAddressBookRef bookRef = ABAddressBookCreate();
    if (!bookRef) return @[];

    CFArrayRef peopleRef = ABAddressBookCopyArrayOfAllPeople(bookRef);
    if (!peopleRef) {
        CFRelease(bookRef);
        return @[];
    }

    CFIndex peopleCount = CFArrayGetCount(peopleRef);
    for (CFIndex index = 0; index < peopleCount; index++) {
        ABRecordRef person = CFArrayGetValueAtIndex(peopleRef, index);
        NSMutableDictionary *entry = [NSMutableDictionary dictionary];

        entry[@"firstName"] = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty) ?: @"";
        entry[@"lastName"] = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty) ?: @"";

        NSMutableArray<NSString *> *phones = [NSMutableArray array];
        ABMultiValueRef phonesRef = ABRecordCopyValue(person, kABPersonPhoneProperty);
        if (phonesRef) {
            CFIndex phoneCount = ABMultiValueGetCount(phonesRef);
            for (CFIndex phoneIndex = 0; phoneIndex < phoneCount; phoneIndex++) {
                CFStringRef phoneRef = ABMultiValueCopyValueAtIndex(phonesRef, phoneIndex);
                if (!phoneRef) continue;
                [phones addObject:(__bridge_transfer NSString *)phoneRef];
            }
            CFRelease(phonesRef);
        }
        entry[@"phoneArray"] = phones.copy;
        entry[@"creatTime"] = (__bridge_transfer NSDate *)ABRecordCopyValue(person, kABPersonCreationDateProperty);
        entry[@"alterTime"] = (__bridge_transfer NSDate *)ABRecordCopyValue(person, kABPersonModificationDateProperty);

        [entries addObject:entry.copy];
        if (limit > 0 && entries.count == (NSUInteger)limit) {
            break;
        }
    }

    CFRelease(peopleRef);
    CFRelease(bookRef);
    return entries.copy;
}

#pragma clang diagnostic pop

@end
