//
//  TextBox.m
//  TestText
//
//  Created by Shankar Arunachalam on 8/14/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "AnnotationTextBox.h"

@implementation AnnotationTextBox
@synthesize textView, doneButton, closeButton, color, fontSize, fontName, alignment, isBold, isItalic, backedUpAttributes;

- (id)initWithFrame:(CGRect)frame andAttributes:(NSDictionary *)attributes
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor colorWithRed:236.0/255.0 green:236.0/255.0 blue:236.0/255.0 alpha:1];
        self.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        self.layer.borderWidth = 1;
        self.layer.cornerRadius = 10;
        
//        closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        [closeButton addTarget:self
//                       action:@selector(closeButtonClicked:)
//             forControlEvents:UIControlEventTouchUpInside];
//        [closeButton setImage:[UIImage imageNamed:@"Cancel-Icon@2x.png"] forState:UIControlStateNormal];
//        closeButton.frame = CGRectMake(frame.size.width - BUTTONS_HEIGHT - TEXTBOX_INNER_DOUBLE_PADDING,
//                                      TEXTBOX_INNER_PADDING,
//                                      BUTTONS_HEIGHT,
//                                      BUTTONS_HEIGHT);
//        [self addSubview:closeButton];

        closeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [closeButton addTarget:self
                       action:@selector(closeButtonClicked:)
             forControlEvents:UIControlEventTouchUpInside];
        [closeButton setTitle:@"Cancel" forState:UIControlStateNormal];
        closeButton.frame = CGRectMake(frame.size.width - DONE_BUTTON_WIDTH,
                                      TEXTBOX_INNER_PADDING,
                                      DONE_BUTTON_WIDTH - TEXTBOX_INNER_PADDING,
                                      BUTTONS_HEIGHT);
        [closeButton setTitleColor:[UIColor colorWithRed:51.0/255.0 green:204.0/255.0 blue:51.0/255.0 alpha:1] forState:UIControlStateNormal];
        [self addSubview:closeButton];

        textView = [[UITextView alloc] initWithFrame:CGRectMake(TEXTBOX_INNER_DOUBLE_PADDING,
                                                                BUTTONS_HEIGHT + TEXTBOX_INNER_DOUBLE_PADDING,
                                                                fminf(frame.size.width - (TEXTBOX_INNER_DOUBLE_PADDING * 2), TEXTBOX_MAX_WIDTH),
                                                                TEXTBOX_MIN_HEIGHT
                                                                )];

        textView.layer.cornerRadius = 5;
        backedUpAttributes = nil;
        [self setNewAttributes:attributes];
        
        [self addSubview:textView];
        [textView becomeFirstResponder];
        textView.delegate = self;

        doneButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [doneButton addTarget:self
                       action:@selector(doneButtonClicked:)
             forControlEvents:UIControlEventTouchUpInside];
        [doneButton setTitle:@"Done" forState:UIControlStateNormal];
        doneButton.frame = CGRectMake(frame.size.width - DONE_BUTTON_WIDTH,
                                      BUTTONS_HEIGHT + TEXTBOX_INNER_DOUBLE_PADDING + TEXTBOX_INNER_PADDING + textView.frame.size.height,
                                      DONE_BUTTON_WIDTH - TEXTBOX_INNER_PADDING,
                                      BUTTONS_HEIGHT);
        [doneButton setTitleColor:[UIColor colorWithRed:51.0/255.0 green:204.0/255.0 blue:51.0/255.0 alpha:1] forState:UIControlStateNormal];
        [self addSubview:doneButton];
    }
    return self;
}

-(void) closeButtonClicked:(UIButton*)sender
{
    [textView resignFirstResponder];
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kEditingCompletedNotification
     object:self userInfo:nil];
}

-(void) doneButtonClicked:(UIButton*)sender
{
    [textView resignFirstResponder];
    UIGraphicsBeginImageContextWithOptions(self.textView.frame.size, NO, 0.0);
    [self.textView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kEditingCompletedNotification
     object:self userInfo:@{@"textAsImage": image}];
}

- (void)setTextColor:(UIColor *)_color {
    color = _color;
    [self updateTextAttributes];
}

- (void)setTextSize:(NSInteger)_size {
    fontSize = _size;
    [self updateTextAttributes];
}

- (void)setFont:(NSString *)_fontName {
    fontName = _fontName;
    [self updateTextAttributes];
}

- (void)makeBold {
    isBold = !isBold;
    [self updateTextAttributes];
}

