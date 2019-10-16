//
//  AddContactViewController.m
//  Liri
//
//  Created by Varun Sankar on 24/09/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "AddContactViewController.h"
#import "Account.h"


@interface AddContactViewController ()

@property (weak, nonatomic) IBOutlet UITextField *emailIdTextField;

@property (weak, nonatomic) IBOutlet UITextField *firstNameTextField;

@property (weak, nonatomic) IBOutlet UITextField *lastNameTextField;


@end

@implementation AddContactViewController

@synthesize emailIdTextField = _emailIdTextField, firstNameTextField = _firstNameTextField, lastNameTextField = _lastNameTextField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - UIView LifeCycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationItem.title = @"Add Email Address";

    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(addContactsAction:)];
    
    rightButton.tintColor = DEFAULT_UICOLOR;
    
    self.navigationItem.rightBarButtonItem = rightButton;
    
    self.emailIdTextField.layer.borderWidth = 2.0f;
    
    self.firstNameTextField.layer.borderWidth = 2.0f;
    
    self.lastNameTextField.layer.borderWidth = 2.0f;
    
    self.emailIdTextField.layer.borderColor = DEFAULT_CGCOLOR;
    
    self.firstNameTextField.layer.borderColor = DEFAULT_CGCOLOR;
    
    self.lastNameTextField.layer.borderColor = DEFAULT_CGCOLOR;
 
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : DEFAULT_UICOLOR}];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private Methods
- (BOOL)addContactValidation
{
    NSString *firstName = [self.firstNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *lastName = [self.lastNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (![Account verifyEmail:self.emailIdTextField.text]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Please enter valid email id" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];
        return NO;
    } else if (firstName.length == 0 || [firstName isEqualToString:@""]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Please enter valid first name" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];
        return NO;
    } else if (lastName.length == 0 || [lastName isEqualToString:@""]){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Please enter valid last name" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];
        return NO;
    } else {
        return YES;
    }
}

- (void)uploadContacts
{
    
    AppDelegate *appdelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [appdelegate showActivityIndicator];
    
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        
        [appdelegate hideActivityIndicator];
        
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Contact has been added."
                                  delegate:self cancelButtonTitle:@"Ok"
                                  otherButtonTitles:nil];
        [alertView setTag: KSuccessAlertTag];
        [alertView show];
        
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [appdelegate hideActivityIndicator];
        
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Unable to add contacts."
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    };
    
    
    
    NSDictionary *dict = [[NSDictionary alloc]initWithObjectsAndKeys:self.emailIdTextField.text, @"email", @"AdHoc", @"source", self.firstNameTextField.text, @"first_name", self.lastNameTextField.text, @"last_name", nil];
    
    NSArray *contactInfo = [[NSArray alloc] initWithObjects:dict, nil];
    
    [endpoint addContacts:contactInfo];
    
}

#pragma mark - UITextfield Delegate Method
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.emailIdTextField) {
        [self.firstNameTextField becomeFirstResponder];
    } else if (textField == self.firstNameTextField) {
        [self.lastNameTextField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
        [self addContactsAction:self];
    }
    return YES;
}

#pragma mark - IBAction Methods
- (IBAction)addContactsAction:(id)sender {
    
    [self.view endEditing:YES];
    
    if ([self addContactValidation]) {
        
        [self uploadContacts];
    }
}

#pragma mark - UIAlertView Delegate Methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == KSuccessAlertTag) {
        
        AppDelegate *appdelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        if (!appdelegate.tabBarController) {
            // first time import
            UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Tabs" bundle:nil];
            UITabBarController *tabBarController = [storyBoard instantiateInitialViewController];
            tabBarController.selectedIndex = CONTACTS_TAB_INDEX;
            [self.view.window setRootViewController:tabBarController];
        } else {
            [self.view.window setRootViewController:appdelegate.tabBarController];
            
            UINavigationController *navCtlr = appdelegate.tabBarController.viewControllers[1];
            appdelegate.tabBarController.selectedIndex = CONTACTS_TAB_INDEX;
            if (navCtlr.childViewControllers.count > 1) {
                NSMutableArray *navigationArray = [[NSMutableArray alloc] initWithArray: navCtlr.viewControllers];
                
                [navigationArray removeObjectAtIndex:1];  // You can pass your index here
                navCtlr.viewControllers = navigationArray;
            }
            GroupsContactsViewController *groupsCtlr = (GroupsContactsViewController *)navCtlr.childViewControllers[0];
            [groupsCtlr getAllContacts];
        }
    }
}

#pragma mark - UITouches Delegate Method
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[self view] endEditing:YES];
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
