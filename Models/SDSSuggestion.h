#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SDSMatchType) {
    SDSMatchTypeNone = 0,
    SDSMatchTypeT9Name = 1,
    SDSMatchTypeSubstring = 2,
    SDSMatchTypePrefix = 3,
    SDSMatchTypeExact = 4,
};

@interface SDSSuggestion : NSObject <NSCopying>
@property(nonatomic, copy) NSString *displayName;
@property(nonatomic, copy) NSString *displayNumber;
@property(nonatomic, copy) NSString *normalizedNumber;
@property(nonatomic, copy) NSString *identityKey;
@property(nonatomic, copy, nullable) NSString *phoneLabel;
@property(nonatomic, copy, nullable) NSString *t9Name;
@property(nonatomic) BOOL inContacts;
@property(nonatomic) BOOL inCallHistory;
@property(nonatomic, strong, nullable) NSDate *lastInteractionDate;
@property(nonatomic) NSUInteger interactionCount;
@property(nonatomic, copy, nullable) NSString *callKind;
@property(nonatomic) SDSMatchType matchType;
@end
NS_ASSUME_NONNULL_END
