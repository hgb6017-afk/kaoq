#import "SDSSuggestionMerger.h"
#import "../Models/SDSContactNumber.h"
#import "../Models/SDSCallHistoryEntry.h"
#import "../Models/SDSSuggestion.h"
#import "SDSPhoneNumberNormalizer.h"
#import "SDSVietnameseNormalizer.h"
#import "SDST9Normalizer.h"

@implementation SDSSuggestionMerger
+ (NSArray<SDSSuggestion *> *)mergeContacts:(NSArray<SDSContactNumber *> *)contacts
                                callHistory:(NSArray<SDSCallHistoryEntry *> *)history
                              defaultRegion:(NSString * _Nullable)region {
    NSMutableDictionary<NSString *, SDSSuggestion *> *map = [NSMutableDictionary dictionary];
    for (SDSContactNumber *contact in contacts ?: @[]) {
        NSString *key = [SDSVietnameseNormalizer identityKeyForNumber:contact.phoneNumber defaultRegion:region];
        if (!key.length) continue;
        SDSSuggestion *s = map[key] ?: [[SDSSuggestion alloc] init];
        s.identityKey = key;
        s.displayName = contact.displayName ?: @"";
        s.displayNumber = contact.phoneNumber ?: @"";
        s.normalizedNumber = [SDSPhoneNumberNormalizer normalizedDialableString:contact.phoneNumber];
        s.phoneLabel = contact.phoneLabel;
        s.t9Name = [SDST9Normalizer t9DigitsForName:s.displayName];
        s.inContacts = YES;
        map[key] = s;
    }
    for (SDSCallHistoryEntry *entry in history ?: @[]) {
        NSString *key = [SDSVietnameseNormalizer identityKeyForNumber:entry.phoneNumber defaultRegion:region];
        if (!key.length) continue;
        SDSSuggestion *s = map[key] ?: [[SDSSuggestion alloc] init];
        s.identityKey = key;
        if (!s.displayNumber.length) s.displayNumber = entry.phoneNumber ?: @"";
        if (!s.normalizedNumber.length) s.normalizedNumber = [SDSPhoneNumberNormalizer normalizedDialableString:entry.phoneNumber];
        if (!s.displayName.length) s.displayName = @"";
        s.inCallHistory = YES;
        if (!s.lastInteractionDate || [entry.lastInteractionDate compare:s.lastInteractionDate] == NSOrderedDescending) {
            s.lastInteractionDate = entry.lastInteractionDate;
            s.callKind = entry.callKind;
        }
        s.interactionCount += MAX((NSUInteger)1, entry.interactionCount);
        map[key] = s;
    }
    return map.allValues;
}
@end
