#import <XCTest/XCTest.h>
#import "../SIMCustomization/SDSSIMLabelProvider.h"
@interface PreferenceTests : XCTestCase @end
@implementation PreferenceTests
- (void)testSIMFallback { XCTAssertEqualObjects([SDSSIMLabelProvider sanitizedLabel:@"   " fallback:@"SIM 1"], @"SIM 1"); }
@end
