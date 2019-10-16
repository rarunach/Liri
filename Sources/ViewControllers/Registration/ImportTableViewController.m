//
//  ImportTableViewController.m
//  Liri
//
//  Created by Ramani Arunachalam on 3/28/14.
//  Copyright (c) 2014 Penguin Labs. All rights reserved.
//

#import "ImportTableViewController.h"
#import "ImportSelectViewController.h"
#import "GroupsContactsViewController.h"
#import "Account.h"
#import "AuthenticationsViewController.h"
#import "AppConstants.h"
#import "Flurry.h"
#import "AddContactViewController.h"

@interface ImportTableViewController ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *skipBtn;

@end

@implementation ImportTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [Flurry logEvent:@"Import Choices Screen"];
    if (self) {
        [[self navigationController] setNavigationBarHidden:NO animated:NO];

        //auth handler
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationCompleted:) name:kAuthenticationCompletedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationFailed:) name:kAuthenticationFailedNotification object:nil];

    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [[self navigationController] setNavigationBarHidden:NO animated:NO];
}

- (void)dealloc
{

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - Private Methods
- (BOOL)isFreeUserForContacts:(NSInteger)selection
{
    if (selection == 0) {
        BOOL salesforce = [[[NSUserDefaults standardUserDefaults] objectForKey:SALESFORCE_CONFIG] boolValue];
        if (!salesforce) {
            return NO;
        }
    } else if (selection == 1) {
        BOOL zoho = [[[NSUserDefaults standardUserDefaults] objectForKey:ZOHO_CONFIG] boolValue];
        if (!zoho) {
            return NO;
        }
    }
    return YES;
}
- (IBAction)skipAction:(id)sender {
    AppDelegate *appdelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (!appdelegate.tabBarController) {
        // first time import
        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Tabs" bundle:nil];
        appdelegate.tabBarController = [storyBoard instantiateInitialViewController];
        appdelegate.tabBarController.selectedIndex = CONTACTS_TAB_INDEX;
        [self.view.window setRootViewController:appdelegate.tabBarController];
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

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0: {
                    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Import" bundle:nil];
                    ImportSelectViewController *selectController = [storyBoard instantiateViewControllerWithIdentifier:@"ImportSelectViewController"];
                    [self.navigationController pushViewController:selectController animated:YES];
                    [selectController getDeviceContacts];
                    break;
                }
                case 1: {
                    [self doAuthForSource:@"Google"];
                    break;
                }
            }
        }
            break;
        case 1: {
            switch (indexPath.row) {
                
                case 0: {
                    if (![self isFreeUserForContacts:indexPath.row]) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:FREE_USER_CONFIG_MSG delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                        [alert show];
                    } else {
                        [self doAuthForSource:@"Salesforce"];
                    }
                }
                    break;
                case 1: {
                    if (![self isFreeUserForContacts:indexPath.row]) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:FREE_USER_CONFIG_MSG delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                        [alert show];
                    } else {
                        [self doAuthForSource:@"Zoho"];
                    }
                }
                    break;
            }
        }
            break;
        case 2: {
            switch (indexPath.row) {
                case 0: {
                    AddContactViewController *addContactController = [self.storyboard instantiateViewControllerWithIdentifier:@"AddContactViewController"];
                    [self.navigationController pushViewController:addContactController animated:YES];
                }
                break;
            }
        }
        default: break;
    }

}

- (void) doAuthForSource:(NSString *)source {
    
    Account *account = [Account sharedInstance];
    if (([source isEqualToString:@"Salesforce"] && account.salesforce_auth) ||
        ([source isEqualToString:@"Google"] && account.google_auth) ||
        ([source isEqualToString:@"Zoho"] && account.zoho_auth)) {
        
        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Import" bundle:nil];
        ImportSelectViewController *selectController = [storyBoard instantiateViewControllerWithIdentifier:@"ImportSelectViewController"];
        [self.navigationController pushViewController:selectController animated:YES];
        [selectController getContactsForSource:source];

//        [[NSNotificationCenter defaultCenter]
//         postNotificationName:kAuthenticationCompletedNotification
//         object:self userInfo:@{@"externalSystem": source}];
        return;
    }
    
    // Need to do authentication
        AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [delegate showActivityIndicator];
        
        // do create
        id<APIAccessClient> endpoint =
        (id<APIAccessClient>)[[APIManager
                                     sharedInstanceWithClientProtocol:
                                     @protocol(APIAccessClient)] client];
        
        endpoint.success = ^(NSURLRequest *request,
                             id response){
            [delegate hideActivityIndicator];
            
            UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
            AuthenticationsViewController *authenticationsController = [storyBoard instantiateViewControllerWithIdentifier:@"AuthenticationsViewController"];
            authenticationsController.contentToLoad = response;
            authenticationsController.externalSystem = source;
            authenticationsController.isFromContacts = true;
            [self.navigationController pushViewController:authenticationsController animated:YES];
//            [self presentViewController:authenticationsController animated:YES completion:nil];
        };
        endpoint.failure = ^(NSURLRequest *request,
                             id response){
            [delegate hideActivityIndicator];
            UIAlertView *failureAlert = [[UIAlertView alloc]
                                         initWithTitle:@""
                                         message:[response objectForKey:@"error"]
                                         delegate:self cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil];
            [failureAlert setTag:KFailureAlertTag];
            [failureAlert show];
            
            NSLog(@"error message %@ and json %@", [response objectForKey:@"error"], response);
        };
        [endpoint getClientAuth];
}

- (void)authenticationFailed:(NSNotification*)aNotification
{
    //[self.navigationController popViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:NO completion:nil];
    NSDictionary* info = [aNotification userInfo];
    NSString *errorMessage = [NSString stringWithFormat:@"%@ authentication failed", [info objectForKey:@"externalSystem"]];
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@""
                              message: errorMessage
                              delegate:nil cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
    [alertView show];
}

- (void)authenticationCompleted:(NSNotification*)aNotification
{
    //[self.navigationController popViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:NO completion:nil];
    NSDictionary* info = [aNotification userInfo];
    Account *account = [Account sharedInstance];
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *source = [info objectForKey:@"externalSystem"];
    if ([source isEqualToString:@"Salesforce"]) {
        account.salesforce_auth = true;
        [standardUserDefaults setBool:account.salesforce_auth forKey:@"SALESFORCE_AUTH"];
    } else if ([source isEqualToString:@"Google"]) {
        account.google_auth = true;
        [standardUserDefaults setBool:account.google_auth forKey:@"GOOGLE_AUTH"];
    } else if ([source isEqualToString:@"Zoho"]) {
        account.zoho_auth = true;
        [standardUserDefaults setBool:account.zoho_auth forKey:@"ZOHO_AUTH"];
    }

    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Import" bundle:nil];
    ImportSelectViewController *selectController = [storyBoard instantiateViewControllerWithIdentifier:@"ImportSelectViewController"];
    [self.navigationController pushViewController:selectController animated:YES];
    [selectController getContactsForSource:source];

}

@end
