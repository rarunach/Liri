//
//  ToDoListViewController.m
//  Liri
//
//  Created by Varun Sankar on 19/08/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "ToDoListViewController.h"
#import "Account.h"
#import "Flurry.h"
#import "Reminder.h"
#import "Meeting.h"
#import "Task.h"
#import "AuthenticationsViewController.h"
#import "DefaultCalendarSelectorViewController.h"
#import <EventKit/EventKit.h>
#import "DiscussionsListController.h"

@interface ToDoListViewController ()
{
//    MKNumberBadgeView *badgeTask, *badgeMeeting;//, *badgeReminder;
    NSMutableArray *tasksArray, *meetingInvitesArray, *remindersArray, *tableArray;
    
    NSIndexPath *index;
    NSString *key, *owner;
    Account *account;
    
    NSMutableDictionary *editDict;
    
    NSDictionary *currentLocalDict;
    NSString *currentTaskId, *currentTaskSource;
    UIAlertView *taskAlertView, *taskFailureAlertView;
    
    BOOL dontCall;
    
    NSDictionary *toDoItemDict;
    
}
@property (weak, nonatomic) IBOutlet UITableView *toDoListTable;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
- (IBAction)segmentCtrlAction:(id)sender;

@end

@implementation ToDoListViewController

@synthesize toDoListTable = _toDoListTable;

