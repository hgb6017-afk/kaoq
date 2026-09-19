#import "SDSContactNumber.h"
@implementation SDSContactNumber
- (instancetype)initWithName:(NSString *)name number:(NSString *)number label:(NSString * _Nullable)label {
    self = [super init];
    if (self) { _displayName = [name copy] ?: @""; _phoneNumber = [number copy] ?: @""; _phoneLabel = [label copy]; }
    return self;
}
@end
