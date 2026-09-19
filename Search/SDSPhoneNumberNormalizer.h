#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface SDSPhoneNumberNormalizer : NSObject
+ (NSString *)normalizedDialableString:(NSString *)input;
+ (NSString *)digitsOnly:(NSString *)input;
+ (BOOL)isUSSDOrServiceCode:(NSString *)input;
+ (BOOL)isShortOrEmergencyLike:(NSString *)input;
@end
NS_ASSUME_NONNULL_END