@synthesize segmentControl = _segmentControl;


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
    [Flurry logEvent:@"To-do List Screen"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getToDoList:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lightBoxFinished:) name:kLightBoxFinishedNotification object:nil];
    
    account = [Account sharedInstance];
    
    self.toDoListTable.separatorInset = UIEdgeInsetsZero;    // <- any custom inset will do
    self.toDoListTable.separatorColor = [UIColor lightGrayColor];
    
    self.toDoListTable.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self createBadge];
    
	    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : DEFAULT_UICOLOR}];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultCalendarSet:) name:kDefaultCalendarSetNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationCompleted:) name:kTaskAuthenticationCompletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationFailed:) name:kTaskAuthenticationFailedNotification object:nil];
}
- (void)viewDidLayoutSubviews
{
    if(IS_IPHONE_5) {
        //do stuff for 4 inch iPhone screen
    }
    else {
        //do stuff for 3.5 inch iPhone screen
        [self.toDoListTable setFrame:CGRectMake(self.toDoListTable.frame.origin.x, self.toDoListTable.frame.origin.y, self.toDoListTable.frame.size.width, self.toDoListTable.frame.size.height - 88)];
    }
}
- (void)viewWillAppear:(BOOL)animated
{
    [UIView animateWithDuration:0.5 animations:^(void) {
        self.view.alpha = 1.0;
        self.tabBarController.tabBar.hidden = NO;

    }];
    if (!dontCall) {
        [self getTasks];
        [self getMeetingInvites];
        [self getReminders];
    } else {
        dontCall = NO;
    }
    
//    self.badgeTask.value = [Account getTaskCount];
//    self.badgeMeeting.value = [Account getMeetingInviteCount];
    account.badgeTask.value = [Account getTaskCount];
    account.badgeMeetingInvite.value = [Account getMeetingInviteCount];
    
    NSString *toDoCountStr = [NSString stringWithFormat:@"%lu",(account.badgeTask.value + account.badgeMeetingInvite.value)];
    
    [Account setCategoriesCount:toDoCountStr];
    
    [[[[[self tabBarController] tabBar] items] objectAtIndex:2] setBadgeValue:[Account getCategoriesCount]];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private Methods
- (void)createBadge
{
    
    account.badgeTask = [[MKNumberBadgeView alloc] initWithFrame:CGRectMake(self.segmentControl.frame.origin.x + 42,
                                                                         -5,
                                                                         30,
                                                                         20)];
    account.badgeTask.hideWhenZero = YES;
    account.badgeTask.fillColor = [UIColor redColor];
    account.badgeTask.strokeColor = [UIColor redColor];
    account.badgeTask.textColor = [UIColor whiteColor];
    account.badgeTask.shine = NO;
    account.badgeTask.shadow = NO;
    [self.segmentControl addSubview:account.badgeTask];
    account.badgeTask.layer.zPosition = 1;
    
    
    account.badgeMeetingInvite = [[MKNumberBadgeView alloc] initWithFrame:CGRectMake(self.segmentControl.frame.origin.x + 140,
                                                                            -5,
                                                                            30,
                                                                            20)];
    account.badgeMeetingInvite.hideWhenZero = YES;
    account.badgeMeetingInvite.fillColor = [UIColor redColor];
    account.badgeMeetingInvite.strokeColor = [UIColor redColor];
    account.badgeMeetingInvite.textColor = [UIColor whiteColor];
    account.badgeMeetingInvite.shine = NO;
    account.badgeMeetingInvite.shadow = NO;
    [self.segmentControl addSubview:account.badgeMeetingInvite];
    account.badgeMeetingInvite.layer.zPosition = 1;
    
    /*
    self.badgeTask = [[MKNumberBadgeView alloc] initWithFrame:CGRectMake(self.segmentControl.frame.origin.x + 42,
                                                                    -5,
                                                                    30,
                                                                    20)];
    self.badgeTask.hideWhenZero = YES;
    self.badgeTask.fillColor = [UIColor redColor];
    self.badgeTask.strokeColor = [UIColor redColor];
    self.badgeTask.textColor = [UIColor whiteColor];
    self.badgeTask.shine = NO;
    self.badgeTask.shadow = NO;
    [self.segmentControl addSubview:self.badgeTask];
    self.badgeTask.layer.zPosition = 1;
    
    
    self.badgeMeeting = [[MKNumberBadgeView alloc] initWithFrame:CGRectMake(self.segmentControl.frame.origin.x + 140,
                                                                       -5,
                                                                       30,
                                                                       20)];
    self.badgeMeeting.hideWhenZero = YES;
    self.badgeMeeting.fillColor = [UIColor redColor];
    self.badgeMeeting.strokeColor = [UIColor redColor];
    self.badgeMeeting.textColor = [UIColor whiteColor];
    self.badgeMeeting.shine = NO;
    self.badgeMeeting.shadow = NO;
    [self.segmentControl addSubview:self.badgeMeeting];
    self.badgeMeeting.layer.zPosition = 1;
    */
    
    /*
    badgeReminder = [[MKNumberBadgeView alloc] initWithFrame:CGRectMake(self.segmentControl.frame.origin.x + 240,
                                                                        -5,
                                                                        30,
                                                                        20)];
    badgeReminder.value = 0;
    badgeReminder.hideWhenZero = YES;
    badgeReminder.fillColor = [UIColor redColor];
    badgeReminder.strokeColor = [UIColor redColor];
    badgeReminder.textColor = [UIColor whiteColor];
    badgeReminder.shine = NO;
    badgeReminder.shadow = NO;
    [self.segmentControl addSubview:badgeReminder];
    badgeReminder.layer.zPosition = 1;
     */
}

- (void)setSegmentControlIndex
{
    
    if ([self.segmentControl selectedSegmentIndex] == 0) {
        [self.segmentControl setSelectedSegmentIndex:0];
        tableArray = tasksArray;
    } else if ([self.segmentControl selectedSegmentIndex] == 1) {
        [self.segmentControl setSelectedSegmentIndex:1];
        tableArray = meetingInvitesArray;
    } else {
        [self.segmentControl setSelectedSegmentIndex:2];
        tableArray = remindersArray;
    }
    [self.toDoListTable reloadData];
}
-(void)getTasks
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
//        tasksArray = [[NSMutableArray alloc] init];
        
        NSMutableArray *pendingTasks = [NSMutableArray array];
        NSMutableArray *acceptedTasks = [NSMutableArray array];
        NSMutableArray *completedTasks = [NSMutableArray array];
        NSMutableArray *assignedTasks = [NSMutableArray array];
        for (NSDictionary *dict in responseJSON[@"tasks"]) {
            NSString *taskDate = [Account convertGmtToLocalTimeZone:dict[@"value"][@"owner_editable"][@"remindertime"]];
            
            NSString *subtitle = [NSString stringWithFormat:@"%@ %@",dict[@"value"][@"owner_editable"][@"actioncategory"], taskDate];
            
            NSMutableDictionary *task = [[NSMutableDictionary alloc] init];
            [task setObject:subtitle forKey:@"subtitle"];
            [task setObject:dict[@"key"] forKey:@"key"];
            [task setObject:dict[@"value"][@"creator"] forKey:@"creator"];
            
            [task setObject:[Task createTaskWithData:dict[@"value"]] forKey:@"task"];
            
            [task setObject:dict[@"value"][@"discussion_id"] forKey:@"discussionId"];
            
            [task setObject:dict[@"value"][@"message_id"] forKey:@"messageId"];
            
            [task setObject:dict[@"value"] forKey:@"jsonData"];
            
            NSDictionary *externalTaskInfo = dict[@"value"][@"owner_editable"][@"external_task_info"];
            
            if(externalTaskInfo != nil) {
                [task setObject:externalTaskInfo forKey:@"externalTaskInfo"];
            }
            
            if ([account.email isEqualToString:dict[@"value"][@"creator"]]) {
                
                [task setObject:dict[@"value"][@"owner_editable"][@"to"] forKey:@"recipients"];
                
                NSString *assignedTitle = [NSString stringWithFormat:@"%@ (Assigned)",dict[@"value"][@"owner_editable"][@"subject"]];
                
                if ([dict[@"value"][@"user_id"] isEqualToString:account.email]) { // The User assigned Task himself List.
                    
                    
                    [task setObject:assignedTitle forKey: @"title"];
                    
                    [task setObject:dict[@"value"][@"is_accepted"] forKey:@"isAccepted"];
                    
                    [task setObject:dict[@"value"][@"progress_status"] forKey:@"progressStatus"];
                    
                    if ([dict[@"value"][@"progress_status"] isEqualToString:@"completed"]) {

                        [completedTasks addObject:task];
                    } else {
                        
                        [acceptedTasks addObject:task];
                    }
                } else { // The User assigned Tasks List
                    
                    [task setObject:assignedTitle forKey: @"title"];
                    [task setObject:[NSNumber numberWithBool:YES] forKey:@"assigned"];
                    [assignedTasks addObject:task];
                }
            } else { // The User received Tasks List
                NSString *receivedTitle = [NSString stringWithFormat:@"%@ (Received)",dict[@"value"][@"owner_editable"][@"subject"]];
                [task setObject:receivedTitle forKey: @"title"];
                [task setObject:dict[@"value"][@"is_accepted"] forKey:@"isAccepted"];
                if ([dict[@"value"][@"is_accepted"] isEqualToString:@"pending"]) {
                    [task setObject:@"" forKey:@"progressStatus"];
                    [pendingTasks addObject:task];
                    
                } else {
                    [task setObject:dict[@"value"][@"progress_status"] forKey:@"progressStatus"];
                    if ([dict[@"value"][@"progress_status"] isEqualToString:@"completed"]) {
                        [completedTasks addObject:task];
                    } else {
                        [acceptedTasks addObject:task];
                    }
                }
            }
            
            tasksArray = [[pendingTasks arrayByAddingObjectsFromArray:[acceptedTasks arrayByAddingObjectsFromArray:[completedTasks arrayByAddingObjectsFromArray:assignedTasks]]] mutableCopy];
        }
        [Account setTaskCount:(int)pendingTasks.count];
        account.badgeTask.value = [Account getTaskCount];
        
        NSString *toDoCountStr = [NSString stringWithFormat:@"%lu",(account.badgeTask.value + account.badgeMeetingInvite.value)];
        
        [Account setCategoriesCount:toDoCountStr];
        
        [[[[[self tabBarController] tabBar] items] objectAtIndex:2] setBadgeValue:[Account getCategoriesCount]];
        
        [self setSegmentControlIndex];
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
        
        NSLog(@"error message %@ and json %@", [responseJSON objectForKey:@"error"], responseJSON);
    };
    [endpoint getUserTasks];
}

