#import "SDSSIMSelectorBridge.h"
#import "SDSSIMLabelProvider.h"
#import "../Utilities/SDSLogger.h"
#import <objc/runtime.h>

static const void *SDSOriginalTextKey = &SDSOriginalTextKey;
static const void *SDSOriginalHiddenKey = &SDSOriginalHiddenKey;
static const void *SDSOriginalFontKey = &SDSOriginalFontKey;
static const void *SDSOriginalAccessibilityKey = &SDSOriginalAccessibilityKey;
static const void *SDSOriginalNumberOfLinesKey = &SDSOriginalNumberOfLinesKey;
static const void *SDSOriginalAdjustsFontKey = &SDSOriginalAdjustsFontKey;

static void SDSCollectSIMViews(UIView *root, NSMutableArray<UIView *> *views) {
    if (!root || root.hidden || root.alpha < 0.02) return;
    [views addObject:root];
    for (UIView *child in root.subviews) SDSCollectSIMViews(child, views);
}

static NSString *SDSControlVisibleText(UIControl *control) {
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    if ([control isKindOfClass:UIButton.class]) {
        NSString *title = [(UIButton *)control titleForState:UIControlStateNormal];
        if (title.length) [parts addObject:title];
    }
    for (UIView *child in control.subviews) {
        if ([child isKindOfClass:UILabel.class] && ((UILabel *)child).text.length) [parts addObject:((UILabel *)child).text];
    }
    if (control.accessibilityLabel.length) [parts addObject:control.accessibilityLabel];
    return [parts componentsJoinedByString:@" "];
}

