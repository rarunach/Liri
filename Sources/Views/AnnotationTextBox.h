//
//  TextBox.h
//  TestText
//
//  Created by Shankar Arunachalam on 8/14/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AnnotationTextBox : UIView <UITextViewDelegate>

@property (nonatomic, retain) UITextView *textView;
@property (nonatomic, retain) UIButton *doneButton;
@property (nonatomic, retain) UIButton *closeButton;
@property (nonatomic, retain) UIColor *color;
@property (nonatomic, retain) NSString *fontName;
@property (nonatomic, assign) NSInteger fontSize;
@property (nonatomic, assign) BOOL isBold;
@property (nonatomic, assign) BOOL isItalic;
@property (nonatomic, assign) NSTextAlignment alignment;
@property (nonatomic, retain) NSDictionary *backedUpAttributes;

- (id)initWithFrame:(CGRect)frame andAttributes:(NSDictionary *)attributes;

//- (void)adjustBoxPosition:(CGPoint)point;
- (BOOL)canDoPan:(CGPoint)point;
- (void)makeBold;
- (void)makeItalic;
- (void)setJustification:(NSTextAlignment)_alignment;
- (void)setFont:(NSString *)_fontName;
- (void)setTextColor:(UIColor *)_color;
- (void)setTextSize:(NSInteger)_size;

@end