- (void)getMeetingInvites
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
//        meetingInvitesArray = [[NSMutableArray alloc] init];
        
        NSMutableArray *pendingMeetings = [NSMutableArray array];
        NSMutableArray *acceptedMeetings = [NSMutableArray array];
        
        for (NSDictionary *dict in responseJSON[@"meeting_invites"]) {
            BOOL allDayEvent = [dict[@"value"][@"owner_editable"][@"alldayevent"] boolValue];
            NSString *meetingDate;
            if (allDayEvent) {
                meetingDate = dict[@"value"][@"owner_editable"][@"starttime"];
            } else {
                meetingDate = [Account convertGmtToLocalTimeZone:dict[@"value"][@"owner_editable"][@"starttime"]];
            }
           
            
            NSString *subtitle = [NSString stringWithFormat:@"Start Time: %@", meetingDate];
            
            NSMutableDictionary *meeting = [[NSMutableDictionary alloc] init];
            [meeting setObject:dict[@"value"][@"owner_editable"][@"subject"] forKey: @"title"];
            [meeting setObject:subtitle forKey:@"subtitle"];
            [meeting setObject:dict[@"key"] forKey:@"key"];
            [meeting setObject:dict[@"value"][@"creator"] forKey:@"creator"];
            
            [meeting setObject:[Meeting createMeetingWithData:dict[@"value"]] forKey:@"meeting"];
            
            [meeting setObject:dict[@"value"][@"discussion_id"] forKey:@"discussionId"];
            
            [meeting setObject:dict[@"value"][@"message_id"] forKey:@"messageId"];
            
            [meeting setObject:dict[@"value"] forKey:@"jsonData"];
            
            if ([account.email isEqualToString:dict[@"value"][@"creator"]]) {
                
                [meeting setObject:dict[@"value"][@"owner_editable"][@"to"] forKey:@"recipients"];
            }
            if ([dict[@"value"][@"is_accepted"] isEqualToString:@"pending"]) {
                [meeting setObject:dict[@"value"][@"is_accepted"] forKey:@"isAccepted"];
                [pendingMeetings addObject:meeting];
            } else {
                [acceptedMeetings addObject:meeting];
            }
//            [meetingInvitesArray addObject:meeting];
            meetingInvitesArray = [[pendingMeetings arrayByAddingObjectsFromArray:acceptedMeetings] mutableCopy];
        }
        [Account setMeetingInviteCount:(int)pendingMeetings.count];
        account.badgeMeetingInvite.value = [Account getMeetingInviteCount];
        NSString *toDoCountStr = [NSString stringWithFormat:@"%lu",(account.badgeTask.value + account.badgeMeetingInvite.value)];
        
        [Account setCategoriesCount:toDoCountStr];
        
        [[[[[self tabBarController] tabBar] items] objectAtIndex:2] setBadgeValue:[Account getCategoriesCount]];
        
        [self setSegmentControlIndex];
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
        NSLog(@"error message %@ and json %@", [responseJSON objectForKey:@"error"], responseJSON);
    };
    [endpoint getUserMeetingInvites];
}

- (void)getReminders
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
        remindersArray = [[NSMutableArray alloc] init];
        
        for (NSDictionary *dict in responseJSON[@"reminders"]) {
            NSString *subtitle = [NSString stringWithFormat:@"Reminder at %@", dict[@"value"][@"attributes"][@"reminder_time"]];
            NSMutableDictionary *reminder = [[NSMutableDictionary alloc] init];
            [reminder setObject:dict[@"value"][@"attributes"][@"subject"] forKey: @"title"];
            [reminder setObject:subtitle forKey:@"subtitle"];
            
            if (dict[@"value"][@"message_timestamp"] != nil) {
                [reminder setObject:dict[@"value"][@"message_timestamp"] forKey:@"msgTimeStamp"];
            } else {
                [reminder setObject:dict[@"value"][@"last_updated_time"] forKey:@"msgTimeStamp"];
            }
            
            [reminder setObject:[Reminder createReminderWithData:dict[@"value"]] forKey:@"reminder"];
            
            [reminder setObject:dict[@"value"][@"discussion_id"] forKey:@"discussionId"];
            
            [reminder setObject:dict[@"value"][@"message_id"] forKey:@"messageId"];
            
            [remindersArray addObject:reminder];

        }
        [self setSegmentControlIndex];
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
        NSLog(@"error message %@ and json %@", [responseJSON objectForKey:@"error"], responseJSON);
    };
    [endpoint getUserReminders];
}

- (void)setCategoryAcceptanceState:(BOOL)flag
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
        NSMutableDictionary *dict = tableArray[index.row];
        
        if (flag) {
            [dict setObject:@"accept" forKey:@"isAccepted"];
            [dict setObject:@"pending" forKey:@"progressStatus"];
        } else {
//            [dict setObject:@"rejected" forKey:@"isAccepted"];
            [tableArray removeObjectAtIndex:index.row];
        }
        if ([self.segmentControl selectedSegmentIndex] == 0) {
//            self.badgeTask.value = self.badgeTask.value - 1;
//            [Account setTaskCount:self.badgeTask.value];
            if (account.badgeTask.value >= 1) {
                account.badgeTask.value = account.badgeTask.value - 1;
                [Account setTaskCount:account.badgeTask.value];
            }
            
        } else {
//            self.badgeMeeting.value = self.badgeMeeting.value - 1;
//            [Account setMeetingInviteCount:self.badgeMeeting.value];
            if (account.badgeMeetingInvite.value >= 1) {
                account.badgeMeetingInvite.value = account.badgeMeetingInvite.value - 1;
                [Account setMeetingInviteCount:account.badgeMeetingInvite.value];
            }
        }
