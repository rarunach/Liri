//
//  AnnotationsViewController.m
//  Liri
//
//  Created by Shankar Arunachalam on 7/3/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "AnnotationsViewController.h"
#import "NKOViewController.h"
#import "AppConstants.h"
#import "Account.h"
#import "ARFontPickerViewController.h"
#import "Flurry.h"

@interface AnnotationsViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@end

@implementation AnnotationsViewController
@synthesize sketchView, backgroundImage, thicknessSlider, penAdjuster, penAdjusterCloser, imageNameToUpload, formatter, oldFormatterFrame, oldJustification, formattersForTypedText, imageData;
@synthesize freeformButton, textButton, shapesButton, imageButton, undoButton, redoButton, currentButton,
    fontButton, boldButton, italicsButton, justificationControl, bulletsButton, formattingDoneButton;
@synthesize scrollView = _scrollView;

#define TAG_GRAYVIEW 5671263 

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)didPressSave:(id)sender {
    imageToUpload = sketchView.image.image;
    imageData = UIImageJPEGRepresentation(imageToUpload, 0.5);
    if (!IS_IPHONE_5) {
        imageToUpload = [UIImage imageWithData:imageData scale:0.5];
    }
    imageNameToUpload = [NSString stringWithFormat:@"%@.jpg", [[NSUUID UUID] UUIDString]];
    
    Account *account = [Account sharedInstance];
    if([account.s3Manager uploadImage:imageData withName:imageNameToUpload]) {
        [self.sketchView removeObservers];
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kNewAnnotationNotification
         object:self userInfo:@{@"postedImageName": imageNameToUpload, @"postedImage": imageToUpload}];
    } else {
        [self.sketchView removeObservers];
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kNewAnnotationNotification
         object:self userInfo:nil];
    }
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.view.alpha = 1.0;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [Flurry logEvent:@"Annotations Screen"];
//    if(self.backgroundImage != nil) {
//        self.sketchView.image.image = self.backgroundImage;
//        self.sketchView.undoImage = self.backgroundImage;
//    }
    self.sketchView.image.contentMode = UIViewContentModeScaleAspectFit;
    self.sketchView.action = NSNone;
    self.sketchView.thickness = 5;
    self.oldJustification = NotJustified;
    [justificationControl setSelectedSegmentIndex:UISegmentedControlNoSegment];

    NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:@"PICKER_COLOR"];
    if(colorData != nil) {
        UIColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
        self.sketchView.brushColor = color;
    } else {
        self.sketchView.brushColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
    }

    NSString *selectedFont = [[NSUserDefaults standardUserDefaults] objectForKey:@"SELECTED_FONT"];
    if(selectedFont != nil) {
        self.sketchView.fontName = selectedFont;
    } else {
        self.sketchView.fontName = @"Helvetica Neue";
    }

    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Save"
                                                                    style:UIBarButtonItemStyleDone
                                                                   target:self
                                                                   action:@selector(didPressSave:)];
    self.navigationItem.rightBarButtonItem = rightButton;
    Account *account = [Account sharedInstance];
    undoButton.userInteractionEnabled = NO;
    redoButton.userInteractionEnabled = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setResetUndoRedoButtons) name:kAnnotationStageCompletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setFontName:) name:kFontSelectedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetFormatter:) name:kAttributesChangingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    //[self didPressFreeformButton:freeformButton];
    self.sketchView.action = NSAnnotationActionFreeForm;
    thicknessSlider.maximumValue = 10;
    thicknessSlider.minimumValue = 1;
    thicknessSlider.value = 5;
    self.sketchView.thickness = 5;
    [self applyOverlay:freeformButton];
}

