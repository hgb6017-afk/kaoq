#import <Foundation/Foundation.h>
@class SDSCallHistoryEntry;
NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT NSErrorDomain const SDSCallHistoryServiceErrorDomain;
@interface SDSCallHistoryService : NSObject
@property(nonatomic, readonly) BOOL available;
@property(nonatomic, copy, readonly) NSString *providerDescription;
- (void)loadRecentCallsWithCompletion:(void (^)(NSArray<SDSCallHistoryEntry *> *entries, NSError * _Nullable error))completion;
- (void)startObservingChangesWithHandler:(dispatch_block_t)handler;
- (void)stopObservingChanges;
@end
NS_ASSUME_NONNULL_END
