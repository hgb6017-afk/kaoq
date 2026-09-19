#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface SDSSIMLabelProvider : NSObject
+ (NSString *)sanitizedLabel:(nullable NSString *)input fallback:(NSString *)fallback;
+ (NSString *)labelForLogicalIndex:(NSUInteger)index customSIM1:(nullable NSString *)sim1 customSIM2:(nullable NSString *)sim2;
@end
NS_ASSUME_NONNULL_END