- (void)viewDidLayoutSubviews
{
    if(IS_IPHONE_5) {
        //do stuff for 4 inch iPhone screen
    }
    else {
        if(self.scrollView.frame.size.width == 300) {
            double oldWidth = self.sketchView.frame.size.width;
//            double newWidth = self.sketchView.frame.size.width * 310 / 400;
            double newWidth = 300;
            [self.scrollView setFrame:CGRectMake(self.scrollView.frame.origin.x + (oldWidth - newWidth) / 2, self.scrollView.frame.origin.y, newWidth, 310)];
            [self.sketchView setFrame:CGRectMake(self.sketchView.frame.origin.x, self.sketchView.frame.origin.y, newWidth, 310)];
            [self.sketchView.image setFrame:CGRectMake(self.sketchView.image.frame.origin.x, self.sketchView.image.frame.origin.y, newWidth, 310)];
            
            [self.formatter setFrame:CGRectMake(self.formatter.frame.origin.x, 440, self.formatter.frame.size.width, self.formatter.frame.size.height)];
        }
    }
    if(self.backgroundImage != nil) {
        self.sketchView.image.image = self.backgroundImage;
        self.sketchView.undoImage = self.backgroundImage;
    }
    self.sketchView.image.contentMode = UIViewContentModeScaleAspectFit;
}

