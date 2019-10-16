//
//  GroupViewController.m
//  Liri
//
//  Created by Ramani Arunachalam on 8/18/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "GroupViewController.h"
#import "APIManager.h"
#import "Flurry.h"
#import "Account.h"
#import "CRNInitialsImageView.h"

@interface GroupViewController ()

@property (weak, nonatomic) IBOutlet UITableView *membersTable;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBtn;
@property (nonatomic, strong) Group *group;

@property (weak, nonatomic) IBOutlet UIView *addContactView;
@property (weak, nonatomic) IBOutlet UIView *deleteContactView;

- (IBAction)addContactsToGroupAction:(id)sender;
- (IBAction)deleteGroup:(id)sender;

@end

@implementation GroupViewController
@synthesize group, editBtn;
@synthesize membersTable;

@synthesize addContactView = _addContactView, deleteContactView = _deleteContactView;


- (void)initWithGroup:(Group *)thegroup new:(BOOL)newFlag
{
    group = thegroup;
    
    if (newFlag) {
        Account *account = [Account sharedInstance];
        group.owner = account.getMyBuddy;
        id<APIAccessClient> endpoint =
        (id<APIAccessClient>)[[APIManager
                               sharedInstanceWithClientProtocol:
                               @protocol(APIAccessClient)] client];
        
        endpoint.successJSON = ^(NSURLRequest *request,
                                 id responseJSON){
            group.groupID = [responseJSON objectForKey:@"group_id"];
            
        };
        endpoint.failureJSON = ^(NSURLRequest *request,
                                 id responseJSON){
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:@""
                                      message:[responseJSON objectForKey:@"message"]
                                      delegate:nil cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
            [alertView show];
        };
        
        NSMutableArray *emails = [[NSMutableArray alloc] init];
        for (Buddy *buddy in group.memberlist.allBuddies) {
            [emails addObject:buddy.email];
        }
        [endpoint createGroupWithName:group.name members:emails];
    } else {
        Buddy *ownerBuddy = nil;
        for(Buddy *thisBuddy in group.memberlist.allBuddies) {
            if([thisBuddy.email isEqualToString:group.owner.email]) {
                ownerBuddy = thisBuddy;
                break;
            }
        }
        if(ownerBuddy != nil) {
            [group.memberlist.allBuddies removeObject:ownerBuddy];
        }
    }
}

- (void)initWithUpdateGroup:(Group *)theGroup
{
    group = theGroup;
    
    Account *account = [Account sharedInstance];
    group.owner = account.getMyBuddy;
    
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
//        group.groupID = [responseJSON objectForKey:@"group_id"];
        
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Alert"
                                  message:@"Error adding contacts. Please try again later."
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    };
    
    NSMutableArray *emails = [[NSMutableArray alloc] init];
    for (Buddy *buddy in group.memberlist.allBuddies) {
        [emails addObject:buddy.email];
    }
    [endpoint updateGroupWithID:group.groupID name:group.name members:emails];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [Flurry logEvent:@"Groups Screen"];
    self.navigationItem.title = group.name;
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : DEFAULT_UICOLOR}];

    Account *account = [Account sharedInstance];
    if (![group.owner.email isEqualToString:account.email]) {
        self.navigationItem.rightBarButtonItem = nil;
        [self.addContactView setHidden:YES];
        [self.deleteContactView setHidden:YES];
    }
}

