#import "SDSDialerInputObserver.h"
#import "SDSDialerBridge.h"
#import <UIKit/UIKit.h>

@interface SDSDialerInputObserver ()
@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic, strong) SDSDialerBridge *bridge;
@property(nonatomic, copy) void (^handler)(NSString *);
@property(nonatomic, copy) NSString *lastValue;
@end

@implementation SDSDialerInputObserver
- (BOOL)supported { return YES; }
- (BOOL)startForVerifiedHost:(id)host changeHandler:(void (^)(NSString *))handler {
    [self stop];
    if (![host isKindOfClass:UIView.class] || !handler) return NO;
    self.bridge = [[SDSDialerBridge alloc] init];
    if (![self.bridge attachToVerifiedHostObject:host]) return NO;
    self.handler = handler;
    self.timer = [NSTimer timerWithTimeInterval:0.18 target:self selector:@selector(tick:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    return YES;
}
- (void)tick:(NSTimer *)timer {
    NSString *value = [self.bridge currentDialString] ?: @"";
    if (![value isEqualToString:self.lastValue ?: @""]) { self.lastValue = value; if (self.handler) self.handler(value); }
}
- (void)stop { [self.timer invalidate]; self.timer = nil; [self.bridge detach]; self.bridge = nil; self.handler = nil; self.lastValue = nil; }
- (void)dealloc { [self stop]; }
@end
