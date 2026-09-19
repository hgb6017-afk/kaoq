#import "SDSSIMLabelProvider.h"
#import "../Config/SDSConstants.h"
@implementation SDSSIMLabelProvider
+ (NSString *)sanitizedLabel:(NSString * _Nullable)input fallback:(NSString *)fallback {
    NSString *s = [[input ?: @"" stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] copy];
    if (!s.length) s = fallback;
    if (s.length > SDSMaximumSIMLabelLength) {
        NSUInteger cut = SDSMaximumSIMLabelLength;
        NSRange sequence = [s rangeOfComposedCharacterSequenceAtIndex:cut - 1];
        if (NSMaxRange(sequence) > cut) cut = sequence.location;
        if (cut == 0) cut = MIN(s.length, SDSMaximumSIMLabelLength);
        s = [s substringToIndex:cut];
    }
    return s;
}
+ (NSString *)labelForLogicalIndex:(NSUInteger)index customSIM1:(NSString * _Nullable)sim1 customSIM2:(NSString * _Nullable)sim2 {
    if (index == 0) return [self sanitizedLabel:sim1 fallback:@"SIM 1"];
    if (index == 1) return [self sanitizedLabel:sim2 fallback:@"SIM 2"];
    return [NSString stringWithFormat:@"SIM %lu", (unsigned long)(index + 1)];
}
@end