//        NSString *toDoCountStr = [NSString stringWithFormat:@"%d",(self.badgeTask.value + self.badgeMeeting.value)];
        NSString *toDoCountStr = [NSString stringWithFormat:@"%lu",(account.badgeTask.value + account.badgeMeetingInvite.value)];

        [Account setCategoriesCount:toDoCountStr];
        
        [[[[[self tabBarController] tabBar] items] objectAtIndex:2] setBadgeValue:[Account getCategoriesCount]];
        
        [self.toDoListTable reloadData];
        
        [delegate hideActivityIndicator];
        if(flag) {
            NSDictionary *externalTaskInfo = dict[@"externalTaskInfo"];
            if(externalTaskInfo != nil) {
                currentTaskId = externalTaskInfo[@"id"];
                currentTaskSource = externalTaskInfo[@"source"];
                currentLocalDict = dict;
                NSString *taskMessage;
                if([currentTaskSource isEqualToString:@"Asana"]) {
                    taskMessage = [NSString stringWithFormat:@"%@ has created a task for this in Asana. Do you want to create a subtask under that task?", dict[@"creator"]];
                } else if([currentTaskSource isEqualToString:@"Trello"]) {
                    taskMessage = [NSString stringWithFormat:@"%@ has created a card for this task in Trello. Do you want to add yourself as a member of that card?", dict[@"creator"]];
                } else if([currentTaskSource isEqualToString:@"Salesforce"]) {
                    taskMessage = [NSString stringWithFormat:@"%@ has indicated that they would like to track this in Salesforce. Do you want to create a task in Salesforce?", dict[@"creator"]];
                }
                taskAlertView = [[UIAlertView alloc]
                                 initWithTitle:@"Task Management Tool"
                                 message:taskMessage
                                 delegate:self cancelButtonTitle:@"No"
                                 otherButtonTitles:@"Yes", nil];
                [taskAlertView show];
            }
        }
        [self removeNotificationItemInLightBox:key];
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                                        id responseJSON){
        [delegate hideActivityIndicator];
        NSLog(@"error message %@ and json %@", responseJSON[@"error"], responseJSON);
    };
    NSArray *separatedArray = [key componentsSeparatedByString:@"::"];
    [endpoint setCategoryAcceptanceWithOwner:owner MessageId:separatedArray[2] DiscussionId:separatedArray[1] CategoryType:[separatedArray[3] intValue] andIsAccepted:flag];
}

- (void)setCategoryProgressStatus
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
        NSMutableDictionary *dict = tableArray[index.row];
        [dict setObject:@"completed" forKey:@"progressStatus"];
        [self.toDoListTable reloadData];
        [delegate hideActivityIndicator];
        
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                                        id responseJSON){
        [delegate hideActivityIndicator];
        NSLog(@"error message %@ and json %@", responseJSON[@"error"], responseJSON);
    };
    NSArray *separatedArray = [key componentsSeparatedByString:@"::"];
    [endpoint setCategoryProgressStatusWithOwner:owner MessageId:separatedArray[2] DiscussionId:separatedArray[1] CategoryType:[separatedArray[3] intValue] andProgressStatus:@"completed"];
}

- (void)getIndexPathUsingEvent:(id)event
{
    NSSet *touches = [event allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.toDoListTable];
	index = [self.toDoListTable indexPathForRowAtPoint: currentTouchPosition];
    
    key = tableArray[index.row][@"key"];
    owner = tableArray[index.row][@"creator"];
}

- (void)getToDoList:(NSNotification *)notification
{
    if (self.navigationController.topViewController == self) {
        [self getTasks];
        [self getMeetingInvites];
        [self getReminders];
    }
}
- (void)goToTaskEditModeScreen:(NSMutableDictionary *)dictionary
{
    editDict = dictionary;
    
    [UIView animateWithDuration:0.5 animations:^(void) {
        self.view.alpha = 0.5;
    }];
    
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Discussion" bundle:nil];
    
    TaskViewController *taskController = [storyBoard instantiateViewControllerWithIdentifier:@"TaskViewController"];
    
    taskController.delegate = self;
    
    taskController.task = editDict[@"task"];
    
    if (editDict[@"msgTimeStamp"] != nil) {
        taskController.messageTimeStamp = editDict[@"msgTimeStamp"];
    } else {
        taskController.messageTimeStamp = [NSString stringWithFormat:@"%@", [NSDate date]];
    }
    
    taskController.discussionId = editDict[@"discussionId"];
    
    taskController.messageId = editDict[@"messageId"];

    taskController.taskExternalSource = editDict[@"externalTaskInfo"];
    
    taskController.isEditMode = YES;
    
    if ([editDict[@"creator"] isEqualToString:account.email]) {
        
        taskController.isNotCurrentUser = NO;
        
        taskController.recipientStatusArray = editDict[@"recipients"];
        
        if (nil == editDict[@"progressStatus"]) {
            taskController.completeTask = NO;
        } else {
            if ([editDict[@"progressStatus"] isEqualToString:@"pending"]) {
                
                taskController.completeTask = YES;
            } else if ([editDict[@"progressStatus"] isEqualToString:@"completed"]){
                
                taskController.completeTask = NO;
            }
            taskController.editTaskDict = editDict;
        }
    } else {
        
        if ([editDict[@"isAccepted"] isEqualToString:@"accept"]) {
            if ([editDict[@"progressStatus"] isEqualToString:@"pending"]) {
                
                taskController.completeTask = YES;
            } else if ([editDict[@"progressStatus"] isEqualToString:@"completed"]){
                
                taskController.completeTask = NO;
            }
            
            taskController.editTaskDict = editDict;
        }
        taskController.isNotCurrentUser = YES;
    }
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        
        self.modalPresentationStyle = UIModalPresentationCurrentContext;
        
        UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
        
        rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
        
    } else {
        
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        
        taskController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        
    }
    
    taskController.view.backgroundColor = [UIColor clearColor];
    
