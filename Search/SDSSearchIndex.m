#import "SDSSearchIndex.h"
#import "../Models/SDSSuggestion.h"
#import "SDSPhoneNumberNormalizer.h"
#import "SDSVietnameseNormalizer.h"
#import "SDSSuggestionRanker.h"

@implementation SDSSearchIndex
- (instancetype)initWithRecords:(NSArray<SDSSuggestion *> *)records {
    self = [super init];
    if (self) _records = [[NSArray alloc] initWithArray:records copyItems:YES];
    return self;
}

- (NSArray<SDSSuggestion *> *)search:(NSString *)query
                           useT9:(BOOL)useT9
                            limit:(NSUInteger)limit
                    defaultRegion:(NSString * _Nullable)region {
    NSString *normalizedQuery = [SDSPhoneNumberNormalizer normalizedDialableString:query];
    if (!normalizedQuery.length) return @[];
    NSArray<NSString *> *queryKeys = [SDSVietnameseNormalizer searchKeysForNumber:normalizedQuery defaultRegion:region];
    NSString *digitQuery = [SDSPhoneNumberNormalizer digitsOnly:normalizedQuery];
    NSMutableArray<SDSSuggestion *> *matches = [NSMutableArray array];

    for (SDSSuggestion *record in self.records) {
        SDSSuggestion *candidate = [record copy];
        candidate.matchType = SDSMatchTypeNone;
        NSArray<NSString *> *recordKeys = [SDSVietnameseNormalizer searchKeysForNumber:record.displayNumber defaultRegion:region];
        for (NSString *q in queryKeys) {
            for (NSString *r in recordKeys) {
                if ([r isEqualToString:q]) candidate.matchType = MAX(candidate.matchType, SDSMatchTypeExact);
                else if ([r hasPrefix:q]) candidate.matchType = MAX(candidate.matchType, SDSMatchTypePrefix);
                else if ([r containsString:q]) candidate.matchType = MAX(candidate.matchType, SDSMatchTypeSubstring);
            }
        }
        if (candidate.matchType == SDSMatchTypeNone && useT9 && digitQuery.length && [record.t9Name hasPrefix:digitQuery]) {
            candidate.matchType = SDSMatchTypeT9Name;
        }
        if (candidate.matchType != SDSMatchTypeNone) [matches addObject:candidate];
    }

    NSArray *ranked = [SDSSuggestionRanker rank:matches];
    if (limit == 0 || ranked.count <= limit) return ranked;
    return [ranked subarrayWithRange:NSMakeRange(0, limit)];
}
@end
