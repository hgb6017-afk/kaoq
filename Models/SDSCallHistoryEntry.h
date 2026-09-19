#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface SDSCallHistoryEntry : NSObject
@property(nonatomic, copy) NSString *phoneNumber;
@property(nonatomic, strong, nullable) NSDate *lastInteractionDate;
@property(nonatomic) NSUInteger interactionCount;
@property(nonatomic, copy, nullable) NSString *callKind;
- (instancetype)initWithNumber:(NSString *)number
                          date:(nullable NSDate *)date
                         count:(NSUInteger)count
                          kind:(nullable NSString *)kind;
@end
NS_ASSUME_NONNULL_END
