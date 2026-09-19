#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface SDSContactNumber : NSObject
@property(nonatomic, copy) NSString *displayName;
@property(nonatomic, copy) NSString *phoneNumber;
@property(nonatomic, copy, nullable) NSString *phoneLabel;
- (instancetype)initWithName:(NSString *)name number:(NSString *)number label:(nullable NSString *)label;
@end
NS_ASSUME_NONNULL_END
