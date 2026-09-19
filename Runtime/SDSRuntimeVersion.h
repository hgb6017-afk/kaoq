#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SDSRuntimeFamily) {
    SDSRuntimeFamilyUnsupported = 0,
    SDSRuntimeFamilyIOS15,
    SDSRuntimeFamilyIOS162,
};

@interface SDSRuntimeVersion : NSObject
@property(nonatomic, readonly) NSOperatingSystemVersion operatingSystemVersion;
@property(nonatomic, readonly) SDSRuntimeFamily family;
@property(nonatomic, copy, readonly) NSString *familyName;
@property(nonatomic, readonly, getter=isSupportedTargetOS) BOOL supportedTargetOS;
+ (instancetype)currentVersion;
@end

NS_ASSUME_NONNULL_END
