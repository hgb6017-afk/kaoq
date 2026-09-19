#import "SDSSIMCustomizer.h"
@implementation SDSSIMCustomizer
+ (void)applyLabel:(NSString *)label toVerifiedLabelView:(UILabel *)labelView {
    if (!labelView) return;
    labelView.text = label;
    labelView.numberOfLines = 1;
    labelView.adjustsFontForContentSizeCategory = YES;
    labelView.accessibilityLabel = label;
}
+ (void)hideVerifiedCarrierImageView:(UIImageView * _Nullable)imageView { if (imageView) imageView.hidden = YES; }
@end
