#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SDSDiagnosticReporter : NSObject
+ (instancetype)sharedReporter;
- (void)start;
- (void)captureAndPersistWithReason:(NSString *)reason;
@end

NS_ASSUME_NONNULL_END
