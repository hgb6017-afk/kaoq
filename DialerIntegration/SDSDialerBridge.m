#import "SDSDialerBridge.h"
#import "../Search/SDSPhoneNumberNormalizer.h"
#import <UIKit/UIKit.h>

@interface SDSDialerBridge ()
@property(nonatomic, weak) UIView *hostView;
@end

@implementation SDSDialerBridge
- (BOOL)supported { return YES; }
- (NSString *)verificationState { return @"ADAPTIVE_UI_SCAN_ACTIVE"; }
- (NSString * _Nullable)currentDialString {
    if (!self.hostView) return nil;
    NSMutableArray<UIView *> *stack = [NSMutableArray arrayWithObject:self.hostView];
    NSString *best = nil;
    while (stack.count) {
        UIView *view = stack.lastObject; [stack removeLastObject];
        [stack addObjectsFromArray:view.subviews];
        NSString *raw = nil;
        if ([view isKindOfClass:UILabel.class]) raw = ((UILabel *)view).text;
        else if ([view isKindOfClass:UITextField.class]) raw = ((UITextField *)view).text;
        if (!raw.length) continue;
        NSString *n = [SDSPhoneNumberNormalizer normalizedDialableString:raw];
        if (n.length > best.length) best = n;
    }
    return best;
}
- (BOOL)attachToVerifiedHostObject:(id)hostObject {
    if (![hostObject isKindOfClass:UIView.class]) return NO;
    self.hostView = hostObject;
    return YES;
}
- (void)detach { self.hostView = nil; }
@end
