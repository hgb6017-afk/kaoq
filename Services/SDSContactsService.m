#import "SDSContactsService.h"
#import "../Models/SDSContactNumber.h"
#import "../Utilities/SDSLogger.h"
#import <Contacts/Contacts.h>

NSErrorDomain const SDSContactsServiceErrorDomain = @"com.smartdialsim.contacts";

@interface SDSContactsService ()
@property(nonatomic, strong) CNContactStore *store;
@property(nonatomic, copy) dispatch_block_t changeHandler;
@property(nonatomic) id observerToken;
@end

@implementation SDSContactsService
- (instancetype)init { self = [super init]; if (self) _store = [[CNContactStore alloc] init]; return self; }
- (BOOL)available {
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    return status != CNAuthorizationStatusDenied && status != CNAuthorizationStatusRestricted;
}

- (void)loadContactsWithCompletion:(void (^)(NSArray<SDSContactNumber *> *contacts, NSError * _Nullable error))completion {
    NSParameterAssert(completion);
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    if (status == CNAuthorizationStatusDenied || status == CNAuthorizationStatusRestricted) {
        NSError *error = [NSError errorWithDomain:SDSContactsServiceErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"Contacts access is unavailable in the Phone process. SmartDialSIM will not request a permission prompt."}];
        completion(@[], error);
        return;
    }
    // For system Phone builds that report NotDetermined despite already having host-process access,
    // attempt a read directly but never call requestAccessForEntityType:, so no surprise TCC prompt is created.

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        NSArray *keys = @[CNContactGivenNameKey, CNContactFamilyNameKey, CNContactOrganizationNameKey, CNContactPhoneNumbersKey];
        CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:keys];
        request.unifyResults = YES;
        NSMutableArray<SDSContactNumber *> *results = [NSMutableArray array];
        NSError *fetchError = nil;
        BOOL ok = [self.store enumerateContactsWithFetchRequest:request error:&fetchError usingBlock:^(CNContact *contact, BOOL *stop) {
            NSString *name = [CNContactFormatter stringFromContact:contact style:CNContactFormatterStyleFullName];
            if (!name.length) name = contact.organizationName ?: @"";
            for (CNLabeledValue<CNPhoneNumber *> *item in contact.phoneNumbers) {
                NSString *number = item.value.stringValue ?: @"";
                if (!number.length) continue;
                NSString *label = item.label ? [CNLabeledValue localizedStringForLabel:item.label] : nil;
                [results addObject:[[SDSContactNumber alloc] initWithName:name number:number label:label]];
            }
        }];
        if (!ok && !fetchError) fetchError = [NSError errorWithDomain:SDSContactsServiceErrorDomain code:2 userInfo:@{NSLocalizedDescriptionKey:@"Unknown Contacts fetch failure"}];
        dispatch_async(dispatch_get_main_queue(), ^{ completion(ok ? results.copy : @[], fetchError); });
    });
}

- (void)startObservingChangesWithHandler:(dispatch_block_t)handler {
    self.changeHandler = handler;
    if (self.observerToken) return;
    __weak typeof(self) weakSelf = self;
    self.observerToken = [[NSNotificationCenter defaultCenter] addObserverForName:CNContactStoreDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        SDSLogInfo(SDSLogCategoryContacts, @"Contacts change notification received");
        if (weakSelf.changeHandler) weakSelf.changeHandler();
    }];
}
- (void)stopObservingChanges {
    if (self.observerToken) [[NSNotificationCenter defaultCenter] removeObserver:self.observerToken];
    self.observerToken = nil;
    self.changeHandler = nil;
}
- (void)dealloc { [self stopObservingChanges]; }
@end
