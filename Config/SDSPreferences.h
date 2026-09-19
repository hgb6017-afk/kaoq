#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SDSPreferencesSnapshot : NSObject <NSCopying>
@property(nonatomic, readonly) BOOL enabled;
@property(nonatomic, readonly) BOOL smartDialEnabled;
@property(nonatomic, readonly) BOOL contactsEnabled;
@property(nonatomic, readonly) BOOL callHistoryEnabled;
@property(nonatomic, readonly) BOOL t9Enabled;
@property(nonatomic, readonly) NSInteger maxSuggestions;
@property(nonatomic, readonly) BOOL compactSIMEnabled;
@property(nonatomic, copy, readonly) NSString *sim1Name;
@property(nonatomic, copy, readonly) NSString *sim2Name;

- (instancetype)initWithEnabled:(BOOL)enabled
               smartDialEnabled:(BOOL)smartDialEnabled
                contactsEnabled:(BOOL)contactsEnabled
             callHistoryEnabled:(BOOL)callHistoryEnabled
                      t9Enabled:(BOOL)t9Enabled
                 maxSuggestions:(NSInteger)maxSuggestions
              compactSIMEnabled:(BOOL)compactSIMEnabled
                       sim1Name:(NSString *)sim1Name
                       sim2Name:(NSString *)sim2Name NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface SDSPreferences : NSObject
@property(atomic, strong, readonly) SDSPreferencesSnapshot *snapshot;
+ (instancetype)sharedPreferences;
- (void)reload;
- (void)startObserving;
- (void)stopObserving;
@end

NS_ASSUME_NONNULL_END
