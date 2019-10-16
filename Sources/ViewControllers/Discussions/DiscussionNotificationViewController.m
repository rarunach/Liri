//
//  DiscussionNotificationViewController.m
//  Liri
//
//  Created by Varun Sankar on 24/07/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "DiscussionNotificationViewController.h"
#import "AppConstants.h"
#import "Account.h"
#import "AppDelegate.h"
#import "APIClient.h"
#import <EventKit/EventKit.h>
#import "TaskViewController.h"
#import "MeetingViewController.h"
#import "DefaultCalendarSelectorViewController.h"
#import "AuthenticationsViewController.h"
#import "Flurry.h"

@interface DiscussionNotificationViewController ()
{
    NSMutableArray *notificationArray;
    NSString *owner;
    NSString *notificationType;
    NSIndexPath *savedIndexPath;
    NSDictionary *currentLocalDict;
    NSString *currentTaskId, *currentTaskSource;
    UIAlertView *taskAlertView, *taskFailureAlertView;
}

@property (weak, nonatomic) IBOutlet UIView *notificationView;
@property (weak, nonatomic) IBOutlet UITableView *notificationTable;

- (IBAction)backAction:(id)sender;

@end

@implementation DiscussionNotificationViewController

@synthesize notificationTable = _notificationTable;

@synthesize notificationView = _notificationView;

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
    [Flurry logEvent:@"Discussion Notification Screen"];
    
    self.notificationTable.separatorInset = UIEdgeInsetsZero;    // <- any custom inset will do
    self.notificationTable.separatorColor = [UIColor lightGrayColor];
    
    notificationArray = [Account sharedInstance].notificationsHistory;
    [self makeViewAlignment];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultCalendarSet:) name:kDefaultCalendarSetNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationCompleted:) name:kTaskAuthenticationCompletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationFailed:) name:kTaskAuthenticationFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lightBoxFinished:) name:kLightBoxFinishedNotification object:nil];
}

