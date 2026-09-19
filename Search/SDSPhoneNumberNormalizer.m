#import "SDSPhoneNumberNormalizer.h"
@implementation SDSPhoneNumberNormalizer
+ (NSString *)normalizedDialableString:(NSString *)input {
    if (![input isKindOfClass:[NSString class]] || input.length == 0) return @"";
    NSMutableString *out = [NSMutableString string];
    NSCharacterSet *digits = [NSCharacterSet decimalDigitCharacterSet];
    for (NSUInteger i = 0; i < input.length; i++) {
        unichar c = [input characterAtIndex:i];
        if ([digits characterIsMember:c]) {
            [out appendFormat:@"%C", c];
        } else if (c == '+' && out.length == 0) {
            [out appendString:@"+"];
        } else if (c == '*' || c == '#') {
            [out appendFormat:@"%C", c];
        }
    }
    return out;
}

+ (NSString *)digitsOnly:(NSString *)input {
    NSMutableString *out = [NSMutableString string];
    NSCharacterSet *digits = [NSCharacterSet decimalDigitCharacterSet];
    for (NSUInteger i = 0; i < input.length; i++) {
        unichar c = [input characterAtIndex:i];
        if ([digits characterIsMember:c]) [out appendFormat:@"%C", c];
    }
    return out;
}

+ (BOOL)isUSSDOrServiceCode:(NSString *)input {
    NSString *n = [self normalizedDialableString:input];
    return [n containsString:@"*"] || [n containsString:@"#"];
}

+ (BOOL)isShortOrEmergencyLike:(NSString *)input {
    NSString *digits = [self digitsOnly:input];
    return digits.length > 0 && digits.length <= 5;
}
@end
