//
//  SourceInfoTableTableViewController.m
//  Liri
//
//  Created by Varun Sankar on 03/09/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "SourceInfoTableTableViewController.h"
#import "Account.h"
#import "AuthenticationsViewController.h"
#import "FolderBrowserController.h"
#import "Flurry.h"

@interface SourceInfoTableTableViewController ()
{
    AuthenticationsViewController *authenticationsController;
}
@property (weak, nonatomic) IBOutlet UIImageView *sourceImgView;
@property (weak, nonatomic) IBOutlet UILabel *sourceLbl;
@property (weak, nonatomic) IBOutlet UIView *removeAccView;
@property (weak, nonatomic) IBOutlet UIButton *removeAccBtn;

- (IBAction)removeAccBtnAction:(id)sender;

@end

@implementation SourceInfoTableTableViewController

@synthesize sourceImgView = _sourceImgView;

@synthesize sourceLbl = _sourceLbl;

@synthesize sourceImg = _sourceImg;

@synthesize sourceTxt = _sourceTxt;

@synthesize isAccountAvailable = _isAccountAvailable;

@synthesize removeAccView = _removeAccView;

@synthesize removeAccBtn = _removeAccBtn;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [Flurry logEvent:@"Source Info Screen"];
    
    self.title = @"Source Information";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationCompleted:)
                                                 name:kAuthenticationCompletedNotificationFromSetting object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationFailed:) name:kAuthenticationFailedNotificationFromSetting object:nil];

    self.sourceImgView.image = self.sourceImg;
    
    self.sourceLbl.text = self.sourceTxt;
    
    [self configureRemoveSource];
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : DEFAULT_UICOLOR}];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) configureRemoveSource
{
    if (self.isAccountAvailable) {
        [self.removeAccView setHidden:NO];
        [self.removeAccBtn setTitle:[NSString stringWithFormat:@"Remove Liri's Access to %@", self.sourceTxt] forState:UIControlStateNormal];
    } else {
        [self.removeAccView setHidden:YES];
//        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    }
}

- (void) showFolderBrowserRoot: (NSString *) externalSystem {

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
            
            [self externalAuthenticationTriggered:response andExtSys:externalSystem];
            
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


- (void)externalAuthenticationTriggered:(NSString *)content andExtSys:(NSString *)extSys
{
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    authenticationsController = [storyBoard instantiateViewControllerWithIdentifier:@"AuthenticationsViewController"];
    
    if(content != nil || extSys != nil) {
        authenticationsController.contentToLoad = content;
        authenticationsController.externalSystem = extSys;
        authenticationsController.isFromSetting = YES;
    }
    [self presentViewController:authenticationsController animated:YES completion:nil];
}

- (void)authenticationCompleted:(NSNotification*)aNotification
{
    [authenticationsController dismissViewControllerAnimated:YES completion:nil];
    NSDictionary* info = [aNotification userInfo];
    Account *account = [Account sharedInstance];
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSString *externalSystem = [info objectForKey:@"externalSystem"];
    
    if([externalSystem isEqualToString:@"Box"]) {
        account.box_auth = true;
        [standardUserDefaults setBool:account.box_auth forKey:@"BOX_AUTH"];
    }
    else if([externalSystem isEqualToString:@"Dropbox"]) {
        account.dropbox_auth = true;
        [standardUserDefaults setBool:account.dropbox_auth forKey:@"DROPBOX_AUTH"];
    }
    else if([externalSystem isEqualToString:@"Google"]) {
        account.google_auth = true;
        [standardUserDefaults setBool:account.google_auth forKey:@"GOOGLE_AUTH"];
    } else if ([externalSystem isEqualToString:@"Salesforce"]) {
        account.salesforce_auth = true;
        [standardUserDefaults setBool:account.salesforce_auth forKey:@"SALESFORCE_AUTH"];
    } else if ([externalSystem isEqualToString:@"Zoho"]) {
        account.zoho_auth = true;
        [standardUserDefaults setBool:account.zoho_auth forKey:@"ZOHO_AUTH"];
    } else if ([externalSystem isEqualToString:@"Asana"]) {
        account.asana_auth = true;
        [standardUserDefaults setBool:account.asana_auth forKey:@"ASANA_AUTH"];
    } else if ([externalSystem isEqualToString:@"Trello"]) {
        account.trello_auth = true;
        [standardUserDefaults setBool:account.trello_auth forKey:@"TRELLO_AUTH"];
    }
    self.isAccountAvailable = YES;
    [self configureRemoveSource];
    [self.tableView reloadData];
}

- (void)authenticationFailed:(NSNotification*)aNotification
{
    [authenticationsController dismissViewControllerAnimated:NO completion:nil];
    NSDictionary* info = [aNotification userInfo];
    NSString *errorMessage = [NSString stringWithFormat:@"%@ authentication failed", [info objectForKey:@"externalSystem"]];
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@""
                              message: errorMessage
                              delegate:nil cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
    [alertView show];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"myCellIdentifier" forIndexPath:indexPath];
    
    // Configure the cell...
    
    UILabel *label = (UILabel *)[cell viewWithTag:100];
    
    if (self.isAccountAvailable) {
        [label setText:@"Account Authorized"];
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    } else {
        [label setText:@"Add Account"];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.isAccountAvailable) {
        if ([self.sourceTxt isEqualToString:@"Box"]) {
            [self showFolderBrowserRoot:@"Box"];
        } else if ([self.sourceTxt isEqualToString:@"Dropbox"]) {
            [self showFolderBrowserRoot:@"Dropbox"];
        } else if ([self.sourceTxt isEqualToString:@"Google Drive"] || [self.sourceTxt isEqualToString:@"Google Mail"]) {
            [self showFolderBrowserRoot:@"Google"];
        } else if ([self.sourceTxt isEqualToString:@"Salesforce"]) {
            [self showFolderBrowserRoot:@"Salesforce"];
        } else if ([self.sourceTxt isEqualToString:@"Zoho"]) {
            [self showFolderBrowserRoot:@"Zoho"];
        } else if ([self.sourceTxt isEqualToString:@"Asana"]) {
            [self showFolderBrowserRoot:@"Asana"];
        } else if ([self.sourceTxt isEqualToString:@"Trello"]) {
            [self showFolderBrowserRoot:@"Trello"];
        }
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 50;
}
/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (IBAction)removeAccBtnAction:(id)sender {
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    // do create
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id response){
        [delegate hideActivityIndicator];
        Account *account = [Account sharedInstance];
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        
        if ([self.sourceTxt isEqualToString:@"Box"]) {
            account.box_auth = NO;
            [standardUserDefaults setBool:account.box_auth forKey:@"BOX_AUTH"];
        } else if ([self.sourceTxt isEqualToString:@"Dropbox"]) {
            account.dropbox_auth = NO;
            [standardUserDefaults setBool:account.dropbox_auth forKey:@"DROPBOX_AUTH"];
        } else if ([self.sourceTxt isEqualToString:@"Google Drive"] || [self.sourceTxt isEqualToString:@"Google Mail"]) {
            account.google_auth = NO;
            [standardUserDefaults setBool:account.google_auth forKey:@"GOOGLE_AUTH"];
        } else if ([self.sourceTxt isEqualToString:@"Salesforce"]) {
            account.salesforce_auth = NO;
            [standardUserDefaults setBool:account.salesforce_auth forKey:@"SALESFORCE_AUTH"];
        } else if ([self.sourceTxt isEqualToString:@"Zoho"]) {
            account.zoho_auth = NO;
            [standardUserDefaults setBool:account.zoho_auth forKey:@"ZOHO_AUTH"];
        } else if ([self.sourceTxt isEqualToString:@"Asana"]) {
            account.asana_auth = NO;
            [standardUserDefaults setBool:account.asana_auth forKey:@"ASANA_AUTH"];
        } else if ([self.sourceTxt isEqualToString:@"Trello"]) {
            account.trello_auth = NO;
            [standardUserDefaults setBool:account.trello_auth forKey:@"TRELLO_AUTH"];
        }
        
        NSString *taskPreference = [standardUserDefaults objectForKey:@"TASK_PREFERENCE_SOURCE"];

        if([self.sourceTxt isEqualToString:taskPreference]) {
            [standardUserDefaults removeObjectForKey:@"TASK_PREFERENCE_SOURCE"];
            [standardUserDefaults removeObjectForKey:@"TASK_PREFERENCE_LEVEL1"];
            [standardUserDefaults removeObjectForKey:@"TASK_PREFERENCE_LEVEL2"];
        }
        [standardUserDefaults synchronize];
        self.isAccountAvailable = NO;
        [self configureRemoveSource];
        [self.tableView reloadData];
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id response){
        [delegate hideActivityIndicator];
        NSLog(@"error message %@ and json %@", [response objectForKey:@"error"], response);
    };
    [endpoint deleteUserSourceUsingType:self.sourceTxt];
}
@end
