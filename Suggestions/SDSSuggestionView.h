#import <UIKit/UIKit.h>
@class SDSSuggestion;
NS_ASSUME_NONNULL_BEGIN
@interface SDSSuggestionView : UIView
@property(nonatomic, copy, nullable) void (^selectionHandler)(SDSSuggestion *suggestion);
- (void)showSuggestions:(NSArray<SDSSuggestion *> *)suggestions;
- (void)hideSuggestions;
@end
NS_ASSUME_NONNULL_END