- (void) lightBoxFinished:(NSNotification*)aNotification {
    NSDictionary *info = [aNotification userInfo];
    if ([info[@"className"] isEqualToString:@"TaskViewController"] || [info[@"className"] isEqualToString:@"MeetingViewController"] || [info[@"className"] isEqualToString:@"DiscussionNotificationViewController"]) {
        [UIView animateWithDuration:0.3 animations:^(void) {
            self.view.alpha = 1.0;
        }];
    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [UIView animateWithDuration:1.0 animations:^(void) {
        self.view.alpha = 1.0;
    }];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private Methods
- (NSString *)setNotificationContentByType:(NSDictionary *)localDict
{
    NSDictionary *notificationDetails = localDict[@"jsonData"];

    NSString *type = localDict[@"notificationType"];
    
    NSString *title = notificationDetails[@"owner_editable"][@"subject"];
    
    NSString *senderName = localDict[@"senderName"];
    
    NSString *dateString;
    NSString *notificationContent;
    
    if ([type isEqualToString:@"Task"]) {
        
        NSString *actionCategory = notificationDetails[@"owner_editable"][@"actioncategory"];
        dateString = [Account convertGmtToLocalTimeZone:notificationDetails[@"owner_editable"][@"remindertime"] ];
//        dateString = notificationDetails[@"owner_editable"][@"remindertime"];
        
        notificationContent = [NSString stringWithFormat:@"Task: %@\nAssigned by: %@\n%@: %@",title, senderName, actionCategory, dateString];
    } else {
        BOOL allDayEvent = [notificationDetails[@"owner_editable"][@"alldayevent"] boolValue];
        if (allDayEvent) {
            dateString = notificationDetails[@"owner_editable"][@"starttime"];
        } else {
            dateString = [Account convertGmtToLocalTimeZone:notificationDetails[@"owner_editable"][@"starttime"]];
        }

//        dateString = notificationDetails[@"owner_editable"][@"starttime"];
        notificationContent = [NSString stringWithFormat:@"Meeting Invite: %@\nFrom: %@\nDate: %@",title, senderName, dateString];
    }
    return notificationContent;
}

- (void)setCategoryAcceptanceState:(BOOL)flag byNotificationId:(NSString *)notificationId andRemoveNotificationByIndex:(NSIndexPath *)index andOtherDetails:(NSDictionary *)localDict
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    // do create
    id<APIAccessClient> discussionsEndpoint =
    (id<APIAccessClient>)[[APIManager
                                 sharedInstanceWithClientProtocol:
                                 @protocol(APIAccessClient)] client];
    
    discussionsEndpoint.successJSON = ^(NSURLRequest *request,
                                        id responseJSON){
        
        //Update To-Do badge value
        Account *account = [Account sharedInstance];
        if ([notificationType isEqualToString:@"Task"]) {
            int taskCount = [Account getTaskCount];
            if (taskCount >= 1) {
                [Account setTaskCount:taskCount - 1];
                account.badgeTask.value = [Account getTaskCount];
            }
            
        } else {
            int meetingInviteCount = [Account getMeetingInviteCount];
            if (meetingInviteCount >= 1) {
                [Account setMeetingInviteCount:meetingInviteCount - 1];
                account.badgeMeetingInvite.value = [Account getMeetingInviteCount];
            }
            
        }
        
        NSString *toDoCountStr = [Account getCategoriesCount];
        int toDoCount = [toDoCountStr intValue];
        if (toDoCount >= 1) {
            [Account setCategoriesCount:[NSString stringWithFormat:@"%d", toDoCount - 1]];
            
            [delegate.tabBarController.tabBar.items[2] setBadgeValue:[Account getCategoriesCount]];
        }
        
        [notificationArray removeObjectAtIndex:index.row];
        [self.notificationTable reloadData];
        
        [delegate hideActivityIndicator];
        if(flag) {
            NSDictionary *notificationDetails = localDict[@"jsonData"];
            NSDictionary *externalTaskInfo = notificationDetails[@"owner_editable"][@"external_task_info"];
            if(externalTaskInfo != nil) {
                if (![self isFreeUserForContacts]) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:FREE_USER_CONFIG_MSG delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    alert.tag = 1;
                    [alert show];
                } else {
                    currentLocalDict = localDict;
                    currentTaskId = externalTaskInfo[@"id"];
                    currentTaskSource = externalTaskInfo[@"source"];
                    NSString *taskMessage;
                    if([currentTaskSource isEqualToString:@"Asana"]) {
                        taskMessage = [NSString stringWithFormat:@"%@ has created a task for this in Asana. Do you want to create a subtask under that task?", localDict[@"senderName"]];
                    } else if([currentTaskSource isEqualToString:@"Trello"]) {
                        taskMessage = [NSString stringWithFormat:@"%@ has created a card for this task in Trello. Do you want to add yourself as a member of that card?", localDict[@"senderName"]];
                    } else if([currentTaskSource isEqualToString:@"Salesforce"]) {
                        taskMessage = [NSString stringWithFormat:@"%@ has indicated that they would like to track this in Salesforce. Do you want to create a task in Salesforce?", localDict[@"senderName"]];
                    }
                    taskAlertView = [[UIAlertView alloc]
                                     initWithTitle:@"Task Management Tool"
                                     message:taskMessage
                                     delegate:self cancelButtonTitle:@"No"
                                     otherButtonTitles:@"Yes", nil];
                    [taskAlertView show];
                }
            } else {
                [self backToNormalView];
                [self dismissSelf];
            }
        } else {
            [self backToNormalView];
            [self dismissSelf];
        }
        
    };
    discussionsEndpoint.failureJSON = ^(NSURLRequest *request,
                                        id responseJSON){
        [self backToNormalView];
        [delegate hideActivityIndicator];
        UIAlertView *failureAlert = [[UIAlertView alloc]
                                     initWithTitle:@""
                                     message:responseJSON[@"error"]
                                     delegate:self cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil];
        [failureAlert setTag:KFailureAlertTag];
        [failureAlert show];
        
        NSLog(@"error message %@ and json %@", responseJSON[@"error"], responseJSON);
    };
    NSArray *separatedArray = [notificationId componentsSeparatedByString:@"::"];
    [discussionsEndpoint setCategoryAcceptanceWithOwner:owner MessageId:separatedArray[2] DiscussionId:separatedArray[1] CategoryType:[separatedArray[3] intValue] andIsAccepted:flag];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView == taskFailureAlertView) {
        [self backToNormalView];
        [self dismissSelf];
    } else if (alertView == taskAlertView) {
        if (alertView.cancelButtonIndex == buttonIndex) {
            [self backToNormalView];
            [self dismissSelf];
        } else {
            [self authenticateTaskSource:currentTaskSource];
        }
    } else if(buttonIndex == 0 && alertView.tag == KLocalResourceAccessFailureTag) {
        NSDictionary *notificationDict = notificationArray[savedIndexPath.row];
        [self setCategoryAcceptanceState:YES byNotificationId:notificationDict[@"notificationId"] andRemoveNotificationByIndex:savedIndexPath andOtherDetails:notificationDict];
    } else if (alertView.tag == 1) {
        [self backToNormalView];
        [self dismissSelf];
    } else {
        return;
    }
}

