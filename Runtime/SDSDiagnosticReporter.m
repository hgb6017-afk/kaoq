#import "SDSDiagnosticReporter.h"
#import "../Config/SDSConstants.h"
#import "../Utilities/SDSLogger.h"
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>
#import <unistd.h>
#import <stdlib.h>

static NSString * const SDSDiagnosticReportKey = @"diagnosticReport";
static NSString * const SDSDiagnosticTimestampKey = @"diagnosticTimestamp";
static NSString * const SDSDiagnosticBundleIDKey = @"diagnosticBundleID";
static NSString * const SDSDiagnosticExecutableKey = @"diagnosticExecutable";
static NSString * const SDSDiagnosticOSKey = @"diagnosticOS";
static NSString * const SDSDiagnosticArmedKey = @"diagnosticArmed";
static CFStringRef const SDSDiagnosticRequestNotification = CFSTR("com.smartdialsim.diagnostic.request");

@interface SDSDiagnosticReporter ()
@property(nonatomic, assign) BOOL started;
@property(nonatomic, assign) BOOL burstScheduled;
- (void)scheduleArmedBurstWithPrefix:(NSString *)prefix;
@end

@implementation SDSDiagnosticReporter

+ (instancetype)sharedReporter {
    static SDSDiagnosticReporter *reporter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ reporter = [[self alloc] init]; });
    return reporter;
}

static void SDSDiagnosticDarwinCallback(CFNotificationCenterRef center,
                                        void *observer,
                                        CFStringRef name,
                                        const void *object,
                                        CFDictionaryRef userInfo) {
    SDSDiagnosticReporter *reporter = (__bridge SDSDiagnosticReporter *)observer;
    dispatch_async(dispatch_get_main_queue(), ^{
        [reporter scheduleArmedBurstWithPrefix:@"manual"];
    });
}

- (void)start {
    if (self.started) return;
    self.started = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    (__bridge const void *)(self),
                                    SDSDiagnosticDarwinCallback,
                                    SDSDiagnosticRequestNotification,
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);

    [self scheduleArmedBurstWithPrefix:@"startup"];
    SDSLogInfo(SDSLogCategoryLifecycle, @"Diagnostic reporter armed-on-demand; idle during normal Phone use");
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self scheduleArmedBurstWithPrefix:@"phone-active"];
}

- (BOOL)isDiagnosticArmed {
    CFPreferencesAppSynchronize((__bridge CFStringRef)SDSPreferencesDomain);
    id value = CFBridgingRelease(CFPreferencesCopyAppValue((__bridge CFStringRef)SDSDiagnosticArmedKey,
                                                            (__bridge CFStringRef)SDSPreferencesDomain));
    return [value respondsToSelector:@selector(boolValue)] && [value boolValue];
}

- (void)scheduleArmedBurstWithPrefix:(NSString *)prefix {
    if (![self isDiagnosticArmed] || self.burstScheduled) return;
    self.burstScheduled = YES;
    NSArray<NSNumber *> *delays = @[@0.8, @3.0, @6.0];
    for (NSNumber *delay in delays) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay.doubleValue * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            UIApplication *app = UIApplication.sharedApplication;
            if (app.applicationState == UIApplicationStateActive) {
                [self captureAndPersistWithReason:[NSString stringWithFormat:@"%@+%.1fs", prefix, delay.doubleValue]];
            }
            if ([delay isEqual:delays.lastObject]) {
                self.burstScheduled = NO;
                CFPreferencesSetAppValue((__bridge CFStringRef)SDSDiagnosticArmedKey, kCFBooleanFalse, (__bridge CFStringRef)SDSPreferencesDomain);
                CFPreferencesAppSynchronize((__bridge CFStringRef)SDSPreferencesDomain);
            }
        });
    }
}

static BOOL SDSStringMatches(NSString *value, NSString *pattern) {
    if (value.length == 0) return NO;
    return [value rangeOfString:pattern options:NSRegularExpressionSearch | NSCaseInsensitiveSearch].location != NSNotFound;
}

static NSString *SDSMethodSummaryForClass(Class cls) {
    NSMutableArray<NSString *> *matches = [NSMutableArray array];
    NSString *pattern = @"digit|dial|key|number|input|insert|append|delete|backspace|clear|erase|paste|call|sim|line|subscription|carrier|account|update|set";

    unsigned int count = 0;
    Method *methods = class_copyMethodList(cls, &count);
    for (unsigned int i = 0; i < count && matches.count < 40; i++) {
        SEL selector = method_getName(methods[i]);
        NSString *name = NSStringFromSelector(selector);
        if (SDSStringMatches(name, pattern)) [matches addObject:name];
    }
    free(methods);

    Class meta = object_getClass(cls);
    count = 0;
    Method *classMethods = class_copyMethodList(meta, &count);
    for (unsigned int i = 0; i < count && matches.count < 40; i++) {
        SEL selector = method_getName(classMethods[i]);
        NSString *name = [@"+" stringByAppendingString:NSStringFromSelector(selector)];
        if (SDSStringMatches(name, pattern)) [matches addObject:name];
    }
    free(classMethods);

    return [matches componentsJoinedByString:@", "];
}


