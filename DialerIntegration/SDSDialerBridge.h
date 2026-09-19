#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@protocol SDSDialerBridgeDelegate <NSObject>
- (void)dialerBridgeDidChangeDialString:(NSString *)dialString;
@end
@interface SDSDialerBridge : NSObject
@property(nonatomic, weak, nullable) id<SDSDialerBridgeDelegate> delegate;
@property(nonatomic, readonly) BOOL supported;
@property(nonatomic, copy, readonly) NSString *verificationState;
- (nullable NSString *)currentDialString;
- (BOOL)attachToVerifiedHostObject:(id)hostObject;
- (void)detach;
@end
NS_ASSUME_NONNULL_END
