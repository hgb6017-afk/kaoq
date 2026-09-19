#import "SDSCallHistoryService.h"
#import "../Models/SDSCallHistoryEntry.h"
#import "../Search/SDSPhoneNumberNormalizer.h"
#import "../Utilities/SDSLogger.h"
#import <Contacts/Contacts.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <string.h>

NSErrorDomain const SDSCallHistoryServiceErrorDomain = @"com.smartdialsim.callhistory";

static id SDSCHSendId0(id target, SEL sel) {
    return ((id (*)(id, SEL))objc_msgSend)(target, sel);
}
static id SDSCHSendId1(id target, SEL sel, id arg) {
    return ((id (*)(id, SEL, id))objc_msgSend)(target, sel, arg);
}
static id SDSCHSendIdBool(id target, SEL sel, BOOL arg) {
    return ((id (*)(id, SEL, BOOL))objc_msgSend)(target, sel, arg);
}
static void SDSCHSendVoidBool(id target, SEL sel, BOOL arg) {
    ((void (*)(id, SEL, BOOL))objc_msgSend)(target, sel, arg);
}

static const char *SDSCHSkipTypeQualifiers(const char *type) {
    if (!type) return "";
    while (*type && strchr("rnNoORV", *type)) type++;
    return type;
}

static BOOL SDSCHSignatureMatches(id target, SEL sel, BOOL objectReturn, NSUInteger argumentCount, NSArray<NSString *> *argumentKinds) {
    if (!target || !sel || ![target respondsToSelector:sel]) return NO;
    NSMethodSignature *signature = [target methodSignatureForSelector:sel];
    if (!signature || signature.numberOfArguments != argumentCount) return NO;
    const char *returnType = SDSCHSkipTypeQualifiers(signature.methodReturnType);
    if (objectReturn && returnType[0] != '@') return NO;
    if (!objectReturn && returnType[0] != 'v') return NO;
    for (NSUInteger i = 0; i < argumentKinds.count; i++) {
        const char *type = SDSCHSkipTypeQualifiers([signature getArgumentTypeAtIndex:i + 2]);
        NSString *kind = argumentKinds[i];
        if ([kind isEqualToString:@"object"] && type[0] != '@') return NO;
        if ([kind isEqualToString:@"bool"] && !(type[0] == 'B' || type[0] == 'c')) return NO;
    }
    return YES;
}

static id SDSCHKVCValue(id object, NSArray<NSString *> *keys) {
    if (!object) return nil;
    for (NSString *key in keys) {
        @try {
            id value = [object valueForKey:key];
            if (value && value != NSNull.null) return value;
        } @catch (__unused NSException *exception) {
        }
    }
    return nil;
}

static NSString *SDSCHStringFromValue(id value) {
    if (!value || value == NSNull.null) return nil;
    if ([value isKindOfClass:NSString.class]) return value;
    id nestedValue = SDSCHKVCValue(value, @[@"stringValue", @"phoneNumber", @"number", @"digits", @"address", @"value"]);
    if ([nestedValue isKindOfClass:NSString.class] && [nestedValue length]) return nestedValue;
    NSString *description = [value description];
    if ([description containsString:@"<"] && [description containsString:@">"]) return nil;
    NSString *dialable = [SDSPhoneNumberNormalizer normalizedDialableString:description];
    return dialable.length >= 3 ? description : nil;
}

static NSString *SDSCHPhoneStringFromCall(id call) {
    NSArray<NSString *> *keys = @[@"address", @"phoneNumber", @"remoteParticipant", @"handle", @"callerId"];
    for (NSString *key in keys) {
        id value = SDSCHKVCValue(call, @[key]);
        NSString *candidate = SDSCHStringFromValue(value);
        if ([SDSPhoneNumberNormalizer normalizedDialableString:candidate ?: @""].length) return candidate;
    }
    return nil;
}

