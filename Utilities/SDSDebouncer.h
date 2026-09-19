#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface SDSDebouncer : NSObject
- (instancetype)initWithDelay:(NSTimeInterval)delay queue:(dispatch_queue_t)queue;
- (void)schedule:(dispatch_block_t)block;
- (void)cancel;
@end
NS_ASSUME_NONNULL_END
