//
//  SignupViewController.m
//  Liri
//
//  Created by Ramani Arunachalam on 3/27/14.
//  Copyright (c) 2014 Penguin Labs. All rights reserved.
//

#import "SignupViewController.h"
#import "PasswordViewController.h"
#import "Account.h"
#import <QuartzCore/QuartzCore.h>
#import "Flurry.h"
#import "WebViewController.h"

@interface SignupViewController ()
{
    BOOL isLoginFlow;
}
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UIButton *signupAction;
@property (weak, nonatomic) IBOutlet UIButton *loginAction;

@property (weak, nonatomic) IBOutlet UIImageView *frontScreenImgView;
@end

@implementation SignupViewController
@synthesize frontScreenImgView = _frontScreenImgView;


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
    
    [Flurry logEvent:@"Signup Screen"];
    
    if(IS_IPHONE_5) {
        //do stuff for 4 inch iPhone screen
    }
    else {
        //do stuff for 3.5 inch iPhone screen
        [self.frontScreenImgView setFrame:CGRectMake(self.frontScreenImgView.frame.origin.x, self.frontScreenImgView.frame.origin.y - 88, self.frontScreenImgView.frame.size.width, self.frontScreenImgView.frame.size.height)];
    }
    
    self.emailField.borderStyle = UITextBorderStyleRoundedRect;

    self.emailField.layer.cornerRadius=8.0f;
    self.emailField.layer.masksToBounds=YES;
    self.emailField.layer.borderColor=DEFAULT_CGCOLOR;
    self.emailField.layer.borderWidth= 2.0f;
    self.emailField.keyboardAppearance = UIKeyboardAppearanceAlert;
    
    isLoginFlow = NO;
	// Do any additional setup after loading the view.
    //[self.emailField becomeFirstResponder];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.hidesBackButton = YES;
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
}

- (BOOL)verifyEmailString:(NSString *)emailStr
{
    BOOL isEmailValid = [Account verifyEmail:emailStr];
    
    if (isEmailValid)
    {
        Account *account = [Account sharedInstance];
        
        // set the valid email into the Account singleton
        account.email = emailStr;
        account.jid = [Account emailToJid:account.email];
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        [standardUserDefaults setObject:emailStr forKey:@"USEREMAIL"];
        [standardUserDefaults synchronize];
        
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:emailStr
                                  message:kEmailIDCheckMessage
                                  delegate:self cancelButtonTitle:@"No"
                                  otherButtonTitles:@"Yes", nil];
        [alertView show];
        

    } else {
        self.emailField.text = nil;
    }
    
    return isEmailValid;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        self.emailField.text = nil;
    } else {
        PasswordViewController *passwdController = [self.storyboard instantiateViewControllerWithIdentifier:@"PasswordViewController"];
        if (isLoginFlow) {
            passwdController.isLoginFlow = isLoginFlow;
        }
        [self.navigationController pushViewController:passwdController animated:YES];
    }
}
- (IBAction)signupAction:(id)sender {
    
    isLoginFlow = NO;
    
    NSString *email = self.emailField.text;
    DebugLog(@"email = %@",email);

    if ([self verifyEmailString:email] == NO){
                
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:kNameInvalidAlertTitle
                                  message:kEmailInvalidAlertMessage
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (IBAction)loginAction:(id)sender {

    NSString *email = self.emailField.text;
    DebugLog(@"email = %@",email);
    isLoginFlow = YES;
    if ([self verifyEmailString:email] == NO){
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:kNameInvalidAlertTitle
                                  message:kEmailInvalidAlertMessage
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
//        PasswordViewController *passwdController = [self.storyboard instantiateViewControllerWithIdentifier:@"PasswordViewController"];
//        passwdController.isLoginFlow = YES;
//        [self.navigationController pushViewController:passwdController animated:YES];
    }
}

- (IBAction)termsPrivacyAction:(id)sender {
    UIButton *termsPrivacyBtn = (UIButton *)sender;
    NSString *url;
    NSString *title;
    if (termsPrivacyBtn.tag == 1) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:kNameInvalidAlertTitle
                                  message:@"Please visit www.liriapp.com/terms.html to review our terms of service."
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        //url = @"http://www.liriapp.com/termsandconditions.html";
        //title = @"Terms and Conditions";
    } else {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:kNameInvalidAlertTitle
                                  message:@"Please visit www.liriapp.com/privacy.html to review our privacy policy."
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        //url = @"http://www.liriapp.com/privacypolicy.html";
        //title = @"Privacy Policy";
    }
    //[[UIApplication sharedApplication] openURL:[NSURL URLWithString: url]];
    /*
    WebViewController *webViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"WebViewController"];
    
    webViewController.fullURL = url;
    webViewController.pageTitle = title;
    
    [self.navigationController pushViewController:webViewController animated:YES];
     */
}


- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[self view] endEditing:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