@interface SDSCallHistoryService ()
@property(nonatomic, strong) id manager;
@property(nonatomic, strong) CNContactStore *contactStore;
@property(nonatomic, strong) dispatch_queue_t providerQueue;
@property(nonatomic, copy) dispatch_block_t changeHandler;
@property(nonatomic, strong) id notificationToken;
@property(nonatomic, copy) NSString *providerDescriptionValue;
@end

@implementation SDSCallHistoryService

- (instancetype)init {
    self = [super init];
    if (self) {
        _providerQueue = dispatch_queue_create("com.smartdialsim.callhistory-provider", DISPATCH_QUEUE_SERIAL);
        _contactStore = [[CNContactStore alloc] init];
    }
    return self;
}

- (BOOL)ensureManager {
    if (self.manager) return YES;
    void *handle = dlopen("/System/Library/PrivateFrameworks/CallHistory.framework/CallHistory", RTLD_LAZY | RTLD_LOCAL);
    if (!handle) return NO;
    Class managerClass = NSClassFromString(@"CHManager");
    if (!managerClass) return NO;
    @try {
        id allocated = [managerClass alloc];
        SEL withStoreQueue = NSSelectorFromString(@"initWithContactStore:queue:");
        SEL withStore = NSSelectorFromString(@"initWithContactStore:");
        if (SDSCHSignatureMatches(allocated, withStoreQueue, YES, 4, @[@"object", @"object"])) {
            self.manager = ((id (*)(id, SEL, id, id))objc_msgSend)(allocated, withStoreQueue, self.contactStore, self.providerQueue);
            self.providerDescriptionValue = @"CallHistory.framework CHManager initWithContactStore:queue:";
        } else if (SDSCHSignatureMatches(allocated, withStore, YES, 3, @[@"object"])) {
            self.manager = SDSCHSendId1(allocated, withStore, self.contactStore);
            self.providerDescriptionValue = @"CallHistory.framework CHManager initWithContactStore:";
        } else if ([allocated respondsToSelector:@selector(init)]) {
            self.manager = [allocated init];
            self.providerDescriptionValue = @"CallHistory.framework CHManager init";
        }
        SEL showsTelephony = NSSelectorFromString(@"setShowsTelephonyCalls:");
        if (SDSCHSignatureMatches(self.manager, showsTelephony, NO, 3, @[@"bool"])) SDSCHSendVoidBool(self.manager, showsTelephony, YES);
        return self.manager != nil;
    } @catch (NSException *exception) {
        SDSLogInfo(SDSLogCategoryCallHistory, @"CallHistory manager init failed safely: %@", exception.name);
        self.manager = nil;
        return NO;
    }
}

- (BOOL)available {
    if (![self ensureManager]) return NO;
    SEL fetch = NSSelectorFromString(@"fetchRecentCallsSyncWithCoalescing:");
    SEL recent = NSSelectorFromString(@"recentCalls");
    SEL predicate = NSSelectorFromString(@"recentCallsWithPredicate:");
    return SDSCHSignatureMatches(self.manager, fetch, YES, 3, @[@"bool"]) ||
           SDSCHSignatureMatches(self.manager, recent, YES, 2, @[]) ||
           SDSCHSignatureMatches(self.manager, predicate, YES, 3, @[@"object"]);
}

- (NSString *)providerDescription { return self.providerDescriptionValue ?: @"CallHistory.framework unavailable"; }

