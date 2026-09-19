#import "SDSPreferences.h"
#import "SDSConstants.h"
#import "../Utilities/SDSLogger.h"
#import <CoreFoundation/CoreFoundation.h>

static id SDSCopyPreference(NSString *key) {
    CFPropertyListRef value = CFPreferencesCopyAppValue((__bridge CFStringRef)key,
                                                         (__bridge CFStringRef)SDSPreferencesDomain);
    return CFBridgingRelease(value);
}

static BOOL SDSBoolPref(NSString *key, BOOL fallback) {
    id value = SDSCopyPreference(key);
    return [value respondsToSelector:@selector(boolValue)] ? [value boolValue] : fallback;
}

static NSInteger SDSIntegerPref(NSString *key, NSInteger fallback) {
    id value = SDSCopyPreference(key);
    return [value respondsToSelector:@selector(integerValue)] ? [value integerValue] : fallback;
}

static NSString *SDSStringPref(NSString *key, NSString *fallback) {
    id value = SDSCopyPreference(key);
    if (![value isKindOfClass:[NSString class]]) return fallback;
    NSString *trimmed = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trimmed.length ? trimmed : fallback;
}

@implementation SDSPreferencesSnapshot
- (instancetype)initWithEnabled:(BOOL)enabled
               smartDialEnabled:(BOOL)smartDialEnabled
                contactsEnabled:(BOOL)contactsEnabled
             callHistoryEnabled:(BOOL)callHistoryEnabled
                      t9Enabled:(BOOL)t9Enabled
                 maxSuggestions:(NSInteger)maxSuggestions
              compactSIMEnabled:(BOOL)compactSIMEnabled
                       sim1Name:(NSString *)sim1Name
                       sim2Name:(NSString *)sim2Name {
    self = [super init];
    if (self) {
        _enabled = enabled;
        _smartDialEnabled = smartDialEnabled;
        _contactsEnabled = contactsEnabled;
        _callHistoryEnabled = callHistoryEnabled;
        _t9Enabled = t9Enabled;
        _maxSuggestions = MAX(1, MIN(5, maxSuggestions));
        _compactSIMEnabled = compactSIMEnabled;
        _sim1Name = [sim1Name copy];
        _sim2Name = [sim2Name copy];
    }
    return self;
}
- (id)copyWithZone:(NSZone *)zone { return self; }
@end

static void SDSPreferencesChangedCallback(CFNotificationCenterRef center,
                                          void *observer,
                                          CFStringRef name,
                                          const void *object,
                                          CFDictionaryRef userInfo) {
    SDSPreferences *prefs = (__bridge SDSPreferences *)observer;
    [prefs reload];
}

@interface SDSPreferences ()
@property(atomic, strong, readwrite) SDSPreferencesSnapshot *snapshot;
@property(nonatomic) BOOL observing;
@end

@implementation SDSPreferences
+ (instancetype)sharedPreferences {
    static SDSPreferences *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] initPrivate];
    });
    return instance;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) [self reload];
    return self;
}

- (void)reload {
    CFPreferencesAppSynchronize((__bridge CFStringRef)SDSPreferencesDomain);
    NSInteger maxResults = SDSIntegerPref(@"maxSuggestions", SDSDefaultMaxSuggestions);
    self.snapshot = [[SDSPreferencesSnapshot alloc]
                     initWithEnabled:SDSBoolPref(@"enabled", YES)
                     smartDialEnabled:SDSBoolPref(@"smartDialEnabled", YES)
                     contactsEnabled:SDSBoolPref(@"contactsEnabled", YES)
                     callHistoryEnabled:SDSBoolPref(@"callHistoryEnabled", YES)
                     t9Enabled:SDSBoolPref(@"t9Enabled", NO)
                     maxSuggestions:maxResults
                     compactSIMEnabled:SDSBoolPref(@"compactSIMEnabled", YES)
                     sim1Name:SDSStringPref(@"sim1Name", @"SIM 1")
                     sim2Name:SDSStringPref(@"sim2Name", @"SIM 2")];
    SDSLogInfo(SDSLogCategoryPreferences, @"Preferences reloaded");
}

- (void)startObserving {
    if (self.observing) return;
    self.observing = YES;
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    (__bridge const void *)(self),
                                    SDSPreferencesChangedCallback,
                                    (__bridge CFStringRef)SDSPreferencesChangedDarwinNotification,
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
}

- (void)stopObserving {
    if (!self.observing) return;
    self.observing = NO;
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                       (__bridge const void *)(self),
                                       (__bridge CFStringRef)SDSPreferencesChangedDarwinNotification,
                                       NULL);
}

- (void)dealloc { [self stopObserving]; }
@end
