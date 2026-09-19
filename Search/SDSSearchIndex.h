#import <Foundation/Foundation.h>
@class SDSSuggestion;
NS_ASSUME_NONNULL_BEGIN
@interface SDSSearchIndex : NSObject
@property(nonatomic, copy, readonly) NSArray<SDSSuggestion *> *records;
- (instancetype)initWithRecords:(NSArray<SDSSuggestion *> *)records;
- (NSArray<SDSSuggestion *> *)search:(NSString *)query
                           useT9:(BOOL)useT9
                            limit:(NSUInteger)limit
                    defaultRegion:(nullable NSString *)region;
@end
NS_ASSUME_NONNULL_END
