//
//  DefaultSelectorViewController.m
//  Liri
//
//  Created by Shankar Arunachalam on 9/4/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "DefaultSelectorViewController.h"
#import <EventKit/EventKit.h>
#import "AppDelegate.h"
#import "Account.h"
#import "OwnershipDetailsViewController.h"
#import "Flurry.h"

@interface DefaultSelectorViewController ()
@end

@implementation DefaultSelectorViewController
@synthesize localCalendars, localCalendarsDict, calendarsButton, calendarsPicker, taskSources, taskSourceImages;

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
    [Flurry logEvent:@"Default Task and Calendar Selector Screen"];
    taskSources = [[NSMutableArray alloc] initWithObjects:@"Asana", @"Salesforce", @"Trello", nil];
    taskSourceImages = [[NSMutableArray alloc] initWithObjects:@"Asana-Icon.png", @"SalesForce-icon.png", @"Trello-Icon.png", nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationCompleted:) name:kTaskAuthenticationCompletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationFailed:) name:kTaskAuthenticationFailedNotification object:nil];
}


- (void)viewDidAppear:(BOOL)animated
{
    [UIView animateWithDuration:0.5f animations:^(void) {
        self.view.alpha = 1.0;
    }];
    //    [self goToBottom];
    [self getCalendars];
}

- (void) getCalendars {
    EKEventStore * eventStore = [[EKEventStore alloc] init];
    NSArray *allCalendars = [eventStore calendarsForEntityType:EKEntityTypeEvent];
    localCalendars = [[NSMutableArray alloc] init];
    localCalendarsDict = [[NSMutableDictionary alloc] init];
    
    for (int i=0; i<allCalendars.count; i++) {
        EKCalendar *currentCalendar = [allCalendars objectAtIndex:i];
        //if (currentCalendar.type == EKCalendarTypeLocal) {
        if(currentCalendar.allowsContentModifications == YES) {
            [localCalendarsDict setObject:currentCalendar forKey:currentCalendar.calendarIdentifier];
            [localCalendars addObject:currentCalendar];
        }
    }
    [calendarsPicker reloadAllComponents];
    if(localCalendars.count == 1) {
        EKCalendar *currentCalendar = [localCalendars objectAtIndex:0];
        [calendarsButton setTitle:currentCalendar.title forState:UIControlStateNormal];
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        [standardUserDefaults setObject:currentCalendar.calendarIdentifier forKey:@"CALENDAR_PREFERENCE"];
        [standardUserDefaults synchronize];

    }
    else if(localCalendars.count > 1) {
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        NSString *calendarPreference = [standardUserDefaults objectForKey:@"CALENDAR_PREFERENCE"];
        if(calendarPreference != nil) {
            EKCalendar *currentCalendar = [localCalendarsDict objectForKey:calendarPreference];
            [calendarsButton setTitle:currentCalendar.title forState:UIControlStateNormal];
        }
        else {
            [calendarsButton setTitle:@"Choose..." forState:UIControlStateNormal];
        }
    } else {
        [calendarsButton setTitle:@"No calendars" forState:UIControlStateNormal];
    }
}

- (IBAction)pickCalendar:(id)sender {
    if(localCalendars.count == 1) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Since you have configured only one calendar in this device, we have chosen that to be Liri's default calendar."
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
    else if(localCalendars.count > 1) {
        [calendarsPicker setHidden:NO];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"You have not configured any calendars in this device yet."
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (IBAction)didPressDoneButton:(id)sender {
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSString *calendarPreference = [standardUserDefaults objectForKey:@"CALENDAR_PREFERENCE"];
    if(calendarPreference == nil) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Please select a default calendar for us to save your tasks and meeting invites."
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    } else {
        [self dismissViewControllerAnimated:NO completion:^{
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kDefaultCalendarSetNotification
             object:self userInfo:nil];
        }];
    }
}

#pragma mark - UIPickerView DataSource Methods
//Columns in picker views

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView; {
    return 1;
}

//Rows in each Column

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [localCalendars count];
}

