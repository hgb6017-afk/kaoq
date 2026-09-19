#import <Foundation/Foundation.h>
@class SDSContactNumber, SDSCallHistoryEntry, SDSSuggestion;
NS_ASSUME_NONNULL_BEGIN
@interface SDSSuggestionMerger : NSObject
+ (NSArray<SDSSuggestion *> *)mergeContacts:(NSArray<SDSContactNumber *> *)contacts
                                callHistory:(NSArray<SDSCallHistoryEntry *> *)history
                              defaultRegion:(nullable NSString *)region;
@end
NS_ASSUME_NONNULL_END