static BOOL SDSIsDialKeyControl(UIControl *control) {
    NSString *s = [SDSControlVisibleText(control) stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *lower = s.lowercaseString;
    NSArray<NSString *> *nonKeyWords = @[@"sim", @"line", @"subscription", @"cellular", @"primary", @"secondary", @"personal", @"business", @"carrier", @"account"];
    for (NSString *word in nonKeyWords) if ([lower containsString:word]) return NO;
    if ([s containsString:@"*"] || [s containsString:@"#"]) return YES;
    NSCharacterSet *digits = NSCharacterSet.decimalDigitCharacterSet;
    unichar uniqueDigit = 0;
    BOOL foundDigit = NO;
    for (NSUInteger i = 0; i < s.length; i++) {
        unichar c = [s characterAtIndex:i];
        if (![digits characterIsMember:c]) continue;
        if (!foundDigit) { uniqueDigit = c; foundDigit = YES; }
        else if (c != uniqueDigit) return NO;
    }
    return foundDigit;
}

static NSString *SDSNativeTextForControl(UIControl *control, NSString *lastAlias) {
    if ([control isKindOfClass:UIButton.class]) {
        UIButton *button = (UIButton *)control;
        NSString *current = [button titleForState:UIControlStateNormal];
        if (current.length && ![current isEqualToString:lastAlias ?: @""]) return current;
        NSString *saved = objc_getAssociatedObject(button, SDSOriginalTextKey);
        if (saved.length) return saved;
    }
    NSString *visible = SDSControlVisibleText(control);
    return visible ?: @"";
}

static NSUInteger SDSLogicalIndexForControl(UIControl *control, NSString *lastAlias) {
    if ([control isKindOfClass:UIButton.class]) {
        UIButton *button = (UIButton *)control;
        if (@available(iOS 14.0, *)) {
            NSArray<UIMenuElement *> *children = button.menu.children;
            NSMutableArray<UIAction *> *actions = [NSMutableArray array];
            for (UIMenuElement *element in children) if ([element isKindOfClass:UIAction.class]) [actions addObject:(UIAction *)element];
            if (actions.count == 2) {
                for (NSUInteger i = 0; i < actions.count; i++) {
                    if (actions[i].state == UIMenuElementStateOn) return i;
                }
                NSString *nativeTitle = SDSNativeTextForControl(control, lastAlias).lowercaseString;
                if (nativeTitle.length) {
                    for (NSUInteger i = 0; i < actions.count; i++) {
                        NSString *title = actions[i].title.lowercaseString;
                        if (title.length && ([nativeTitle isEqualToString:title] || [nativeTitle containsString:title] || [title containsString:nativeTitle])) {
                            return i;
                        }
                    }
                }
            }
        }
    }

    // Safe fallback only when Apple's own presentation explicitly identifies a logical line.
    // Do not infer SIM order from carrier name, physical/eSIM type, or observation order.
    NSString *native = SDSNativeTextForControl(control, lastAlias).lowercaseString;
    NSArray<NSString *> *firstMarkers = @[@"sim 1", @"sim1", @"primary", @"chính"];
    NSArray<NSString *> *secondMarkers = @[@"sim 2", @"sim2", @"secondary", @"phụ"];
    for (NSString *marker in firstMarkers) if ([native containsString:marker]) return 0;
    for (NSString *marker in secondMarkers) if ([native containsString:marker]) return 1;
    return NSNotFound;
}

static BOOL SDSShouldHideSIMImage(UIImageView *imageView, UIControl *control) {
    if (!imageView.image) return NO;
    CGRect f = [imageView convertRect:imageView.bounds toView:control];
    // Preserve the small trailing disclosure/chevron commonly used by Apple's selector.
    if (f.size.width <= 18.0 && f.size.height <= 24.0 && CGRectGetMidX(f) > control.bounds.size.width * 0.62) return NO;
    return YES;
}

@interface SDSSIMSelectorBridge ()
@property(nonatomic, weak) UIControl *control;
@property(nonatomic, copy) NSString *sim1Name;
@property(nonatomic, copy) NSString *sim2Name;
@property(nonatomic, copy) NSString *lastAppliedAlias;
@end

@implementation SDSSIMSelectorBridge

- (BOOL)supported { return YES; }
- (NSString *)verificationState { return @"ADAPTIVE_PRESENTATION_ONLY"; }

- (BOOL)attachToVerifiedNativeControl:(id)control {
    if (![control isKindOfClass:UIControl.class]) return NO;
    if (self.control && self.control != control) [self restoreOriginalPresentation];
    self.control = (UIControl *)control;
    return YES;
}

- (void)discoverAndApplyInRootView:(UIView *)rootView keypadTopY:(CGFloat)keypadTopY sim1Name:(NSString *)sim1Name sim2Name:(NSString *)sim2Name {
    if (!rootView) return;
    self.sim1Name = sim1Name;
    self.sim2Name = sim2Name;

    NSMutableArray<UIView *> *views = [NSMutableArray array];
    SDSCollectSIMViews(rootView, views);
    UIControl *best = nil;
    NSInteger bestScore = NSIntegerMin;
    for (UIView *view in views) {
        if (![view isKindOfClass:UIControl.class]) continue;
        UIControl *control = (UIControl *)view;
        if (SDSIsDialKeyControl(control)) continue;
        CGRect f = [control convertRect:control.bounds toView:rootView];
        if (CGRectGetMaxY(f) >= keypadTopY || f.size.width < 35.0 || f.size.height < 20.0 || f.size.height > 100.0) continue;

        NSUInteger logicalIndex = SDSLogicalIndexForControl(control, self.lastAppliedAlias);
        if (logicalIndex == NSNotFound) continue; // no reliable native mapping -> leave untouched

        NSString *className = NSStringFromClass(control.class).lowercaseString;
        NSString *visible = SDSControlVisibleText(control).lowercaseString;
        NSInteger score = 40; // already has a reliable logical-line mapping
        NSArray<NSString *> *keywords = @[@"sim", @"line", @"subscription", @"cellular", @"primary", @"secondary", @"personal", @"business", @"account"];
        for (NSString *keyword in keywords) {
            if ([className containsString:keyword]) score += 18;
            if ([visible containsString:keyword]) score += 12;
        }
        if ([control isKindOfClass:UIButton.class]) {
            UIButton *button = (UIButton *)control;
            if (@available(iOS 14.0, *)) if (button.menu.children.count >= 2) score += 50;
        }
        if (score > bestScore) { bestScore = score; best = control; }
    }

    if (!best || bestScore < 40) {
        if (self.control) [self restoreOriginalPresentation];
        self.control = nil;
        self.lastAppliedAlias = nil;
        return;
    }
    [self attachToVerifiedNativeControl:best];
    [self applyPresentationOnly];
}

- (void)applyPresentationOnly {
    UIControl *control = self.control;
    if (!control) return;

    NSUInteger logicalIndex = SDSLogicalIndexForControl(control, self.lastAppliedAlias);
    if (logicalIndex == NSNotFound) {
        [self restoreOriginalPresentation];
        return;
    }
    NSString *alias = [SDSSIMLabelProvider labelForLogicalIndex:logicalIndex customSIM1:self.sim1Name ?: @"SIM 1" customSIM2:self.sim2Name ?: @"SIM 2"];

    if (!objc_getAssociatedObject(control, SDSOriginalAccessibilityKey)) {
        objc_setAssociatedObject(control, SDSOriginalAccessibilityKey, control.accessibilityLabel ?: @"", OBJC_ASSOCIATION_COPY_NONATOMIC);
    } else if (control.accessibilityLabel.length && ![control.accessibilityLabel isEqualToString:self.lastAppliedAlias ?: @""]) {
        objc_setAssociatedObject(control, SDSOriginalAccessibilityKey, control.accessibilityLabel, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }

    if ([control isKindOfClass:UIButton.class]) {
        UIButton *button = (UIButton *)control;
        NSString *title = [button titleForState:UIControlStateNormal];
        if (title.length && ![title isEqualToString:self.lastAppliedAlias ?: @""]) {
            objc_setAssociatedObject(button, SDSOriginalTextKey, title, OBJC_ASSOCIATION_COPY_NONATOMIC);
        }
        if (title.length || objc_getAssociatedObject(button, SDSOriginalTextKey)) [button setTitle:alias forState:UIControlStateNormal];
        button.accessibilityLabel = alias;
    }

    NSMutableArray<UIView *> *views = [NSMutableArray array];
    SDSCollectSIMViews(control, views);
    BOOL changedLabel = NO;
    for (UIView *view in views) {
        if ([view isKindOfClass:UIImageView.class]) {
            UIImageView *imageView = (UIImageView *)view;
            if (!SDSShouldHideSIMImage(imageView, control)) continue;
            if (!objc_getAssociatedObject(view, SDSOriginalHiddenKey)) objc_setAssociatedObject(view, SDSOriginalHiddenKey, @(imageView.hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            imageView.hidden = YES;
        } else if ([view isKindOfClass:UILabel.class]) {
            UILabel *label = (UILabel *)view;
            if (!label.text.length && !objc_getAssociatedObject(label, SDSOriginalTextKey)) continue;
            if (label.text.length && ![label.text isEqualToString:self.lastAppliedAlias ?: @""]) {
                objc_setAssociatedObject(label, SDSOriginalTextKey, label.text, OBJC_ASSOCIATION_COPY_NONATOMIC);
            }
            if (!objc_getAssociatedObject(label, SDSOriginalAccessibilityKey)) objc_setAssociatedObject(label, SDSOriginalAccessibilityKey, label.accessibilityLabel ?: @"", OBJC_ASSOCIATION_COPY_NONATOMIC);
            if (!objc_getAssociatedObject(label, SDSOriginalHiddenKey)) objc_setAssociatedObject(label, SDSOriginalHiddenKey, @(label.hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            if (!objc_getAssociatedObject(label, SDSOriginalNumberOfLinesKey)) objc_setAssociatedObject(label, SDSOriginalNumberOfLinesKey, @(label.numberOfLines), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            if (!objc_getAssociatedObject(label, SDSOriginalAdjustsFontKey)) objc_setAssociatedObject(label, SDSOriginalAdjustsFontKey, @(label.adjustsFontForContentSizeCategory), OBJC_ASSOCIATION_RETAIN_NONATOMIC);

            if (!changedLabel) {
                if (!objc_getAssociatedObject(label, SDSOriginalFontKey) && label.font) objc_setAssociatedObject(label, SDSOriginalFontKey, label.font, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                label.text = alias;
                label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
                label.adjustsFontForContentSizeCategory = YES;
                label.numberOfLines = 1;
                label.hidden = NO;
                label.accessibilityLabel = alias;
                changedLabel = YES;
            } else {
                label.hidden = YES;
            }
        }
    }
    self.lastAppliedAlias = alias;
    SDSLogInfo(SDSLogCategorySIM, @"Applied compact SIM presentation alias %@ without changing native target/action", alias);
}

- (void)restoreOriginalPresentation {
    UIControl *control = self.control;
    if (!control) return;
    if ([control isKindOfClass:UIButton.class]) {
        NSString *title = objc_getAssociatedObject(control, SDSOriginalTextKey);
        if (title) [(UIButton *)control setTitle:title forState:UIControlStateNormal];
    }
    NSString *controlA11y = objc_getAssociatedObject(control, SDSOriginalAccessibilityKey);
    if (controlA11y) control.accessibilityLabel = controlA11y.length ? controlA11y : nil;

    NSMutableArray<UIView *> *views = [NSMutableArray array];
    SDSCollectSIMViews(control, views);
    for (UIView *view in views) {
        if ([view isKindOfClass:UIImageView.class]) {
            NSNumber *hidden = objc_getAssociatedObject(view, SDSOriginalHiddenKey);
            if (hidden) ((UIImageView *)view).hidden = hidden.boolValue;
        } else if ([view isKindOfClass:UILabel.class]) {
            UILabel *label = (UILabel *)view;
            NSString *text = objc_getAssociatedObject(label, SDSOriginalTextKey);
            UIFont *font = objc_getAssociatedObject(label, SDSOriginalFontKey);
            NSNumber *hidden = objc_getAssociatedObject(label, SDSOriginalHiddenKey);
            NSString *a11y = objc_getAssociatedObject(label, SDSOriginalAccessibilityKey);
            NSNumber *lines = objc_getAssociatedObject(label, SDSOriginalNumberOfLinesKey);
            NSNumber *adjusts = objc_getAssociatedObject(label, SDSOriginalAdjustsFontKey);
            if (text) label.text = text;
            if (font) label.font = font;
            if (hidden) label.hidden = hidden.boolValue;
            if (a11y) label.accessibilityLabel = a11y.length ? a11y : nil;
            if (lines) label.numberOfLines = lines.integerValue;
            if (adjusts) label.adjustsFontForContentSizeCategory = adjusts.boolValue;
        }
    }
    self.lastAppliedAlias = nil;
}

- (void)detach {
    [self restoreOriginalPresentation];
    self.control = nil;
    self.lastAppliedAlias = nil;
}

@end
