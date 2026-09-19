#import <XCTest/XCTest.h>
#import "../Search/SDSSuggestionRanker.h"
#import "../Models/SDSSuggestion.h"
@interface RankingTests : XCTestCase @end
@implementation RankingTests
- (void)testExactBeatsPrefix {
    SDSSuggestion *a=[SDSSuggestion new]; a.matchType=SDSMatchTypePrefix;
    SDSSuggestion *b=[SDSSuggestion new]; b.matchType=SDSMatchTypeExact;
    NSArray *r=[SDSSuggestionRanker rank:@[a,b]];
    XCTAssertEqualObjects(r.firstObject, b);
}
@end
