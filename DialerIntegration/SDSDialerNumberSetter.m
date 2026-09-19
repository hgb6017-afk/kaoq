#import "SDSDialerNumberSetter.h"
#import "../Search/SDSPhoneNumberNormalizer.h"
#import "../Utilities/SDSLogger.h"
#import <UIKit/UIKit.h>

static void SDSCollectSetterViews(UIView *root, NSMutableArray<UIView *> *views) {
    if (!root || root.hidden || root.alpha < 0.02) return;
    [views addObject:root];
    for (UIView *child in root.subviews) SDSCollectSetterViews(child, views);
}

static NSString *SDSSetterControlText(UIControl *control) {
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    if ([control isKindOfClass:UIButton.class]) {
        NSString *title = [(UIButton *)control titleForState:UIControlStateNormal];
        if (title.length) [parts addObject:title];
    }
    if (control.accessibilityLabel.length) [parts addObject:control.accessibilityLabel];
    if (control.accessibilityIdentifier.length) [parts addObject:control.accessibilityIdentifier];
    return [[parts componentsJoinedByString:@" "] lowercaseString];
}

static NSString *SDSSetterKeyForControl(UIControl *control) {
    NSString *token = [SDSSetterControlText(control) stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!token.length) return nil;
    NSArray<NSString *> *nonKeyWords = @[@"sim", @"line", @"subscription", @"cellular", @"primary", @"secondary", @"personal", @"business", @"carrier", @"account"];
    for (NSString *word in nonKeyWords) if ([token containsString:word]) return nil;
    if ([token containsString:@"*"]) return @"*";
    if ([token containsString:@"#"]) return @"#";

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

static UIControl *SDSFindDeleteControl(NSArray<UIView *> *views, UIView *root) {
    NSArray<NSString *> *needles = @[@"delete", @"backspace", @"erase", @"clear", @"xóa", @"xoá", @"xoa", @"⌫"];
    for (UIView *view in views) {
        if (![view isKindOfClass:UIControl.class]) continue;
        UIControl *control = (UIControl *)view;
        CGRect f = [control convertRect:control.bounds toView:root];
        if (CGRectGetMidY(f) < root.bounds.size.height * 0.30 ||
            f.size.width < 20.0 || f.size.width > 180.0 ||
            f.size.height < 20.0 || f.size.height > 120.0) continue;
        NSString *token = SDSSetterControlText(control);
        for (NSString *needle in needles) if ([token containsString:needle]) return control;
    }
    return nil;
}

static void SDSSendControl(UIControl *control) {
    if (!control || !control.enabled) return;
    UIControlEvents events = control.allControlEvents;
    if (events & UIControlEventTouchUpInside) [control sendActionsForControlEvents:UIControlEventTouchUpInside];
    else if (events & UIControlEventTouchDown) [control sendActionsForControlEvents:UIControlEventTouchDown];
    else if (events != 0) [control sendActionsForControlEvents:events];
}

static id<UIKeyInput> SDSFindKeyInputCandidate(NSArray<UIView *> *views) {
    NSMutableArray<UIView<UIKeyInput> *> *candidates = [NSMutableArray array];
    for (UIView *view in views) {
        if ([view conformsToProtocol:@protocol(UIKeyInput)] &&
            [view respondsToSelector:@selector(insertText:)] &&
            [view respondsToSelector:@selector(deleteBackward)]) {
            if (view.isFirstResponder) return (id<UIKeyInput>)view;
            [candidates addObject:(UIView<UIKeyInput> *)view];
        }
    }
    // Do not guess between multiple visible editable views in Phone.
    return candidates.count == 1 ? candidates.firstObject : nil;
}

static BOOL SDSSetterRawStringLooksDialable(NSString *raw) {
    if (!raw.length) return NO;
    NSCharacterSet *digits = NSCharacterSet.decimalDigitCharacterSet;
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:@" +-()./\u00a0\u202f*#"];
    BOOL hasDialChar = NO;
    for (NSUInteger i = 0; i < raw.length; i++) {
        unichar c = [raw characterAtIndex:i];
        if ([digits characterIsMember:c] || c == '*' || c == '#' || c == '+') { hasDialChar = YES; continue; }
        if ([allowed characterIsMember:c]) continue;
        return NO;
    }
    return hasDialChar;
}

static NSUInteger SDSCurrentDialLength(NSArray<UIView *> *views) {
    NSUInteger best = 0;
    for (UIView *view in views) {
        if ([view isKindOfClass:UIControl.class]) continue;
        NSString *raw = nil;
        if ([view isKindOfClass:UILabel.class]) raw = ((UILabel *)view).text;
        else if ([view isKindOfClass:UITextField.class]) raw = ((UITextField *)view).text;
        else if ([view isKindOfClass:UITextView.class]) raw = ((UITextView *)view).text;
        if (!SDSSetterRawStringLooksDialable(raw)) continue;
        NSString *dial = [SDSPhoneNumberNormalizer normalizedDialableString:raw];
        best = MAX(best, dial.length);
    }
    return best;
}

