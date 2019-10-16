//
//  PasswordViewController.m
//  Liri
//
//  Created by Ramani Arunachalam on 4/7/14.
//  Copyright (c) 2014 Penguin Labs. All rights reserved.
//

#import "PasswordViewController.h"
#import "XMPPManager.h"
#import "ActivationViewController.h"
#import "Account.h"
#import "AppDelegate.h"
#import "S3Manager.h"
#import "Flurry.h"

@interface PasswordViewController ()
{
    UIAlertView *alertView;
}
@property (weak, nonatomic) IBOutlet UILabel *pinLabel;
@property (weak, nonatomic) IBOutlet UITextField *pinField;

@property (weak, nonatomic) IBOutlet UIButton *submitBtn;
@property (weak, nonatomic) IBOutlet UIButton *forgotPinBtn;
@property (weak, nonatomic) IBOutlet UIImageView *frontScreenImgView;

@property (nonatomic) NSNumber *pin;

@end

@implementation PasswordViewController
@synthesize pinLabel, pinField, submitBtn, pin, forgotPinBtn;
@synthesize isLoginFlow = _isLoginFlow;
@synthesize frontScreenImgView = _frontScreenImgView;
@synthesize isForgotPinFlow;

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
    [Flurry logEvent:@"Password Screen"];
    
    if(IS_IPHONE_5) {
        //do stuff for 4 inch iPhone screen
    }
    else {
        //do stuff for 3.5 inch iPhone screen
        [self.frontScreenImgView setFrame:CGRectMake(self.frontScreenImgView.frame.origin.x, self.frontScreenImgView.frame.origin.y - 88, self.frontScreenImgView.frame.size.width, self.frontScreenImgView.frame.size.height)];
    }
    pinField.borderStyle = UITextBorderStyleRoundedRect;

    pinField.layer.cornerRadius=8.0f;
    pinField.layer.masksToBounds=YES;
    pinField.layer.borderColor=DEFAULT_CGCOLOR;
    pinField.layer.borderWidth= 2.0f;
    pinField.keyboardAppearance = UIKeyboardAppearanceAlert;
    pinField.secureTextEntry = YES;
    self.navigationItem.hidesBackButton = YES;
    
    if (self.isLoginFlow) {
        
        pinLabel.text = @"";
        forgotPinBtn.hidden = NO;
        
        self.title = @"Enter Liri PIN";
        
        [self.navigationController.navigationBar
         setTitleTextAttributes:@{NSForegroundColorAttributeName : DEFAULT_UICOLOR}];
        
        self.navigationItem.hidesBackButton = NO;
        
        [[self navigationController] setNavigationBarHidden:NO animated:YES];
    }
    
    if(self.isForgotPinFlow) {
        self.title = @"PIN Reset";
    }

    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [pinField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)verifyPIN:(NSNumber *)givenpin
{
    //BOOL isValid = [Account verifyPassword:passwd];
    BOOL isValid = YES;
    if (isValid)
    {
        Account *account = [Account sharedInstance];
        account.password = givenpin;
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        [standardUserDefaults setObject:account.password forKey:@"USERPASS"];
        [standardUserDefaults synchronize];
    }
    else {
        pinField.text = nil;
    }
    
    return isValid;
}

