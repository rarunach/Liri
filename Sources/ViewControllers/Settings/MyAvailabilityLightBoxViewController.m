//
//  MyAvailabilityLightBoxViewController.m
//  Liri
//
//  Created by Varun Sankar on 15/10/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "MyAvailabilityLightBoxViewController.h"
#import "Account.h"

@interface MyAvailabilityLightBoxViewController ()
{
    NSArray *contentsArray, *imagesArray;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *availabilityView;

@end

@implementation MyAvailabilityLightBoxViewController

@synthesize existingStatus = _existingStatus;
@synthesize tableView = _tableView;
@synthesize availabilityView = _availabilityView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    imagesArray = [[NSArray alloc] initWithObjects:@"Status-Available-Icon@2x.png", @"Status-Away-Icon@2x.png", @"Status-Busy-Icon@2x.png", nil];
    
    contentsArray = [[NSArray alloc] initWithObjects:@"Available", @"Away", @"Busy", nil];
}

- (void)viewDidLayoutSubviews
{
    [self.availabilityView setCenter:self.view.center];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setUserAvailability
{
    NSString *userStatus;
    if (self.existingStatus == 0) {
        userStatus = contentsArray[0];
    } else if (self.existingStatus == 1) {
        userStatus = contentsArray[1];
    } else if (self.existingStatus == 2) {
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
        [self.delegate returnSelectedIndexPath:self.existingStatus];
        [self dismissSelf];
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
        NSLog(@"error message %@ and json %@", responseJSON[@"error"], responseJSON);
    };
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:userStatus, @"availability_status", nil];
    [endpoint setUserAvailability: params];
}

- (void)markCurrentUserStatus:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UIButton *statusBtn = (UIButton *)[cell viewWithTag:100];
    [statusBtn setBackgroundColor:DEFAULT_UICOLOR];
    
    self.existingStatus = (int)indexPath.row;
    
    NSArray *cellArray = [self.tableView indexPathsForVisibleRows];
    for (NSIndexPath *index in cellArray) {
        if ([indexPath compare:index] != NSOrderedSame) {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:index];
            UIButton *statusBtn = (UIButton *)[cell viewWithTag:100];
            [statusBtn setBackgroundColor:nil];
        }
    }
}

- (void) dismissSelf {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        [self dismissViewControllerAnimated:NO completion:nil];
    } else {
        [self dismissViewControllerAnimated:NO completion:^{
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kLightBoxFinishedNotification
             object:self userInfo:@{@"className" : NSStringFromClass([self class])}];
        }];
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

#pragma mark - IBAction Methods
- (IBAction)cancelAction:(id)sender {
    [self dismissSelf];
}

- (IBAction)doneAction:(id)sender {
    [self setUserAvailability];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"myCategoriesCell" forIndexPath:indexPath];
    
    // Configure the cell...
    
    UIButton *statusBtn = (UIButton *)[cell viewWithTag:100];
    [statusBtn.layer setBorderColor:DEFAULT_CGCOLOR];
    if (self.existingStatus == indexPath.row) {
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
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
