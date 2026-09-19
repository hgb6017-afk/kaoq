#import <XCTest/XCTest.h>
#import "../Search/SDSSuggestionMerger.h"
#import "../Models/SDSContactNumber.h"
#import "../Models/SDSCallHistoryEntry.h"
@interface MergeTests : XCTestCase @end
@implementation MergeTests
- (void)testContactHistoryDedup {
    SDSContactNumber *c=[[SDSContactNumber alloc] initWithName:@"A" number:@"0912 345 678" label:@"mobile"];
    SDSCallHistoryEntry *h=[[SDSCallHistoryEntry alloc] initWithNumber:@"+84 912 345 678" date:[NSDate date] count:2 kind:@"recent"];
    NSArray *m=[SDSSuggestionMerger mergeContacts:@[c] callHistory:@[h] defaultRegion:@"VN"];
    XCTAssertEqual(m.count, 1u);
}
@end