- (void)viewDidLayoutSubviews
{
    if(IS_IPHONE_5) {
        //do stuff for 4 inch iPhone screen
    }
    else {
        //do stuff for 3.5 inch iPhone screen
        [self.membersTable setFrame:CGRectMake(self.membersTable.frame.origin.x, self.membersTable.frame.origin.y, self.membersTable.frame.size.width, self.membersTable.frame.size.height - 88)];
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UITableView
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    return [group.memberlist.allBuddies count]+1;
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"memberCell"];
    UILabel *lblName = (UILabel *)[cell viewWithTag:100];
    Buddy *buddy;
    if (indexPath.row == 0) {
        buddy = group.owner;
    } else {
        buddy = [group.memberlist.allBuddies objectAtIndex:indexPath.row-1];
    }
    [lblName setText:buddy.displayName];
    
    UIImageView *photoView = (UIImageView *)[cell viewWithTag:200];
    photoView.contentMode = UIViewContentModeScaleAspectFit;
    if (buddy.photo) {
        photoView.image = buddy.photo;

    } else {
        photoView.layer.borderWidth = 2;
        photoView.layer.borderColor = DEFAULT_CGCOLOR;
        CRNInitialsImageView *crnImageView = [[CRNInitialsImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        crnImageView.initialsBackgroundColor = [UIColor whiteColor];
        crnImageView.initialsTextColor = DEFAULT_UICOLOR;
        crnImageView.initialsFont = [UIFont boldSystemFontOfSize:18];
        crnImageView.useCircle = TRUE;
        crnImageView.firstName = buddy.firstName;
        crnImageView.lastName = buddy.lastName;
        crnImageView.email = buddy.email;
        [crnImageView drawImage];
        photoView.image = crnImageView.image;
//        if ((buddy.profile_pic == nil) || ([buddy.profile_pic isEqualToString:@""])) {
//            photoView.image = [UIImage imageNamed:@"No-Photo-Icon.png"];
//        } else {
//            photoView.image = buddy.photo;
//        }
    }
    photoView.layer.cornerRadius = (photoView.frame.size.width)/2;
    photoView.clipsToBounds = YES;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0)
        return NO;
    else return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [group.memberlist.allBuddies removeObjectAtIndex:indexPath.row-1];
        [tableView reloadData]; // tell table to refresh now
    }
}

- (IBAction)editAction:(id)sender {
    if (![membersTable isEditing]) {
        [membersTable setEditing:YES];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(editAction:)];
    } else {
        
        id<APIAccessClient> endpoint =
        (id<APIAccessClient>)[[APIManager
                               sharedInstanceWithClientProtocol:
                               @protocol(APIAccessClient)] client];
        
        endpoint.successJSON = ^(NSURLRequest *request,
                                 id responseJSON){
        };
        endpoint.failureJSON = ^(NSURLRequest *request,
                                 id responseJSON){
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:@""
                                      message:@"Unable to update the group."
                                      delegate:nil cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
            [alertView show];
        };
        
        NSMutableArray *emails = [[NSMutableArray alloc] init];
        for (Buddy *buddy in group.memberlist.allBuddies) {
            [emails addObject:buddy.email];
        }
        [endpoint updateGroupWithID:group.groupID name:group.name members:emails];
        
        [membersTable setEditing:NO];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editAction:)];
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


- (IBAction)addContactsToGroupAction:(id)sender {
    [[NSNotificationCenter defaultCenter]
     
     postNotificationName:kBackFromEditGroupNotification
     
     object:self userInfo:@{@"group" : @"edit"}];
    
    [self.navigationController popViewControllerAnimated:NO];
    
    AppDelegate *appdelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [self.view.window setRootViewController:appdelegate.tabBarController];
    
    UINavigationController *navCtlr = (UINavigationController *)appdelegate.tabBarController.selectedViewController;
    
    GroupsContactsViewController *groupsCtlr = (GroupsContactsViewController *)navCtlr.topViewController;
    
    [groupsCtlr setSelectionMode:YES];
}

- (IBAction)deleteGroup:(id)sender {
    AppDelegate *appdelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [appdelegate showActivityIndicator];
    
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
    
        [appdelegate hideActivityIndicator];

        NSArray *responseKeys = [responseJSON allKeys];
        
        // Now see if the array contains the key you are looking for
        
        BOOL isErrorResponse = [responseKeys containsObject:@"details"];
        if (isErrorResponse) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:responseJSON[@"message"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
        } else {
            [[NSNotificationCenter defaultCenter]
                 
            postNotificationName:kDeleteGroupFromListNotification
             
            object:self userInfo:@{@"deleteGroup" : group}];
            
            [self.navigationController popViewControllerAnimated:YES];
        }
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [appdelegate hideActivityIndicator];
    };
    
    [endpoint deleteGroupWithID:group.groupID];
}
@end