//    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
//    
//    rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
    
    self.tabBarController.tabBar.hidden = YES;
    
    [self presentViewController:taskController animated:YES completion:nil];
}

- (void)goToMeetingEditModeScreen:(NSMutableDictionary *)dictionary
{
    editDict = dictionary;
    
    [UIView animateWithDuration:0.5 animations:^(void) {
        self.view.alpha = 0.5;
    }];
    
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Discussion" bundle:nil];
    
    MeetingViewController *meetingController = [storyBoard instantiateViewControllerWithIdentifier:@"MeetingViewController"];
    
    meetingController.delegate = self;
    
    meetingController.meeting = editDict[@"meeting"];
    
    if (editDict[@"msgTimeStamp"] != nil) {
        meetingController.messageTimeStamp = editDict[@"msgTimeStamp"];
    } else {
        meetingController.messageTimeStamp = [NSString stringWithFormat:@"%@", [NSDate date]];
    }
    
    meetingController.discussionId = editDict[@"discussionId"];
    
    meetingController.messageId = editDict[@"messageId"];
    
    meetingController.isEditMode = YES;
    
    if ([editDict[@"creator"] isEqualToString:account.email]) {
        
        meetingController.isNotCurrentUser = NO;
        
        meetingController.recipientStatusArray = editDict[@"recipients"];
        
    } else {
        
        meetingController.isNotCurrentUser = YES;
    }

    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        
        self.modalPresentationStyle = UIModalPresentationCurrentContext;
        
        UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
        
        rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
        
    } else {
        
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        
        meetingController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        
    }

    meetingController.view.backgroundColor = [UIColor clearColor];
    
//    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
//    
//    rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
    
    self.tabBarController.tabBar.hidden = YES;
    
    [self presentViewController:meetingController animated:YES completion:nil];
}

- (void)goToReminderEditModeScreen:(NSMutableDictionary *)dictionary
{
    editDict = dictionary;
    
    [UIView animateWithDuration:0.5 animations:^(void) {
        self.view.alpha = 0.5;
    }];
    
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Discussion" bundle:nil];
    
    ReminderViewController *reminderController = [storyBoard instantiateViewControllerWithIdentifier:@"ReminderViewController"];

    reminderController.delegate = self;
    
    reminderController.reminder = editDict[@"reminder"];
    
    if (editDict[@"msgTimeStamp"] != nil) {
        reminderController.messageTimeStamp = editDict[@"msgTimeStamp"];
    } else {
        reminderController.messageTimeStamp = [NSString stringWithFormat:@"%@", [NSDate date]];
    }
    
    reminderController.discussionId = editDict[@"discussionId"];

    reminderController.messageId = editDict[@"messageId"];
    
    reminderController.isEditMode = YES;
    
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        
        self.modalPresentationStyle = UIModalPresentationCurrentContext;
        
        UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
        
        rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
        
    } else {
        
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        
        reminderController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        
    }
    reminderController.view.backgroundColor = [UIColor clearColor];
    
    self.tabBarController.tabBar.hidden = YES;
    
    [self presentViewController:reminderController animated:YES completion:nil];
    
}

- (BOOL)theItemIsCreatedByCurrentUser:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)addEventToCalender:(NSDictionary *)localDict
{
    NSDictionary *notificationDetails = localDict;
    
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
                
                if ([self.segmentControl selectedSegmentIndex] == 0) {
                    NSString *taskDate = [Account convertGmtToLocalTimeZone:notificationDetails[@"owner_editable"] [@"remindertime"]];
                    thisEvent.startDate = [dateFormatter dateFromString:taskDate];
                    //                    thisEvent.startDate = [Account convertGmtToLocalTimeZone:notificationDetails[@"owner_editable"] [@"remindertime"] andDateFormat:NO];
                    
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
                    if ([self.segmentControl selectedSegmentIndex] == 0) {
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
                
                [self setCategoryAcceptanceState:YES];
            });
        }
    }];
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

- (void)defaultCalendarSet:(NSNotification*)aNotification
{
//    [self lightBoxFinished];
    [[NSNotificationCenter defaultCenter]
     
     postNotificationName:kLightBoxFinishedNotification
     
     object:self userInfo:@{@"className" : NSStringFromClass([self class])}];
    [self addEventToCalender:toDoItemDict];
}

- (void) lightBoxFinished:(NSNotification*)aNotification {
    
    NSDictionary *info = [aNotification userInfo];
    if ([info[@"className"] isEqualToString:@"ReminderViewController"] || [info[@"className"] isEqualToString:@"TaskViewController"] || [info[@"className"] isEqualToString:@"MeetingViewController"] || [info[@"className"] isEqualToString:@"ToDoListViewController"]) {
        [UIView animateWithDuration:0.3 animations:^(void) {
            
            self.view.alpha = 1.0;
            if(self.isViewLoaded && self.view.window) {
                self.tabBarController.tabBar.hidden = NO;
            }

        }];
        if (!dontCall) {
            [self getTasks];
            [self getMeetingInvites];
            [self getReminders];
        } else {
            dontCall = NO;
        }
        
        //    self.badgeTask.value = [Account getTaskCount];
        //    self.badgeMeeting.value = [Account getMeetingInviteCount];
        account.badgeTask.value = [Account getTaskCount];
        account.badgeMeetingInvite.value = [Account getMeetingInviteCount];
        
        NSString *toDoCountStr = [NSString stringWithFormat:@"%lu",(account.badgeTask.value + account.badgeMeetingInvite.value)];
        
        [Account setCategoriesCount:toDoCountStr];
        
        [[[[[self tabBarController] tabBar] items] objectAtIndex:2] setBadgeValue:[Account getCategoriesCount]];
    }
    

}

