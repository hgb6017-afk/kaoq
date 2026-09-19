#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface SDSDialerNumberSetter : NSObject
@property(nonatomic, readonly) BOOL supported;
- (BOOL)setCompleteNumberUsingVerifiedNativeFlow:(NSString *)number host:(id)host error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
