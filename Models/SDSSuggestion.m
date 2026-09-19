#import "SDSSuggestion.h"
@implementation SDSSuggestion
- (instancetype)init {
    self = [super init];
    if (self) { _displayName = @""; _displayNumber = @""; _normalizedNumber = @""; _identityKey = @""; }
    return self;
}
- (id)copyWithZone:(NSZone *)zone {
    SDSSuggestion *copy = [[[self class] allocWithZone:zone] init];
    copy.displayName = self.displayName;
    copy.displayNumber = self.displayNumber;
    copy.normalizedNumber = self.normalizedNumber;
    copy.identityKey = self.identityKey;
    copy.phoneLabel = self.phoneLabel;
    copy.t9Name = self.t9Name;
    copy.inContacts = self.inContacts;
    copy.inCallHistory = self.inCallHistory;
    copy.lastInteractionDate = self.lastInteractionDate;
    copy.interactionCount = self.interactionCount;
    copy.callKind = self.callKind;
    copy.matchType = self.matchType;
    return copy;
}
@end
