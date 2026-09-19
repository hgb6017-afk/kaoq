#import <Foundation/Foundation.h>
#import "SDSRuntimeVersion.h"

NS_ASSUME_NONNULL_BEGIN
@interface SDSRuntimeCapabilities : NSObject
@property(nonatomic, strong) SDSRuntimeVersion *runtimeVersion;
@property(nonatomic) BOOL verifiedTargetProcess;
@property(nonatomic) BOOL keypadHostAvailable;
@property(nonatomic) BOOL dialStringObserverAvailable;
@property(nonatomic) BOOL nativeNumberSetterAvailable;
@property(nonatomic) BOOL callHistoryAvailable;
@property(nonatomic) BOOL simSelectorAvailable;
@property(nonatomic, copy) NSString *targetSummary;
@property(nonatomic, copy) NSString *privateIntegrationState;
@end
NS_ASSUME_NONNULL_END
