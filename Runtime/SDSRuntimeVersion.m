#import "SDSRuntimeVersion.h"

@interface SDSRuntimeVersion ()
@property(nonatomic, readwrite) NSOperatingSystemVersion operatingSystemVersion;
@property(nonatomic, readwrite) SDSRuntimeFamily family;
@property(nonatomic, copy, readwrite) NSString *familyName;
@property(nonatomic, readwrite, getter=isSupportedTargetOS) BOOL supportedTargetOS;
@end

@implementation SDSRuntimeVersion

+ (instancetype)currentVersion {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    NSOperatingSystemVersion v = NSProcessInfo.processInfo.operatingSystemVersion;
    _operatingSystemVersion = v;

    if (v.majorVersion == 15) {
        _family = SDSRuntimeFamilyIOS15;
        _familyName = @"iOS15.x";
        _supportedTargetOS = YES;
    } else if (v.majorVersion == 16 && v.minorVersion == 2) {
        _family = SDSRuntimeFamilyIOS162;
        _familyName = @"iOS16.2";
        _supportedTargetOS = YES;
    } else {
        _family = SDSRuntimeFamilyUnsupported;
        _familyName = @"UNSUPPORTED";
        _supportedTargetOS = NO;
    }

    return self;
}

@end
