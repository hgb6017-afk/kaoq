#import "SDSAdaptivePhoneIntegration.h"
#import "SDSDialerNumberSetter.h"
#import "../Config/SDSPreferences.h"
#import "../Services/SDSContactsService.h"
#import "../Services/SDSCallHistoryService.h"
#import "../Services/SDSDataIndexCoordinator.h"
#import "../Suggestions/SDSSuggestionController.h"
#import "../Suggestions/SDSSuggestionView.h"
#import "../Models/SDSSuggestion.h"
#import "../Search/SDSPhoneNumberNormalizer.h"
#import "../SIMCustomization/SDSSIMSelectorBridge.h"
#import "../Utilities/SDSLogger.h"
#import <UIKit/UIKit.h>
#import <math.h>

static NSString *SDSVisibleTextForView(UIView *view) {
    NSString *text = nil;
    if ([view isKindOfClass:UILabel.class]) text = ((UILabel *)view).text;
    else if ([view isKindOfClass:UITextField.class]) text = ((UITextField *)view).text;
    else if ([view isKindOfClass:UITextView.class]) text = ((UITextView *)view).text;
    else if ([view isKindOfClass:UIButton.class]) text = [(UIButton *)view titleForState:UIControlStateNormal];
    if (!text.length && [view.accessibilityValue isKindOfClass:NSString.class]) text = (NSString *)view.accessibilityValue;
    if (!text.length) text = view.accessibilityLabel;
    return text ?: @"";
}

static BOOL SDSRawStringLooksDialable(NSString *raw) {
    if (!raw.length) return NO;
    NSCharacterSet *digits = NSCharacterSet.decimalDigitCharacterSet;
    NSCharacterSet *allowedFormatting = [NSCharacterSet characterSetWithCharactersInString:@" +-()./\u00a0\u202f*#"];
    BOOL hasDialChar = NO;
    for (NSUInteger i = 0; i < raw.length; i++) {
        unichar c = [raw characterAtIndex:i];
        if ([digits characterIsMember:c] || c == '*' || c == '#') { hasDialChar = YES; continue; }
        if (c == '+') { hasDialChar = YES; continue; }
        if ([allowedFormatting characterIsMember:c]) continue;
        return NO;
    }
    return hasDialChar;
}

static void SDSCollectViews(UIView *root, NSMutableArray<UIView *> *views) {
    if (!root || root.hidden || root.alpha < 0.02) return;
    [views addObject:root];
    for (UIView *child in root.subviews) SDSCollectViews(child, views);
}

static NSString *SDSControlToken(UIControl *control) {
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    if ([control isKindOfClass:UIButton.class]) {
        NSString *title = [(UIButton *)control titleForState:UIControlStateNormal];
        if (title.length) [parts addObject:title];
    }
    if (control.accessibilityLabel.length) [parts addObject:control.accessibilityLabel];
    if ([control.accessibilityValue isKindOfClass:NSString.class] && [(NSString *)control.accessibilityValue length]) [parts addObject:(NSString *)control.accessibilityValue];
    if (control.accessibilityIdentifier.length) [parts addObject:control.accessibilityIdentifier];
    return [parts componentsJoinedByString:@" "];
}

static NSString *SDSKeyForControl(UIControl *control) {
    NSString *token = [SDSControlToken(control) stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!token.length) return nil;
    NSString *lower = token.lowercaseString;
    NSArray<NSString *> *nonKeyWords = @[@"sim", @"line", @"subscription", @"cellular", @"primary", @"secondary", @"personal", @"business", @"carrier", @"account"];
    for (NSString *word in nonKeyWords) if ([lower containsString:word]) return nil;
    if ([token containsString:@"*"]) return @"*";
    if ([token containsString:@"#"]) return @"#";

    // UIKit controls often expose the same digit in both title and accessibilityLabel
    // (for example "1 1" or "2 ABC 2"). Treat repeated copies of one digit as one key,
    // but reject controls containing different digits such as badges/counters.
    NSCharacterSet *digits = NSCharacterSet.decimalDigitCharacterSet;
    unichar uniqueDigit = 0;
    BOOL foundDigit = NO;
    for (NSUInteger i = 0; i < token.length; i++) {
        unichar c = [token characterAtIndex:i];
        if (![digits characterIsMember:c]) continue;
        if (!foundDigit) { uniqueDigit = c; foundDigit = YES; }
        else if (c != uniqueDigit) return nil;
    }
    return foundDigit ? [NSString stringWithFormat:@"%C", uniqueDigit] : nil;
}

