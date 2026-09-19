#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface SDSSIMSelectorBridge : NSObject
@property(nonatomic, readonly) BOOL supported;
@property(nonatomic, copy, readonly) NSString *verificationState;
- (BOOL)attachToVerifiedNativeControl:(id)control;
- (void)discoverAndApplyInRootView:(UIView *)rootView
                       keypadTopY:(CGFloat)keypadTopY
                          sim1Name:(NSString *)sim1Name
                          sim2Name:(NSString *)sim2Name;
- (void)applyPresentationOnly;
- (void)restoreOriginalPresentation;
- (void)detach;
@end
NS_ASSUME_NONNULL_END
