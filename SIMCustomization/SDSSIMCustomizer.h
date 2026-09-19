#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@interface SDSSIMCustomizer : NSObject
+ (void)applyLabel:(NSString *)label toVerifiedLabelView:(UILabel *)labelView;
+ (void)hideVerifiedCarrierImageView:(nullable UIImageView *)imageView;
@end
NS_ASSUME_NONNULL_END
