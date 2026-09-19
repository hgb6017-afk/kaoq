#import <Foundation/Foundation.h>
@class SDSRuntimeCapabilities;
NS_ASSUME_NONNULL_BEGIN
@interface SDSRuntimeInspector : NSObject
@property(nonatomic, strong, readonly) SDSRuntimeCapabilities *capabilities;
- (void)inspect;
@end
NS_ASSUME_NONNULL_END
