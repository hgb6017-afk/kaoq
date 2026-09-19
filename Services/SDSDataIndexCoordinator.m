#import "SDSDataIndexCoordinator.h"
#import "SDSContactsService.h"
#import "SDSCallHistoryService.h"
#import "../Search/SDSSearchIndex.h"
#import "../Search/SDSSuggestionMerger.h"
#import "../Utilities/SDSLogger.h"

@interface SDSDataIndexCoordinator ()
@property(nonatomic, strong) SDSContactsService *contactsService;
@property(nonatomic, strong) SDSCallHistoryService *callHistoryService;
@property(atomic, strong, readwrite) SDSSearchIndex *currentIndex;
@property(nonatomic, strong) dispatch_queue_t buildQueue;
@property(atomic) NSUInteger generation;
@property(nonatomic) BOOL lastContactsEnabled;
@property(nonatomic) BOOL lastCallHistoryEnabled;
@property(nonatomic, copy) NSString *lastRegion;
@property(nonatomic) BOOL sourceRefreshScheduled;
@end

@implementation SDSDataIndexCoordinator
- (instancetype)initWithContactsService:(SDSContactsService *)contactsService callHistoryService:(SDSCallHistoryService *)callHistoryService {
    self = [super init];
    if (self) {
        _contactsService = contactsService;
        _callHistoryService = callHistoryService;
        _currentIndex = [[SDSSearchIndex alloc] initWithRecords:@[]];
        _buildQueue = dispatch_queue_create("com.smartdialsim.index-build", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)refreshWithContactsEnabled:(BOOL)contactsEnabled callHistoryEnabled:(BOOL)callHistoryEnabled defaultRegion:(NSString * _Nullable)region completion:(dispatch_block_t _Nullable)completion {
    self.lastContactsEnabled = contactsEnabled;
    self.lastCallHistoryEnabled = callHistoryEnabled;
    self.lastRegion = [region copy] ?: @"VN";
    NSUInteger requestGeneration = ++self.generation;
    dispatch_group_t group = dispatch_group_create();
    __block NSArray *contacts = @[];
    __block NSArray *history = @[];

    if (contactsEnabled) {
        dispatch_group_enter(group);
        [self.contactsService loadContactsWithCompletion:^(NSArray *items, NSError *error) {
            contacts = items ?: @[];
            if (error) SDSLogError(SDSLogCategoryContacts, @"Contacts source failed safely: %@", error.localizedDescription);
            dispatch_group_leave(group);
        }];
    }
    if (callHistoryEnabled) {
        dispatch_group_enter(group);
        [self.callHistoryService loadRecentCallsWithCompletion:^(NSArray *items, NSError *error) {
            history = items ?: @[];
            if (error) SDSLogInfo(SDSLogCategoryCallHistory, @"History source unavailable; continuing without it");
            dispatch_group_leave(group);
        }];
    }

    dispatch_group_notify(group, self.buildQueue, ^{
        NSArray *merged = [SDSSuggestionMerger mergeContacts:contacts callHistory:history defaultRegion:region];
        SDSSearchIndex *newIndex = [[SDSSearchIndex alloc] initWithRecords:merged];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (requestGeneration != self.generation) return;
            self.currentIndex = newIndex;
            SDSLogInfo(SDSLogCategorySearch, @"Search index swapped: %lu records", (unsigned long)newIndex.records.count);
            if (completion) completion();
            if (self.indexDidChangeHandler) self.indexDidChangeHandler();
        });
    });
}

- (void)scheduleRefreshAfterSourceChange {
    if (self.sourceRefreshScheduled) return;
    self.sourceRefreshScheduled = YES;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.sourceRefreshScheduled = NO;
        [strongSelf refreshWithContactsEnabled:strongSelf.lastContactsEnabled
                            callHistoryEnabled:strongSelf.lastCallHistoryEnabled
                                 defaultRegion:strongSelf.lastRegion ?: @"VN"
                                    completion:nil];
    });
}

- (void)startChangeObservation {
    __weak typeof(self) weakSelf = self;
    [self.contactsService startObservingChangesWithHandler:^{ [weakSelf scheduleRefreshAfterSourceChange]; }];
    [self.callHistoryService startObservingChangesWithHandler:^{ [weakSelf scheduleRefreshAfterSourceChange]; }];
}
- (void)stopChangeObservation { [self.contactsService stopObservingChanges]; [self.callHistoryService stopObservingChanges]; }
- (void)dealloc { [self stopChangeObservation]; }
@end
