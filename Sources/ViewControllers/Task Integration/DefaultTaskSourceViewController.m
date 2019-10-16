//
//  DefaultTaskSourceViewController.m
//  Liri
//
//  Created by Shankar Arunachalam on 9/10/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "DefaultTaskSourceViewController.h"
#import <EventKit/EventKit.h>
#import "AppDelegate.h"
#import "Account.h"
#import "OwnershipDetailsViewController.h"
#import "AuthenticationsViewController.h"
#import "Flurry.h"

@interface DefaultTaskSourceViewController ()

@property (weak, nonatomic) IBOutlet UIView *defaultTaskView;

@end

@implementation DefaultTaskSourceViewController
@synthesize taskSources, taskSourceImages;
@synthesize defaultTaskView =_defaultTaskView;

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
    [Flurry logEvent:@"Default Task Source Selector Screen"];
    taskSources = [[NSMutableArray alloc] initWithObjects:@"Asana", @"Salesforce", @"Trello", nil];
    taskSourceImages = [[NSMutableArray alloc] initWithObjects:@"Asana-Icon.png", @"SalesForce-icon.png", @"Trello-Icon.png", nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationCompleted:) name:kTaskAuthenticationCompletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationFailed:) name:kTaskAuthenticationFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPressDoneButton:) name:kTaskSourceSelectedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lightBoxFinished:) name:kLightBoxFinishedNotification object:nil];
}
- (void)viewDidLayoutSubviews
{

    [self.defaultTaskView setCenter:self.view.center];
}
- (void)viewDidAppear:(BOOL)animated
{
    [UIView animateWithDuration:0.5f animations:^(void) {
        self.view.alpha = 1.0;
    }];
    //    [self goToBottom];
}

- (void) lightBoxFinished:(NSNotification*)aNotification {
    NSDictionary *info = [aNotification userInfo];
    if ([info[@"className"] isEqualToString:@"DefaultTaskSourceViewController"] || [info[@"className"] isEqualToString:@"OwnershipDetailsViewController"] || [info[@"className"] isEqualToString:@"AuthenticationsViewController"]) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
            self.view.hidden = NO;
            
            [UIView animateWithDuration:0.3 animations:^(void) {
                self.view.alpha = 1.0;
            }];
        }
    }
    
    
}

- (IBAction)didPressDoneButton:(id)sender {
//    [self lightBoxFinished];
    [[NSNotificationCenter defaultCenter]
     
     postNotificationName:kLightBoxFinishedNotification
     
     object:self userInfo:@{@"className" : NSStringFromClass([self class])}];
    [self dismissViewControllerAnimated:NO completion:^{
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kTaskSelectionCompletedNotification
         object:self userInfo:nil];
    }];
}

- (IBAction)didPressCancelButton:(id)sender {
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
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSString *taskPreference = [standardUserDefaults objectForKey:@"TASK_PREFERENCE_SOURCE"];

    if([[taskSources objectAtIndex:indexPath.row] isEqualToString:taskPreference]) {
        [sourceButton setBackgroundColor: DEFAULT_UICOLOR];
    } else {
        [sourceButton setBackgroundColor: nil];
    }
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
        [self launchOwnershipDetailsScreen:externalSystem withAuthFlow:NO];
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
            
            UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
            AuthenticationsViewController *authenticationsController = [storyBoard instantiateViewControllerWithIdentifier:@"AuthenticationsViewController"];
            authenticationsController.contentToLoad = response;
            authenticationsController.externalSystem = externalSystem;
            if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
            } else {
//                self.view.hidden = YES;
                self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
                authenticationsController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            }

            [self presentViewController:authenticationsController animated:YES completion:nil];
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
    [self dismissViewControllerAnimated:NO completion:nil];
    NSDictionary* info = [aNotification userInfo];
    NSString *externalSystem = [info objectForKey:@"externalSystem"];
    [self launchOwnershipDetailsScreen:externalSystem withAuthFlow:YES];
}

- (void)launchOwnershipDetailsScreen: (NSString *)externalSystem withAuthFlow:(BOOL)isAuthFlow {
    Account *account = [Account sharedInstance];
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
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
    
        [UIView animateWithDuration:0.5 animations:^(void) {
            self.view.alpha = 0.5;
        }];
    
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Tasks" bundle:nil];
    OwnershipDetailsViewController *detailsController = [storyBoard instantiateViewControllerWithIdentifier:@"OwnershipDetailsViewController"];
    detailsController.view.backgroundColor = [UIColor clearColor];
    detailsController.taskSource = externalSystem;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
    } else {

        self.view.hidden = YES;
        
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;

        detailsController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    }


//    if(isAuthFlow) {
//        UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
//        rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
//        [rootViewController dismissViewControllerAnimated:NO completion:nil];
//        [rootViewController presentViewController:detailsController animated:YES completion:nil];
//    } else {
        [self presentViewController:detailsController animated:YES completion:nil];
//    }
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
