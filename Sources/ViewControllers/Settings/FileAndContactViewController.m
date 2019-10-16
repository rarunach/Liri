//
//  FileAndContactViewController.m
//  Liri
//
//  Created by Varun Sankar on 01/09/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "FileAndContactViewController.h"
#import "SourceInfoTableTableViewController.h"
#import "Account.h"
#import "Flurry.h"

@interface FileAndContactViewController ()
{
    NSMutableArray *fileContentArray, *contactContentArray, *tasksContentArray, *tableContentArray;
}
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentCtrl;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (IBAction)segmentCtrlAction:(id)sender;

@end

@implementation FileAndContactViewController

@synthesize segmentCtrl = _segmentCtrl;

@synthesize tableView = _tableView;

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
    [Flurry logEvent:@"File/Contact Sources Screen"];
    
    self.title = @"Manage Sources";
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    [self createFileAndContactData];
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : DEFAULT_UICOLOR}];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"SourceInfoIdentifier"]) {
        
        SourceInfoTableTableViewController *sourceInfoCtrl = segue.destinationViewController;
        
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:sender];
        UIImageView *imgView = (UIImageView *)[cell viewWithTag:100];
        UILabel *titleLabel = (UILabel *)[cell viewWithTag:200];
        UILabel *statusLabel = (UILabel *)[cell viewWithTag:201];
        if (statusLabel.isHidden) {
            sourceInfoCtrl.isAccountAvailable = NO;
        } else {
            sourceInfoCtrl.isAccountAvailable = YES;
        }
        sourceInfoCtrl.sourceTxt = titleLabel.text;
        sourceInfoCtrl.sourceImg = imgView.image;
    }
}

#pragma mark - Private Methods
- (void)createFileAndContactData

{    fileContentArray = [[NSMutableArray alloc] init];

    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:@"Box", @"title", @"Account Available", @"status", @"Box-Icon.png", @"image", nil];
    
    [fileContentArray addObject:dict];
    
    dict = [[NSDictionary alloc] initWithObjectsAndKeys:@"Dropbox", @"title", @"Account Available", @"status", @"Dropbox-icon.png", @"image", nil];
    
    [fileContentArray addObject:dict];
    
    dict = [[NSDictionary alloc] initWithObjectsAndKeys:@"Google Drive", @"title", @"Account Available", @"status", @"Google-Drive-icon.png", @"image", nil];
    
    [fileContentArray addObject:dict];
    
    tableContentArray = fileContentArray;
    
    contactContentArray = [[NSMutableArray alloc] init];
    
    dict = [[NSDictionary alloc] initWithObjectsAndKeys:@"Google Mail", @"title", @"Account Available", @"status", @"Google-Icon", @"image", nil];
    
    [contactContentArray addObject:dict];
    
    
    dict = [[NSDictionary alloc] initWithObjectsAndKeys:@"Salesforce", @"title", @"Account Available", @"status", @"SalesForce-icon", @"image", nil];
    
    [contactContentArray addObject:dict];
    
    dict = [[NSDictionary alloc] initWithObjectsAndKeys:@"Zoho", @"title", @"Account Available", @"status", @"Zoho-Icon", @"image", nil];
    
    [contactContentArray addObject:dict];
    
    tasksContentArray = [[NSMutableArray alloc] init];
    
    dict = [[NSDictionary alloc] initWithObjectsAndKeys:@"Asana", @"title", @"Account Available", @"status", @"Asana-Icon", @"image", nil];
    
    [tasksContentArray addObject:dict];
    
    
    dict = [[NSDictionary alloc] initWithObjectsAndKeys:@"Salesforce", @"title", @"Account Available", @"status", @"SalesForce-icon", @"image", nil];
    
    [tasksContentArray addObject:dict];
    
    dict = [[NSDictionary alloc] initWithObjectsAndKeys:@"Trello", @"title", @"Account Available", @"status", @"Trello-Icon", @"image", nil];
    
    [tasksContentArray addObject:dict];
    
}