@implementation SDSDialerNumberSetter

- (BOOL)supported { return YES; }

- (BOOL)setCompleteNumberUsingVerifiedNativeFlow:(NSString *)number host:(id)host error:(NSError * _Nullable * _Nullable)error {
    if (![host isKindOfClass:UIView.class] || !number.length) {
        if (error) *error = [NSError errorWithDomain:@"com.smartdialsim.dialer" code:101 userInfo:@{NSLocalizedDescriptionKey:@"Missing active Phone host or number."}];
        return NO;
    }

    UIView *root = (UIView *)host;
    NSMutableArray<UIView *> *views = [NSMutableArray array];
    SDSCollectSetterViews(root, views);
    NSString *normalized = [SDSPhoneNumberNormalizer normalizedDialableString:number];
    if (!normalized.length) {
        if (error) *error = [NSError errorWithDomain:@"com.smartdialsim.dialer" code:102 userInfo:@{NSLocalizedDescriptionKey:@"The selected suggestion has no dialable characters."}];
        return NO;
    }

    // Preferred adaptive path: if Apple's current dialer view exposes the public UIKeyInput boundary,
    // use that boundary so the Phone app remains the owner of its internal dial state.
    id<UIKeyInput> keyInput = SDSFindKeyInputCandidate(views);
    if (keyInput) {
        @try {
            NSUInteger safety = 0;
            while ([keyInput hasText] && safety++ < 64) [keyInput deleteBackward];
            [keyInput insertText:normalized];
            SDSLogInfo(SDSLogCategoryKeypad, @"Filled suggestion through UIKeyInput (length=%lu)", (unsigned long)normalized.length);
            return YES;
        } @catch (NSException *exception) {
            SDSLogInfo(SDSLogCategoryKeypad, @"UIKeyInput path unavailable; falling back to native keypad controls");
        }
    }

    NSMutableDictionary<NSString *, UIControl *> *keys = [NSMutableDictionary dictionary];
    for (UIView *view in views) {
        if (![view isKindOfClass:UIControl.class]) continue;
        UIControl *control = (UIControl *)view;
        CGRect f = [control convertRect:control.bounds toView:root];
        if (CGRectGetMidY(f) < root.bounds.size.height * 0.30 ||
            f.size.width < 24.0 || f.size.width > 150.0 ||
            f.size.height < 24.0 || f.size.height > 120.0) continue;
        NSString *key = SDSSetterKeyForControl(control);
        if (key.length && !keys[key]) keys[key] = control;
    }
    NSUInteger digitCount = 0;
    for (NSInteger d = 0; d <= 9; d++) if (keys[[NSString stringWithFormat:@"%ld", (long)d]]) digitCount++;
    if (digitCount >= 8) {
        NSString *keypadNumber = normalized;
        // A visible keypad has no direct "+" key. Only for the keypad-control fallback,
        // convert Vietnam +84 form to the equivalent national form. UIKeyInput keeps the
        // exact international form when that safer boundary is available.
        if ([keypadNumber hasPrefix:@"+84"] && keypadNumber.length > 3) {
            keypadNumber = [@"0" stringByAppendingString:[keypadNumber substringFromIndex:3]];
        }
        UIControl *deleteControl = SDSFindDeleteControl(views, root);
        if (!deleteControl) {
            if (error) *error = [NSError errorWithDomain:@"com.smartdialsim.dialer" code:104 userInfo:@{NSLocalizedDescriptionKey:@"Native keypad was found but its delete control could not be identified safely."}];
            return NO;
        }
        NSUInteger existingLength = SDSCurrentDialLength(views);
        if (existingLength == 0 || existingLength > 64) {
            if (error) *error = [NSError errorWithDomain:@"com.smartdialsim.dialer" code:105 userInfo:@{NSLocalizedDescriptionKey:@"Could not determine the current native dial string safely before replacement."}];
            return NO;
        }
        for (NSUInteger i = 0; i < existingLength; i++) SDSSendControl(deleteControl);

        BOOL canEnter = YES;
        for (NSUInteger i = 0; i < keypadNumber.length; i++) {
            NSString *key = [keypadNumber substringWithRange:NSMakeRange(i, 1)];
            UIControl *control = keys[key];
            if (!control) { canEnter = NO; break; }
            SDSSendControl(control);
        }
        if (canEnter) {
            SDSLogInfo(SDSLogCategoryKeypad, @"Filled suggestion through Apple's visible keypad controls (length=%lu)", (unsigned long)normalized.length);
            return YES;
        }
    }

    // No clipboard fallback: changing the user's pasteboard or targeting an unrelated responder
    // is not acceptable in Phone. If UIKeyInput and the visible native keypad are unavailable,
    // fail closed and let the user keep using Apple's dialer unchanged.
    if (error) *error = [NSError errorWithDomain:@"com.smartdialsim.dialer" code:103 userInfo:@{NSLocalizedDescriptionKey:@"No safe native dial-entry boundary was discoverable on this Phone build."}];
    return NO;
}
@end