static UIWindow *SDSActiveWindow(void) {
    UIApplication *app = UIApplication.sharedApplication;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in app.connectedScenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive || ![scene isKindOfClass:UIWindowScene.class]) continue;
            for (UIWindow *window in ((UIWindowScene *)scene).windows) if (window.isKeyWindow) return window;
        }
        for (UIScene *scene in app.connectedScenes) {
            if (![scene isKindOfClass:UIWindowScene.class]) continue;
            for (UIWindow *window in ((UIWindowScene *)scene).windows) if (!window.hidden && window.alpha > 0.01) return window;
        }
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return app.keyWindow ?: app.windows.firstObject;
#pragma clang diagnostic pop
}

@interface SDSAdaptivePhoneIntegration ()
@property(nonatomic, strong) NSTimer *scanTimer;
@property(nonatomic, strong) SDSContactsService *contactsService;
@property(nonatomic, strong) SDSCallHistoryService *callHistoryService;
@property(nonatomic, strong) SDSDataIndexCoordinator *indexCoordinator;
@property(nonatomic, strong) SDSSuggestionController *suggestionController;
@property(nonatomic, strong) SDSDialerNumberSetter *numberSetter;
@property(nonatomic, strong) SDSSIMSelectorBridge *simBridge;
@property(nonatomic, weak) UIWindow *activeWindow;
@property(nonatomic, weak) UIView *keypadAnchorView;
@property(nonatomic, weak) UIView *numberDisplayView;
@property(nonatomic, copy) NSString *lastDialString;
@property(nonatomic, copy) NSString *lastConfigSignature;
@property(nonatomic) BOOL started;
@property(nonatomic) NSUInteger scanCounter;
@property(nonatomic) BOOL keypadWasPresent;
@end

@implementation SDSAdaptivePhoneIntegration

+ (instancetype)sharedIntegration {
    static SDSAdaptivePhoneIntegration *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[self alloc] init]; });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _contactsService = [[SDSContactsService alloc] init];
        _callHistoryService = [[SDSCallHistoryService alloc] init];
        _indexCoordinator = [[SDSDataIndexCoordinator alloc] initWithContactsService:_contactsService callHistoryService:_callHistoryService];
        _numberSetter = [[SDSDialerNumberSetter alloc] init];
        _simBridge = [[SDSSIMSelectorBridge alloc] init];
        __weak typeof(self) weakSelf = self;
        _suggestionController = [[SDSSuggestionController alloc] initWithSearchIndexProvider:^id{
            return weakSelf.indexCoordinator.currentIndex;
        }];
        _indexCoordinator.indexDidChangeHandler = ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            SDSPreferencesSnapshot *prefs = [SDSPreferences sharedPreferences].snapshot;
            if (prefs.enabled && prefs.smartDialEnabled && strongSelf.lastDialString.length) {
                [strongSelf.suggestionController updateDialString:strongSelf.lastDialString
                                                             useT9:prefs.t9Enabled
                                                        maxResults:(NSUInteger)prefs.maxSuggestions];
            }
        };
        _suggestionController.selectionHandler = ^(SDSSuggestion *suggestion) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf || !suggestion.displayNumber.length || !strongSelf.activeWindow) return;
            NSError *error = nil;
            BOOL ok = [strongSelf.numberSetter setCompleteNumberUsingVerifiedNativeFlow:suggestion.displayNumber host:strongSelf.activeWindow error:&error];
            if (!ok) SDSLogError(SDSLogCategoryKeypad, @"Adaptive native number fill failed safely: %@", error.localizedDescription ?: @"unknown");
        };
    }
    return self;
}