#pragma mark - UIPickerView Delegate Method
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    EKCalendar *currentCalendar = [localCalendars objectAtIndex:row];
    return currentCalendar.title;
}

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    EKCalendar *currentCalendar = [localCalendars objectAtIndex:row];
    [calendarsPicker setHidden:YES];
    [calendarsButton setTitle:currentCalendar.title forState:UIControlStateNormal];
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setObject:currentCalendar.calendarIdentifier forKey:@"CALENDAR_PREFERENCE"];
    [standardUserDefaults synchronize];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    return 3;
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"taskCell"];
    
    UIButton *sourceButton = (UIButton *)[cell viewWithTag:100];
    UIImageView *sourceImage = (UIImageView *)[cell viewWithTag:200];
    UILabel *sourceName = (UILabel *)[cell viewWithTag:300];
//    [sourceButton addTarget:self action:@selector(categoryCheckAction:event:) forControlEvents:UIControlEventTouchUpInside];
    [sourceButton.layer setBorderColor:DEFAULT_CGCOLOR];
    [sourceButton setBackgroundColor: nil];
    [sourceButton.layer setBorderWidth:2.0f];
    
    sourceImage.image = [UIImage imageNamed:[taskSourceImages objectAtIndex:indexPath.row]];
    sourceImage.contentMode = UIViewContentModeScaleAspectFit;
    
    sourceName.text = [taskSources objectAtIndex:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
//    for(int i = 0; i < taskSources.count; i++) {
//        if(i == indexPath.row) {
//            NSUInteger ints[2] = {0,i};
//            NSIndexPath *index = [NSIndexPath indexPathWithIndexes:ints length:2];
//            UITableViewCell *cell = [tableView cellForRowAtIndexPath:index];
//            UIButton *sourceButton = (UIButton *)[cell viewWithTag:100];
//            [sourceButton setBackgroundColor: nil];
//        }
//    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"taskCell"];
    UIButton *sourceButton = (UIButton *)[cell viewWithTag:100];
    [sourceButton setBackgroundColor: DEFAULT_UICOLOR];
    NSString *taskSource = [taskSources objectAtIndex:indexPath.row];
    if([taskSource isEqualToString:@"Salesforce"]) {
        taskSource = @"SalesforceTasks";
    }
    [self authenticateTaskSource:taskSource];
}

- (void) authenticateTaskSource: (NSString *) externalSystem {
    Account *account = [Account sharedInstance];
    if((account.asana_auth && [externalSystem isEqualToString:@"Asana"])
       || (account.salesforce_auth && [externalSystem isEqualToString:@"SalesforceTasks"])
       || (account.trello_auth && [externalSystem isEqualToString:@"Trello"])) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kTaskAuthenticationCompletedNotification
         object:self userInfo:@{@"externalSystem": externalSystem}];
    } else {
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
            
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kExternalAuthenticationSelectedNotification
             object:self userInfo:@{@"contentToLoad": response, @"externalSystem": externalSystem}];
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
}

- (void)authenticationFailed:(NSNotification*)aNotification
{
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
    //[self dismissViewControllerAnimated:NO completion:nil];
    NSDictionary* info = [aNotification userInfo];
    Account *account = [Account sharedInstance];
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSString *externalSystem = [info objectForKey:@"externalSystem"];
    
    if ([externalSystem isEqualToString:@"SalesforceTasks"]) {
        account.salesforce_auth = true;
        [standardUserDefaults setBool:account.salesforce_auth forKey:@"SALESFORCE_AUTH"];
    }
    else if ([externalSystem isEqualToString:@"Asana"]) {
        account.asana_auth = true;
        [standardUserDefaults setBool:account.asana_auth forKey:@"ASANA_AUTH"];
    }
    else if ([externalSystem isEqualToString:@"Trello"]) {
        account.trello_auth = true;
        [standardUserDefaults setBool:account.trello_auth forKey:@"TRELLO_AUTH"];
    }
    
//    [UIView animateWithDuration:0.5 animations:^(void) {
//        self.view.alpha = 0.5;
//    }];
//    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
//    rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
    
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Tasks" bundle:nil];
    OwnershipDetailsViewController *detailsController = [storyBoard instantiateViewControllerWithIdentifier:@"OwnershipDetailsViewController"];
    detailsController.view.backgroundColor = [UIColor clearColor];
    detailsController.taskSource = [info objectForKey:@"externalSystem"];
    [self presentViewController:detailsController animated:YES completion:nil];
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

@end
