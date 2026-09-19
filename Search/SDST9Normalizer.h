#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface SDST9Normalizer : NSObject
+ (NSString *)foldedName:(NSString *)name;
+ (NSString *)t9DigitsForName:(NSString *)name;
@end
NS_ASSUME_NONNULL_END
