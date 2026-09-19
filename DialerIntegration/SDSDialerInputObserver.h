#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface SDSDialerInputObserver : NSObject
@property(nonatomic, readonly) BOOL supported;
- (BOOL)startForVerifiedHost:(id)host changeHandler:(void (^)(NSString *dialString))handler;
- (void)stop;
@end
NS_ASSUME_NONNULL_END
