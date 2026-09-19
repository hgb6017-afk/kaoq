#import "SDSCallHistoryEntry.h"
@implementation SDSCallHistoryEntry
- (instancetype)initWithNumber:(NSString *)number date:(NSDate * _Nullable)date count:(NSUInteger)count kind:(NSString * _Nullable)kind {
    self = [super init];
    if (self) { _phoneNumber = [number copy] ?: @""; _lastInteractionDate = date; _interactionCount = count; _callKind = [kind copy]; }
    return self;
}
@end