- (void)addEventToCalender:(NSDictionary *)localDict andIndexPath:(NSIndexPath *)index
{
    NSDictionary *notificationDetails = localDict[@"jsonData"];
    
    NSString *type = localDict[@"notificationType"];
    
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        if (!granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alertView = [[UIAlertView alloc]
                                          initWithTitle:@""
                                          message:@"Calendar access to Liri app is turned off in your device. You can enable calendar access to Liri app from Settings > Privacy > Calendar."
                                          delegate:self cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
                alertView.tag = KLocalResourceAccessFailureTag;
                [alertView show];
            });
        } else {
            // handle access here
            dispatch_async(dispatch_get_main_queue(), ^{
                
                EKEvent *thisEvent  = [EKEvent eventWithEventStore:eventStore];
                
                
                //Title
                thisEvent.title = notificationDetails[@"owner_editable"][@"subject"];;
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"EEE, MM/dd/yy, h:mm a"];
                
                NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
                NSString *calendarPreference = [standardUserDefaults objectForKey:@"CALENDAR_PREFERENCE"];
                
                [thisEvent setCalendar:[eventStore calendarWithIdentifier:calendarPreference]];
                
                if ([type isEqualToString:@"Task"]) {
                    NSString *taskDate = [Account convertGmtToLocalTimeZone:notificationDetails[@"owner_editable"] [@"remindertime"]];
                    thisEvent.startDate = [dateFormatter dateFromString:taskDate];
                    
                } else {
                    thisEvent.allDay = [notificationDetails[@"owner_editable"][@"alldayevent"] boolValue];
                    NSString *meetingStartDate;
                    NSString *meetingEndDate;
                    if (thisEvent.allDay) {
                        [dateFormatter setDateFormat:@"MM/dd/yy"];
                        meetingStartDate = notificationDetails[@"owner_editable"] [@"starttime"];
                        meetingEndDate = notificationDetails[@"owner_editable"] [@"endtime"];
                    } else {
                        meetingStartDate = [Account convertGmtToLocalTimeZone:notificationDetails[@"owner_editable"] [@"starttime"]];
                        meetingEndDate = [Account convertGmtToLocalTimeZone:notificationDetails[@"owner_editable"] [@"endtime"]];
                    }
                    thisEvent.startDate = [dateFormatter dateFromString:meetingStartDate];
                    thisEvent.endDate = [dateFormatter dateFromString:meetingEndDate];
                    
                }
                
                
                //setting the Reuccurence rule
                //Repeat
                NSString *repeatText = notificationDetails[@"owner_editable"][@"repeat_frequency"];
                repeatText = [repeatText substringToIndex:[repeatText length] - 2];
                BOOL isRecurrenceFrequencyExists = TRUE;
                
                EKRecurrenceFrequency  recurrenceFrequency;
                int interval = 1;
                if ([repeatText isEqualToString: @"Every day"]) {
                    recurrenceFrequency = EKRecurrenceFrequencyDaily;
                } else if([repeatText isEqualToString: @"Every week"]){
                    recurrenceFrequency = EKRecurrenceFrequencyWeekly;
                } else if([repeatText isEqualToString: @"Every 2 weeks"]) {
                    recurrenceFrequency = EKRecurrenceFrequencyWeekly;
                    interval = 2;
                } else if([repeatText isEqualToString: @"Every month"]){
                    recurrenceFrequency = EKRecurrenceFrequencyMonthly;
                } else if([repeatText isEqualToString: @"Every year"]){
                    recurrenceFrequency = EKRecurrenceFrequencyYearly;
                } else{
                    isRecurrenceFrequencyExists = FALSE;
                    if ([type isEqualToString:@"Task"]) {
                        thisEvent.endDate = thisEvent.startDate;
                    }
                }
                
                if(isRecurrenceFrequencyExists){
                    EKRecurrenceRule * recurrenceRule = [[EKRecurrenceRule alloc]
                                                         
                                                         initRecurrenceWithFrequency:recurrenceFrequency
                                                         interval:interval
                                                         end:nil];
                    if (thisEvent.endDate != nil) {
                        EKRecurrenceEnd * end = [EKRecurrenceEnd recurrenceEndWithEndDate:thisEvent.endDate];
                        recurrenceRule.recurrenceEnd = end;
                    }else {
                        thisEvent.endDate = thisEvent.startDate;
                    }
                    [thisEvent addRecurrenceRule:recurrenceRule];
                }
                
                //Alarms
                
                NSMutableArray *myAlarmsArray = [[NSMutableArray alloc] init];
                
                if (![notificationDetails[@"member_editable"][@"alert1"] isEqualToString:@"Never >"]) {
                    EKAlarm *alarm1 = [EKAlarm alarmWithRelativeOffset:[self configureAlarm:notificationDetails[@"member_editable"][@"alert1"]]];
                    [myAlarmsArray addObject:alarm1];
                }
                
                if (![notificationDetails[@"member_editable"][@"alert2"] isEqualToString:@"Never >"]) {
                    EKAlarm *alarm2 = [EKAlarm alarmWithRelativeOffset:[self configureAlarm:notificationDetails[@"member_editable"][@"alert2"]]];
                    [myAlarmsArray addObject:alarm2];
                }
                if (myAlarmsArray.count > 0) {
                    thisEvent.alarms = myAlarmsArray;
                }
                
                
                //Notes
                thisEvent.notes = notificationDetails[@"owner_editable"][@"notes"];
                
                
                NSError *err;
                
                
                BOOL success = [eventStore saveEvent:thisEvent span:EKSpanFutureEvents error:&err];
                if (!success) {
                    NSLog(@"error in calender event %@", err);
                    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                    [delegate hideActivityIndicator];
                }
                NSLog(@"calendar id %@", thisEvent.eventIdentifier);
                
                [self setCategoryAcceptanceState:YES byNotificationId:localDict[@"notificationId"] andRemoveNotificationByIndex:index andOtherDetails:localDict];
            });
        }
    }];
}

