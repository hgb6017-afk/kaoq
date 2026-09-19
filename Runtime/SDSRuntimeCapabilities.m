#import "SDSRuntimeCapabilities.h"
@implementation SDSRuntimeCapabilities
- (instancetype)init {
    self = [super init];
    if (self) {
        _runtimeVersion = [SDSRuntimeVersion currentVersion];
        _targetSummary = @"Apple Phone adaptive UI/runtime integration";
        _privateIntegrationState = @"G6_ADAPTIVE_RUNTIME_DISCOVERY";
    }
    return self;
}
@end
