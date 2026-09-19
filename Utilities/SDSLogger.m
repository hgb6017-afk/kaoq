#import "SDSLogger.h"
#import <stdarg.h>
static NSString *SDSCategoryName(SDSLogCategory c) {
    switch (c) {
        case SDSLogCategoryLifecycle: return @"Lifecycle"; case SDSLogCategoryHook: return @"Hook";
        case SDSLogCategoryKeypad: return @"Keypad"; case SDSLogCategoryContacts: return @"Contacts";
        case SDSLogCategoryCallHistory: return @"CallHistory"; case SDSLogCategorySearch: return @"Search";
        case SDSLogCategorySuggestions: return @"Suggestions"; case SDSLogCategorySIM: return @"SIM";
        case SDSLogCategoryPreferences: return @"Preferences"; case SDSLogCategoryError: return @"Errors";
    }
    return @"Unknown";
}
NSString *SDSMaskPhoneLikeText(NSString *text) {
    if (!text.length) return text ?: @"";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\+?\\d[\\d\\s().-]{3,}\\d" options:0 error:nil];
    NSMutableString *out = [text mutableCopy];
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    for (NSTextCheckingResult *match in matches.reverseObjectEnumerator) {
        NSString *raw = [text substringWithRange:match.range];
        NSString *digits = [[raw componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
        NSString *tail = digits.length >= 2 ? [digits substringFromIndex:digits.length - 2] : @"**";
        NSString *masked = [raw hasPrefix:@"+"] ? [@"+***" stringByAppendingString:tail] : [@"***" stringByAppendingString:tail];
        [out replaceCharactersInRange:match.range withString:masked];
    }
    return out;
}
void SDSLogMessage(SDSLogCategory category, BOOL error, NSString *format, ...) {
    va_list args; va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
#if DEBUG
    NSLog(@"[SmartDialSIM][%@]%@ %@", SDSCategoryName(category), error ? @"[ERROR]" : @"", SDSMaskPhoneLikeText(message));
#else
    if (error) NSLog(@"[SmartDialSIM][%@][ERROR] %@", SDSCategoryName(category), SDSMaskPhoneLikeText(message));
#endif
}
