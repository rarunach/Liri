#import <Foundation/Foundation.h>

@interface NSString (PhoneNumber)

- (NSString *)stringApplyingFormat:(NSString *)format;
- (NSString *)stringRemovingFormat:(NSString *)format;
@end