- (void) authenticateTaskSource: (NSString *) externalSystem {
    Account *account = [Account sharedInstance];
    if((account.asana_auth && [externalSystem isEqualToString:@"Asana"])
       || (account.salesforce_auth && [externalSystem isEqualToString:@"Salesforce"])
       || (account.trello_auth && [externalSystem isEqualToString:@"Trello"])) {
        [self processExternalTaskSource:externalSystem withId:currentTaskId andOtherDetails:currentLocalDict];
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
            [self presentViewController:authenticationsController animated:YES completion:nil];
        };
        endpoint.failure = ^(NSURLRequest *request,
                             id response){
            [delegate hideActivityIndicator];
            taskFailureAlertView = [[UIAlertView alloc]
                                         initWithTitle:@""
                                         message:[response objectForKey:@"error"]
                                         delegate:self cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil];
            [taskFailureAlertView setTag:KFailureAlertTag];
            [taskFailureAlertView show];
            
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
    Account *account = [Account sharedInstance];
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSString *externalSystem = [info objectForKey:@"externalSystem"];
    
    if ([externalSystem isEqualToString:@"SalesforceTasks"]) {
        account.salesforce_auth = true;
        [standardUserDefaults setBool:account.salesforce_auth forKey:@"SALESFORCE_AUTH"];
    }
    else if ([externalSystem isEqualToString:@"Asana"]) {
        account.asana_auth = true;
        [standardUserDefaults setBool:account.google_auth forKey:@"ASANA_AUTH"];
    }
    else if ([externalSystem isEqualToString:@"Trello"]) {
        account.trello_auth = true;
        [standardUserDefaults setBool:account.zoho_auth forKey:@"TRELLO_AUTH"];
    }
    [self processExternalTaskSource:externalSystem withId:currentTaskId andOtherDetails:currentLocalDict];
}

- (void)processExternalTaskSource:(NSString *)source withId:(NSString *)id andOtherDetails:(NSDictionary *)localDict {
    if([source isEqualToString:@"Asana"]) {
        [self createAsanaSubtask:id withOtherDetails:localDict];
    } else if([source isEqualToString:@"Trello"]) {
        [self joinTrelloTask:id withOtherDetails:localDict];
    } else if([source isEqualToString:@"Salesforce"]) {
        [self createSalesforceTask:id withOtherDetails:localDict];
    }
}

- (void)createAsanaSubtask:(NSString *)idnum withOtherDetails:(NSDictionary *)localDict {
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    NSDictionary *notificationDetails = localDict[@"jsonData"];
    
    // do create
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id response){
        [delegate hideActivityIndicator];
        [self backToNormalView];
        [self dismissSelf];
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id response){
        [delegate hideActivityIndicator];
        taskFailureAlertView = [[UIAlertView alloc]
                                     initWithTitle:@""
                                     message:[response objectForKey:@"error"]
                                     delegate:self cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil];
        [taskFailureAlertView setTag:KFailureAlertTag];
        [taskFailureAlertView show];
        
        NSLog(@"error message %@ and json %@", [response objectForKey:@"error"], response);
    };
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE, MM/dd/yy, h:mm a"];
    
    NSDateFormatter *dateFormatter2 = [[NSDateFormatter alloc] init];
    [dateFormatter2 setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    
    NSDate *duedate = [dateFormatter dateFromString:notificationDetails[@"owner_editable"][@"remindertime"]];
    NSString *duedatestring = [dateFormatter2 stringFromDate:duedate];
    
    [endpoint saveAsanaSubtask:idnum withName:notificationDetails[@"owner_editable"][@"subject"] andDescription:notificationDetails[@"owner_editable"][@"notes"] andDue:duedatestring];
}

- (void)joinTrelloTask:(NSString *)idnum withOtherDetails:(NSDictionary *)localDict {
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
        [self backToNormalView];
        [self dismissSelf];
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id response){
        [delegate hideActivityIndicator];
        taskFailureAlertView = [[UIAlertView alloc]
                                     initWithTitle:@""
                                     message:[response objectForKey:@"error"]
                                     delegate:self cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil];
        [taskFailureAlertView setTag:KFailureAlertTag];
        [taskFailureAlertView show];
        
        NSLog(@"error message %@ and json %@", [response objectForKey:@"error"], response);
    };
    [endpoint joinTrelloTask:idnum];
}

