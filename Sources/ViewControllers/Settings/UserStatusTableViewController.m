//
//  UserStatusTableViewController.m
//  Liri
//
//  Created by Varun Sankar on 26/08/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "UserStatusTableViewController.h"
#import "Account.h"
#import "Flurry.h"

@interface UserStatusTableViewController ()
{
    NSArray *contentsArray, *imagesArray;
    int selectedRow;
}
@end

@implementation UserStatusTableViewController

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
    
    [Flurry logEvent:@"User Status Screen"];
    self.title = @"My Availability";
    
    selectedRow = -1;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    imagesArray = [[NSArray alloc] initWithObjects:@"Status-Available-Icon@2x.png", @"Status-Away-Icon@2x.png", @"Status-Busy-Icon@2x.png", nil];

    contentsArray = [[NSArray alloc] initWithObjects:@"Available", @"Away", @"Busy", nil];
    
    [self getUserAvailability];
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : DEFAULT_UICOLOR}];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:YES];
    
    [self setUserAvailability];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setUserAvailability
{
    NSString *userStatus;
    if (selectedRow == 0) {
        userStatus = contentsArray[0];
    } else if (selectedRow == 1) {
        userStatus = contentsArray[1];
    } else if (selectedRow == 2) {
        userStatus = contentsArray[2];
    }
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    // do create
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
        NSLog(@"error message %@ and json %@", responseJSON[@"error"], responseJSON);
    };
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:userStatus, @"availability_status", nil];
    [endpoint setUserAvailability: params];
}

- (void)getUserAvailability
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    // do create
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        NSString *status = responseJSON[@"availability_status"];
        if ([status isEqualToString:@"Available"]) {
            selectedRow = 0;
        } else if ([status isEqualToString:@"Away"]) {
            selectedRow = 1;
        } else if ([status isEqualToString:@"Busy"]) {
            selectedRow = 2;
        } else { // Delete else statement after clean up the junk data on server side
            selectedRow = 0;
        }
        [self.tableView reloadData];
        [delegate hideActivityIndicator];
        
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
        NSLog(@"error message %@ and json %@", responseJSON[@"error"], responseJSON);
    };
    [endpoint getUserAvailability];
}

- (void)markCurrentUserStatus:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UIButton *statusBtn = (UIButton *)[cell viewWithTag:100];
    [statusBtn setBackgroundColor:DEFAULT_UICOLOR];
    
    selectedRow = indexPath.row;
    
    NSArray *cellArray = [self.tableView indexPathsForVisibleRows];
    for (NSIndexPath *index in cellArray) {
        if ([indexPath compare:index] != NSOrderedSame) {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:index];
            UIButton *statusBtn = (UIButton *)[cell viewWithTag:100];
            [statusBtn setBackgroundColor:nil];
        }
    }
}

#pragma mark - UIButton Action Methods
- (void)statusBtnAction:(id)sender event:(id)event
{
    NSSet *touches = [event allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.tableView];
	NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint: currentTouchPosition];
    
    [self markCurrentUserStatus:indexPath];
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
    return [contentsArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"userStatusCellIdentifier" forIndexPath:indexPath];
    
    // Configure the cell...
    
    UIButton *statusBtn = (UIButton *)[cell viewWithTag:100];
    [statusBtn.layer setBorderColor:DEFAULT_CGCOLOR];
    if (selectedRow == indexPath.row) {
        [statusBtn setBackgroundColor:DEFAULT_UICOLOR];
    }
    [statusBtn addTarget:self action:@selector(statusBtnAction:event:) forControlEvents:UIControlEventTouchUpInside];
    
    UIImageView *statusImgView = (UIImageView *)[cell viewWithTag:200];
    [statusImgView setImage:[UIImage imageNamed:imagesArray[indexPath.row]]];
    
    UILabel *statusLabel = (UILabel *)[cell viewWithTag:300];
    [statusLabel setText:contentsArray[indexPath.row]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self markCurrentUserStatus:indexPath];
    
}
/*
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50;
}
*/
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

@end
