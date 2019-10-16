//
//  SketchView.m
//  DoodleTop
//
//  Created by Shankar Arunachalam on 5/4/14.
//  Copyright (c) 2014 Penguin Labs. All rights reserved.
//

#import "SketchView.h"
#import <AVFoundation/AVFoundation.h>

@implementation SketchView

@synthesize CurrentPoint;
@synthesize PreviousPoint;
@synthesize InitialPoint;
@synthesize image;
@synthesize action;
@synthesize thickness;
@synthesize brushColor;
@synthesize undoManager;
@synthesize undoImage;
@synthesize _pgr, _pinchgr, textBox, isEditing;
@synthesize didViewMoveForKeyboard, originalViewHeight, originalSketchViewHeight;
@synthesize fontName, alignment, isBold, isItalic, screenHeight;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    undoManager = [[NSUndoManager alloc] init];
    [undoManager setLevelsOfUndo:20];
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        // Initialization code
    }
    
    if(IS_IPHONE_5) {
        screenHeight = 568;
    } else {
        screenHeight = 480;
    }
    undoManager = [[NSUndoManager alloc] init];
    [undoManager setLevelsOfUndo:20];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingCompleted:) name:kEditingCompletedNotification object:nil];
    
    _pgr = [[UIPanGestureRecognizer alloc]
            initWithTarget:self
            action:@selector(handlePan:)];
    _pgr.delegate = self;
    
    _pinchgr = [[UIPinchGestureRecognizer alloc]
            initWithTarget:self
            action:@selector(handlePinch:)];
    _pinchgr.delegate = self;
    
    [self addGestureRecognizer:_pinchgr];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    return self;
}

- (void) removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kEditingCompletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

-(void)keyboardWillShow:(NSNotification*)aNotification {
    NSDictionary* info = [aNotification userInfo];
    CGSize kbBeginSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    CGSize kbEndSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    if (self.superview.frame.origin.y + self.textBox.frame.origin.y + self.textBox.frame.size.height > screenHeight - kbEndSize.height - 40 - 10) //40 is the magic number for height of the formatter view and 10 for padding
    {
        if(kbEndSize.height >= kbBeginSize.height) {
            [self setViewMovedUp:YES andSize:kbEndSize];
            didViewMoveForKeyboard = YES;
        } else {
            [self setViewMovedUp:NO andSize:kbEndSize];
            didViewMoveForKeyboard = NO;
        }
    }
}

-(void)keyboardWillHide:(NSNotification*)aNotification{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    if(didViewMoveForKeyboard) {
        [self setViewMovedUp:NO andSize:kbSize];
        didViewMoveForKeyboard = NO;
    }
}

-(void)setViewMovedUp:(BOOL)movedUp andSize:(CGSize)size
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    
    CGRect rect = self.textBox.frame;
    CGRect sketchViewRect = self.frame;
    if (movedUp)
    {
        originalViewHeight = rect.origin.y;
        originalSketchViewHeight = sketchViewRect.origin.y;
        //rect.origin.y = screenHeight - size.height - self.superview.frame.origin.y - rect.size.height - 40 - 10; //40 is the magic number for height of the formatter view and 10 for padding
        //sketchViewRect.origin.y -= (originalViewHeight + rect.size.height + 10);//screenHeight - size.height - 40 - 10 - sketchViewRect.size.height;
        sketchViewRect.origin.y -= rect.origin.y + BUTTONS_HEIGHT + (2 * TEXTBOX_INNER_DOUBLE_PADDING) - (screenHeight - self.superview.frame.origin.y - size.height - 10 - rect.size.height);
    }
    else
    {
        rect.origin.y = originalViewHeight;
        sketchViewRect.origin.y  = originalSketchViewHeight;
    }
    //self.textBox.frame = rect;
    self.frame = sketchViewRect;
    
    [UIView commitAnimations];
}

- (void)editingCompleted:(NSNotification*)aNotification
{
    CGFloat left = self.textBox.frame.origin.x + TEXTBOX_INNER_PADDING;
    CGFloat top = self.textBox.frame.origin.y + BUTTONS_HEIGHT + TEXTBOX_INNER_DOUBLE_PADDING + TEXTBOX_INNER_PADDING;
    CGFloat width = self.textBox.textView.frame.size.width;
    CGFloat height = self.textBox.textView.frame.size.height;
    
    NSDictionary* info = [aNotification userInfo];
    UIImage *textAsImage = [info objectForKey:@"textAsImage"];
    
    if(textAsImage != nil) {
        UIGraphicsBeginImageContextWithOptions(image.bounds.size, NO, 0.0f);
    
        CGRect rect = AVMakeRectWithAspectRatioInsideRect(image.image.size, image.bounds);
        [image.image drawInRect:rect];
        
        [self.textBox.textView.attributedText drawInRect:CGRectMake(left, top, width, height)];
        
//        [textAsImage drawInRect:CGRectMake(left, top, width, height)];
        image.image = UIGraphicsGetImageFromCurrentImageContext();
        image.contentMode = UIViewContentModeScaleAspectFit;
        UIGraphicsEndImageContext();
        
        [self setAnnotationImage:image.image];
    }
    if(self.textBox != nil) {
        [self.textBox removeFromSuperview];
    }
    isEditing = false;
}

-(void)handlePinch:(UIPinchGestureRecognizer*)pinchgr
{
//    pinchgr.view.transform = CGAffineTransformScale(pinchgr.view.transform, pinchgr.scale, pinchgr.scale);
//    pinchgr.scale = 1;
}

