#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface SDSWeakProxy : NSProxy
@property(nonatomic, weak, readonly) id target;
+ (instancetype)proxyWithTarget:(id)target;
@end
NS_ASSUME_NONNULL_END
