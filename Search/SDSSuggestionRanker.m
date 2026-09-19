#import "SDSSuggestionRanker.h"
#import "../Models/SDSSuggestion.h"
@implementation SDSSuggestionRanker
+ (NSArray<SDSSuggestion *> *)rank:(NSArray<SDSSuggestion *> *)suggestions {
    return [suggestions sortedArrayUsingComparator:^NSComparisonResult(SDSSuggestion *a, SDSSuggestion *b) {
        if (a.matchType != b.matchType) return a.matchType > b.matchType ? NSOrderedAscending : NSOrderedDescending;
        if (a.inContacts != b.inContacts) return a.inContacts ? NSOrderedAscending : NSOrderedDescending;
        NSDate *ad = a.lastInteractionDate ?: [NSDate distantPast];
        NSDate *bd = b.lastInteractionDate ?: [NSDate distantPast];
        NSComparisonResult dateResult = [bd compare:ad];
        if (dateResult != NSOrderedSame) return dateResult;
        if (a.interactionCount != b.interactionCount) return a.interactionCount > b.interactionCount ? NSOrderedAscending : NSOrderedDescending;
        return [a.displayName localizedCaseInsensitiveCompare:b.displayName];
    }];
}
@end