- (void)createSalesforceTask:(NSString *)idnum withOtherDetails:(NSDictionary *)localDict {
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    NSDictionary *notificationDetails = localDict[@"jsonData"];

    // do create
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id response){
        [delegate hideActivityIndicator];
        [self backToNormalView];
        [self dismissSelf];
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id response){
        [delegate hideActivityIndicator];
        taskFailureAlertView = [[UIAlertView alloc]
                                     initWithTitle:@""
                                message:@"Something went wrong when saving the task to Salesforce. If the problem persists, please authorize the account again from Settings > Manage Sources > Tasks > Salesforce"
                                     delegate:self cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil];
        [taskFailureAlertView setTag:KFailureAlertTag];
        [taskFailureAlertView show];
        
        NSLog(@"error message %@ and json %@", [response objectForKey:@"error"], response);
    };
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE, MM/dd/yy, h:mm a"];
    
    NSDateFormatter *dateFormatter2 = [[NSDateFormatter alloc] init];
    [dateFormatter2 setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    
    NSDate *duedate = [dateFormatter dateFromString:notificationDetails[@"owner_editable"][@"remindertime"]];
    NSString *duedatestring = [dateFormatter2 stringFromDate:duedate];
    
    [endpoint saveSalesforceTask:notificationDetails[@"owner_editable"][@"subject"] withAccountId:idnum andDescription:notificationDetails[@"owner_editable"][@"notes"] andDue:duedatestring];
}

