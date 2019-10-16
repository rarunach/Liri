//
//  ActivationViewController.m
//  Liri
//
//  Created by Ramani Arunachalam on 3/27/14.
//  Copyright (c) 2014 Penguin Labs. All rights reserved.
//

#import "ActivationViewController.h"
#import "Account.h"
#import "ProfileViewController.h"
#import "XMPPManager.h"
#import "AppDelegate.h"
#import "Flurry.h"
#import "PasswordViewController.h"

@interface ActivationViewController ()
@property (weak, nonatomic) IBOutlet UILabel *activationLabel;
@property (weak, nonatomic) IBOutlet UILabel *activationBottomLabel;
@property (weak, nonatomic) IBOutlet UITextField *activationField;
@property (weak, nonatomic) IBOutlet UIButton *submitBtn;
@property (weak, nonatomic) IBOutlet UIImageView *frontScreenImgView;
@end

@implementation ActivationViewController

@synthesize activationField = _activationField;
@synthesize frontScreenImgView = _frontScreenImgView;
@synthesize fromForgotPin;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.activationField.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [Flurry logEvent:@"Activation Screen"];
    if(IS_IPHONE_5) {
        //do stuff for 4 inch iPhone screen
    }
    else {
        //do stuff for 3.5 inch iPhone screen
        [self.frontScreenImgView setFrame:CGRectMake(self.frontScreenImgView.frame.origin.x, self.frontScreenImgView.frame.origin.y - 88, self.frontScreenImgView.frame.size.width, self.frontScreenImgView.frame.size.height)];
    }
    self.navigationController.navigationItem.hidesBackButton=YES;
    Account *account = [Account sharedInstance];
    
    self.activationLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.activationLabel.numberOfLines = 0;
    self.activationLabel.text = [NSString stringWithFormat:@"Enter the activation code sent to %@", account.email];
    if(fromForgotPin) {
        self.activationLabel.text = [NSString stringWithFormat:@"Enter the verification code sent to %@", account.email];
        self.activationField.placeholder = @"Verification Code";
        self.activationBottomLabel.text = @"Verification code email may take few minutes to reach you. If you do not see it in your inbox, check your spam folder for the activation code.";
    }
    
    self.activationField.borderStyle = UITextBorderStyleRoundedRect;

    self.activationField.layer.cornerRadius=8.0f;
    self.activationField.layer.masksToBounds=YES;
    self.activationField.layer.borderColor=DEFAULT_CGCOLOR;
    self.activationField.layer.borderWidth= 2.0f;
    self.activationField.keyboardAppearance = UIKeyboardAppearanceAlert;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.activationField becomeFirstResponder];

    if(fromForgotPin) {
        [self requestVerificationCode];
    } else {
        [self signup];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > 4) ? NO : YES;
}

- (void)requestVerificationCode
{
    Account *account = [Account sharedInstance];
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];

    NSLog(@"request verification code: email %@", account.email);
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
        NSString *responseMsg = [responseJSON objectForKey:@"error"];
        if(![responseMsg isEqualToString:@"Please contact us at 1-844-LIRIAPP to reset your PIN."]) {
            responseMsg = @"Unable to send verification code email. Please try again later.";
        }
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:responseMsg
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        //[self.navigationController popToRootViewControllerAnimated:YES];
        [self.navigationController popViewControllerAnimated:NO];
    };
    
    [endpoint requestVerificationCode:account.email];
}

- (void)signup
{
    Account *account = [Account sharedInstance];

    NSLog(@"signup: email %@, password %@", account.email, account.password);
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                                 sharedInstanceWithClientProtocol:
                                 @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                                     id responseJSON){
        NSString *chatPin = [responseJSON objectForKey:@"chat_pin"];
        account.chatPin = [NSNumber numberWithInteger:[chatPin integerValue]];
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        [standardUserDefaults setObject:account.chatPin forKey:@"CHAT_PIN"];
        [standardUserDefaults synchronize];

    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                                     id responseJSON){
        
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:[responseJSON objectForKey:@"error"]
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        [self.navigationController popToRootViewControllerAnimated:YES];
    };
    
    [endpoint postEmail:account.email password:account.password jid:[Account emailToJid:account.email] devicetoken:account.deviceToken];
}