- (void)makeItalic {
    isItalic = !isItalic;
    [self updateTextAttributes];
}

- (void)setJustification:(NSTextAlignment)_alignment {
    alignment = _alignment;
    [self updateTextAttributes];
}

- (void) backupCurrentAttributes {
    NSData *colorStorage = [NSKeyedArchiver archivedDataWithRootObject:self.color];
    backedUpAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                colorStorage, @"color",
                                self.fontName, @"fontName",
                                [NSNumber numberWithInteger: self.fontSize], @"fontSize",
                                [NSNumber numberWithBool:self.isBold], @"isBold",
                                [NSNumber numberWithBool:self.isItalic], @"isItalic",
                                [NSNumber numberWithInteger:self.alignment], @"alignment",
                                nil];
}

- (void) setNewAttributes:(NSDictionary *)attributes {
    fontName = [attributes valueForKey:@"fontName"];
    fontSize = [[attributes valueForKey:@"fontSize"] integerValue];
    color = [NSKeyedUnarchiver unarchiveObjectWithData:[attributes objectForKey:@"color"]];
    isBold = [[attributes valueForKey:@"isBold"] boolValue];
    isItalic = [[attributes valueForKey:@"isItalic"] boolValue];
    alignment = [[attributes valueForKey:@"alignment"] integerValue];
    [self updateTextAttributes];
}

- (NSDictionary *) getTextAttributesForSelection {
    NSRange selectedRange = [textView selectedRange];
    
    NSDictionary *currentAttributesDict = [textView.textStorage attributesAtIndex:selectedRange.location
                                                                    effectiveRange:nil];
    
    UIColor *_color = nil;
    if ([currentAttributesDict objectForKey:NSForegroundColorAttributeName] != nil) {
        _color = [currentAttributesDict objectForKey:NSForegroundColorAttributeName];
    }
    UIFont *currentFont = [currentAttributesDict objectForKey:NSFontAttributeName];
    
    UIFontDescriptor *fontDescriptor = [currentFont fontDescriptor];
    
    NSString *fontNameAttribute = [[fontDescriptor fontAttributes] objectForKey:UIFontDescriptorNameAttribute];
    NSInteger fontSizeAttribute = [[[fontDescriptor fontAttributes] objectForKey:UIFontDescriptorSizeAttribute] integerValue];
    
    BOOL _isBold = NO;
    if ([fontNameAttribute rangeOfString:@"Bold"].location != NSNotFound) {
        _isBold = YES;
    }
    BOOL _isItalic = NO;
    if ([fontNameAttribute rangeOfString:@"Italic"].location != NSNotFound) {
        _isItalic = YES;
    }
    NSData *colorStorage = [NSKeyedArchiver archivedDataWithRootObject:self.color];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                colorStorage, @"color",
                                currentFont.familyName, @"fontName",
                                [NSNumber numberWithInteger: fontSizeAttribute], @"fontSize",
                                [NSNumber numberWithBool:_isBold], @"isBold",
                                [NSNumber numberWithBool:_isItalic], @"isItalic",
                                [NSNumber numberWithInteger:alignment], @"alignment",
                                nil];
    return attributes;
}

- (void) updateTextAttributes {
    uint32_t fontTraits = 0;
    if(isBold) {
        fontTraits |= UIFontDescriptorTraitBold;
    }
    if(isItalic) {
        fontTraits |= UIFontDescriptorTraitItalic;
    }
    
    UIFontDescriptor *fontDescriptor = [[UIFontDescriptor alloc] init];
    
    UIFontDescriptor *fontDescriptorForDefault = [fontDescriptor fontDescriptorWithFamily:self.fontName];
    UIFontDescriptor *symbolicFontDescriptor = [fontDescriptorForDefault fontDescriptorWithSymbolicTraits:fontTraits];
    
    if(symbolicFontDescriptor != nil) {
        UIFont *updatedFont = [UIFont fontWithDescriptor:symbolicFontDescriptor size:fontSize];
        
        NSMutableParagraphStyle *newParagraphStyle = [[NSMutableParagraphStyle alloc] init];
        [newParagraphStyle setAlignment:alignment];
        
        NSDictionary *updatedAttributes = @{NSFontAttributeName: updatedFont, NSParagraphStyleAttributeName: newParagraphStyle, NSForegroundColorAttributeName: color};

        NSRange selectedRange = [textView selectedRange];
        
        if(selectedRange.length > 0) {
            [textView.textStorage beginEditing];
            [textView.textStorage setAttributes:updatedAttributes range:selectedRange];
            [textView.textStorage endEditing];
        }
        textView.typingAttributes = updatedAttributes;
    }
}