- (IBAction)submitAction:(id)sender {

    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *givenpin = [f numberFromString:self.pinField.text];
    if ([self verifyPIN:givenpin]) {
        
        if (self.isLoginFlow) {
            [self signIn];
        } else if(self.isForgotPinFlow) {
            if (!pin) {
                pin = givenpin;
                pinLabel.text = @"Confirm PIN";
                pinField.text = nil;
            } else {
                if (![pin isEqualToNumber:givenpin]) {
                    pin = nil;
                    pinLabel.text = @"Create Liri PIN";
                    pinField.text = nil;
                    UIAlertView *alertView = [[UIAlertView alloc]
                                              initWithTitle:@""
                                              message:@"PIN values don't match"
                                              delegate:nil cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
                    [alertView show];
                } else {
                    [self resetPin:self.pinField.text];
                }
            }
        } else {
            if (!pin) {
                pin = givenpin;
                pinLabel.text = @"Confirm PIN";
                pinField.text = nil;
            } else {
                if (![pin isEqualToNumber:givenpin]) {
                    pin = nil;
                    pinLabel.text = @"Create Liri PIN";
                    pinField.text = nil;
                    UIAlertView *alertView = [[UIAlertView alloc]
                                              initWithTitle:@""
                                              message:@"PIN values don't match"
                                              delegate:nil cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
                    [alertView show];
                    
                } else {
                    ActivationViewController *actController = [self.storyboard instantiateViewControllerWithIdentifier:@"ActivationViewController"];
                    [self.navigationController pushViewController:actController animated:YES];
                }
            }
        }
    } else {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Please provide a 4 digit PIN"
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        pinField.text = nil;
    }
}

- (void)populateCompanyContacts
{
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    Account *account = [Account sharedInstance];
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        NSArray *dictArray = (NSArray *)responseJSON;
        for (int i = 0; i < [dictArray count]; i++)
        {
            NSString *name = [NSString stringWithFormat:@"%@ %@", [dictArray[i] objectForKey:@"first_name"],
                              [dictArray[i] objectForKey:@"last_name"]];
            NSString *email = [dictArray[i] objectForKey:@"email"];
            NSString *profile_pic = [dictArray[i] objectForKey:@"profile_pic"];
            
            Buddy *buddy = [account.buddyList findBuddyForEmail:email];
            if (buddy == nil) {
                
                UIImage *buddyphoto = [account.s3Manager downloadImage:profile_pic];
                
                NSLog(@"Adding new buddy for %@!", email);
                buddy = [Buddy buddyWithDisplayName:name email:email photo:buddyphoto isUser:YES];
                [account.buddyList addBuddy:buddy];
            }

        }
        // Also store an entry for myself
        BOOL isMyBuddyExist = NO;
        for (Buddy *myBuddy in account.buddyList.allBuddies) {
            if ([myBuddy.email isEqualToString:[account getMyBuddy].email]) {
                isMyBuddyExist = YES;
                break;
            }
        }
        if (!isMyBuddyExist) {
            [account.buddyList addBuddy:[account getMyBuddy]];
        }
        [account.buddyList saveBuddiesToUserDefaults];
        
        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Tabs" bundle:nil];
        //        UITabBarController *tabBarController = [storyBoard instantiateInitialViewController];
        delegate.tabBarController = [storyBoard instantiateInitialViewController];
        
        delegate.tabBarController.selectedIndex = DISCUSSIONS_TAB_INDEX;
        [self.view.window setRootViewController:delegate.tabBarController];
        
        [account getUserCategoriesCount];
        
        [delegate hideActivityIndicator];
        [alertView dismissWithClickedButtonIndex:0 animated:YES];


    };
        endpoint.failureJSON = ^(NSURLRequest *request,
                                 id responseJSON){
            [delegate hideActivityIndicator];
    };
        
    [endpoint getCompanyContacts];

}

- (void)populateContacts
{
    alertView = [[UIAlertView alloc]
                              initWithTitle:@""
                              message:@"Retrieving your account info, please wait..."
                              delegate:nil cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
    [alertView show];
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    Account *account = [Account sharedInstance];

    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        NSArray *dictArray = (NSArray *)[responseJSON objectForKey:@"data"];
        
        for (int i = 0; i < [dictArray count]; i++)
        {
            NSString *name = [NSString stringWithFormat:@"%@ %@", [dictArray[i] objectForKey:@"first_name"],
                              [dictArray[i] objectForKey:@"last_name"]];
            NSString *email = [dictArray[i] objectForKey:@"email"];
            NSNumber *is_liri_user = [dictArray[i] objectForKey:@"is_liri_user"];
            NSString *profile_pic = [dictArray[i] objectForKey:@"profile_pic"];
            
            Buddy *buddy = [account.buddyList findBuddyForEmail:email];
            if (buddy == nil) {
                
                UIImage *buddyphoto = [account.s3Manager downloadImage:profile_pic];
                
                NSLog(@"Adding new buddy for %@!", email);
                buddy = [Buddy buddyWithDisplayName:name email:email photo:buddyphoto isUser:[is_liri_user boolValue]];
                [account.buddyList addBuddy:buddy];
            }
        }
        [self populateCompanyContacts];
        [delegate hideActivityIndicator];
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                                 id responseJSON){
            [delegate hideActivityIndicator];
            
    };
        
    [endpoint getContacts];
}

- (void)resetPin:(NSString *)newPin
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    Account *account = [Account sharedInstance];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"PIN Updated successfully. Please login again with the new PIN."
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];

        PasswordViewController *passwdController = [self.storyboard instantiateViewControllerWithIdentifier:@"PasswordViewController"];
        passwdController.isLoginFlow = YES;
        [self.navigationController pushViewController:passwdController animated:YES];
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"PIN Update failed. Please try again."
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    };
    
    [endpoint updatePin:newPin];
}

