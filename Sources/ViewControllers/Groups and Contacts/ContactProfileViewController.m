//
//  ContactProfileViewController.m
//  Liri
//
//  Created by Ramani Arunachalam on 8/22/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "ContactProfileViewController.h"
#import "CRNInitialsImageView.h"
#import "Flurry.h"
#import "Account.h"

@interface ContactProfileViewController ()

@property (nonatomic) Buddy *buddy;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *contactName;
@property (weak, nonatomic) IBOutlet UILabel *contactEmail;
@property (weak, nonatomic) IBOutlet UIButton *sendMessageBtn;
@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;
@end

@implementation ContactProfileViewController
@synthesize buddy;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : DEFAULT_UICOLOR}];

    [Flurry logEvent:@"Contact Profile Screen"];
    self.sendMessageBtn.layer.masksToBounds = YES;
    self.sendMessageBtn.layer.cornerRadius = 10;
    
    self.deleteBtn.layer.borderColor = [[UIColor redColor] CGColor];
    self.deleteBtn.layer.borderWidth= 2.0f;
    self.deleteBtn.layer.masksToBounds = YES;
    self.deleteBtn.layer.cornerRadius = 10;
    
    self.imageView.layer.masksToBounds = YES;
    self.imageView.layer.cornerRadius = 50;
    self.imageView.layer.borderWidth = 2;
    self.imageView.layer.borderColor = DEFAULT_CGCOLOR;
    
    // Do any additional setup after loading the view.
    if (buddy.photo) {
        self.imageView.image = buddy.photo;
    } else {
        /* CRNInitialsImageView *crnImageView = [[CRNInitialsImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        crnImageView.initialsBackgroundColor = DEFAULT_UICOLOR;
        crnImageView.initialsTextColor = [UIColor whiteColor];
        crnImageView.initialsFont = [UIFont fontWithName:@"HelveticaNeue" size:20];
        crnImageView.useCircle = FALSE;
        crnImageView.firstName = buddy.firstName;
        crnImageView.lastName = buddy.lastName;
        [crnImageView drawImage];
        self.imageView.image = crnImageView.image;*/
        self.imageView.image = [UIImage imageNamed:@"No-Photo-Icon.png"];
    }
    [self.contactName setText:buddy.displayName];
    self.contactEmail.text = buddy.email;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initWithBuddy:(Buddy *)thebuddy
{
    buddy = thebuddy;
}

- (IBAction)sendMessageAction:(id)sender {
    if (!buddy.isUser) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Unable to send message because user does not have Liri account."
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:buddy, @"buddy", nil];
    [[NSNotificationCenter defaultCenter]
        postNotificationName:kStartNew1On1DiscussionNotification
        object:self userInfo:dict];
}

- (IBAction)deleteAction:(id)sender {
    
    AppDelegate *appdelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [appdelegate showActivityIndicator];
    
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [appdelegate hideActivityIndicator];
        
        NSArray *details = responseJSON[@"details"];
        
        if (details.count == 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:responseJSON[@"message"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
        } else {
            [[NSNotificationCenter defaultCenter]
             
             postNotificationName:kDeleteContactFromListNotification
             
             object:self userInfo:@{@"deleteBuddy" : buddy}];
                        
            [self.navigationController popViewControllerAnimated:YES];
        }
        
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [appdelegate hideActivityIndicator];
    };
    
    if ([self checkCompanyContactValidation]) {
        [endpoint deleteContacts:buddy.email];
    } else {
        [appdelegate hideActivityIndicator];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Internal company contacts cannot be deleted. You can only delete external contacts." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }
}

#pragma mark - Private Methods

- (BOOL)checkCompanyContactValidation
{
    NSArray *domains = [[NSArray alloc] initWithObjects:@"gmail.com", @"yahoo.com", @"hotmail.com", @"outlook.com", @"live.com", @"aol.com", nil];
    
    NSArray* emailComponents = [buddy.email componentsSeparatedByString: @"@"];
    NSString* domain = [emailComponents objectAtIndex: 1];
    if ([domains containsObject:domain]) {
        return YES;
    } else {
        Account *account = [Account sharedInstance];
        Buddy *me = [account getMyBuddy];
        NSArray* myEmailComponents = [me.email componentsSeparatedByString: @"@"];
        NSString* myDomain = [myEmailComponents objectAtIndex: 1];
        if([domain isEqualToString:myDomain]) {
            return NO;
        } else {
            return YES;
        }
    }
}
@end
