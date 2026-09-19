#import <XCTest/XCTest.h>
#import "../Search/SDST9Normalizer.h"
@interface T9Tests : XCTestCase @end
@implementation T9Tests
- (void)testVietnameseDiacritics { XCTAssertEqualObjects([SDST9Normalizer t9DigitsForName:@"Đặng"], @"3264"); }
@end
