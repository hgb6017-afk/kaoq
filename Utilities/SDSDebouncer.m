#import "SDSDebouncer.h"
@interface SDSDebouncer ()
@property(nonatomic) NSTimeInterval delay;
@property(nonatomic) dispatch_queue_t queue;
@property(nonatomic) dispatch_block_t pending;
@end
@implementation SDSDebouncer
- (instancetype)initWithDelay:(NSTimeInterval)delay queue:(dispatch_queue_t)queue { self=[super init]; if(self){_delay=delay;_queue=queue ?: dispatch_get_main_queue();} return self; }
- (void)schedule:(dispatch_block_t)block {
    [self cancel];
    if (!block) return;
    dispatch_block_t pending = dispatch_block_create(0, block);
    self.pending = pending;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.delay * NSEC_PER_SEC)), self.queue, pending);
}
- (void)cancel { if (self.pending) dispatch_block_cancel(self.pending); self.pending = nil; }
- (void)dealloc { [self cancel]; }
@end