static NSString *SDSSafeDiagnosticText(NSString *text) {
    if (!text.length) return @"";
    NSString *lower = text.lowercaseString;
    NSArray<NSString *> *safeWords = @[@"sim", @"line", @"keypad", @"dial", @"call", @"delete", @"backspace", @"primary", @"secondary", @"cellular", @"subscription"];
    BOOL hasSafeWord = NO;
    for (NSString *word in safeWords) if ([lower containsString:word]) { hasSafeWord = YES; break; }

    NSCharacterSet *digits = NSCharacterSet.decimalDigitCharacterSet;
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:@" +-()./\u00a0\u202f*#"];
    BOOL hasDigit = NO;
    BOOL dialableOnly = YES;
    for (NSUInteger i = 0; i < text.length; i++) {
        unichar c = [text characterAtIndex:i];
        if ([digits characterIsMember:c]) { hasDigit = YES; continue; }
        if (![allowed characterIsMember:c]) { dialableOnly = NO; break; }
    }
    if (hasDigit && dialableOnly) return SDSMaskPhoneLikeText(text);
    if (hasSafeWord) {
        NSString *shortText = text.length > 80 ? [[text substringToIndex:80] stringByAppendingString:@"…"] : text;
        return SDSMaskPhoneLikeText(shortText);
    }
    return [NSString stringWithFormat:@"<redacted len=%lu>", (unsigned long)text.length];
}

static void SDSAppendView(NSMutableString *out, UIView *view, NSUInteger depth, NSUInteger *budget) {
    if (!view || *budget == 0 || depth > 14) return;
    (*budget)--;

    NSMutableArray<NSString *> *texts = [NSMutableArray array];
    NSString *accessibility = view.accessibilityLabel;
    if (accessibility.length) [texts addObject:[NSString stringWithFormat:@"a11y=\"%@\"", SDSSafeDiagnosticText(accessibility)]];

    if ([view isKindOfClass:UILabel.class]) {
        NSString *text = ((UILabel *)view).text;
        if (text.length) [texts addObject:[NSString stringWithFormat:@"text=\"%@\"", SDSSafeDiagnosticText(text)]];
    } else if ([view isKindOfClass:UIButton.class]) {
        NSString *title = [(UIButton *)view titleForState:UIControlStateNormal];
        if (title.length) [texts addObject:[NSString stringWithFormat:@"title=\"%@\"", SDSSafeDiagnosticText(title)]];
    } else if ([view isKindOfClass:UITextField.class]) {
        NSString *text = ((UITextField *)view).text;
        if (text.length) [texts addObject:[NSString stringWithFormat:@"text=\"%@\"", SDSSafeDiagnosticText(text)]];
    } else if ([view isKindOfClass:UITextView.class]) {
        NSString *text = ((UITextView *)view).text;
        if (text.length) [texts addObject:[NSString stringWithFormat:@"text=\"%@\"", SDSSafeDiagnosticText(text)]];
    }

    CGRect f = view.frame;
    [out appendFormat:@"%@VIEW %@ frame=(%.0f,%.0f %.0fx%.0f) hidden=%d alpha=%.2f %@\n",
     [@"  " stringByPaddingToLength:depth * 2 withString:@"  " startingAtIndex:0],
     NSStringFromClass(view.class), f.origin.x, f.origin.y, f.size.width, f.size.height,
     view.hidden, view.alpha, [texts componentsJoinedByString:@" "]];

    for (UIView *child in view.subviews) {
        SDSAppendView(out, child, depth + 1, budget);
        if (*budget == 0) break;
    }
}

static void SDSAppendController(NSMutableString *out, UIViewController *vc, NSUInteger depth, NSUInteger *budget) {
    if (!vc || *budget == 0 || depth > 12) return;
    (*budget)--;
    [out appendFormat:@"%@VC %@\n",
     [@"  " stringByPaddingToLength:depth * 2 withString:@"  " startingAtIndex:0],
     NSStringFromClass(vc.class)];

    if (vc.presentedViewController) {
        [out appendFormat:@"%@presented:\n", [@"  " stringByPaddingToLength:(depth + 1) * 2 withString:@"  " startingAtIndex:0]];
        SDSAppendController(out, vc.presentedViewController, depth + 2, budget);
    }
    for (UIViewController *child in vc.childViewControllers) {
        SDSAppendController(out, child, depth + 1, budget);
        if (*budget == 0) break;
    }
}