- (void)deleteCategoryInDiscussionListUsingDiscussionId:(NSString *)discussionId messageId:(NSString *)msgId andCategoryType:(int)categoryType
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    UITabBarController *tabBarCtrl = [delegate tabBarController];
    if (nil != tabBarCtrl && tabBarCtrl.viewControllers.count > 0) {
        
        UINavigationController *navCtlr = tabBarCtrl.viewControllers[0];
        
        if (nil != navCtlr) {
            
            if (navCtlr.childViewControllers.count > 0) {
                
                DiscussionsListController * discussionListCtrl = (DiscussionsListController *)navCtlr.childViewControllers[0];
                
                if (nil != discussionListCtrl) {
                    [discussionListCtrl deleteCategoryUsingDiscussionId:discussionId messageId:msgId andCategoryType:categoryType];
                }
            }
        }
    }
}

- (void)removeNotificationItemInLightBox:(NSString *)notificationDetails
{
    NSArray *separatedArray = [notificationDetails componentsSeparatedByString:@"::"];
    NSMutableArray *notifications = [Account sharedInstance].notificationsHistory;
    for (int i = 0; i < notifications.count; i++ ) {
        NSDictionary *categoryDetails = notifications[i][@"jsonData"];
        NSInteger categoryType = [categoryDetails[@"category_type"] integerValue] ;
        
        if ([categoryDetails[@"discussion_id"] isEqualToString:separatedArray[1]] && [categoryDetails[@"message_id"] isEqualToString:separatedArray[2]] &&categoryType == [separatedArray[3] integerValue]) {
            [[Account sharedInstance].notificationsHistory removeObject:notifications[i]];
            break;
        }
    }
}

#pragma mark - UIButton Actions
- (void)acceptOrDeclineBtnAction:(id)sender event:(id)event
{
    [self getIndexPathUsingEvent:event];
    UIButton *didPressButton = (UIButton *)sender;
    toDoItemDict = tableArray[index.row][@"jsonData"];
    
    if (didPressButton.tag == 300) {
//        [self setCategoryAcceptanceState:YES];
        
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        NSString *calendarPreference = [standardUserDefaults objectForKey:@"CALENDAR_PREFERENCE"];
        if(calendarPreference == nil) {
            [UIView animateWithDuration:0.5 animations:^(void) {
                self.view.alpha = 0.5;
            }];
            
            UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Tasks" bundle:nil];
            DefaultCalendarSelectorViewController *defaultsController = [storyBoard instantiateViewControllerWithIdentifier:@"DefaultCalendarSelectorViewController"];
            defaultsController.view.backgroundColor = [UIColor clearColor];
            
            UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
            
            rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
            
            if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
                rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
            } else {
                rootViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
                defaultsController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            }
            [self presentViewController:defaultsController animated:YES completion:nil];
        } else {
            [self addEventToCalender:toDoItemDict];
        }
    } else if (didPressButton.tag == 301) {
        [self setCategoryAcceptanceState:NO];
    }
}
- (void)circleBtnAction:(id)sender event:(id)event
{
    [self getIndexPathUsingEvent:event];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Can this task be marked complete?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alert.tag = 1;
    [alert show];

}

