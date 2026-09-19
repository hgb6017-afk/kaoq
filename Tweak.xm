#import <Foundation/Foundation.h>
#import "Config/SDSPreferences.h"
#import "Runtime/SDSRuntimeInspector.h"
#import "Runtime/SDSRuntimeCapabilities.h"
#import "Runtime/SDSRuntimeVersion.h"
#import "Runtime/SDSDiagnosticReporter.h"
#import "DialerIntegration/SDSAdaptivePhoneIntegration.h"
#import "Utilities/SDSLogger.h"

static SDSPreferences *gPreferences = nil;
static SDSRuntimeInspector *gRuntimeInspector = nil;

%ctor {
    @autoreleasepool {
        gPreferences = [SDSPreferences sharedPreferences];
        [gPreferences startObserving];

        gRuntimeInspector = [[SDSRuntimeInspector alloc] init];
        [gRuntimeInspector inspect];

        SDSRuntimeVersion *version = gRuntimeInspector.capabilities.runtimeVersion;
        if (!version.isSupportedTargetOS) {
            SDSLogInfo(SDSLogCategoryLifecycle,
                       @"SmartDialSIM G6 loaded but OS is outside supported target scope (iOS 15.x / iOS 16.2); leaving Phone untouched");
            return;
        }

        // G6 keeps the privacy-masked diagnostic reporter enabled so one real-device test can
        // validate both functionality and the adaptive runtime decisions without a second diagnostic build.
        [[SDSDiagnosticReporter sharedReporter] start];
        [[SDSAdaptivePhoneIntegration sharedIntegration] start];

        SDSLogInfo(SDSLogCategoryLifecycle,
                   @"SmartDialSIM G6.1 audit-fixed candidate active for %@", version.familyName);
    }
}