- (NSArray *)fetchCallsSafely:(NSError **)outError {
    if (![self ensureManager]) {
        if (outError) *outError = [NSError errorWithDomain:SDSCallHistoryServiceErrorDomain code:100 userInfo:@{NSLocalizedDescriptionKey:@"CallHistory.framework/CHManager is unavailable in this Phone process."}];
        return @[];
    }
    @try {
        SEL fetch = NSSelectorFromString(@"fetchRecentCallsSyncWithCoalescing:");
        SEL recent = NSSelectorFromString(@"recentCalls");
        SEL predicate = NSSelectorFromString(@"recentCallsWithPredicate:");
        id result = nil;
        if (SDSCHSignatureMatches(self.manager, fetch, YES, 3, @[@"bool"])) result = SDSCHSendIdBool(self.manager, fetch, YES);
        else if (SDSCHSignatureMatches(self.manager, recent, YES, 2, @[])) result = SDSCHSendId0(self.manager, recent);
        else if (SDSCHSignatureMatches(self.manager, predicate, YES, 3, @[@"object"])) result = SDSCHSendId1(self.manager, predicate, nil);
        if ([result isKindOfClass:NSArray.class]) return result;
        return @[];
    } @catch (NSException *exception) {
        if (outError) *outError = [NSError errorWithDomain:SDSCallHistoryServiceErrorDomain code:101 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"CallHistory provider raised %@ and was disabled for this refresh.", exception.name]}];
        return @[];
    }
}

- (void)loadRecentCallsWithCompletion:(void (^)(NSArray<SDSCallHistoryEntry *> *entries, NSError * _Nullable error))completion {
    if (!completion) return;
    dispatch_async(self.providerQueue, ^{
        NSError *providerError = nil;
        NSArray *calls = [self fetchCallsSafely:&providerError];
        NSMutableArray<SDSCallHistoryEntry *> *entries = [NSMutableArray array];
        NSUInteger inspected = 0;
        for (id call in calls) {
            if (++inspected > 400) break;
            NSString *number = SDSCHPhoneStringFromCall(call);
            NSString *normalized = [SDSPhoneNumberNormalizer normalizedDialableString:number ?: @""];
            if (!normalized.length) continue;

            id rawDate = SDSCHKVCValue(call, @[@"date", @"startDate", @"timestamp"]);
            NSDate *date = [rawDate isKindOfClass:NSDate.class] ? rawDate : nil;
            id rawKind = SDSCHKVCValue(call, @[@"callType", @"callCategory", @"status", @"disconnectedReason"]);
            NSString *kind = nil;
            if ([rawKind isKindOfClass:NSString.class]) kind = rawKind;
            else if ([rawKind respondsToSelector:@selector(stringValue)]) kind = [rawKind stringValue];
            [entries addObject:[[SDSCallHistoryEntry alloc] initWithNumber:number ?: normalized date:date count:1 kind:kind]];
        }
        SDSLogInfo(SDSLogCategoryCallHistory, @"CallHistory refresh produced %lu usable records from %lu inspected calls", (unsigned long)entries.count, (unsigned long)MIN(inspected, (NSUInteger)400));
        dispatch_async(dispatch_get_main_queue(), ^{ completion(entries.copy, providerError); });
    });
}

- (void)startObservingChangesWithHandler:(dispatch_block_t)handler {
    self.changeHandler = handler;
    if (self.notificationToken) return;
    __weak typeof(self) weakSelf = self;
    // Do not guess a private notification constant. Observe local Phone notifications by name only
    // and react opportunistically when a CallHistory/Recent-call notification is actually posted.
    // No object/userInfo is read, and the coordinator debounces resulting refreshes.
    self.notificationToken = [[NSNotificationCenter defaultCenter] addObserverForName:nil
                                                                                object:nil
                                                                                 queue:[NSOperationQueue mainQueue]
                                                                            usingBlock:^(NSNotification *note) {
        NSString *name = note.name.lowercaseString ?: @"";
        BOOL looksRelevant = [name containsString:@"callhistory"] ||
                             [name containsString:@"call_history"] ||
                             [name containsString:@"recentcall"] ||
                             ([name containsString:@"call"] && [name containsString:@"history"]);
        if (looksRelevant && weakSelf.changeHandler) weakSelf.changeHandler();
    }];
}

- (void)stopObservingChanges {
    if (self.notificationToken) [[NSNotificationCenter defaultCenter] removeObserver:self.notificationToken];
    self.notificationToken = nil;
    self.changeHandler = nil;
}

- (void)dealloc { [self stopObservingChanges]; }
@end
