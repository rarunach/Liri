//
//  NKOViewController.m
//  ColorPicker-Demo
//
//  Created by Carlos Vidal Pallín on 02/03/2014.
//  Copyright (c) 2014 nakioStudio. All rights reserved.
//

#import "NKOViewController.h"
#import "NKOColorPickerView.h"
#import "AnnotationsViewController.h"
#import "Flurry.h"

@interface NKOViewController()

@property (nonatomic, weak) IBOutlet NKOColorPickerView *pickerView;
@property (nonatomic, weak) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UILabel *selectedColorLabel;

@property (weak, nonatomic) IBOutlet UIView *footerView;
@end

@implementation NKOViewController
@synthesize selectedColorLabel = _selectedColorLabel;
@synthesize footerView = _footerView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [Flurry logEvent:@"Color Picker Screen"];
    
    __weak NKOViewController *weakSelf = self;
    
    [self.pickerView setDidChangeColorBlock:^(UIColor *color){
        [weakSelf _customizeButton];
    }];
    
    NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:@"PICKER_COLOR"];
    UIColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
    self.pickerView.color = color;

    [self.pickerView setTintColor:[UIColor darkGrayColor]];
    
    [self _customizeButton];
}
- (void)viewDidLayoutSubviews
{
    if(!IS_IPHONE_5) {
        [self.pickerView setFrame:CGRectMake(self.pickerView.frame.origin.x, self.pickerView.frame.origin.y, self.pickerView.frame.size.width, 300)];
        [self.selectedColorLabel setFrame:CGRectMake(self.selectedColorLabel.frame.origin.x, 380, self.selectedColorLabel.frame.size.width, 40)];
        [self.footerView setFrame:CGRectMake(self.footerView.frame.origin.x, 420, self.footerView.frame.size.width, 60)];
        [self.button setFrame:CGRectMake(self.button.frame.origin.x, 10, self.button.frame.size.width, 40)];
    }
}
#pragma mark - Private methods
- (void)_customizeButton
{
    self.button.layer.cornerRadius = 6;
    self.button.backgroundColor = self.pickerView.color;
}

- (IBAction)_onButtonClick:(id)sender
{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSData *backGroundColorStorage = [NSKeyedArchiver archivedDataWithRootObject:self.pickerView.color];
    [standardUserDefaults setObject:backGroundColorStorage forKey:@"PICKER_COLOR"];
    [standardUserDefaults synchronize];

    AnnotationsViewController *mainController = (AnnotationsViewController *)self.presentingViewController;
    
    [self dismissViewControllerAnimated:YES completion:^{
        [mainController updateSelectedColor:self.pickerView.color];
    }];
}

@end
