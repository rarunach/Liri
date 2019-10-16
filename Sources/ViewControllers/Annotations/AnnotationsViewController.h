//
//  AnnotationsViewController.h
//  Liri
//
//  Created by Shankar Arunachalam on 7/3/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "SketchView.h"
#import "S3Manager.h"
#import "CustomSegmentedControl.h"

@interface AnnotationsViewController : UIViewController {
    UIImage *backgroundImage;
    NSString *imageNameToUpload;
    UIImage *imageToUpload;
}

@property (nonatomic, retain) IBOutlet SketchView *sketchView;
@property (nonatomic, retain) IBOutlet UIButton* freeformButton;
@property (nonatomic, retain) IBOutlet UIButton* textButton;
@property (nonatomic, retain) IBOutlet UIButton* imageButton;
@property (nonatomic, retain) IBOutlet UIButton* shapesButton;
@property (nonatomic, retain) IBOutlet UIButton* undoButton;
@property (nonatomic, retain) IBOutlet UIButton* redoButton;
@property (nonatomic, retain) IBOutlet UIButton* fontButton;
@property (nonatomic, retain) IBOutlet UIButton* boldButton;
@property (nonatomic, retain) IBOutlet UIButton* italicsButton;
@property (nonatomic, retain) IBOutlet CustomSegmentedControl* justificationControl;
@property (nonatomic, retain) IBOutlet UIButton* bulletsButton;
@property (nonatomic, retain) IBOutlet UIButton* formattingDoneButton;
@property (nonatomic, retain) UIButton* currentButton;

@property (nonatomic, retain) IBOutlet UISlider* thicknessSlider;
@property (nonatomic, retain) IBOutlet UIView* penAdjuster;
@property (nonatomic, retain) IBOutlet UIView* formatter;
@property (nonatomic, retain) IBOutlet UIButton* penAdjusterCloser;
@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, strong) NSString *imageNameToUpload;
@property (nonatomic, assign) CGRect oldFormatterFrame;
@property (nonatomic, assign) TextJustification oldJustification;
@property (nonatomic, retain) NSMutableDictionary* formattersForTypedText;
@property (nonatomic, retain) NSData *imageData;

- (IBAction)didPressFreeformButton:(id)sender;
- (IBAction)didPressTextButton:(id)sender;
- (IBAction)didPressShapesButton:(id)sender;
- (IBAction)didPressUndoButton:(id)sender;
- (IBAction)didPressRedoButton:(id)sender;
- (IBAction)didPressImageButton:(id)sender;
- (IBAction)didPressPenAdjusterCloser:(id)sender;
- (IBAction)didPressColorPicker:(id)sender;
- (IBAction)thicknessSlider:(UISlider *)sender;
- (IBAction)didPressSave:(id)sender;
- (IBAction)backAction:(id)sender;
- (void)updateSelectedColor:(UIColor*)color;
- (void)updateSelectedFont:(NSString*)fontName;

- (IBAction)didPressFontButton:(id)sender;
- (IBAction)didPressBoldButton:(id)sender;
- (IBAction)didPressItalicsButton:(id)sender;
- (IBAction)didSelectJustificationControl:(id)sender;
- (IBAction)didPressBulletsButton:(id)sender;

@end