- (void)start {
    if (self.started) return;
    self.started = YES;
    [self.indexCoordinator startChangeObservation];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResign:) name:UIApplicationWillResignActiveNotification object:nil];
    [self refreshIndexIfNeededForce:YES];
    self.scanTimer = [NSTimer timerWithTimeInterval:0.30 target:self selector:@selector(scanTick:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.scanTimer forMode:NSRunLoopCommonModes];
    [self scanTick:nil];
    SDSLogInfo(SDSLogCategoryLifecycle, @"Adaptive Phone integration started");
}

- (void)stop {
    if (!self.started) return;
    self.started = NO;
    [self.scanTimer invalidate]; self.scanTimer = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.indexCoordinator stopChangeObservation];
    [self.suggestionController detach];
    [self.simBridge detach];
    self.lastDialString = nil;
    self.activeWindow = nil;
}

- (void)appDidBecomeActive:(NSNotification *)note {
    [self refreshIndexIfNeededForce:YES];
    [self scanTick:nil];
}

- (void)appWillResign:(NSNotification *)note {
    [self.suggestionController cancelPendingSearch];
    [self.suggestionController.suggestionView setHidden:YES];
}

- (NSString *)configSignatureForSnapshot:(SDSPreferencesSnapshot *)p {
    // Only data-source switches require rebuilding the in-memory index. T9, max rows and
    // SIM presentation are applied live without re-reading Contacts/Recents.
    return [NSString stringWithFormat:@"%d:%d:%d:%d", p.enabled, p.smartDialEnabled, p.contactsEnabled, p.callHistoryEnabled];
}

- (void)refreshIndexIfNeededForce:(BOOL)force {
    SDSPreferencesSnapshot *p = [SDSPreferences sharedPreferences].snapshot;
    NSString *signature = [self configSignatureForSnapshot:p];
    if (!force && [signature isEqualToString:self.lastConfigSignature]) return;
    self.lastConfigSignature = signature;
    [self.indexCoordinator refreshWithContactsEnabled:(p.enabled && p.smartDialEnabled && p.contactsEnabled)
                                    callHistoryEnabled:(p.enabled && p.smartDialEnabled && p.callHistoryEnabled)
                                         defaultRegion:@"VN"
                                            completion:nil];
}

