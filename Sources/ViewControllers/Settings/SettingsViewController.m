//
//  SettingsViewController.m
//  Liri
//
//  Created by Varun Sankar on 25/08/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "SettingsViewController.h"
#import "MyProfileViewController.h"
#import "UserStatusTableViewController.h"
#import "FileAndContactViewController.h"
#import "WebViewController.h"
#import "Flurry.h"

@interface SettingsViewController ()
{
    NSString *version;
}
- (IBAction)profileBtnAction:(id)sender;
- (IBAction)sourceBtnAction:(id)sender;
- (IBAction)helpBtnAcion:(id)sender;
- (IBAction)availabilityBtnAction:(id)sender;
- (IBAction)contactsBtnAction:(id)sender;
- (IBAction)categoriesBtnAction:(id)sender;
- (IBAction)feedbackBtnAction:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *liriVersionLbl;
@end

@implementation SettingsViewController
@synthesize liriVersionLbl = _liriVersionLbl;

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
    [Flurry logEvent:@"Settings Screen"];
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : DEFAULT_UICOLOR}];
    
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    version = [info objectForKey:@"CFBundleShortVersionString"];
    [self.liriVersionLbl setText:[NSString stringWithFormat:@"Liri version %@", version]];
}

- (void)viewDidAppear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = NO;
    
}

- (void)viewDidLayoutSubviews
{
    if(!IS_IPHONE_5) {
        //do stuff for 3.5 inch iPhone screen
        [self.liriVersionLbl setFrame:CGRectMake(self.liriVersionLbl.frame.origin.x, 407, self.liriVersionLbl.frame.size.width, self.liriVersionLbl.frame.size.height)];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (IBAction)profileBtnAction:(id)sender {
    self.tabBarController.tabBar.hidden = YES;
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Settings" bundle:nil];
    MyProfileViewController *profCtlr = [storyBoard instantiateViewControllerWithIdentifier:@"MyProfileViewController"];
    [self.navigationController pushViewController:profCtlr animated:YES];
}

- (IBAction)sourceBtnAction:(id)sender {
    self.tabBarController.tabBar.hidden = YES;
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Settings" bundle:nil];
    FileAndContactViewController *fileCtlr = [storyBoard instantiateViewControllerWithIdentifier:@"FileAndContactViewController"];
    [self.navigationController pushViewController:fileCtlr animated:YES];
}

- (IBAction)helpBtnAcion:(id)sender {
    //self.tabBarController.tabBar.hidden = YES;
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:kNameInvalidAlertTitle
                              message:@"Please visit www.liriapp.com/faq.html to review our frequently asked questions."
                              delegate:nil cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
    [alertView show];
    
    //NSString *helpURL = @"http://www.liriapp.com/frequently-asked-questions.html";
    //[[UIApplication sharedApplication] openURL:[NSURL URLWithString: url]];
    
    /*
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    
 
    WebViewController *webViewController = [storyBoard instantiateViewControllerWithIdentifier:@"WebViewController"];
    
    webViewController.fullURL = @"http://www.liriapp.com/frequently-asked-questions.html";
    webViewController.pageTitle = @"Help";
     */
    
    //[self.navigationController pushViewController:webViewController animated:YES];
}

- (IBAction)availabilityBtnAction:(id)sender {

    self.tabBarController.tabBar.hidden = YES;
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Settings" bundle:nil];
    UserStatusTableViewController *statusCtlr = [storyBoard instantiateViewControllerWithIdentifier:@"UserStatusTableViewController"];
    [self.navigationController pushViewController:statusCtlr animated:YES];
}

- (IBAction)contactsBtnAction:(id)sender {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Import" bundle:nil];
    UIViewController *viewController = [storyBoard instantiateInitialViewController];
    [self.view.window setRootViewController:viewController];
    self.tabBarController.tabBar.hidden = YES;
}

- (IBAction)categoriesBtnAction:(id)sender {
}

- (IBAction)feedbackBtnAction:(id)sender {
    
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailComposer =
        [[MFMailComposeViewController alloc] init];
        
        [mailComposer setToRecipients:[NSArray arrayWithObjects:@"feedback@liriapp.com", nil]];
        [mailComposer setSubject:[NSString stringWithFormat:@"Feedback on Liri app version %@", version]];
        
        [mailComposer setMessageBody:@""
                              isHTML:YES];
        mailComposer.mailComposeDelegate = self;
        [self presentViewController:mailComposer animated:YES completion:nil];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Unable to send feedback, please add an email account to Mail app."
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }

}

#pragma mark MFMailComposeViewControllerDelegate

-(void)mailComposeController:(MFMailComposeViewController *)controller
         didFinishWithResult:(MFMailComposeResult)result
                       error:(NSError *)error{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