#pragma mark - UITableView Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    return tableArray.count;
}
- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
//    static NSString *cellIdentifier = @"toDoListCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"toDoListCell"];
    if (cell != nil) {
        UIImageView *photoImgView = (UIImageView *)[cell viewWithTag:100];
        [photoImgView.layer setBorderColor:DEFAULT_CGCOLOR];
        
        UILabel *lblName = (UILabel *)[cell viewWithTag:200];
        [lblName setText:tableArray[indexPath.row][@"title"]];
        
        UILabel *timestamp = (UILabel *)[cell viewWithTag:201];
        [timestamp setText:tableArray[indexPath.row][@"subtitle"]];
        
        UIButton *acceptBtn = (UIButton *)[cell viewWithTag:300];
        [acceptBtn.layer setBorderColor:[[UIColor greenColor] CGColor]];
        [acceptBtn addTarget:self action:@selector(acceptOrDeclineBtnAction:event:) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *declineBtn = (UIButton *)[cell viewWithTag:301];
        [declineBtn.layer setBorderColor:[[UIColor redColor] CGColor]];
        [declineBtn addTarget:self action:@selector(acceptOrDeclineBtnAction:event:) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *circleBtn = (UIButton *)[cell viewWithTag:302];
        circleBtn.layer.cornerRadius = circleBtn.frame.size.width / 2;
        [circleBtn.layer setBorderColor:DEFAULT_CGCOLOR];
        [circleBtn addTarget:self action:@selector(circleBtnAction:event:) forControlEvents:UIControlEventTouchUpInside];
        
        UIImageView *calendarImg = (UIImageView *)[cell viewWithTag:303];
//        NSLog(@"title %@", lblName.text);
        if ([self.segmentControl selectedSegmentIndex] == 0) {
            
            calendarImg.hidden = YES;
            
            if ([tableArray[indexPath.row][@"isAccepted"] isEqualToString:@"pending"]) {
                acceptBtn.hidden = NO;
                declineBtn.hidden = NO;
                circleBtn.hidden = YES;
            } else {
                if ([tableArray[indexPath.row][@"progressStatus"] isEqualToString:@"pending"]) {
                    [circleBtn setBackgroundColor:nil];
                    [circleBtn setUserInteractionEnabled:YES];
                    
                    acceptBtn.hidden = YES;
                    declineBtn.hidden = YES;
                    circleBtn.hidden = NO;
                } else {
                    if (tableArray[indexPath.row][@"assigned"]) {
                        acceptBtn.hidden = YES;
                        declineBtn.hidden = YES;
                        circleBtn.hidden = YES;
                        
                        calendarImg.hidden = NO;
                        calendarImg.image = [UIImage imageNamed:@"Task-Outgoing-Icon.png"];
                    } else {
                        [circleBtn setBackgroundColor:DEFAULT_UICOLOR];
                        [circleBtn setUserInteractionEnabled:NO];
                        
                        NSMutableAttributedString *attString=[[NSMutableAttributedString alloc]initWithString:lblName.text];
                        [attString addAttribute:NSStrikethroughStyleAttributeName value:[NSNumber numberWithInt:2] range:NSMakeRange(0,[attString length])];
                        
                        lblName.attributedText = attString;
                        
                        attString=[[NSMutableAttributedString alloc]initWithString:timestamp.text];
                        [attString addAttribute:NSStrikethroughStyleAttributeName value:[NSNumber numberWithInt:2] range:NSMakeRange(0,[attString length])];
                        
                        timestamp.attributedText = attString;
                        
                        acceptBtn.hidden = YES;
                        declineBtn.hidden = YES;
                        circleBtn.hidden = NO;
                    }
                }
            }
        } else if ([self.segmentControl selectedSegmentIndex] == 1) {
            calendarImg.hidden = NO;
            calendarImg.image = [UIImage imageNamed:@"Calendar-Icon.png"];
            if ([tableArray[indexPath.row][@"isAccepted"] isEqualToString:@"pending"]) {
                acceptBtn.hidden = NO;
                declineBtn.hidden = NO;
            } else {
                acceptBtn.hidden = YES;
                declineBtn.hidden = YES;
            }
            circleBtn.hidden = YES;
        } else {
            calendarImg.hidden = NO;
            calendarImg.image = [UIImage imageNamed:@"Reminder-Icon.png"];
            acceptBtn.hidden = YES;
            declineBtn.hidden = YES;
            circleBtn.hidden = YES;
        }
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.segmentControl selectedSegmentIndex] == 0) {
//        if ([self theItemIsCreatedByCurrentUser:indexPath]) {
            [self goToTaskEditModeScreen:tableArray[indexPath.row]];
//        }
    } else if ([self.segmentControl selectedSegmentIndex] == 1) {
        
//        if ([self theItemIsCreatedByCurrentUser:indexPath]) {
            [self goToMeetingEditModeScreen:tableArray[indexPath.row]];
//        }
    } else {
        
        [self goToReminderEditModeScreen:tableArray[indexPath.row]];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [delegate showActivityIndicator];
        
        NSDictionary *category =  tableArray[indexPath.row];
        
        int type;
        
        if ([self.segmentControl selectedSegmentIndex] == 0) {
            type = 3;
        } else if ([self.segmentControl selectedSegmentIndex] == 1) {
            type = 4;
        } else {
            type = 2;
        }
        
        id<APIAccessClient> endpoint =
        (id<APIAccessClient>)[[APIManager
                               sharedInstanceWithClientProtocol:
                               @protocol(APIAccessClient)] client];
        
        endpoint.successJSON = ^(NSURLRequest *request,
                                 id responseJSON){
            
            if ([self.segmentControl selectedSegmentIndex] == 0) {
                
                Task *task = tableArray[indexPath.row][@"task"];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    EKEventStore *store = [[EKEventStore alloc] init];
                    
                    EKEvent* eventToRemove = [store eventWithIdentifier:task.calendarId];
                    
                    NSError *err;
                    
                    BOOL success = [store removeEvent:eventToRemove span:EKSpanThisEvent error:&err];
                    if (!success) {
                        NSLog(@"Error %@", err);
                    }
                });
            } else if ([self.segmentControl selectedSegmentIndex] == 1) {
                
                Meeting *meeting = tableArray[indexPath.row][@"meeting"];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    EKEventStore *store = [[EKEventStore alloc] init];
                    
                    EKEvent* eventToRemove = [store eventWithIdentifier:meeting.calendarId];
                    
                    NSError *err;
                    BOOL success = [store removeEvent:eventToRemove span:EKSpanFutureEvents error:&err];
                    
                    if (!success) {
                        NSLog(@"Error %@", err);
                    }
                });
            } else {
                Reminder *myReminder = tableArray[indexPath.row][@"reminder"];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    EKEventStore *store = [[EKEventStore alloc] init];
                    EKReminder *reminder = (EKReminder *)[store calendarItemWithIdentifier:myReminder.reminderId];
                    
                    NSError *err;
                    BOOL success = [store removeReminder:reminder commit:YES error:&err];
                    if (!success) {
                        NSLog(@"Error %@", err);
                    }
                });
            }
            
            [tableView beginUpdates];
            
            [tableArray removeObjectAtIndex:indexPath.row];
            
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
            
            [tableView endUpdates];
            
            if (type == 3 || type == 4) {
                
                if ([category[@"creator"] isEqualToString:account.email]) {
                    [self deleteCategoryInDiscussionListUsingDiscussionId:category[@"discussionId"] messageId:category[@"messageId"] andCategoryType:type];
                }
            } else {
                [self deleteCategoryInDiscussionListUsingDiscussionId:category[@"discussionId"] messageId:category[@"messageId"] andCategoryType:type];
            }
            [delegate hideActivityIndicator];
            
        };
        endpoint.failureJSON = ^(NSURLRequest *request,
                                 id responseJSON){
            [delegate hideActivityIndicator];
        };
        
        [endpoint deleteCategoryWithDiscussionId: category[@"discussionId"] MessageId: category[@"messageId"] CategoryType: type];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.segmentControl selectedSegmentIndex] == 0) {
        if (![tableArray[indexPath.row][@"isAccepted"] isEqualToString:@"pending"]) {
            return 60;
        }
    } else if ([self.segmentControl selectedSegmentIndex] == 1) {
        if (![tableArray[indexPath.row][@"isAccepted"] isEqualToString:@"pending"]) {
            return 60;
        }
    } else {
        return 60;
    }
    return 75;
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

#pragma mark - UIAlertView Methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            [self setCategoryProgressStatus];
        }
    }
    if(alertView == taskFailureAlertView) {
    } else if (alertView == taskAlertView) {
        if (alertView.cancelButtonIndex == buttonIndex) {
        } else {
            [self authenticateTaskSource:currentTaskSource];
        }
    } else if(buttonIndex == 0 && alertView.tag == KLocalResourceAccessFailureTag) {

        [self setCategoryAcceptanceState:YES];
    }
}