- (NSString *)buildReportForReason:(NSString *)reason {
    NSMutableString *out = [NSMutableString string];
    NSBundle *bundle = NSBundle.mainBundle;
    NSString *bundleID = bundle.bundleIdentifier ?: @"<nil>";
    NSString *executable = bundle.executablePath.lastPathComponent ?: @"<nil>";
    NSOperatingSystemVersion os = NSProcessInfo.processInfo.operatingSystemVersion;

    [out appendFormat:@"SmartDialSIM G6.1 AUDIT-FIXED DIAGNOSTIC\nreason=%@\nos=%ld.%ld.%ld\nbundle=%@\nexecutable=%@\npid=%d\n",
     reason, (long)os.majorVersion, (long)os.minorVersion, (long)os.patchVersion,
     bundleID, executable, getpid()];

    [out appendString:@"\n=== WINDOWS / CONTROLLERS / VIEWS ===\n"];
    UIApplication *app = UIApplication.sharedApplication;
    NSMutableArray<UIWindow *> *windows = [NSMutableArray array];
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in app.connectedScenes) {
            if (![scene isKindOfClass:UIWindowScene.class]) continue;
            for (UIWindow *window in ((UIWindowScene *)scene).windows) [windows addObject:window];
        }
    }
    if (windows.count == 0) [windows addObjectsFromArray:app.windows ?: @[]];

    NSUInteger windowIndex = 0;
    for (UIWindow *window in windows) {
        [out appendFormat:@"\nWINDOW[%lu] %@ key=%d\n", (unsigned long)windowIndex++, NSStringFromClass(window.class), window.isKeyWindow];
        NSUInteger controllerBudget = 80;
        SDSAppendController(out, window.rootViewController, 0, &controllerBudget);
        NSUInteger viewBudget = 320;
        SDSAppendView(out, window, 0, &viewBudget);
    }

    [out appendString:@"\n=== INTERESTING OBJC CLASSES / METHODS ===\n"];
    NSString *classPattern = @"dial|dialer|keypad|key|number|phone|call|recent|history|sim|subscription|line|telephony|contact";
    int total = objc_getClassList(NULL, 0);
    Class *classes = total > 0 ? (__unsafe_unretained Class *)malloc(sizeof(Class) * (NSUInteger)total) : NULL;
    int actual = classes ? objc_getClassList(classes, total) : 0;
    NSUInteger emitted = 0;
    for (int i = 0; i < actual && emitted < 220; i++) {
        Class cls = classes[i];
        NSString *name = NSStringFromClass(cls);
        if (!SDSStringMatches(name, classPattern)) continue;
        const char *image = class_getImageName(cls);
        NSString *methods = SDSMethodSummaryForClass(cls);
        [out appendFormat:@"CLASS %@ | image=%s\n", name, image ?: "<unknown>"];
        if (methods.length) [out appendFormat:@"  METHODS %@\n", methods];
        emitted++;
    }
    free(classes);
    [out appendFormat:@"interestingClassCount=%lu\n", (unsigned long)emitted];

    return SDSMaskPhoneLikeText(out);
}

- (void)captureAndPersistWithReason:(NSString *)reason {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self captureAndPersistWithReason:reason]; });
        return;
    }

    NSString *snapshot = [self buildReportForReason:reason ?: @"manual"];
    NSString *existing = (__bridge_transfer NSString *)CFPreferencesCopyAppValue((__bridge CFStringRef)SDSDiagnosticReportKey,
                                                                                 (__bridge CFStringRef)SDSPreferencesDomain);
    if (existing.length > 90000) existing = [existing substringFromIndex:existing.length - 70000];
    NSString *combined = existing.length ? [NSString stringWithFormat:@"%@\n\n==============================\n\n%@", existing, snapshot] : snapshot;

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss Z";
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];

    NSBundle *bundle = NSBundle.mainBundle;
    NSOperatingSystemVersion os = NSProcessInfo.processInfo.operatingSystemVersion;
    NSString *osString = [NSString stringWithFormat:@"%ld.%ld.%ld", (long)os.majorVersion, (long)os.minorVersion, (long)os.patchVersion];

    CFPreferencesSetAppValue((__bridge CFStringRef)SDSDiagnosticReportKey, (__bridge CFPropertyListRef)combined, (__bridge CFStringRef)SDSPreferencesDomain);
    CFPreferencesSetAppValue((__bridge CFStringRef)SDSDiagnosticTimestampKey, (__bridge CFPropertyListRef)timestamp, (__bridge CFStringRef)SDSPreferencesDomain);
    CFPreferencesSetAppValue((__bridge CFStringRef)SDSDiagnosticBundleIDKey, (__bridge CFPropertyListRef)(bundle.bundleIdentifier ?: @"<nil>"), (__bridge CFStringRef)SDSPreferencesDomain);
    CFPreferencesSetAppValue((__bridge CFStringRef)SDSDiagnosticExecutableKey, (__bridge CFPropertyListRef)(bundle.executablePath.lastPathComponent ?: @"<nil>"), (__bridge CFStringRef)SDSPreferencesDomain);
    CFPreferencesSetAppValue((__bridge CFStringRef)SDSDiagnosticOSKey, (__bridge CFPropertyListRef)osString, (__bridge CFStringRef)SDSPreferencesDomain);
    CFPreferencesAppSynchronize((__bridge CFStringRef)SDSPreferencesDomain);

    SDSLogInfo(SDSLogCategoryHook, @"Diagnostic snapshot persisted (%@)", reason ?: @"manual");
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                       (__bridge const void *)(self),
                                       SDSDiagnosticRequestNotification,
                                       NULL);
}

@end