- (void)signIn
{
    Account *account = [Account sharedInstance];
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    NSLog(@"Login: email %@, password %@", account.email, account.password);
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                                 sharedInstanceWithClientProtocol:
                                 @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                                         id responseJSON){
        [delegate hideActivityIndicator];
        NSDictionary *userDictionary = [responseJSON valueForKey:@"user"];
        account.serverToken = [userDictionary valueForKey:@"token"];
        account.chatPin = [userDictionary valueForKey:@"chat_pin"];
        account.firstName = [userDictionary valueForKey:@"firstname"];
        account.lastName = [userDictionary valueForKey:@"lastname"];
        
        account.box_auth = [[userDictionary valueForKey:@"box_auth"] integerValue] == 1;
        account.dropbox_auth = [[userDictionary valueForKey:@"dropbox_auth"] integerValue] == 1;
        account.google_auth = [[userDictionary valueForKey:@"google_auth"] integerValue] == 1;
        account.salesforce_auth = [[userDictionary valueForKey:@"salesforce_auth"] integerValue] == 1;
        account.asana_auth = [[userDictionary valueForKey:@"asana_auth"] integerValue] == 1;
        account.trello_auth = [[userDictionary valueForKey:@"trello_auth"] integerValue] == 1;
        account.zoho_auth = [[userDictionary valueForKey:@"zoho_auth"] integerValue] == 1;
        account.linkedin_auth = [[userDictionary valueForKey:@"linkedin_auth"] integerValue] == 1;

        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        [standardUserDefaults setObject:account.serverToken forKey:@"SERVERTOKEN"];
        [standardUserDefaults setObject:account.firstName forKey:@"FIRSTNAME"];
        [standardUserDefaults setObject:account.lastName forKey:@"LASTNAME"];
        [standardUserDefaults setBool:account.box_auth forKey:@"BOX_AUTH"];
        [standardUserDefaults setBool:account.dropbox_auth forKey:@"DROPBOX_AUTH"];
        [standardUserDefaults setBool:account.google_auth forKey:@"GOOGLE_AUTH"];
        [standardUserDefaults setBool:account.salesforce_auth forKey:@"SALESFORCE_AUTH"];
        [standardUserDefaults setBool:account.asana_auth forKey:@"ASANA_AUTH"];
        [standardUserDefaults setBool:account.trello_auth forKey:@"TRELLO_AUTH"];
        [standardUserDefaults setBool:account.zoho_auth forKey:@"ZOHO_AUTH"];
        [standardUserDefaults setBool:account.linkedin_auth forKey:@"LINKEDIN_AUTH"];
        [standardUserDefaults setObject:account.chatPin forKey:@"CHAT_PIN"];
        [standardUserDefaults setObject:@"YES" forKey:@"XMPP_REG_DONE"];
        [standardUserDefaults setBool:NO forKey:@"VERIFICATION_IN_PROGRESS"];

        if([userDictionary valueForKey:@"external_task_preference"] != nil) {
            [standardUserDefaults setObject:[userDictionary valueForKey:@"external_task_preference"] forKey:@"TASK_PREFERENCE_SOURCE"];
            [standardUserDefaults setObject:[[userDictionary valueForKey:@"external_task_details"] valueForKey:@"task_level1"] forKey:@"TASK_PREFERENCE_LEVEL1"];
            [standardUserDefaults setObject:[[userDictionary valueForKey:@"external_task_details"] valueForKey:@"task_level2"] forKey:@"TASK_PREFERENCE_LEVEL2"];
        }

        //[[XMPPManager sharedInstance] registerOrLogin];
        
        account.photo = [account.s3Manager downloadImage:[userDictionary valueForKey:@"profile_pic"]];
        if(account.photo != nil) {
            NSData* imageData = UIImagePNGRepresentation(account.photo);
            [standardUserDefaults setObject:imageData forKey:@"PHOTO"];
        }

        [standardUserDefaults synchronize];
        
        [account getConfiguration:NO];
        [self populateContacts];
        
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                                         id responseJSON){
        [delegate hideActivityIndicator];
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Incorrect email id or PIN"
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    };
    
    [endpoint login:account.email andPassword:account.password];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[self view] endEditing:YES];
}

- (IBAction)forgotPinAction:(id)sender {
    ActivationViewController *actController = [self.storyboard instantiateViewControllerWithIdentifier:@"ActivationViewController"];
    actController.fromForgotPin = YES;
    [self.navigationController pushViewController:actController animated:YES];
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
