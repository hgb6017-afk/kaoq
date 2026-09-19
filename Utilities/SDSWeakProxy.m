#import "SDSWeakProxy.h"
@interface SDSWeakProxy ()
@property(nonatomic, weak, readwrite) id target;
@end
@implementation SDSWeakProxy
+ (instancetype)proxyWithTarget:(id)target { SDSWeakProxy *proxy=[SDSWeakProxy alloc]; proxy.target=target; return proxy; }
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel { return [self.target methodSignatureForSelector:sel] ?: [NSMethodSignature signatureWithObjCTypes:"v@:"]; }
- (void)forwardInvocation:(NSInvocation *)invocation { if ([self.target respondsToSelector:invocation.selector]) [invocation invokeWithTarget:self.target]; }
- (BOOL)respondsToSelector:(SEL)aSelector { return [self.target respondsToSelector:aSelector]; }
@end
