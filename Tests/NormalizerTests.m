#import <XCTest/XCTest.h>
#import "../Search/SDSPhoneNumberNormalizer.h"
#import "../Search/SDSVietnameseNormalizer.h"
@interface NormalizerTests : XCTestCase @end
@implementation NormalizerTests
- (void)testFormatting { XCTAssertEqualObjects([SDSPhoneNumberNormalizer normalizedDialableString:@"0912 345-678"], @"0912345678"); }
- (void)testVietnamEquivalent { XCTAssertEqualObjects([SDSVietnameseNormalizer identityKeyForNumber:@"0912 345 678" defaultRegion:@"VN"], [SDSVietnameseNormalizer identityKeyForNumber:@"+84 912 345 678" defaultRegion:@"VN"]); }
- (void)testUSSDPreserved { XCTAssertEqualObjects([SDSVietnameseNormalizer identityKeyForNumber:@"*101#" defaultRegion:@"VN"], @"*101#"); }
@end