- (BOOL)textView:(UITextView *)_textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return _textView.text.length + (text.length - range.length) <= 140;
}

- (void)textViewDidChangeSelection:(UITextView *)_textView {
    if(_textView.selectedRange.length > 0) {
        [self backupCurrentAttributes];
        NSDictionary *newAttributes = [self getTextAttributesForSelection];
        [self setNewAttributes:newAttributes];
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kAttributesChangingNotification
         object:self userInfo:@{@"newAttributes": newAttributes}];
    } else {
        if(backedUpAttributes != nil) {
            [self setNewAttributes:backedUpAttributes];
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kAttributesChangingNotification
             object:self userInfo:@{@"newAttributes": backedUpAttributes}];
            backedUpAttributes = nil;
        }
    }
}

- (BOOL)canDoPan:(CGPoint)translation {
    int textBoxMaxRight = TEXTBOX_MAX_RIGHT_4S;
    if(IS_IPHONE_5) {
        textBoxMaxRight = TEXTBOX_MAX_RIGHT;
    }
    if(self.frame.origin.x + translation.x > textBoxMaxRight - textView.frame.size.width - 20 ||
       self.frame.origin.x + translation.x < TEXTBOX_MIN_LEFT ||
       self.frame.origin.y + translation.y > TEXTBOX_MAX_BOTTOM - ((BUTTONS_HEIGHT * 2) + textView.frame.size.height + (TEXTBOX_INNER_DOUBLE_PADDING * 2) + TEXTBOX_INNER_PADDING + 10) ||
       self.frame.origin.y + translation.y < TEXTBOX_MIN_TOP + 30) {
        return NO;
    }
    return YES;
}

//- (void)adjustBoxPosition:(CGPoint)translation {
//    CGFloat fixedWidth = TEXTBOX_MAX_RIGHT - self.frame.origin.x - textView.frame.origin.x;
//    if(self.frame.origin.x <= TEXTBOX_MIN_LEFT) {
//        fixedWidth = textView.frame.size.width + translation.x;
//    }
//    CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
//    NSLog(@"%f", newSize.height);
//    CGRect newFrame = textView.frame;
//    newFrame.size = CGSizeMake(fminf(fmaxf(newSize.width, fixedWidth), TEXTBOX_MAX_WIDTH), newSize.height);
//    textView.frame = newFrame;
//    textView.scrollEnabled = NO;
//    CGRect viewFrame = CGRectMake(self.frame.origin.x,
//                                  self.frame.origin.y,
//                                  fminf(newFrame.size.width + TEXTBOX_INNER_DOUBLE_PADDING, TEXTBOX_MAX_WIDTH + 10),
//                                  newFrame.size.height + BUTTONS_HEIGHT + TEXTBOX_INNER_DOUBLE_PADDING + TEXTBOX_INNER_PADDING);
//    self.frame = viewFrame;
//    CGRect doneButtonFrame = CGRectMake(self.frame.size.width - DONE_BUTTON_WIDTH,
//                                        TEXTBOX_INNER_PADDING,
//                                        DONE_BUTTON_WIDTH - TEXTBOX_INNER_PADDING,
//                                        BUTTONS_HEIGHT);
//    self.doneButton.frame = doneButtonFrame;
//}

- (void)textViewDidBeginEditing:(UITextView *)_textView {
    //[self setFormatting];
}

- (void)textViewDidChange:(UITextView *)_textView
{
    CGFloat fixedWidth = _textView.frame.size.width;
    CGSize newSize = [_textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    CGRect newFrame = _textView.frame;
    newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);
    _textView.frame = newFrame;
    _textView.scrollEnabled = NO;
    CGRect viewFrame = CGRectMake(self.frame.origin.x,
                                  self.frame.origin.y,
                                  self.frame.size.width,
                                  newFrame.size.height + (BUTTONS_HEIGHT * 2) + (TEXTBOX_INNER_DOUBLE_PADDING * 2));
    self.frame = viewFrame;
    doneButton.frame = CGRectMake(self.frame.size.width - DONE_BUTTON_WIDTH,
                                  BUTTONS_HEIGHT + TEXTBOX_INNER_DOUBLE_PADDING + TEXTBOX_INNER_PADDING + textView.frame.size.height,
                                  DONE_BUTTON_WIDTH - TEXTBOX_INNER_PADDING,
                                  BUTTONS_HEIGHT);
    //[self setFormatting];
//    textView.font = self.font;
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
