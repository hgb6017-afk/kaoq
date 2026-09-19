#import "SDST9Normalizer.h"
@implementation SDST9Normalizer
+ (NSString *)foldedName:(NSString *)name {
    NSString *s = [name ?: @"" stringByReplacingOccurrencesOfString:@"Đ" withString:@"D"];
    s = [s stringByReplacingOccurrencesOfString:@"đ" withString:@"d"];
    s = [s stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:[NSLocale localeWithLocaleIdentifier:@"vi_VN"]];
    return [s uppercaseString];
}
+ (NSString *)t9DigitsForName:(NSString *)name {
    NSString *folded = [self foldedName:name];
    NSDictionary<NSString *, NSString *> *map = @{
        @"A":@"2", @"B":@"2", @"C":@"2",
        @"D":@"3", @"E":@"3", @"F":@"3",
        @"G":@"4", @"H":@"4", @"I":@"4",
        @"J":@"5", @"K":@"5", @"L":@"5",
        @"M":@"6", @"N":@"6", @"O":@"6",
        @"P":@"7", @"Q":@"7", @"R":@"7", @"S":@"7",
        @"T":@"8", @"U":@"8", @"V":@"8",
        @"W":@"9", @"X":@"9", @"Y":@"9", @"Z":@"9"
    };
    NSMutableString *out = [NSMutableString string];
    for (NSUInteger i=0; i<folded.length; i++) {
        NSString *ch = [folded substringWithRange:NSMakeRange(i, 1)];
        NSString *digit = map[ch];
        if (digit) [out appendString:digit];
    }
    return out;
}
@end
