//
//  ProfileViewController.m
//  Liri
//
//  Created by Ramani Arunachalam on 5/20/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "ProfileViewController.h"
#import "Account.h"
#import "ImportTableViewController.h"
#import "AppDelegate.h"
#import "Flurry.h"
#import "AddPhotoViewController.h"


@interface ProfileViewController ()
{
    BOOL keyboardShown;
    CGSize keyboardSize;
}
@property (weak, nonatomic) IBOutlet UIButton *addphotoBtn;
@property (weak, nonatomic) IBOutlet UITextField *firstnameField;
@property (weak, nonatomic) IBOutlet UITextField *lastnameField;
@property (weak, nonatomic) IBOutlet UITextField *jobtitleField;
@property (weak, nonatomic) IBOutlet UITextField *mobileField;
@property (weak, nonatomic) IBOutlet UIButton *submitBtn;
@property (weak, nonatomic) IBOutlet UIButton *laterBtn;

@end

@implementation ProfileViewController

@synthesize firstnameField, lastnameField, jobtitleField, mobileField;
@synthesize addphotoBtn;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lightBoxFinished:) name:kLightBoxFinishedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    [Flurry logEvent:@"Profile Screen"];
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    
    firstnameField.layer.cornerRadius=8.0f;
    firstnameField.layer.masksToBounds=YES;
    firstnameField.layer.borderColor=DEFAULT_CGCOLOR;
    firstnameField.layer.borderWidth= 2.0f;
    firstnameField.keyboardAppearance = UIKeyboardAppearanceAlert;
    
    lastnameField.layer.cornerRadius=8.0f;
    lastnameField.layer.masksToBounds=YES;
    lastnameField.layer.borderColor=DEFAULT_CGCOLOR;
    lastnameField.layer.borderWidth= 2.0f;
    lastnameField.keyboardAppearance = UIKeyboardAppearanceAlert;

    jobtitleField.layer.cornerRadius=8.0f;
    jobtitleField.layer.masksToBounds=YES;
    jobtitleField.layer.borderColor=DEFAULT_CGCOLOR;
    jobtitleField.layer.borderWidth= 2.0f;
    jobtitleField.keyboardAppearance = UIKeyboardAppearanceAlert;
    
    mobileField.layer.cornerRadius=8.0f;
    mobileField.layer.masksToBounds=YES;
    mobileField.layer.borderColor=DEFAULT_CGCOLOR;
    mobileField.layer.borderWidth= 2.0f;
    mobileField.keyboardAppearance = UIKeyboardAppearanceAlert;
    
    keyboardShown = NO;
    
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [UIView animateWithDuration:1.0 animations:^(void) {
        self.view.alpha = 1.0;
    }];
    
    Account *account = [Account sharedInstance];
    if (account.photo) {
        [addphotoBtn setBackgroundImage:account.photo forState:UIControlStateNormal];
        addphotoBtn.layer.cornerRadius = addphotoBtn.frame.size.width / 2;
        addphotoBtn.clipsToBounds = YES;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)addphotoAction:(id)sender {
    [UIView animateWithDuration:0.5 animations:^(void) {
        self.view.alpha = 0.5;
    }];
    
    AddPhotoViewController *photoCtlr = [self.storyboard instantiateViewControllerWithIdentifier:@"AddPhotoViewController"];
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
    } else {
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        photoCtlr.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    }
    [photoCtlr.view setBackgroundColor:[UIColor clearColor]];
    [self presentViewController:photoCtlr animated:YES completion:nil];
}

- (IBAction)submitAction:(id)sender {

    if (([firstnameField.text isEqualToString:@""]) || ([lastnameField.text isEqualToString:@""])) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Firstname and Lastname are required."
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    Account *account = [Account sharedInstance];
    account.firstName = firstnameField.text;
    account.lastName = lastnameField.text;
    
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                                 sharedInstanceWithClientProtocol:
                                 @protocol(APIAccessClient)] client];
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];

    endpoint.success = ^(NSURLRequest *request,
                                     id responseJSON){
        
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        
        [standardUserDefaults setObject:account.firstName forKey:@"FIRSTNAME"];
        [standardUserDefaults setObject:account.lastName forKey:@"LASTNAME"];
        NSData* imageData = UIImagePNGRepresentation(account.photo);
        [standardUserDefaults setObject:imageData forKey:@"PHOTO"];

        [standardUserDefaults synchronize];
        
        [delegate hideActivityIndicator];
        
        [account getConfiguration:YES];
        
        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Import" bundle:nil];
        UIViewController *viewController = [storyBoard instantiateInitialViewController];
        [self.view.window setRootViewController:viewController];
        
    };
    endpoint.failure = ^(NSURLRequest *request,
                                         id responseJSON){
        
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:[responseJSON objectForKey:@"error"]
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        [delegate hideActivityIndicator];
    };
    

    [endpoint addProfile:firstnameField.text lastname:lastnameField.text photo:account.photo jobtitle:jobtitleField.text mobilenumber:mobileField.text];
    
}

- (IBAction)laterAction:(id)sender {
    //This token is needed for all further API calls
    Account *account = [Account sharedInstance];
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setObject:account.serverToken forKey:@"SERVERTOKEN"];
    [standardUserDefaults synchronize];
    
//    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Import" bundle:nil];
//
//    ImportTableViewController *importController = [storyBoard instantiateViewControllerWithIdentifier:@"ImportTableViewController"];
//    [self.navigationController pushViewController:importController animated:YES];
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Import" bundle:nil];
    UIViewController *viewController = [storyBoard instantiateInitialViewController];
    [self.view.window setRootViewController:viewController];
}

- (void) lightBoxFinished:(NSNotification*)aNotification {
    
    NSDictionary *info = [aNotification userInfo];
    if ([info[@"className"] isEqualToString:@"AddPhotoViewController"]){
        [UIView animateWithDuration:0.3 animations:^(void) {
            
            self.view.alpha = 1.0;
            
        }];
        
        Account *account = [Account sharedInstance];
        if (account.photo) {
            [addphotoBtn setBackgroundImage:account.photo forState:UIControlStateNormal];
            addphotoBtn.layer.cornerRadius = addphotoBtn.frame.size.width / 2;
            addphotoBtn.clipsToBounds = YES;
        }
    }
    
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[self view] endEditing:YES];
}


- (void)keyboardWasShown:(NSNotification*)aNotification
{
    if (!keyboardShown) {
        
        keyboardShown = YES;
        
        NSDictionary* info = [aNotification userInfo];
        CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
        keyboardSize = kbSize;
        [UIView animateWithDuration:0.2f animations:^{
            
            CGRect frame = self.view.frame;
            frame.origin.y -= (kbSize.height - 80);
            self.view.frame = frame;
            
        }];
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    keyboardShown = NO;
    
//    NSDictionary* info = [aNotification userInfo];
//    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    [UIView animateWithDuration:0.2f animations:^{
        
        CGRect frame = self.view.frame;
        frame.origin.y += (keyboardSize.height - 80);
        self.view.frame = frame;

    }];
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
