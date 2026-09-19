#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SDSLogCategory) {
    SDSLogCategoryLifecycle,
    SDSLogCategoryHook,
    SDSLogCategoryKeypad,
    SDSLogCategoryContacts,
    SDSLogCategoryCallHistory,
    SDSLogCategorySearch,
    SDSLogCategorySuggestions,
    SDSLogCategorySIM,
    SDSLogCategoryPreferences,
    SDSLogCategoryError,
};
FOUNDATION_EXPORT NSString *SDSMaskPhoneLikeText(NSString *text);
FOUNDATION_EXPORT void SDSLogMessage(SDSLogCategory category, BOOL error, NSString *format, ...) NS_FORMAT_FUNCTION(3,4);
#define SDSLogInfo(category, format, ...) SDSLogMessage((category), NO, (format), ##__VA_ARGS__)
#define SDSLogError(category, format, ...) SDSLogMessage((category), YES, (format), ##__VA_ARGS__)
NS_ASSUME_NONNULL_END
