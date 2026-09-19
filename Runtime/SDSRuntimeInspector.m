#import "SDSRuntimeInspector.h"
#import "SDSRuntimeCapabilities.h"
#import "../Utilities/SDSLogger.h"

@interface SDSRuntimeInspector ()
@property(nonatomic, strong, readwrite) SDSRuntimeCapabilities *capabilities;
@end

@implementation SDSRuntimeInspector

- (instancetype)init {
    self = [super init];
    if (self) _capabilities = [[SDSRuntimeCapabilities alloc] init];
    return self;
}

- (void)inspect {
    NSBundle *bundle = NSBundle.mainBundle;
    NSString *bundleID = bundle.bundleIdentifier ?: @"<nil>";
    NSString *executable = bundle.executablePath.lastPathComponent ?: @"<nil>";
    SDSRuntimeVersion *version = self.capabilities.runtimeVersion;
    NSOperatingSystemVersion v = version.operatingSystemVersion;

    BOOL isPhone = [bundleID isEqualToString:@"com.apple.mobilephone"];
    self.capabilities.verifiedTargetProcess = isPhone;
    // Eligibility is not the same as a discovered capability. These remain NO until a
    // concrete runtime boundary is found by the adaptive modules; do not report guesses as facts.
    self.capabilities.keypadHostAvailable = NO;
    self.capabilities.dialStringObserverAvailable = NO;
    self.capabilities.nativeNumberSetterAvailable = NO;
    self.capabilities.callHistoryAvailable = NO;
    self.capabilities.simSelectorAvailable = NO;
    self.capabilities.targetSummary = [NSString stringWithFormat:
        @"os=%ld.%ld.%ld family=%@ bundle=%@ executable=%@ adaptive=%@",
        (long)v.majorVersion, (long)v.minorVersion, (long)v.patchVersion,
        version.familyName, bundleID, executable,
        (version.isSupportedTargetOS && isPhone) ? @"enabled" : @"disabled"];
    self.capabilities.privateIntegrationState = (version.isSupportedTargetOS && isPhone)
        ? @"G6_ADAPTIVE_RUNTIME_DISCOVERY"
        : @"UNSUPPORTED_OR_WRONG_PROCESS_INERT";

    SDSLogInfo(SDSLogCategoryHook, @"Runtime inspect: %@", self.capabilities.targetSummary);
}

@end
