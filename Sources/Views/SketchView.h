//
//  SketchView.h
//  DoodleTop
//
//  Created by Shankar Arunachalam on 5/4/14.
//  Copyright (c) 2014 Penguin Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AnnotationTextBox.h"

enum NSAnnotationAction : NSUInteger {
    NSNone = 0,
    NSAnnotationActionFreeForm = 1,
    NSAnnotationActionText = 2,
};

@interface SketchView : UIView <UIGestureRecognizerDelegate> {
    enum NSAnnotationAction action;
    NSUInteger thickness;
    UIColor *brushColor;
}

@property (assign, nonatomic) CGPoint CurrentPoint;
@property (assign, nonatomic) CGPoint PreviousPoint;
@property (assign, nonatomic) CGPoint InitialPoint;
@property (retain, nonatomic) IBOutlet UIImageView* image;
@property (assign, nonatomic) enum NSAnnotationAction action;
@property (assign, nonatomic) NSUInteger thickness;
@property (retain, nonatomic) UIColor* brushColor;
@property (nonatomic, retain) NSUndoManager *undoManager;
@property (nonatomic, retain) UIImage *undoImage;
@property (nonatomic, retain) AnnotationTextBox *textBox;
@property (nonatomic, assign) BOOL isEditing;
@property (nonatomic, assign) BOOL didViewMoveForKeyboard;
@property (nonatomic, assign) CGFloat originalViewHeight;
@property (nonatomic, assign) CGFloat originalSketchViewHeight;
@property (nonatomic, retain) UIPanGestureRecognizer* _pgr;
@property (nonatomic, retain) UIPinchGestureRecognizer* _pinchgr;

@property (nonatomic, retain) NSString *fontName;
@property (nonatomic, assign) bool isBold;
@property (nonatomic, assign) bool isItalic;
@property (nonatomic, assign) NSTextAlignment alignment;
@property (nonatomic, assign) int screenHeight;

- (void)makeBold;
- (void)makeItalic;
- (void)setJustification:(NSTextAlignment)_alignment;
- (void)setFont:(NSString *)_fontName;
- (void)setColor:(UIColor *)_color;
- (void)setSize:(NSInteger)size;
- (void) removeObservers;

@end