-(void)keyboardWillShow:(NSNotification*)aNotification {
    if(self.sketchView.action == NSAnnotationActionText) {
        NSDictionary* info = [aNotification userInfo];
        CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
        CGSize kbBeginSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:[info[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
        [UIView setAnimationCurve:[info[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
        [UIView setAnimationBeginsFromCurrentState:YES];
        
        if(kbBeginSize.height == kbSize.height) {
            oldFormatterFrame = self.formatter.frame;
        }

        CGRect rect = CGRectMake(self.formatter.frame.origin.x,
                                 self.view.frame.size.height - kbSize.height - self.formatter.frame.size.height,
                                 self.formatter.frame.size.width, self.formatter.frame.size.height);
        self.formatter.frame = rect;
        [UIView commitAnimations];
    }
}

- (void)updateSelectedFont:(NSString*)fontName
{
    [self.sketchView setFont:fontName];
}

-(void)keyboardWillHide:(NSNotification*)aNotification{
    self.formatter.frame = oldFormatterFrame;
}

-(void)saveFormatterSettingsIfNeeded:(NSNotification*)aNotification{
    if(self.sketchView.textBox != nil && self.sketchView.textBox.textView.selectedRange.length > 0) {
        formattersForTypedText = [[NSMutableDictionary alloc] init];
        if(self.sketchView.isBold) {
            [formattersForTypedText setObject:[NSNumber numberWithBool:YES] forKey:@"isBold"];
        } else {
            [formattersForTypedText setObject:[NSNumber numberWithBool:NO] forKey:@"isBold"];
        }
        if(self.sketchView.isItalic) {
            [formattersForTypedText setObject:[NSNumber numberWithBool:YES] forKey:@"isItalic"];
        } else {
            [formattersForTypedText setObject:[NSNumber numberWithBool:NO] forKey:@"isItalic"];
        }
        [formattersForTypedText setObject:[NSNumber numberWithInteger:self.sketchView.thickness] forKey:@"fontSize"];
        [formattersForTypedText setObject:self.sketchView.fontName forKey:@"fontName"];
        [formattersForTypedText setObject:[NSNumber numberWithInteger:self.sketchView.alignment] forKey:@"alignment"];
        NSData *backGroundColorStorage = [NSKeyedArchiver archivedDataWithRootObject:self.sketchView.brushColor];
        [formattersForTypedText setObject:backGroundColorStorage forKey:@"color"];
    } else {
        formattersForTypedText = nil;
    }
}

-(void)resetFormatter:(NSNotification*)aNotification{
    NSDictionary* newAttributes = [[aNotification userInfo] objectForKey:@"newAttributes"];
    self.sketchView.isBold = [[newAttributes objectForKey:@"isBold"] boolValue];
    self.sketchView.isItalic = [[newAttributes objectForKey:@"isItalic"] boolValue];
    self.sketchView.thickness = [[newAttributes objectForKey:@"fontSize"] integerValue];
    self.sketchView.alignment = [[newAttributes objectForKey:@"alignment"] integerValue];
    self.sketchView.fontName = [newAttributes objectForKey:@"fontName"];
    self.sketchView.brushColor = [NSKeyedUnarchiver unarchiveObjectWithData:[newAttributes objectForKey:@"color"]];
    
    if(self.sketchView.isBold) {
        [boldButton setTitleColor:[UIColor colorWithRed:51.0/255.0 green:204.0/255.0 blue:51.0/255.0 alpha:1] forState:UIControlStateNormal];
    } else {
        [boldButton setTitleColor:[UIColor colorWithRed:164.0/255.0 green:187.0/255.0 blue:164.0/255.0 alpha:1] forState:UIControlStateNormal];
    }

    if(self.sketchView.isItalic) {
        [italicsButton setTitleColor:[UIColor colorWithRed:51.0/255.0 green:204.0/255.0 blue:51.0/255.0 alpha:1] forState:UIControlStateNormal];
    } else {
        [italicsButton setTitleColor:[UIColor colorWithRed:164.0/255.0 green:187.0/255.0 blue:164.0/255.0 alpha:1] forState:UIControlStateNormal];
    }

    if(self.sketchView.alignment == NSTextAlignmentNatural)
    {
        [justificationControl setSelectedSegmentIndex:0];
    }
    else if(self.sketchView.alignment == NSTextAlignmentCenter)
    {
        [justificationControl setSelectedSegmentIndex:1];
    }
    else if(self.sketchView.alignment == NSTextAlignmentRight)
    {
        [justificationControl setSelectedSegmentIndex:2];
    }
    else {
        [justificationControl setSelectedSegmentIndex:UISegmentedControlNoSegment];
    }
    [self.thicknessSlider setValue:self.sketchView.thickness];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
}

- (void) applyOverlay:(UIButton *) button {
    if(currentButton != nil) {
        UIView *oldOverlayView = [currentButton viewWithTag:TAG_GRAYVIEW];
        [oldOverlayView removeFromSuperview];
    }

    UIView *newOverlayView = [[UIView alloc] initWithFrame:button.bounds];
    newOverlayView.backgroundColor = [UIColor colorWithRed:177.0/255.0 green:228.0/255.0 blue:177.0/255.0 alpha:0.5];
    newOverlayView.tag = TAG_GRAYVIEW;
    newOverlayView.userInteractionEnabled = YES;

    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(handleSingleTap:)];
    [newOverlayView addGestureRecognizer:singleFingerTap];
    
    [button addSubview:newOverlayView];
    currentButton = button;
    
//    if(penAdjuster.hidden == NO &&
//       (self.sketchView.action != NSAnnotationActionFreeForm && self.sketchView.action != NSAnnotationActionText)) {
//        [self hidePenAdjuster];
//    }
    
    if(formatter.hidden == NO && self.sketchView.action != NSAnnotationActionText) {
        [self hideFormatter];
    }
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    [currentButton sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (IBAction)didPressFreeformButton:(id)sender {
    self.sketchView.action = NSAnnotationActionFreeForm;
    thicknessSlider.maximumValue = 10;
    thicknessSlider.minimumValue = 1;
    thicknessSlider.value = 5;
    self.sketchView.thickness = 5;
    //[self showPenAdjuster];
    [self applyOverlay:sender];
}

- (IBAction)didPressTextButton:(id)sender {
    self.sketchView.action = NSAnnotationActionText;
    thicknessSlider.maximumValue = 24;
    thicknessSlider.minimumValue = 2;
    thicknessSlider.value = 14;
    self.sketchView.thickness = 14;
    //[self showPenAdjuster];
    [self showFormatter];
    [self applyOverlay:sender];
}

- (IBAction)didPressShapesButton:(id)sender {
    self.sketchView.action = NSNone;
    [self applyOverlay:sender];
}

- (IBAction)didPressImageButton:(id)sender {
    self.sketchView.action = NSNone;
    [self applyOverlay:sender];
}

- (IBAction)didPressUndoButton:(id)sender {
    [self.sketchView.undoManager undo];
    [self setResetUndoRedoButtons];
}

- (IBAction)didPressRedoButton:(id)sender {
    [self.sketchView.undoManager redo];
    [self setResetUndoRedoButtons];
}

- (void) setResetUndoRedoButtons {
    if([self.sketchView.undoManager canUndo]) {
        undoButton.userInteractionEnabled = YES;
        [undoButton setImage:[UIImage imageNamed:@"Undo-Icon@2x.png"] forState:UIControlStateNormal];
    } else {
        undoButton.userInteractionEnabled = NO;
        [undoButton setImage:[UIImage imageNamed:@"Undo-Icon-Gray@2x.png"] forState:UIControlStateNormal];
    }
    if([self.sketchView.undoManager canRedo]) {
        redoButton.userInteractionEnabled = YES;
        [redoButton setImage:[UIImage imageNamed:@"Redo-Icon@2x.png"] forState:UIControlStateNormal];
    } else {
        redoButton.userInteractionEnabled = NO;
        [redoButton setImage:[UIImage imageNamed:@"Redo-Icon-Gray@2x.png"] forState:UIControlStateNormal];
    }
}

- (IBAction)backAction:(id)sender {
    [self.sketchView removeObservers];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)didPressPenAdjusterCloser:(id)sender {
    [self hidePenAdjuster];
}

- (IBAction)didPressColorPicker:(id)sender {
    NKOViewController *colorPickerController = [self.storyboard instantiateViewControllerWithIdentifier:@"NKOViewController"];
    [self presentViewController:colorPickerController animated:YES completion:nil];
}

- (void)updateSelectedColor:(UIColor*)color {
    [self.sketchView setColor:color];
}

- (IBAction)thicknessSlider:(UISlider *)sender {
    [self.sketchView setSize:sender.value];
}

- (IBAction)didPressFontButton:(id)sender {
    ARFontPickerViewController *fontPickerController = [self.storyboard instantiateViewControllerWithIdentifier:@"ARFontPickerViewController"];
//    fontPickerController.view.backgroundColor = [UIColor clearColor];
    [self presentViewController:fontPickerController animated:YES completion:nil];
}

- (IBAction)didPressBoldButton:(id)sender {
    if(self.sketchView.textBox.isBold) {
        [boldButton setTitleColor:[UIColor colorWithRed:164.0/255.0 green:187.0/255.0 blue:164.0/255.0 alpha:1] forState:UIControlStateNormal];
    } else {
        [boldButton setTitleColor:[UIColor colorWithRed:51.0/255.0 green:204.0/255.0 blue:51.0/255.0 alpha:1] forState:UIControlStateNormal];
    }
    [self.sketchView makeBold];
}

- (IBAction)didPressItalicsButton:(id)sender {
    if(self.sketchView.textBox.isItalic) {
        [italicsButton setTitleColor:[UIColor colorWithRed:164.0/255.0 green:187.0/255.0 blue:164.0/255.0 alpha:1] forState:UIControlStateNormal];
    } else {
        [italicsButton setTitleColor:[UIColor colorWithRed:51.0/255.0 green:204.0/255.0 blue:51.0/255.0 alpha:1] forState:UIControlStateNormal];
    }
    [self.sketchView makeItalic];
}

- (IBAction)didSelectJustificationControl:(id)sender {
    if(justificationControl.selectedSegmentIndex == 0)
    {
        if(oldJustification == LeftJustified) {
            [justificationControl setSelectedSegmentIndex:UISegmentedControlNoSegment];
            [self setJustification:NSTextAlignmentNatural];
            oldJustification = NotJustified;
        } else {
            [self setJustification:NSTextAlignmentLeft];
            oldJustification = LeftJustified;
        }
    }
    else if(justificationControl.selectedSegmentIndex == 1)
    {
        if(oldJustification == CenterJustified) {
            [justificationControl setSelectedSegmentIndex:UISegmentedControlNoSegment];
            [self setJustification:NSTextAlignmentNatural];
            oldJustification = NotJustified;
        } else {
            [self setJustification:NSTextAlignmentCenter];
            oldJustification = CenterJustified;
        }
    }
    else if(justificationControl.selectedSegmentIndex == 2)
    {
        if(oldJustification == RightJustified) {
            [justificationControl setSelectedSegmentIndex:UISegmentedControlNoSegment];
            [self setJustification:NSTextAlignmentNatural];
            oldJustification = NotJustified;
        } else {
            [self setJustification:NSTextAlignmentRight];
            oldJustification = RightJustified;
        }
    }
}

- (void) setJustification: (NSTextAlignment) alignment {
    [self.sketchView setJustification:alignment];
}

- (IBAction)didPressBulletsButton:(id)sender {
    
}

- (void) showFormatter{
    formatter.hidden = NO;
}

- (void) hideFormatter{
    formatter.hidden = YES;
}

- (void) showPenAdjuster{
    penAdjuster.hidden = NO;
}

- (void) hidePenAdjuster{
    penAdjuster.hidden = YES;
}

@end