- (void)scanTick:(NSTimer *)timer {
    if (!self.started || UIApplication.sharedApplication.applicationState != UIApplicationStateActive) return;
    SDSPreferencesSnapshot *prefs = [SDSPreferences sharedPreferences].snapshot;
    [self refreshIndexIfNeededForce:NO];
    if (!prefs.enabled) {
        [self.suggestionController detach];
        [self.simBridge restoreOriginalPresentation];
        self.lastDialString = nil;
        return;
    }

    UIWindow *window = SDSActiveWindow();
    if (!window) return;
    self.activeWindow = window;
    NSMutableArray<UIView *> *views = [NSMutableArray array];
    SDSCollectViews(window, views);

    NSMutableDictionary<NSString *, UIControl *> *keyControls = [NSMutableDictionary dictionary];
    CGFloat keypadTop = CGFLOAT_MAX;
    UIView *topmostKeyView = nil;
    for (UIView *view in views) {
        if (![view isKindOfClass:UIControl.class]) continue;
        UIControl *control = (UIControl *)view;
        CGRect f = [control convertRect:control.bounds toView:window];
        // Phone's numeric keypad lives in the lower portion of the active window and uses
        // compact controls. Reject upper controls (including SIM selectors containing digits)
        // before interpreting their accessibility/title text as keypad keys.
        if (CGRectGetMidY(f) < window.bounds.size.height * 0.30 ||
            f.size.width < 24.0 || f.size.width > 150.0 ||
            f.size.height < 24.0 || f.size.height > 120.0) continue;
        NSString *key = SDSKeyForControl(control);
        if (!key.length || keyControls[key]) continue;
        keyControls[key] = control;
        if (f.origin.y < keypadTop) { keypadTop = f.origin.y; topmostKeyView = control; }
    }

    NSUInteger digitKeys = 0;
    for (NSInteger d = 0; d <= 9; d++) if (keyControls[[NSString stringWithFormat:@"%ld", (long)d]]) digitKeys++;
    BOOL keypadPresent = digitKeys >= 8 && topmostKeyView != nil;
    if (!keypadPresent) {
        self.lastDialString = nil;
        [self.suggestionController detach];
        [self.simBridge detach];
        return;
    }

    UIView *previousKeypadAnchor = self.keypadAnchorView;
    UIView *previousDisplay = self.numberDisplayView;
    self.keypadAnchorView = topmostKeyView;
    UIView *bestDisplay = nil;
    NSString *bestDial = @"";
    NSInteger bestScore = NSIntegerMin;
    for (UIView *view in views) {
        SDSSuggestionView *suggestionView = self.suggestionController.suggestionView;
        if (view == suggestionView || [view isDescendantOfView:suggestionView]) continue;
        if (view == topmostKeyView || ([view isKindOfClass:UIControl.class] && SDSKeyForControl((UIControl *)view).length)) continue;
        BOOL supportedDisplayClass = [view isKindOfClass:UILabel.class] ||
                                     [view isKindOfClass:UITextField.class] ||
                                     [view isKindOfClass:UITextView.class];
        if (!supportedDisplayClass) continue;
        CGRect f = [view convertRect:view.bounds toView:window];
        if (CGRectGetMaxY(f) >= keypadTop - 2.0 || f.size.width < 50.0 || f.size.height < 8.0) continue;
        if (CGRectGetMinY(f) < window.safeAreaInsets.top + 8.0) continue; // avoid status-bar counters/clock
        NSString *raw = SDSVisibleTextForView(view);
        if (!SDSRawStringLooksDialable(raw)) continue;
        NSString *dial = [SDSPhoneNumberNormalizer normalizedDialableString:raw];
        if (!dial.length) continue;
        NSInteger score = (NSInteger)MIN((NSUInteger)40, dial.length * 4);
        score += (NSInteger)(f.size.width / 25.0);
        score += (NSInteger)(f.origin.y / 35.0);
        CGFloat centerDistance = fabs(CGRectGetMidX(f) - CGRectGetMidX(window.bounds));
        score += (NSInteger)MAX(0.0, 18.0 - centerDistance / 10.0);
        if ([view isKindOfClass:UILabel.class]) {
            score += 12;
            UIFont *font = ((UILabel *)view).font;
            if (font.pointSize >= 20.0) score += 16;
        } else if ([view isKindOfClass:UITextField.class]) {
            score += 12;
        }
        if (score > bestScore) { bestScore = score; bestDisplay = view; bestDial = dial; }
    }

    if (bestScore < 40) { bestDisplay = nil; bestDial = @""; }
    self.numberDisplayView = bestDisplay;
    NSString *dialString = bestDisplay ? bestDial : @"";
    if (prefs.smartDialEnabled) {
        NSLayoutYAxisAnchor *topAnchor = bestDisplay ? bestDisplay.bottomAnchor : window.safeAreaLayoutGuide.topAnchor;
        BOOL anchorsChanged = self.suggestionController.suggestionView.superview != window ||
                              previousKeypadAnchor != topmostKeyView ||
                              previousDisplay != bestDisplay;
        if (anchorsChanged) [self.suggestionController detach];
        [self.suggestionController attachToHostView:window topAnchor:topAnchor bottomAnchor:topmostKeyView.topAnchor];
        if (![dialString isEqualToString:self.lastDialString ?: @""]) {
            self.lastDialString = dialString;
            [self.suggestionController updateDialString:dialString useT9:prefs.t9Enabled maxResults:(NSUInteger)prefs.maxSuggestions];
            SDSLogInfo(SDSLogCategoryKeypad, @"Dial string changed (length=%lu)", (unsigned long)dialString.length);
        }
    } else {
        [self.suggestionController detach];
        self.lastDialString = nil;
    }

    if (prefs.compactSIMEnabled) {
        [self.simBridge discoverAndApplyInRootView:window
                                      keypadTopY:keypadTop
                                         sim1Name:prefs.sim1Name
                                         sim2Name:prefs.sim2Name];
    } else {
        [self.simBridge restoreOriginalPresentation];
    }
}

- (void)dealloc { [self stop]; }

@end