- (IBAction)segmentCtrlAction:(id)sender {
    if ([self.segmentControl selectedSegmentIndex] == 0) {
        tableArray = tasksArray;
    } else if ([self.segmentControl selectedSegmentIndex] == 1) {
        tableArray = meetingInvitesArray;
    } else {
        tableArray = remindersArray;
    }
    [self.toDoListTable reloadData];
}

- (void)reminderCreatedWithSubject:(NSString *)subject time:(NSString*)time tone:(NSString*)tone frequency:(NSString*)frequency notes:(NSString *)notes priority:(NSString *)priority reminderId:(NSString *)reminderId categoryType:(int)categoryType categoryId:(int)categoryId andEditMode:(BOOL)edited
{
    dontCall = YES;
    
    NSString *subtitle = [NSString stringWithFormat:@"Reminder at %@", time];
    
    [editDict setObject:subject forKey: @"title"];
    
    [editDict setObject:subtitle forKey:@"subtitle"];
    
    Reminder *editedReminder = editDict[@"reminder"];
    
    editedReminder.subject = subject;
    
    editedReminder.reminderTime = time;
    
    editedReminder.ringtone = tone;
    
    editedReminder.repeatFrequency = frequency;
    
    editedReminder.text = notes;
    
    editedReminder.priority = priority;
    
    editedReminder.reminderId = reminderId;
 
    [self.toDoListTable reloadData];
}

- (void)taskCreatedWithSubject:(NSString *)subject toList:(NSString*)toList category:(NSString*)category reminderTime:(NSString*)reminderTime alert:(NSString *)alert secondAlert:(NSString *)secondAlert repeatFrequency:(NSString *)repeatFrequency priority:(NSString *)priority notes:(NSString *)notes calendarId:(NSString *)calendarId categoryType:(int)categoryType categoryId:(int)categoryId andEditMode:(BOOL)edited
{
    
    dontCall = YES;
    
    NSString *assignedTitle = [NSString stringWithFormat:@"%@ (Assigned)", subject];
    
    NSString *subtitle = [NSString stringWithFormat:@"%@ %@",category, reminderTime];
    
    [editDict setObject:assignedTitle forKey: @"title"];
    
    [editDict setObject:subtitle forKey:@"subtitle"];
    
    Task *editedTask = editDict[@"task"];
    
    editedTask.subject = subject;
    
    editedTask.toList = toList;
    
    editedTask.actionCategory = category;
    
    editedTask.reminderTime = reminderTime;
    
    editedTask.alert = alert;
    
    editedTask.secondAlert = secondAlert;
    
    editedTask.repeatFrequency = repeatFrequency;
    
    editedTask.priority = priority;
    
    editedTask.text = notes;
    
    editedTask.calendarId = calendarId;
    
    [self.toDoListTable reloadData];
}

- (void)meetingCreatedWithSubject:(NSString *)subject toList:(NSString *)toList location:(NSString *)location allDayEvent:(BOOL)allDay startDate:(NSString *)startDate endDate:(NSString *)endDate repeatFrequency:(NSString *)repeatFrequency alert:(NSString *)alert secondAlert:(NSString *)secondAlert priority:(NSString *)priority filePath:(NSString *)filePath notes:(NSString *)notes calendarId:(NSString *)calendarId categoryType:(int)categoryType categoryId:(int)categoryId andEditMode:(BOOL)edited
{
    dontCall = YES;
    
    NSString *subtitle = [NSString stringWithFormat:@"Start Time: %@", startDate];
    
    [editDict setObject:subject forKey: @"title"];
    
    [editDict setObject:subtitle forKey:@"subtitle"];
    
    Meeting *editedMeeting = editDict[@"meeting"];
    
    editedMeeting.subject = subject;
    
    editedMeeting.toList = toList;
    
    editedMeeting.location = location;
    
    editedMeeting.allDayEvent = allDay;
    
    editedMeeting.startDate = startDate;
    
    editedMeeting.endDate = endDate;
    
    editedMeeting.repeatFrequency = repeatFrequency;
    
    editedMeeting.alert = alert;
    
    editedMeeting.secondAlert = secondAlert;
    
    editedMeeting.priority = priority;
    
    editedMeeting.filePath = filePath;
    
    editedMeeting.text = notes;
    
    editedMeeting.calendarId = calendarId;
    
    [self.toDoListTable reloadData];
}

- (void)markTaskAsCompleted
{
    dontCall = YES;
    
    [editDict setObject:@"completed" forKey: @"progressStatus"];
    
    [self.toDoListTable reloadData];
}

- (void) authenticateTaskSource: (NSString *) externalSystem {
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
    
    // do create
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id response){
        [delegate hideActivityIndicator];
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
    
    NSDate *duedate = [dateFormatter dateFromString:localDict[@"jsonData"][@"owner_editable"][@"remindertime"]];
    NSString *duedatestring = [dateFormatter2 stringFromDate:duedate];
    
    [endpoint saveAsanaSubtask:idnum withName:localDict[@"jsonData"][@"owner_editable"][@"subject"] andDescription:localDict[@"jsonData"][@"owner_editable"][@"notes"] andDue:duedatestring];
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
    
    Task *taskDetails = localDict[@"value"][@"task"];
    
    // do create
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id response){
        [delegate hideActivityIndicator];
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
    
    NSDate *duedate = [dateFormatter dateFromString:localDict[@"jsonData"][@"owner_editable"][@"remindertime"]];
    NSString *duedatestring = [dateFormatter2 stringFromDate:duedate];
    
    [endpoint saveSalesforceTask:localDict[@"jsonData"][@"owner_editable"][@"subject"] withAccountId:idnum andDescription:localDict[@"jsonData"][@"owner_editable"][@"notes"] andDue:duedatestring];
}
@end