-(void)handlePan:(UIPanGestureRecognizer*)pgr
{
    CGPoint center = pgr.view.center;
    CGPoint translation = [pgr translationInView:pgr.view];
    if (![self.textBox canDoPan:translation]) {
        pgr.enabled = NO;
    } else {
        center = CGPointMake(center.x + translation.x,
                             center.y + translation.y);
        pgr.view.center = center;
        [pgr setTranslation:CGPointZero inView:pgr.view];
        //[self.textBox adjustBoxPosition:translation];
    }
    if (pgr.state == UIGestureRecognizerStateCancelled) {
        pgr.enabled = YES;
    }
}

- (void)makeBold {
    if(self.textBox != nil) {
        [self.textBox makeBold];
    }
    self.isBold = !self.isBold;
}

- (void)makeItalic {
    if(self.textBox != nil) {
        [self.textBox makeItalic];
    }
    self.isItalic = !self.isItalic;
}

- (void)setJustification:(NSTextAlignment)_alignment {
    if(self.textBox != nil) {
        [self.textBox setJustification:_alignment];
    }
    self.alignment = _alignment;
}

- (void)setFont:(NSString *)_fontName {
    if(self.textBox != nil) {
        [self.textBox setFont:_fontName];
    }
    self.fontName = _fontName;
}

- (void)setColor:(UIColor *)_color {
    if(self.textBox != nil) {
        [self.textBox setTextColor:_color];
    }
    self.brushColor = _color;
}

- (void)setSize:(NSInteger)_size {
    if(self.textBox != nil) {
        [self.textBox setTextSize:_size];
    }
    self.thickness = _size;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    if(action == NSAnnotationActionFreeForm) {
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:image];
        InitialPoint = point;
    } else if(self.action == NSAnnotationActionText) {
        UITouch *touch = [touches anyObject];
        CGPoint textPoint = [touch locationInView:self.textBox.textView];
        if(textPoint.x < 0 || textPoint.y < 0 ||
           textPoint.x > self.textBox.textView.frame.size.width ||
           textPoint.y > self.textBox.textView.frame.size.height) {
            [textBox.textView resignFirstResponder];
        }
        int textBoxMaxRight = TEXTBOX_MAX_RIGHT_4S;
        if(IS_IPHONE_5) {
            textBoxMaxRight = TEXTBOX_MAX_RIGHT;
        }
        if(!self.isEditing) {
            CGPoint point = [touch locationInView:self];
            if(textBoxMaxRight - point.x < DONE_BUTTON_WIDTH) {
                point.x = textBoxMaxRight - DONE_BUTTON_WIDTH;
            }
            
            NSData *colorStorage = [NSKeyedArchiver archivedDataWithRootObject:self.brushColor];
            NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        colorStorage, @"color",
                                        self.fontName, @"fontName",
                                        [NSNumber numberWithInteger: self.thickness], @"fontSize",
                                        [NSNumber numberWithBool:self.isBold], @"isBold",
                                        [NSNumber numberWithBool:self.isItalic], @"isItalic",
                                        [NSNumber numberWithInteger:self.alignment], @"alignment",
                                        nil];
            self.textBox = [[AnnotationTextBox alloc] initWithFrame:CGRectMake(point.x - TEXTBOX_INNER_DOUBLE_PADDING,
                                                                               point.y - BUTTONS_HEIGHT - TEXTBOX_INNER_DOUBLE_PADDING,
                                                                               fminf(textBoxMaxRight - point.x, TEXTBOX_MAX_WIDTH + 10),
                                                                               (BUTTONS_HEIGHT * 2) + TEXTBOX_MIN_HEIGHT + (TEXTBOX_INNER_DOUBLE_PADDING * 2))
                                                      andAttributes:attributes];
            [self.textBox addGestureRecognizer:_pgr];
            [self addSubview:textBox];
            self.isEditing = true;
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    if(action == NSAnnotationActionFreeForm) {
        [self setAnnotationImage:image.image];
    }
}

- (void)setAnnotationImage:(UIImage *)_image {
    UIImage *currentImage = undoImage;    
    if ((_image != currentImage)) {
        [[undoManager prepareWithInvocationTarget:self]
         setAnnotationImage:currentImage];
        [undoManager setActionName:NSLocalizedString(@"Image Change", @"image undo")];
        undoImage = _image;
        image.image = _image;
    }
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kAnnotationStageCompletedNotification
     object:self userInfo:nil];
}

//When touch is moving, draw the image dynamically
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    if(action == NSAnnotationActionFreeForm) {
        UITouch *touch = [touches anyObject];
        PreviousPoint = [touch previousLocationInView:image];
        CurrentPoint = [touch locationInView:image];
        UIGraphicsBeginImageContextWithOptions(image.bounds.size, NO, 0.0f);
        CGContextRef ctx = UIGraphicsGetCurrentContext();

        CGRect rect = AVMakeRectWithAspectRatioInsideRect(image.image.size, image.bounds);
        [image.image drawInRect:rect];
        CGContextSetLineCap(ctx, kCGLineCapRound);
        CGContextSetLineWidth(ctx, thickness);
        
        CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
        [brushColor getRed:&red green:&green blue:&blue alpha:&alpha];
        CGContextSetRGBStrokeColor(ctx, red, green, blue, alpha);
        CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, PreviousPoint.x, PreviousPoint.y);
        CGContextAddLineToPoint(ctx, CurrentPoint.x, CurrentPoint.y);
        CGContextStrokePath(ctx);
        image.image = UIGraphicsGetImageFromCurrentImageContext();
        image.contentMode = UIViewContentModeScaleAspectFit;
        UIGraphicsEndImageContext();
    }
}

- (void) dealloc {
    [self removeObservers];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
