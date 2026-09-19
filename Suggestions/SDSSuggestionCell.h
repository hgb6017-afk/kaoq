#import <UIKit/UIKit.h>
@class SDSSuggestion;
NS_ASSUME_NONNULL_BEGIN
@interface SDSSuggestionCell : UITableViewCell
- (void)configureWithSuggestion:(SDSSuggestion *)suggestion;
@end
NS_ASSUME_NONNULL_END
