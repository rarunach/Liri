#import "NSString+Additions.h"

@implementation NSString (Additions)

#pragma mark -
#pragma mark NSString (Additions)

- (NSString *)substringForLimit:(NSUInteger)limit
{
    NSUInteger length = [self length];

    return [self substringToIndex:(length > limit ? limit : length)];
}
@end
