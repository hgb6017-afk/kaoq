#import "SDSVietnameseNormalizer.h"
#import "SDSPhoneNumberNormalizer.h"

@implementation SDSVietnameseNormalizer
+ (BOOL)looksLikeVietnamNationalNumberDigits:(NSString *)digits {
    // Deliberately conservative: excludes short codes and only canonicalizes
    // plausible national-length numbers. This can be extended after product tests.
    return digits.length >= 9 && digits.length <= 11;
}

+ (NSString *)identityKeyForNumber:(NSString *)input defaultRegion:(NSString * _Nullable)region {
    NSString *normalized = [SDSPhoneNumberNormalizer normalizedDialableString:input];
    if (normalized.length == 0) return @"";
    if ([SDSPhoneNumberNormalizer isUSSDOrServiceCode:normalized] ||
        [SDSPhoneNumberNormalizer isShortOrEmergencyLike:normalized]) return normalized;

    BOOL useVN = region.length == 0 || [[region uppercaseString] isEqualToString:@"VN"];
    if (!useVN) return normalized;

    NSString *digits = [SDSPhoneNumberNormalizer digitsOnly:normalized];
    if ([normalized hasPrefix:@"+84"]) {
        NSString *national = digits.length > 2 ? [digits substringFromIndex:2] : @"";
        if ([self looksLikeVietnamNationalNumberDigits:national]) return [@"+84" stringByAppendingString:national];
    }
    if ([digits hasPrefix:@"84"] && digits.length > 2) {
        NSString *national = [digits substringFromIndex:2];
        if ([self looksLikeVietnamNationalNumberDigits:national]) return [@"+84" stringByAppendingString:national];
    }
    if ([digits hasPrefix:@"0"] && digits.length > 1) {
        NSString *national = [digits substringFromIndex:1];
        if ([self looksLikeVietnamNationalNumberDigits:national]) return [@"+84" stringByAppendingString:national];
    }
    return normalized;
}

+ (NSArray<NSString *> *)searchKeysForNumber:(NSString *)input defaultRegion:(NSString * _Nullable)region {
    NSString *normalized = [SDSPhoneNumberNormalizer normalizedDialableString:input];
    NSString *digits = [SDSPhoneNumberNormalizer digitsOnly:input];
    NSString *identity = [self identityKeyForNumber:input defaultRegion:region];
    NSMutableOrderedSet<NSString *> *keys = [NSMutableOrderedSet orderedSet];
    if (normalized.length) [keys addObject:normalized];
    if (digits.length) [keys addObject:digits];
    if (identity.length) [keys addObject:identity];
    if ([identity hasPrefix:@"+84"] && identity.length > 3) {
        NSString *national = [identity substringFromIndex:3];
        [keys addObject:[@"0" stringByAppendingString:national]];
        [keys addObject:[@"84" stringByAppendingString:national]];
        [keys addObject:national];
    }
    return keys.array;
}
@end