- (int)configureAlarm:(NSString *)alarm
{
    int offsetValue;
    if ([alarm isEqualToString:@"At time of event >"]) {
        offsetValue = 0;
    } else if ([alarm isEqualToString:@"5 minutes before >"]) {
        offsetValue = 60 * 5;
    } else if ([alarm isEqualToString:@"15 minutes before >"]) {
        offsetValue = 60 * 15;
    } else if ([alarm isEqualToString:@"30 minutes before >"]) {
        offsetValue = 60 *30;
    } else if ([alarm isEqualToString:@"1 hour before >"]) {
        offsetValue = 60 * 60;
    } else if ([alarm isEqualToString:@"2 hours before >"]) {
        offsetValue = 60 * (60 * 2);
    } else if ([alarm isEqualToString:@"1 day before >"]) {
        offsetValue = 60 * (60 * 24);// 86400;
    } else if ([alarm isEqualToString:@"2 days before >"]) {
        offsetValue = 60 * (60 * (24 * 2));
    } else if ([alarm isEqualToString:@"1 week before >"]) {
        offsetValue = 60 * (60 * (24 * 7));
    } else {
        offsetValue = 0; // Never
    }
    return -offsetValue;
}

- (void)backToNormalView
{
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    [UIView animateWithDuration:0.5 animations:^(void) {
        rootViewController.view.alpha = 1.0;
    }];
}

- (void)makeViewAlignment
{
    CGFloat categoryViewHeight, categoryTableHeight;
    if (IS_IPHONE_5) {
        categoryViewHeight = 440;
        categoryTableHeight = 390;
    } else {
        categoryViewHeight = 352;
        categoryTableHeight = 302;
    }
    CGRect frame = self.notificationView.frame;
    frame.size.height = MIN((notificationArray.count * 140) + 50, categoryViewHeight);
    frame.origin.y = (self.view.frame.size.height - frame.size.height) / 2;
    self.notificationView.frame = frame;
    
    frame = self.notificationTable.frame;
    frame.size.height = MIN((notificationArray.count * 140) + 50, categoryTableHeight);
    self.notificationTable.frame = frame;
}

- (BOOL)isFreeUserForContacts
{
    BOOL asana = [[[NSUserDefaults standardUserDefaults] objectForKey:ASANA_CONFIG] boolValue];
    BOOL salesforce = [[[NSUserDefaults standardUserDefaults] objectForKey:SALESFORCE_CONFIG] boolValue];
    BOOL trello = [[[NSUserDefaults standardUserDefaults] objectForKey:TRELLO_CONFIG] boolValue];
    
    if (!asana && !salesforce && !trello) {
        return NO;
    }
    return YES;
}

#pragma mark - UIButton Methods
- (void)backAction:(id)sender
{
    [self backToNormalView];
    [self dismissSelf];
}