- (BOOL)compareFileAuth:(NSIndexPath *)index
{
    Account *account = [Account sharedInstance];
    switch (index.row) {
        case 0:
            return account.box_auth;
            break;
        case 1:
            return account.dropbox_auth;
        case 2:
            return account.google_auth;
        default:
            return NO;
            break;
    }
}

- (BOOL)compareContactAuth:(NSIndexPath *)index
{
    Account *account = [Account sharedInstance];
    switch (index.row) {
        case 0:
            return account.google_auth;
            break;
        case 1:
            return account.salesforce_auth;
        case 2:
            return account.zoho_auth;
        default:
            return NO;
            break;
    }
}

- (BOOL)compareTaskAuth:(NSIndexPath *)index
{
    Account *account = [Account sharedInstance];
    switch (index.row) {
        case 0:
            return account.asana_auth;
            break;
        case 1:
            return account.salesforce_auth;
        case 2:
            return account.trello_auth;
        default:
            return NO;
            break;
    }
}

- (IBAction)segmentCtrlAction:(id)sender {
    if ([self.segmentCtrl selectedSegmentIndex] == 0) {
        tableContentArray = fileContentArray;
    } else if ([self.segmentCtrl selectedSegmentIndex] == 1){
        tableContentArray = contactContentArray;
    } else {
        tableContentArray = tasksContentArray;
    }
    [self.tableView reloadData];
}

- (BOOL)isFreeUserForContacts:(NSInteger)selection
{
    if ([self.segmentCtrl selectedSegmentIndex] == 1){
        if (selection == 1) {
            BOOL salesforce = [[[NSUserDefaults standardUserDefaults] objectForKey:SALESFORCE_CONFIG] boolValue];
            if (!salesforce) {
                return NO;
            }
        } else if (selection == 2) {
            BOOL zoho = [[[NSUserDefaults standardUserDefaults] objectForKey:ZOHO_CONFIG] boolValue];
            if (!zoho) {
                return NO;
            }
        }
    } else if ([self.segmentCtrl selectedSegmentIndex] == 2){
        if (selection == 0) {
            BOOL asana = [[[NSUserDefaults standardUserDefaults] objectForKey:ASANA_CONFIG] boolValue];
            if (!asana) {
                return NO;
            }
        } else if (selection == 1) {
            BOOL salesforce = [[[NSUserDefaults standardUserDefaults] objectForKey:SALESFORCE_CONFIG] boolValue];
            if (!salesforce) {
                return NO;
            }
        } else {
            BOOL trello = [[[NSUserDefaults standardUserDefaults] objectForKey:TRELLO_CONFIG] boolValue];
            if (!trello) {
                return NO;
            }
        }
    }
    
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [tableContentArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"myCellIdentifier" forIndexPath:indexPath];
    
    // Configure the cell...
    
    UIImageView *imgView = (UIImageView *)[cell viewWithTag:100];
    [imgView setImage:[UIImage imageNamed:tableContentArray[indexPath.row][@"image"]]];
    
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:200];
    [titleLabel setText:tableContentArray[indexPath.row][@"title"]];

    UILabel *statusLabel = (UILabel *)[cell viewWithTag:201];
    [statusLabel setText:tableContentArray[indexPath.row][@"status"]];
    
    
    if ([self.segmentCtrl selectedSegmentIndex] == 0) {
        if (![self compareFileAuth:indexPath]) {
            [statusLabel setHidden:YES];
        } else {
            [statusLabel setHidden:NO];
        }
    } else if ([self.segmentCtrl selectedSegmentIndex] == 1){
        if (![self compareContactAuth:indexPath]) {
            [statusLabel setHidden:YES];
        } else {
            [statusLabel setHidden:NO];
        }
    } else {
        if (![self compareTaskAuth:indexPath]) {
            [statusLabel setHidden:YES];
        } else {
            [statusLabel setHidden:NO];
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![self isFreeUserForContacts:indexPath.row]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:FREE_USER_CONFIG_MSG delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    } else {
        [self performSegueWithIdentifier:@"SourceInfoIdentifier" sender:indexPath];
    }
}

@end