- (BOOL)isConfirmationCodeValid:(NSString *)string
{
    NSUInteger maximumLength = 4;
    return  [string length] == maximumLength;
}

- (void)activate:(NSString *)code
{
    Account *account = [Account sharedInstance];
    
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                                 sharedInstanceWithClientProtocol:
                                 @protocol(APIAccessClient)] client];

    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                                          id responseJSON){
        NSString *alert = nil;
        NSString *message = [responseJSON valueForKey:@"message"];
        if ([message isEqualToString:@"Activation Success"]) {
            // Now register with XMPP
            [[XMPPManager sharedInstance] registerOrLogin];
            
            account.serverToken = [responseJSON valueForKey:@"token"];
            NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
            [standardUserDefaults setObject:account.serverToken forKey:@"SERVERTOKEN"];
            account.box_auth = false;
            account.dropbox_auth = false;
            account.google_auth = false;
            account.salesforce_auth = false;
            account.asana_auth = false;
            account.trello_auth = false;
            account.zoho_auth = false;
            account.linkedin_auth = false;
            [standardUserDefaults setBool:account.box_auth forKey:@"BOX_AUTH"];
            [standardUserDefaults setBool:account.dropbox_auth forKey:@"DROPBOX_AUTH"];
            [standardUserDefaults setBool:account.google_auth forKey:@"GOOGLE_AUTH"];
            [standardUserDefaults setBool:account.salesforce_auth forKey:@"SALESFORCE_AUTH"];
            [standardUserDefaults setBool:account.asana_auth forKey:@"ASANA_AUTH"];
            [standardUserDefaults setBool:account.trello_auth forKey:@"TRELLO_AUTH"];
            [standardUserDefaults setBool:account.zoho_auth forKey:@"ZOHO_AUTH"];
            [standardUserDefaults setBool:account.linkedin_auth forKey:@"LINKEDIN_AUTH"];
            [standardUserDefaults synchronize];
            
            ProfileViewController *profileController = [self.storyboard instantiateViewControllerWithIdentifier:@"ProfileViewController"];
            [self.navigationController pushViewController:profileController animated:YES];
        }
        self.activationField.text = nil;

        if (alert) {
            UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:alert
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            [alertView show];
        }
        [delegate hideActivityIndicator];
    };
    
    endpoint.failureJSON = ^(NSURLRequest *request,
                                          id responseJSON){
        
        self.activationField.text = nil;

        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Unable to activate, please check the code"
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        [delegate hideActivityIndicator];
    };
    
    [endpoint postActivationCode:code
                forEmail:account.email forPassword:account.password];
}

- (void)verifyCode:(NSString *)code
{
    Account *account = [Account sharedInstance];
    
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
        account.serverToken = [responseJSON valueForKey:@"token"];
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        [standardUserDefaults setObject:account.serverToken forKey:@"SERVERTOKEN"];
        [standardUserDefaults setBool:YES forKey:@"VERIFICATION_IN_PROGRESS"];
        [standardUserDefaults synchronize];
        
        PasswordViewController *passwdController = [self.storyboard instantiateViewControllerWithIdentifier:@"PasswordViewController"];
        passwdController.isForgotPinFlow = YES;
        [self.navigationController pushViewController:passwdController animated:YES];

    };
    
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        
        self.activationField.text = nil;
        
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Unable to verify, please check the code"
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        [delegate hideActivityIndicator];
    };
    
    [endpoint postVerificationCode:code forEmail:account.email];
}

- (IBAction)submitAction:(id)sender {

    [self.activationField resignFirstResponder];
    NSString *code = self.activationField.text;

    if ([self isConfirmationCodeValid:code]) {
        if(fromForgotPin) {
            [self verifyCode:code];
        } else {
            [self activate:code];
        }
    }

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
