#import <Foundation/Foundation.h>
@class SDSContactNumber;
NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT NSErrorDomain const SDSContactsServiceErrorDomain;
@interface SDSContactsService : NSObject
@property(nonatomic, readonly) BOOL available;
- (void)loadContactsWithCompletion:(void (^)(NSArray<SDSContactNumber *> *contacts, NSError * _Nullable error))completion;
- (void)startObservingChangesWithHandler:(dispatch_block_t)handler;
- (void)stopObservingChanges;
@end
NS_ASSUME_NONNULL_END
