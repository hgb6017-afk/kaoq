#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SDSAdaptivePhoneIntegration : NSObject
+ (instancetype)sharedIntegration;
- (void)start;
- (void)stop;
@end

NS_ASSUME_NONNULL_END