- (void)acceptOrDeclineOrDetailsBtnAction:(id)sender event:(id)event
{
    NSSet *touches = [event allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.notificationTable];
	NSIndexPath *indexPath = [self.notificationTable indexPathForRowAtPoint: currentTouchPosition];
    
    NSDictionary *notificationDict = notificationArray[indexPath.row];
    owner = notificationDict[@"jsonData"][@"creator"];
    
    notificationType = notificationDict[@"notificationType"];
    
    UIButton *didPressButton = (UIButton *)sender;
    
    if (didPressButton.tag == 200) {
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        NSString *calendarPreference = [standardUserDefaults objectForKey:@"CALENDAR_PREFERENCE"];
        if(calendarPreference == nil) {
            savedIndexPath = indexPath;
            [UIView animateWithDuration:0.5 animations:^(void) {
                self.view.alpha = 0.5;
            }];

            UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Tasks" bundle:nil];
            DefaultCalendarSelectorViewController *defaultsController = [storyBoard instantiateViewControllerWithIdentifier:@"DefaultCalendarSelectorViewController"];
            defaultsController.view.backgroundColor = [UIColor clearColor];
            if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
            } else {
                defaultsController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            }
            
            [self presentViewController:defaultsController animated:YES completion:nil];
        } else {
            [self addEventToCalender:notificationDict andIndexPath:indexPath];
        }
    } else if (didPressButton.tag == 201) {
        [self setCategoryAcceptanceState:NO byNotificationId:notificationDict[@"notificationId"] andRemoveNotificationByIndex:indexPath andOtherDetails:nil];
    } else {
        [self showDetailScreenByNotificationDict:notificationDict];
    }
}

- (void)defaultCalendarSet:(NSNotification*)aNotification
{
//    [self lightBoxFinished];
    [[NSNotificationCenter defaultCenter]
     
     postNotificationName:kLightBoxFinishedNotification
     
     object:self userInfo:@{@"className" : NSStringFromClass([self class])}];
    
    NSDictionary *notificationDict = notificationArray[savedIndexPath.row];
    [self addEventToCalender:notificationDict andIndexPath:savedIndexPath];
}

- (void)showDetailScreenByNotificationDict:(NSDictionary *)notificationDict
{
    
    NSString *type = notificationDict[@"notificationType"];
    [UIView animateWithDuration:0.5 animations:^(void) {
        self.view.alpha = 0.5;
    }];
    if ([type isEqualToString:@"Task"]) {
        TaskViewController *taskController = [self.storyboard instantiateViewControllerWithIdentifier:@"TaskViewController"];
        taskController.notificationDict = notificationDict[@"jsonData"];
        
        taskController.view.backgroundColor = [UIColor clearColor];
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
            self.modalPresentationStyle = UIModalPresentationCurrentContext;
        } else {
            self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            taskController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        }
        
        [self presentViewController:taskController animated:YES completion:nil];
    } else {
        MeetingViewController *meetingController = [self.storyboard instantiateViewControllerWithIdentifier:@"MeetingViewController"];
        meetingController.notificationDict = notificationDict[@"jsonData"];
        
        meetingController.view.backgroundColor = [UIColor clearColor];
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
            self.modalPresentationStyle = UIModalPresentationCurrentContext;
        } else {
            self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            meetingController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        }
        
        [self presentViewController:meetingController animated:YES completion:nil];
    }
}

#pragma mark - UITableView DataSource Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    return [notificationArray count];
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NotificationCell"];
        
    UILabel *contentLbl = (UILabel *)[cell viewWithTag:100];
    [contentLbl setText:[self setNotificationContentByType:notificationArray[indexPath.row]]];
    
    UIButton *acceptBtn = (UIButton *)[cell viewWithTag:200];
    [acceptBtn addTarget:self action:@selector(acceptOrDeclineOrDetailsBtnAction:event:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *declineBtn = (UIButton *)[cell viewWithTag:201];
    [declineBtn addTarget:self action:@selector(acceptOrDeclineOrDetailsBtnAction:event:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *detailsBtn = (UIButton *)[cell viewWithTag:202];
    [detailsBtn addTarget:self action:@selector(acceptOrDeclineOrDetailsBtnAction:event:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}

#pragma mark - UITableView Delegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
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
