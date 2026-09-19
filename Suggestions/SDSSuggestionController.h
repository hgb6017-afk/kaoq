#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class SDSSearchIndex, SDSSuggestionView, SDSSuggestion;
NS_ASSUME_NONNULL_BEGIN
@interface SDSSuggestionController : NSObject
@property(nonatomic, strong, readonly) SDSSuggestionView *suggestionView;
@property(nonatomic, copy, nullable) void (^selectionHandler)(SDSSuggestion *suggestion);
- (instancetype)initWithSearchIndexProvider:(SDSSearchIndex * _Nonnull (^)(void))provider;
- (void)attachToHostView:(UIView *)hostView
               topAnchor:(NSLayoutYAxisAnchor *)topAnchor
            bottomAnchor:(NSLayoutYAxisAnchor *)bottomAnchor;
- (void)updateDialString:(NSString *)dialString useT9:(BOOL)useT9 maxResults:(NSUInteger)maxResults;
- (void)cancelPendingSearch;
- (void)detach;
@end
NS_ASSUME_NONNULL_END
