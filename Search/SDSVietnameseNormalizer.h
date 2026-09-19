#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface SDSVietnameseNormalizer : NSObject
+ (NSString *)identityKeyForNumber:(NSString *)input defaultRegion:(nullable NSString *)region;
+ (NSArray<NSString *> *)searchKeysForNumber:(NSString *)input defaultRegion:(nullable NSString *)region;
@end
NS_ASSUME_NONNULL_END
