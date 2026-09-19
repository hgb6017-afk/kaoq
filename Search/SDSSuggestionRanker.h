#import <Foundation/Foundation.h>
@class SDSSuggestion;
NS_ASSUME_NONNULL_BEGIN
@interface SDSSuggestionRanker : NSObject
+ (NSArray<SDSSuggestion *> *)rank:(NSArray<SDSSuggestion *> *)suggestions;
@end
NS_ASSUME_NONNULL_END
