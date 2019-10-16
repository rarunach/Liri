//
//  AddPhotoViewController.m
//  Liri
//
//  Created by Ramani Arunachalam on 5/29/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "AddPhotoViewController.h"
#import "Account.h"
#import "Flurry.h"

@interface AddPhotoViewController ()

@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;
@property (weak, nonatomic) IBOutlet UIButton *doneBtn;
@property (weak, nonatomic) IBOutlet UIImageView *photoView;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoBtn;
@property (weak, nonatomic) IBOutlet UIButton *choosePhotoBtn;
@property (weak, nonatomic) IBOutlet UIButton *deletePhotoBtn;
@property (weak, nonatomic) IBOutlet UIView *addPhotoLBView;

@end

@implementation AddPhotoViewController

@synthesize photoView;
@synthesize addPhotoLBView = _addPhotoLBView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    
    [Flurry logEvent:@"Add Photo Screen"];
    photoView.layer.cornerRadius = photoView.frame.size.width / 2;
    photoView.clipsToBounds = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews
{
    [self.addPhotoLBView setCenter:self.view.center];
}

- (IBAction)takePhotoAction:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;

    //picker.showsCameraControls = NO;
    
    //UIViewController *overlayCtlr = [self.storyboard instantiateViewControllerWithIdentifier:@"OverlayViewController"];
    //picker.cameraOverlayView = overlayCtlr.view;

	if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
	    picker.modalPresentationStyle = UIModalPresentationOverCurrentContext;
	}

    [self presentViewController:picker animated:YES completion:NULL];
}

- (IBAction)choosePhotoAction:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
    	picker.modalPresentationStyle = UIModalPresentationOverCurrentContext;
	}
    [self presentViewController:picker animated:YES completion:NULL];
}

- (IBAction)deletePhotoAction:(id)sender {
    Account *account = [Account sharedInstance];
    account.photo = nil;
    self.photoView.image = [UIImage imageNamed:@"Add-Photo-Image-with-Text-80x80.png"];
    self.deletePhotoBtn.hidden = YES;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *originalImage = info[UIImagePickerControllerEditedImage];

    CGSize destinationSize = CGSizeMake(100, 100);
    UIGraphicsBeginImageContext(destinationSize);
    [originalImage drawInRect:CGRectMake(0,0,destinationSize.width,destinationSize.height)];
    UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.photoView.image = thumbnail;
    self.deletePhotoBtn.hidden = NO;
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}


- (IBAction)cancelAction:(id)sender {
//    [self dismissViewControllerAnimated:NO completion:nil];
    [self dismissSelf];
}

- (IBAction)doneAction:(id)sender {
//    [self dismissViewControllerAnimated:NO completion:nil];
    
    
    Account *account = [Account sharedInstance];
    account.photo = self.photoView.image;
    
    [self dismissSelf];
}

- (void) dismissSelf {
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        
        [self dismissViewControllerAnimated:NO completion:nil];
        
    } else {
        
        [self dismissViewControllerAnimated:NO completion:^{
            
            [[NSNotificationCenter defaultCenter]
             
             postNotificationName:kLightBoxFinishedNotification
             
             object:self userInfo:@{@"className" : NSStringFromClass([self class])}];
            
        }];
        
    }
    
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
