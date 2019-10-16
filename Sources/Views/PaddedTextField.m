#import "PaddedTextField.h"

@implementation PaddedTextField

#pragma mark -
#pragma mark UITextField

- (CGRect)textRectForBounds:(CGRect)bounds
{
    if (UIEdgeInsetsEqualToEdgeInsets(self.contentInset, UIEdgeInsetsZero))
        return [super textRectForBounds:bounds];

    return CGRectMake(bounds.origin.x + contentInset.left,
        bounds.origin.y + contentInset.top,
        bounds.size.width - contentInset.right,
        bounds.size.height - contentInset.bottom);
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return [self textRectForBounds:bounds];
}

#pragma mark -
#pragma mark PaddedTextField

@synthesize contentInset;
@end
