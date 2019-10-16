//
//  RecipientStatusViewController.m
//  Liri
//
//  Created by Varun Sankar on 18/09/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "RecipientStatusViewController.h"

@interface RecipientStatusViewController ()

@property (weak, nonatomic) IBOutlet UITableView *recipientTableView;
@property (weak, nonatomic) IBOutlet UIView *recipientStatusView;
- (IBAction)backBtnAction:(id)sender;
@end

@implementation RecipientStatusViewController

@synthesize recipientTableView = _recipientTableView;

@synthesize recipientStatusArray = _recipientStatusArray;

@synthesize recipientStatusView = _recipientStatusView;

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
}

- (void)viewDidLayoutSubviews
{
    if(IS_IPHONE_5) {
        //do stuff for 4 inch iPhone screen
    }
    else {
        //do stuff for 3.5 inch iPhone screen
        [self.recipientStatusView setCenter:self.view.center];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableView DataSource Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.recipientStatusArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
        
    }
    
    cell.textLabel.text = self.recipientStatusArray[indexPath.row][@"user"];
    
    if ([self.recipientStatusArray[indexPath.row][@"acceptancestatus"] isEqualToString:@"accepted"])
    {
        cell.detailTextLabel.text = self.recipientStatusArray[indexPath.row][@"acceptancestatus"];
        
        if ([self.recipientStatusArray[indexPath.row][@"progressstatus"] isEqualToString:@"completed"])
        {
            cell.detailTextLabel.text = self.recipientStatusArray[indexPath.row][@"progressstatus"];
        }
    } else {
        cell.detailTextLabel.text = self.recipientStatusArray[indexPath.row][@"acceptancestatus"];
    }
    
    
    return cell;
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

- (IBAction)backBtnAction:(id)sender {
//    [self dismissViewControllerAnimated:YES completion:nil];
    [self dismissSelf];
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
@end
