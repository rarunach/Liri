//
//  TaskViewController.m
//  Liri
//
//  Created by Varun Sankar on 22/07/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "TaskViewController.h"
#import "Account.h"
#import "AppDelegate.h"
#import "AppConstants.h"
#import <EventKit/EventKit.h>
#import "DefaultTaskSourceViewController.h"
#import "Flurry.h"
#import "DefaultCalendarSelectorViewController.h"
#import "RecipientStatusViewController.h"

@interface TaskViewController ()
{
    
    UITextField *titleField, *contactField;
    UIButton *taskDateButton, *taskCategoryButton, *taskRepeatButton, *taskAlertButton, *taskSecondAlertButton, *taskExternalSourceButton;
    UIDatePicker *datePicker;
    UIPickerView *pickerView;
    UISegmentedControl *taskPriority;
    UITextView *taskNotes;
    
    NSString *defaultTitle, *defaultContact, *defaultCategory, *defaultDate, *defaultRepeat, *defaultAlert, *defaultSecondAlert, *defaultNotes, *defaultTaskExternalSource, *localToGmt;
    NSArray *pickerData, *taskCategoryData, *taskRepeatData, *taskAlertData;
    NSInteger selectedIndex;
    NSString *selectedTaskSource;
    
    int priorityIndex, selectionId;
    BOOL taskNotesAppear, isSender, taskSourceSelected;
    NSString *externalTaskId;

    NSMutableArray *emailArr;
    NSMutableArray *searchArray;
    
    NSString *calendarId;
}

@property (weak, nonatomic) IBOutlet UIView *taskView;
@property (weak, nonatomic) IBOutlet UITableView *taskTable;
@property (weak, nonatomic) IBOutlet UITableView *contactTableView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@property (weak, nonatomic) IBOutlet UILabel *taskTitle;

@property (weak, nonatomic) IBOutlet UIView *footerTaskView;

@property (weak, nonatomic) IBOutlet UIButton *footerBtn;
@property (weak, nonatomic) IBOutlet UIButton *completeBtn;

- (IBAction)backAction:(id)sender;
- (IBAction)doneAction:(id)sender;

- (IBAction)footerBtnAction:(id)sender;

@end

@implementation TaskViewController
@synthesize taskView = _taskView;
@synthesize taskTable = _taskTable, contactTableView = _contactTableView;
@synthesize isEditMode = _isEditMode;
@synthesize task = _task;
@synthesize chatName = _chatName, chatMessage = _chatMessage, discussionId = _discussionId, messageId = _messageId;
@synthesize delegate = _delegate;
@synthesize annotationImg = _annotationImg;
@synthesize notificationDict = _notificationDict;
@synthesize backButton = _backButton, doneButton = _doneButton;
@synthesize discussionTitle;
@synthesize messageTimeStamp = _messageTimeStamp;

@synthesize recipientStatusArray = _recipientStatusArray;

@synthesize isNotCurrentUser = _isNotCurrentUser;

@synthesize taskTitle = _taskTitle;

@synthesize completeTask = _completeTask;

@synthesize editTaskDict = _editTaskDict;

@synthesize taskExternalSource = _taskExternalSource;

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
    
    [Flurry logEvent:@"Task Screen"];
    selectedIndex = -1;
    selectedTaskSource = @"";
    self.taskTable.separatorInset = UIEdgeInsetsZero;    // <- any custom inset will do
    self.taskTable.separatorColor = [UIColor lightGrayColor];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tableViewTapped:)];
    [tap setNumberOfTapsRequired:1];
    [self.taskTable addGestureRecognizer:tap];

    self.contactTableView.separatorInset = UIEdgeInsetsZero;
    self.contactTableView.separatorColor = [UIColor lightGrayColor];
    
    datePicker = [[UIDatePicker alloc]init];
    
    
    CGRect frame = datePicker.frame;
    frame.size.width -= 50;
    frame.size.height -= 50;
    frame.origin.x += 5;
    frame.origin.y += 40;
    [datePicker setFrame:frame];
    [datePicker addTarget:self action:@selector(dateValueChanged:) forControlEvents:UIControlEventValueChanged];
    [datePicker setMinimumDate:[NSDate date]];
    [datePicker setDatePickerMode:UIDatePickerModeDateAndTime];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultCalendarSet:) name:kDefaultCalendarSetNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskSelectionCompleted:) name:kTaskSelectionCompletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lightBoxFinished:) name:kLightBoxFinishedNotification object:nil];


    if (self.isEditMode) {
        
        [self.taskTitle setText:self.task.subject];
        
        if (self.isNotCurrentUser) {
            
            [self.backButton setTitle:@"Close" forState:UIControlStateNormal];
            
            [self.doneButton setHidden:YES];
            
            if (self.completeTask) {
                
                [self.footerTaskView setHidden:NO];
                
                [self.footerBtn setHidden:NO];
                                
                [self.footerBtn setTitle:@"Mark as complete" forState:UIControlStateNormal];
            }
        }
        
        if (nil != self.recipientStatusArray) {
            
            [self.footerTaskView setHidden:NO];
            
            [self.footerBtn setHidden:NO];
            
            if (self.completeTask) {
                [self.completeBtn setHidden:NO];
            }
            
        }
        
        defaultTitle = self.task.subject;
        defaultContact = self.task.toList;
        defaultCategory = self.task.actionCategory;
        
        defaultDate = [Account convertGmtToLocalTimeZone:self.task.reminderTime];
        
//        defaultDate = self.task.reminderTime;
        defaultAlert = self.task.alert;
        defaultSecondAlert = self.task.secondAlert;
        defaultRepeat = self.task.repeatFrequency;
        
        if (nil != self.taskExternalSource) {
            defaultTaskExternalSource = self.taskExternalSource[@"source"];
        } else {
            defaultTaskExternalSource = @"Choose >";
        }
        
        if ([self.task.priority isEqualToString:@"None"]) {
            priorityIndex = 0;
        } else if ([self.task.priority isEqualToString:@"Low"]) {
            priorityIndex = 1;
        } else if ([self.task.priority isEqualToString:@"Med"]) {
            priorityIndex = 2;
        } else {
            priorityIndex = 3;
        }
        defaultNotes =self.task.text;
        
    } else if (nil != self.notificationDict) {
        
        [self.taskTitle setText:[[self.notificationDict objectForKey:@"owner_editable"] objectForKey:@"subject"]];
        
        [self.taskTable setUserInteractionEnabled:NO];

        [self.backButton setTitle:@"Close" forState:UIControlStateNormal];
        [self.doneButton setHidden:YES];
        
        defaultTitle = [[self.notificationDict objectForKey:@"owner_editable"] objectForKey:@"subject"];
        NSArray *toArray = [[self.notificationDict objectForKey:@"owner_editable"] objectForKey:@"to"];
        NSString *emailStr = @"";
        for (NSString *recipient in toArray) {
            emailStr = [emailStr stringByAppendingString:[NSString stringWithFormat:@"%@,",recipient]];
        }
        defaultContact = emailStr;
        defaultCategory = [[self.notificationDict objectForKey:@"owner_editable"] objectForKey:@"actioncategory"];
        
        defaultDate = [Account convertGmtToLocalTimeZone:[[self.notificationDict objectForKey:@"owner_editable"] objectForKey:@"remindertime"]];
//        defaultDate = [[self.notificationDict objectForKey:@"owner_editable"] objectForKey:@"remindertime"];
        defaultAlert = [[self.notificationDict objectForKey:@"member_editable"] objectForKey:@"alert1"];
        defaultSecondAlert = [[self.notificationDict objectForKey:@"member_editable"] objectForKey:@"alert2"];
        defaultRepeat = [[self.notificationDict objectForKey:@"owner_editable"] objectForKey:@"repeat_frequency"];
        
        if (nil != self.notificationDict[@"owner_editable"][@"external_task_info"]) {
            defaultTaskExternalSource = self.notificationDict[@"owner_editable"][@"external_task_info"][@"source"];
        } else {
            defaultTaskExternalSource = @"Choose >";
        }
        
        NSString *priority = [[self.notificationDict objectForKey:@"owner_editable"] objectForKey:@"priority"];
        
        
        if ([priority isEqualToString:@"None"]) {
            priorityIndex = 0;
        } else if ([priority isEqualToString:@"Low"]) {
            priorityIndex = 1;
        } else if ([priority isEqualToString:@"Med"]) {
            priorityIndex = 2;
        } else {
            priorityIndex = 3;
        }
        defaultNotes = [[self.notificationDict objectForKey:@"owner_editable"] objectForKey:@"notes"];
    } else {
        defaultTitle = @"";
        defaultCategory = @"Complete by";
        [self getDate];
        defaultRepeat = @"Never >";
        defaultAlert = @"Never >";
        defaultSecondAlert = @"Never >";
        
        defaultTaskExternalSource = @"Choose >";
        
        [taskPriority setSelectedSegmentIndex:0];
//        if ([self.chatMessage isEqualToString:@""]) {
//            UIImageView *imageView = [[UIImageView alloc] initWithImage:self.annotationImg];
//            CGRect aRect = CGRectMake(156, 8, 16, 16);
//            [imageView setFrame:aRect];
//            UIBezierPath *exclusionPath = [UIBezierPath bezierPathWithRect:CGRectMake(CGRectGetMinX(imageView.frame), CGRectGetMinY(imageView.frame), CGRectGetWidth(taskNotes.frame), CGRectGetHeight(imageView.frame))];
//            taskNotes.textContainer.exclusionPaths = @[exclusionPath];
//            [taskNotes addSubview:imageView];
//        }
        defaultNotes = [NSString stringWithFormat:@"[%@] %@", self.chatName, self.chatMessage];
        priorityIndex = 0;
        if (nil != self.annotationImg) {
            defaultNotes = [NSString stringWithFormat:@"%@ posted an annotated picture.", self.chatName];
        } else if (defaultNotes.length > KMaxSummaryPointDescriptionLength){
            defaultNotes = [defaultNotes substringToIndex:[defaultNotes length] - KMaxSummaryPointDescriptionLength];
        }
    }
    
    
    pickerView = [[UIPickerView alloc]initWithFrame:CGRectMake(15, 30, 250, 200)];
    pickerView.showsSelectionIndicator = YES;
    pickerView.delegate = self;
    taskCategoryData = [[NSArray alloc] initWithObjects:@"Follow up by", @"Complete by", @"Send by", @"Receive by", @"Read by", @"Review by", @"Respond by", nil];
    taskRepeatData = [[NSArray alloc] initWithObjects:@"Never", @"Every day", @"Every week", @"Every 2 weeks", @"Every month", @"Every year", nil];
    taskAlertData = [[NSArray alloc] initWithObjects:@"Never", @"At time of event", @"5 minutes before", @"15 minutes before", @"30 minutes before", @"1 hour before", @"2 hours before", @"1 day before", @"2 days before", @"1 week before", nil];
    [self emailContact];
    
}

- (void)viewDidLayoutSubviews
{
    if(!IS_IPHONE_5) {
        //do stuff for 3.5 inch iPhone screen
        [self.taskView setFrame:CGRectMake(self.taskView.frame.origin.x, self.taskView.frame.origin.y, self.taskView.frame.size.width, 460)];
        
        [self.contactTableView setFrame:CGRectMake(self.contactTableView.frame.origin.x, self.contactTableView.frame.origin.y, self.contactTableView.frame.size.width, 105)];
        [self.completeBtn setFrame:CGRectMake(self.completeBtn.frame.origin.x, 379, self.completeBtn.frame.size.width, 40)];
        
        [self.footerBtn setFrame:CGRectMake(self.footerBtn.frame.origin.x, 420, self.footerBtn.frame.size.width, 40)];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    selectedIndex = -1;
    [UIView animateWithDuration:0.5f animations:^(void) {
        self.view.alpha = 1.0;
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private Methods
- (void)getDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE, MM/dd/yy, h:mm a"];
    
    NSDate *currentDate = [NSDate date];
//    NSTimeInterval secondsInFiveMinutes = 5 * 60;
//    NSDate *dateFiveMinutesAhead = [currentDate dateByAddingTimeInterval:secondsInFiveMinutes];
    NSString *stringFromDate = [dateFormatter stringFromDate:currentDate];
    defaultDate = stringFromDate;
}

- (void)getIndexPath:(id)sender event:(id)event
{
    [pickerView reloadAllComponents];
    [titleField resignFirstResponder];
    [contactField resignFirstResponder];
    [self.taskTable flashScrollIndicators];
    
    NSSet *touches = [event allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.taskTable];
	NSIndexPath *indexPath = [self.taskTable indexPathForRowAtPoint: currentTouchPosition];

    
    NSMutableArray *indexArray =[[NSMutableArray alloc]init];
	
    if(selectedIndex == indexPath.row)
    {
        selectedIndex = -1;
    }
    //First we check if a cell is already expanded.
    //If it is we want to minimize make sure it is reloaded to minimize it back
    
    else if(selectedIndex >= 0)
	{
		NSIndexPath *previousPath = [NSIndexPath indexPathForRow:selectedIndex inSection:0];
		[indexArray addObject:previousPath];
		selectedIndex = indexPath.row;
    }
	else
	{
		selectedIndex = indexPath.row;
	}
    
    //Finally set the selected index to the new selection and reload it to expand
    if (indexPath!=nil) {
        [indexArray addObject:indexPath];
        [self.taskTable reloadRowsAtIndexPaths:indexArray withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    UIButton *button = (UIButton *)sender;
    if (button.tag == 500) {
        [datePicker removeFromSuperview];
    } else if (button.tag == 600) {
        [pickerView removeFromSuperview];
    }
}

- (void)emailContact

{
    emailArr = [[NSMutableArray alloc]init];
    searchArray = [[NSMutableArray alloc]init];

    Account *account = [Account sharedInstance];
    for (Buddy *buddy in account.buddyList.allBuddies) {
        if (buddy.isUser) {
            NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:buddy.firstName, @"firstName", buddy.lastName, @"lastName", buddy.displayName, @"name", buddy.email, @"email", nil];
            if (![emailArr containsObject:dict]) {
                [emailArr addObject:dict];
            }
            
            //            [emailArr addObject:buddy.email];
        }
    }
    
}

- (void)searchAutocompleteEntriesWithSubstring:(NSString *)substring
{
    
    [searchArray removeAllObjects];
    
    /*
     for(NSString *curString in emailArr)
     {
     NSRange substringRange = [curString rangeOfString:substring options:NSCaseInsensitiveSearch];
     if (substringRange.location == 0)
     {
     [searchArray addObject:curString];
     }
     }
     */
    
    for(NSDictionary *curDict in emailArr)
    {
        //        if ([[curDict objectForKey:@"name"] rangeOfString:substring options:NSCaseInsensitiveSearch].location!=NSNotFound)
        //        {
        //            [searchArray addObject:curDict];
        //        }
        
        
        //        NSRange substringRange = [[curDict objectForKey:@"name"] rangeOfString:substring options:NSCaseInsensitiveSearch];
        //        if (substringRange.location == 0)
        //        {
        //            [searchArray addObject:curDict];
        //        }
        NSString *first = [curDict objectForKey:@"firstName"];
        NSString *last = [curDict objectForKey:@"lastName"];
        NSString *name = curDict[@"name"];
        
        if ((first == [NSNull null]) || (last == [NSNull null]) || (name == [NSNull null])) continue;
        
        NSRange firstNameRange = [[curDict objectForKey:@"firstName"] rangeOfString:substring options:NSCaseInsensitiveSearch];
        NSRange lastNameRange = [[curDict objectForKey:@"lastName"] rangeOfString:substring options:NSCaseInsensitiveSearch];
        NSRange nameRange = [name rangeOfString:substring options:NSCaseInsensitiveSearch];
        
        if (firstNameRange.location == 0 || lastNameRange.location == 0 || nameRange.location == 0)
        {
            [searchArray addObject:curDict];
        }
    }
    
    if ([searchArray count] > 0) {
        self.contactTableView.hidden = NO;
    } else {
        self.contactTableView.hidden = YES;
    }
    
    [self.contactTableView reloadData];
}

- (void)stopInteractTableView
{
    taskNotesAppear = YES;
    [UIView animateWithDuration:0.2f animations:^{
        CGRect frame = self.taskTable.frame;
        frame.origin.y -= 180;
        [self.taskTable setFrame:frame];
    }];
}

- (BOOL)contactFieldValidation
{
    
    NSMutableArray *validateEmailArray =  (NSMutableArray *)[contactField.text componentsSeparatedByString:@","];
    
    BOOL isValid = YES;
    isSender = NO;
    Account *account = [Account sharedInstance];

    for (int i = 0; i < [validateEmailArray count]; i++) {
        
        if ([account.email isEqualToString:[validateEmailArray objectAtIndex:i]]) {
            isSender = YES;
        }
        
        if (i != [validateEmailArray count] - 1) {
            if ([[validateEmailArray objectAtIndex:i] isEqualToString:@""] || ![self validateEmail:[validateEmailArray objectAtIndex:i]]) {
                isValid = NO;
                break;
            }
        }
        else {
            if (![[validateEmailArray objectAtIndex:i] isEqualToString:@""]) {
                if(![self validateEmail:[validateEmailArray objectAtIndex:i]]){
                    isValid = NO;
                    break;
                }
            } else {
                break;
            }
        }
    }
    return isValid;
}

- (BOOL)validateEmail: (NSString *) candidate {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    return [emailTest evaluateWithObject:candidate];
}

- (void)setAnnotationImage
{
    UIImageView *imageView = [[UIImageView alloc] initWithImage:self.annotationImg];
    CGRect aRect = CGRectMake(20, 8, 60, 60);
    [imageView setFrame:aRect];
    UIBezierPath *exclusionPath = [UIBezierPath bezierPathWithRect:CGRectMake(CGRectGetMinX(imageView.frame), CGRectGetMinY(imageView.frame), CGRectGetWidth(taskNotes.frame), CGRectGetHeight(imageView.frame))];
    taskNotes.textContainer.exclusionPaths = @[exclusionPath];
    [taskNotes addSubview:imageView];
}

- (void)validationAlertWithTitle:(NSString *)title andMessage:(NSString *)message
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate hideActivityIndicator];
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:title
                          message:message
                          delegate:self cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
    [alert show];
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

- (void)addTaskToCalender
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
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
                EKEvent *thisEvent;
                if (self.isEditMode) {
                    thisEvent  = [eventStore eventWithIdentifier:self.task.calendarId];
	                if (nil == thisEvent) {
                    
	                    thisEvent  = [EKEvent eventWithEventStore:eventStore];
	                }
                } else {
                    thisEvent  = [EKEvent eventWithEventStore:eventStore];
                }
                //Title
                thisEvent.title = titleField.text;
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"EEE, MM/dd/yy, h:mm a"];
                
                thisEvent.startDate = [dateFormatter dateFromString:taskDateButton.titleLabel.text];
                //    thisEvent.endDate = [dateFormatter dateFromString:[itsEndDate objectAtIndex:indexPath.row]];
                NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
                NSString *calendarPreference = [standardUserDefaults objectForKey:@"CALENDAR_PREFERENCE"];
                
                [thisEvent setCalendar:[eventStore calendarWithIdentifier:calendarPreference]];
                // thisEvent.allDay = TRUE;
                
                //setting the Reuccurence rule
                //Repeat
                NSString *repeatText = taskRepeatButton.titleLabel.text;
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
                    thisEvent.endDate = [dateFormatter dateFromString:taskDateButton.titleLabel.text];
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
                
                if (![taskAlertButton.titleLabel.text isEqualToString:@"Never >"]) {
                    EKAlarm *alarm1 = [EKAlarm alarmWithRelativeOffset:[self configureAlarm:taskAlertButton.titleLabel.text]];
                    [myAlarmsArray addObject:alarm1];
                }
                
                if (![taskSecondAlertButton.titleLabel.text isEqualToString:@"Never >"]) {
                    EKAlarm *alarm2 = [EKAlarm alarmWithRelativeOffset:[self configureAlarm:taskSecondAlertButton.titleLabel.text]];
                    [myAlarmsArray addObject:alarm2];
                }
                if (myAlarmsArray.count > 0) {
                    thisEvent.alarms = myAlarmsArray;
                }
                
                
                //Notes
                thisEvent.notes = taskNotes.text;
                
                
                NSError *err;
                
                
                BOOL success = [eventStore saveEvent:thisEvent span:EKSpanFutureEvents error:&err];
                if (!success) {
                    NSLog(@"error in calender event %@", err);
                    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                    [delegate hideActivityIndicator];
	            } else {
	                calendarId = thisEvent.eventIdentifier;
	                if(taskSourceSelected) {
	                    [self saveTaskToExternalSource];
	                } else {
    	                [self createTask:thisEvent.eventIdentifier];
        	        }
            	}
                NSLog(@"%@", thisEvent.eventIdentifier);
            });
        }
    }];
}

- (void)createTask:(NSString *)localCalendarId
{
    //do server action
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // do create
    id<APIAccessClient> discussionsEndpoint =
    (id<APIAccessClient>)[[APIManager
                                 sharedInstanceWithClientProtocol:
                                 @protocol(APIAccessClient)] client];
    
    discussionsEndpoint.successJSON = ^(NSURLRequest *request,
                                        id responseJSON){
        
        if ([self.delegate respondsToSelector:@selector(taskCreatedWithSubject:toList:category:reminderTime:alert:secondAlert:repeatFrequency:priority:notes:calendarId:categoryType:categoryId:andEditMode:)]) {
            [self.delegate taskCreatedWithSubject:titleField.text toList:contactField.text category:taskCategoryButton.titleLabel.text reminderTime:localToGmt alert:taskAlertButton.titleLabel.text secondAlert:taskSecondAlertButton.titleLabel.text repeatFrequency:taskRepeatButton.titleLabel.text priority:[taskPriority titleForSegmentAtIndex:taskPriority.selectedSegmentIndex] notes:taskNotes.text calendarId:localCalendarId categoryType:3 categoryId:3 andEditMode:self.isEditMode];
        }
        
        [delegate hideActivityIndicator];
        [self dismissSelf];
    };
    discussionsEndpoint.failureJSON = ^(NSURLRequest *request,
                                        id responseJSON){
        [delegate hideActivityIndicator];
        UIAlertView *failureAlert = [[UIAlertView alloc]
                                     initWithTitle:@""
                                     message:[responseJSON objectForKey:@"error"]
                                     delegate:self cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil];
        [failureAlert setTag:112];
        [failureAlert show];
        
        NSLog(@"error message %@ and json %@", [responseJSON objectForKey:@"error"], responseJSON);
    };
    
    NSMutableArray *toListArray = (NSMutableArray *)[contactField.text componentsSeparatedByString:@","];
    if ([[toListArray lastObject] isEqualToString:@""]) {
        [toListArray removeLastObject];
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE, MM/dd/yy, h:mm a"];
     NSDate *localDate = [dateFormatter dateFromString:taskDateButton.titleLabel.text];
    localToGmt = [Account convertLocalToGmtTimeZone:localDate];
    
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:titleField.text, @"subject", toListArray, @"to", taskCategoryButton.titleLabel.text, @"action_category", localToGmt, @"reminder_time", taskAlertButton.titleLabel.text, @"alert1", taskSecondAlertButton.titleLabel.text, @"alert2", taskRepeatButton.titleLabel.text, @"repeat_frequency", taskNotes.text, @"notes", [taskPriority titleForSegmentAtIndex:taskPriority.selectedSegmentIndex], @"priority", localCalendarId, @"local_calendar_id", nil];

    if(taskSourceSelected) {
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        NSString *sourceName = [standardUserDefaults objectForKey:@"TASK_PREFERENCE_SOURCE"];
        NSString *level2Id = [standardUserDefaults objectForKey:@"TASK_PREFERENCE_LEVEL2"];
        if([sourceName isEqualToString:@"Trello"]) {
            [attributes setValue:externalTaskId forKey:@"id"];
            [attributes setValue:sourceName forKey:@"source"];
        } else if([sourceName isEqualToString:@"Asana"]) {
            [attributes setValue:externalTaskId forKey:@"id"];
            [attributes setValue:sourceName forKey:@"source"];
        } else if([sourceName isEqualToString:@"Salesforce"]) {
            [attributes setValue:level2Id forKey:@"id"];
            [attributes setValue:sourceName forKey:@"source"];
        }
    }
    
//    [discussionsEndpoint createTaskWithDiscussionId:self.discussionId MessageId:self.messageId CategoryType:3 andAttributes:attributes];
    [discussionsEndpoint createTaskWithDiscussionId:self.discussionId MessageId:self.messageId CategoryType:3 MsgTimeStamp:self.messageTimeStamp andAttributes:attributes];

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
        if ([self.delegate respondsToSelector:@selector(markTaskAsCompleted)]) {
            
            [self.delegate markTaskAsCompleted];
        }
        [delegate hideActivityIndicator];
        
        [self dismissSelf];

    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        NSLog(@"error message %@ and json %@", responseJSON[@"error"], responseJSON);
        [delegate hideActivityIndicator];

    };
    
    NSArray *separatedArray = [self.editTaskDict[@"key"] componentsSeparatedByString:@"::"];
    
    [endpoint setCategoryProgressStatusWithOwner:self.editTaskDict[@"creator"] MessageId:separatedArray[2] DiscussionId:separatedArray[1] CategoryType:[separatedArray[3] intValue] andProgressStatus:@"completed"];
}

- (void) lightBoxFinished:(NSNotification*)aNotification {
    
    NSDictionary *info = [aNotification userInfo];
    if ([info[@"className"] isEqualToString:@"RecipientStatusViewController"] || [info[@"className"] isEqualToString:@"DefaultTaskSourceViewController"] || [info[@"className"] isEqualToString:@"TaskViewController"]) {
        selectedIndex = -1;
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        } else {
            self.view.hidden = NO;
        }
        
        [UIView animateWithDuration:0.3 animations:^(void) {
            
            self.view.alpha = 1.0;
            
        }];
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

#pragma mark - UIButton Actions
- (void)clearTaskTitleAction:(id)sender
{
    [titleField setText:@""];
}

- (void)clearTaskContactsAction:(id)sender
{
    [contactField setText:@""];
}

- (void)dateValueChanged:(id)sender
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE, MM/dd/yy, h:mm a"];
    
    NSString *stringFromDate = [dateFormatter stringFromDate:[datePicker date]];
    defaultDate = stringFromDate;
    [taskDateButton setTitle:stringFromDate forState:UIControlStateNormal];
}

- (void)taskDateAction:(id)sender event:(id)event
{
    [self getIndexPath:sender event:event];
}

- (void)taskCategoryAction:(id)sender event:(id)event
{
    selectionId = 1;
    pickerData = taskCategoryData;
    [self getIndexPath:sender event:event];
}

- (void)taskRepeatButton:(id)sender event:(id)event
{
    selectionId = 2;
    pickerData = taskRepeatData;
    [self getIndexPath:sender event:event];
}

- (void)taskExternalSourceButton:(id)sender event:(id)event
{
    if (![self isFreeUserForContacts]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:FREE_USER_CONFIG_MSG delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    } else {
        [UIView animateWithDuration:0.5 animations:^(void) {
            self.view.alpha = 0.5;
        }];
        
        UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
        rootViewController.modalPresentationStyle = UIModalPresentationNone;

        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Tasks" bundle:nil];
        DefaultTaskSourceViewController *defaultsController = [storyBoard instantiateViewControllerWithIdentifier:@"DefaultTaskSourceViewController"];
        defaultsController.view.backgroundColor = [UIColor clearColor];
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        } else {
            self.view.hidden = YES;
            defaultsController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        }

        [self presentViewController:defaultsController animated:YES completion:nil];
    }
}

- (void)taskAlertButton:(id)sender event:(id)event
{
    selectionId = 3;
    pickerData = taskAlertData;
    [self getIndexPath:sender event:event];
}

- (void)taskSecondAlertButton:(id)sender event:(id)event
{
    selectionId = 4;
    pickerData = taskAlertData;
    [self getIndexPath:sender event:event];
}

- (void)taskPriorityAction: (id)sender
{
    priorityIndex = (int)taskPriority.selectedSegmentIndex;
}

- (void)clearNotesAction:(id)sender
{
    [taskNotes setText:@""];
}

#pragma mark - IBAction Methods
- (IBAction)backAction:(id)sender
{
    if (self.isEditMode || nil != self.notificationDict) {
        [self dismissSelf];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Do you really want to cancel this task?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        [alert setTag:KWarningAlertTag];
        [alert show];
    }
}

- (IBAction)doneAction:(id)sender
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE, MM/dd/yy, h:mm a"];
    
    NSDate *checkDate = [dateFormatter dateFromString:taskDateButton.titleLabel.text];
    if ([titleField.text isEqualToString:@""]) {
        [self validationAlertWithTitle:@"Alert" andMessage:@"Please provide task subject."];
    } else if ([contactField.text isEqualToString:@""]) {
        [self validationAlertWithTitle:@"Alert" andMessage:@"You should add atleast one recipient for the task to be assigned."];
    } else if (![self contactFieldValidation]) {
        [self validationAlertWithTitle:@"Alert" andMessage:@"Recipient list contains invalid email addresses. Please correct the mistake."];
    } else if ([checkDate timeIntervalSinceNow] < 0.0) {
        // Date has passed
        [self validationAlertWithTitle:@"Alert" andMessage:@"Task date cannot be in the past."];
    } else {
        if (isSender) {
            
            NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
            NSString *calendarPreference = [standardUserDefaults objectForKey:@"CALENDAR_PREFERENCE"];
            if(calendarPreference == nil) {
                [UIView animateWithDuration:0.5 animations:^(void) {
                    self.view.alpha = 0.5;
                }];
                UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
                rootViewController.modalPresentationStyle = UIModalPresentationNone;
                
                UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Tasks" bundle:nil];
                DefaultCalendarSelectorViewController *defaultsController = [storyBoard instantiateViewControllerWithIdentifier:@"DefaultCalendarSelectorViewController"];
                defaultsController.view.backgroundColor = [UIColor clearColor];
                
                if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
                } else {
                    self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
                    defaultsController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
                }

                [self presentViewController:defaultsController animated:YES completion:nil];
            } else {
                [self addTaskToCalender];
            }
        } else {
			calendarId = @"";
            if(taskSourceSelected) {
                [self saveTaskToExternalSource];
            } else {
                [self createTask:@""];
            }
        }
    }
}

- (void)defaultCalendarSet:(NSNotification*)aNotification
{
//    [self lightBoxFinished];
    [[NSNotificationCenter defaultCenter]
     
     postNotificationName:kLightBoxFinishedNotification
     
     object:self userInfo:@{@"className" : NSStringFromClass([self class])}];
    [self addTaskToCalender];
}

- (void)saveTaskToExternalSource {
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSString *taskSource = [standardUserDefaults objectForKey:@"TASK_PREFERENCE_SOURCE"];

    if([taskSource isEqualToString:@"Trello"]) {
        [self saveTaskToTrello];
    } else if([taskSource isEqualToString:@"Asana"]) {
        [self saveTaskToAsana];
    } else if([taskSource isEqualToString:@"Salesforce"]) {
        [self createTask:calendarId];
    }
}

- (void)saveTaskToAsana {
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSString *workspaceId = [standardUserDefaults objectForKey:@"TASK_PREFERENCE_LEVEL1"];
    NSString *projectId = [standardUserDefaults objectForKey:@"TASK_PREFERENCE_LEVEL2"];
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
        externalTaskId = [[response objectForKey:@"data"] objectForKey:@"id"];
        [self createTask:calendarId];
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
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
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE, MM/dd/yy, h:mm a"];
    
    NSDateFormatter *dateFormatter2 = [[NSDateFormatter alloc] init];
    [dateFormatter2 setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    
    NSDate *duedate = [dateFormatter dateFromString:taskDateButton.titleLabel.text];
    NSString *duedatestring = [dateFormatter2 stringFromDate:duedate];
    
    [endpoint saveAsanaTask:titleField.text withWorkspaceId:workspaceId andProjectId:projectId andDescription:taskNotes.text andDue:duedatestring];
}

- (void)saveTaskToTrello {
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSString *listId = [standardUserDefaults objectForKey:@"TASK_PREFERENCE_LEVEL3"];
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
        externalTaskId = [response objectForKey:@"id"];
        [self createTask:calendarId];
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
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
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE, MM/dd/yy, h:mm a"];

    NSDateFormatter *dateFormatter2 = [[NSDateFormatter alloc] init];
    [dateFormatter2 setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];

    NSDate *duedate = [dateFormatter dateFromString:taskDateButton.titleLabel.text];
    NSString *duedatestring = [dateFormatter2 stringFromDate:duedate];

    [endpoint saveTrelloTask:titleField.text withListId:listId andDescription:taskNotes.text andDue:duedatestring];
}

- (void)saveTaskToSalesforce {
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSString *accountId = [standardUserDefaults objectForKey:@"TASK_PREFERENCE_LEVEL2"];
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
        [self createTask:@""];
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
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
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE, MM/dd/yy, h:mm a"];
    
    NSDateFormatter *dateFormatter2 = [[NSDateFormatter alloc] init];
    [dateFormatter2 setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    
    NSDate *duedate = [dateFormatter dateFromString:taskDateButton.titleLabel.text];
    NSString *duedatestring = [dateFormatter2 stringFromDate:duedate];
    
    [endpoint saveSalesforceTask:titleField.text withAccountId:accountId andDescription:taskNotes.text andDue:duedatestring];
}

- (void)taskSelectionCompleted:(NSNotification*)aNotification
{
//    [self lightBoxFinished];
    [[NSNotificationCenter defaultCenter]
     
     postNotificationName:kLightBoxFinishedNotification
     
     object:self userInfo:@{@"className" : NSStringFromClass([self class])}];
    
    NSMutableArray *indexArray = [[NSMutableArray alloc] init];
    NSUInteger cellIndexCoords[2] = {0,4};
    NSIndexPath *cellIndex = [NSIndexPath indexPathWithIndexes:cellIndexCoords length:2];
    [indexArray addObject:cellIndex];
    UITableViewCell *cell = [self.taskTable cellForRowAtIndexPath:cellIndex];
    
    taskExternalSourceButton = (UIButton *)[cell viewWithTag:1400];
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSString *taskPreference = [standardUserDefaults objectForKey:@"TASK_PREFERENCE_SOURCE"];
    if(taskPreference != nil) {
        [taskExternalSourceButton setTitle:[NSString stringWithFormat:@"%@ >", taskPreference] forState:UIControlStateNormal];
        taskSourceSelected = true;
    } else {
        [taskExternalSourceButton setTitle:@"Choose >" forState:UIControlStateNormal];
        taskSourceSelected = false;
    }
}

#pragma mark - UITableView DataSource Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    if (self.taskTable == tableView) {
        return 9;
    } else {
        return [searchArray count];
    }
}
- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    if (self.taskTable == tableView) {
    UITableViewCell *cell;
    if(indexPath.row == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"taskTitleCell"];
        
        titleField = (UITextField *)[cell viewWithTag:100];
        [titleField setText:defaultTitle];
    
    } else if (indexPath.row == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"taskContactCell"];
        
        contactField = (UITextField *)[cell viewWithTag:300];
        [contactField setText:defaultContact];
        
    } else if (indexPath.row == 2) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"taskDateCell"];
        
        taskCategoryButton = (UIButton *)[cell viewWithTag:500];
        [taskCategoryButton addTarget:self action:@selector(taskCategoryAction:event:) forControlEvents:UIControlEventTouchUpInside];
        
        taskDateButton = (UIButton *)[cell viewWithTag:600];
        [taskDateButton addTarget:self action:@selector(taskDateAction:event:) forControlEvents:UIControlEventTouchUpInside];
        
        [taskDateButton setTitle:defaultDate forState:UIControlStateNormal];
        [taskCategoryButton setTitle:defaultCategory forState:UIControlStateNormal];
        
        if (selectedIndex == indexPath.row) {
            [taskDateButton setTitle:defaultDate forState:UIControlStateNormal];
            [cell addSubview:datePicker];
            [cell addSubview:pickerView];
        }
        
    } else if (indexPath.row == 3) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"taskAlarmCell"];
        
        taskRepeatButton = (UIButton *)[cell viewWithTag:700];
        [taskRepeatButton addTarget:self action:@selector(taskRepeatButton:event:) forControlEvents:UIControlEventTouchUpInside];
        if (selectedIndex == indexPath.row) {
            [cell addSubview:pickerView];
        } else {
            [taskRepeatButton setTitle:defaultRepeat forState:UIControlStateNormal];
        }
    } else if (indexPath.row == 4) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"taskExternalSourceCell"];
        
        taskExternalSourceButton = (UIButton *)[cell viewWithTag:1400];
        [taskExternalSourceButton setTitle:defaultTaskExternalSource forState:UIControlStateNormal];
        [taskExternalSourceButton addTarget:self action:@selector(taskExternalSourceButton:event:) forControlEvents:UIControlEventTouchUpInside];
    } else if (indexPath.row == 5) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"taskAlertCell"];
        
        taskAlertButton = (UIButton *)[cell viewWithTag:800];
        [taskAlertButton addTarget:self action:@selector(taskAlertButton:event:) forControlEvents:UIControlEventTouchUpInside];
        if (selectedIndex == indexPath.row) {
            [cell addSubview:pickerView];
        } else {
            [taskAlertButton setTitle:defaultAlert forState:UIControlStateNormal];
        }
    } else if (indexPath.row == 6) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"taskSecondAlertCell"];
        
        taskSecondAlertButton = (UIButton *)[cell viewWithTag:900];
        [taskSecondAlertButton addTarget:self action:@selector(taskSecondAlertButton:event:) forControlEvents:UIControlEventTouchUpInside];
        if (selectedIndex == indexPath.row) {
            [cell addSubview:pickerView];
        } else {
            [taskSecondAlertButton setTitle:defaultSecondAlert forState:UIControlStateNormal];
        }
    } else if (indexPath.row == 7) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"taskPriorityCell"];
        
        taskPriority = (UISegmentedControl *)[cell viewWithTag:1000];
        [taskPriority addTarget:self
                             action:@selector(taskPriorityAction:)
                   forControlEvents:UIControlEventValueChanged];
        [taskPriority setSelectedSegmentIndex:priorityIndex];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"taskNoteCell"];
        
        taskNotes = (UITextView *)[cell viewWithTag:1100];
//        if (self.annotationImg) {
//            [self setAnnotationImage];
//        } else {
            [taskNotes setText:defaultNotes];
//        }
        
        UIButton *clearNotesButton = (UIButton *)[cell viewWithTag:1200];
        [clearNotesButton addTarget:self action:@selector(clearNotesAction:) forControlEvents:UIControlEventTouchUpInside];
        [clearNotesButton.layer setCornerRadius:clearNotesButton.frame.size.width/2];
        /*
        if (nil != self.annotationImg) {
            UIImageView *imgView = (UIImageView *)[cell viewWithTag:1300];
            [imgView setImage: self.annotationImg];
            [imgView setHidden:NO];
            
            [taskNotes setText:self.chatMessage];
            [taskNotes setHidden:YES];
            
            [clearNotesButton setHidden:YES];
        }
         */
    }
        if (nil != self.notificationDict || self.isNotCurrentUser) {
            [cell setUserInteractionEnabled:NO];
        }
    return cell;
    } else {
        static NSString *cellIdentifier = @"ContactCell";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        //5.1 you do not need this if you have set SettingsCell as identifier in the storyboard (else you can remove the comments on this code)
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        }
        
        cell.textLabel.text = [[searchArray objectAtIndex:indexPath.row] objectForKey:@"name"];
        [cell.textLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:15.0]];
        
        cell.detailTextLabel.text = [[searchArray objectAtIndex:indexPath.row] objectForKey:@"email"];
        [cell.detailTextLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:15.0]];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return cell;
    }
}

#pragma mark - UITableView Delegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.taskTable == tableView) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else {
    NSMutableArray *emailAddedArr = (NSMutableArray *)[contactField.text componentsSeparatedByString:@","];
    
    
    
    NSString *emailStr = @"";
    
    if ([emailAddedArr count] == 1)
    {
//        contactField.text = [NSString stringWithFormat:@"%@,",[searchArray objectAtIndex:indexPath.row]];
        contactField.text = [NSString stringWithFormat:@"%@,",[[searchArray objectAtIndex:indexPath.row] objectForKey:@"email"]];
    }
    else
    {
        [emailAddedArr removeLastObject];
        //        [emailAddedArr addObject:[searchArray objectAtIndex:indexPath.row]];
        [emailAddedArr addObject:[[searchArray objectAtIndex:indexPath.row] objectForKey:@"email"]];
        for (NSString *email in emailAddedArr)
        {
            emailStr = [emailStr stringByAppendingString:[NSString stringWithFormat:@"%@,",email]];
        }
        contactField.text = emailStr;
        
    }
        defaultContact = contactField.text;
    self.contactTableView.hidden = YES;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.taskTable == tableView) {
        if(selectedIndex == indexPath.row)
        {
            return 220;
        }
        if (indexPath.row == 8) {
            return 250;
        }
    }
    return 44;
}

#pragma mark - UIPickerView DataSource Methods
//Columns in picker views

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView; {
    return 1;
}

//Rows in each Column

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [pickerData count];
}

#pragma mark - UIPickerView Delegate Method
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [pickerData objectAtIndex:row];
}

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (selectionId == 1) {
        defaultCategory = [pickerData objectAtIndex:row];
        [taskCategoryButton setTitle:defaultCategory forState:UIControlStateNormal];
    } else if (selectionId == 2) {
        defaultRepeat = [NSString stringWithFormat:@"%@ >",[pickerData objectAtIndex:row]];
        [taskRepeatButton setTitle:defaultRepeat forState:UIControlStateNormal];
    } else if (selectionId == 3) {
        defaultAlert = [NSString stringWithFormat:@"%@ >",[pickerData objectAtIndex:row]];
        [taskAlertButton setTitle:defaultAlert forState:UIControlStateNormal];
    } else if (selectionId == 4) {
        defaultSecondAlert = [NSString stringWithFormat:@"%@ >",[pickerData objectAtIndex:row]];
        [taskSecondAlertButton setTitle:defaultSecondAlert forState:UIControlStateNormal];
    }
}

#pragma mark - UITextField Delegate Methods
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == contactField) {
    
        if ([string isEqualToString:@" "] && self.contactTableView.hidden) {
            return NO;
        }
        
        NSString * searchStr = [textField.text stringByReplacingCharactersInRange:range withString:string];
        defaultContact = searchStr;
        NSArray *myArray = [searchStr componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
        if ([myArray count] == 1)
        {
            [self searchAutocompleteEntriesWithSubstring:searchStr];
        } else {
            [self searchAutocompleteEntriesWithSubstring:[myArray lastObject]];
        }
    } else {
        defaultTitle =[textField.text stringByReplacingCharactersInRange:range withString:string];
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        return (newLength > KMaxUserCategoryLength) ? NO : YES;
    }
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField == titleField) {
        [self.contactTableView setHidden:YES];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField;
{
    [textField resignFirstResponder];
    [self.contactTableView setHidden:YES];
    return YES;
    
}

#pragma mark - UITextView Delegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    [self stopInteractTableView];
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    defaultNotes = defaultNotes = [textView.text stringByReplacingCharactersInRange:range withString:text];
    NSUInteger newLength = [textView.text length] + [text length] - range.length;
    return (newLength > KMaxSummaryPointDescriptionLength) ? NO : YES;
}

#pragma mark - UITapGesture Method
- (void)tableViewTapped:(UIGestureRecognizer *)gesture
{
    [[self view] endEditing:YES];
    if (taskNotesAppear) {
        taskNotesAppear = NO;
        [UIView animateWithDuration:0.2f animations:^{
            CGRect frame = self.taskTable.frame;
            frame.origin.y += 180;
            [self.taskTable setFrame:frame];
        }];
    }
    
}

#pragma mark - UIAlertView Delegate Method
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == KWarningAlertTag && buttonIndex == 1) {
        [self dismissSelf];
    } else if (alertView.tag == KLocalResourceAccessFailureTag && buttonIndex == 0) {
        calendarId = @"";
        if(taskSourceSelected) {
            [self saveTaskToExternalSource];
        } else {
            [self createTask:@""];
        }
    } else if (alertView.tag == 1 && buttonIndex == 1) {
        [self setCategoryProgressStatus];
    } else if (alertView.tag == 112) {
        [self dismissSelf];
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

- (IBAction)footerBtnAction:(id)sender {
    
    UIButton *completeBtn = (UIButton *)sender;
    
    if ([completeBtn.titleLabel.text isEqualToString:@"Mark as complete"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Can this task be marked complete?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        alert.tag = 1;
        [alert show];
    } else {
        [UIView animateWithDuration:0.5 animations:^(void) {
            self.view.alpha = 0;
        }];
        
        RecipientStatusViewController *recipientStatusCtlr = [self.storyboard instantiateViewControllerWithIdentifier:@"RecipientStatusViewController"];
        
        recipientStatusCtlr.recipientStatusArray = self.recipientStatusArray;
        
        recipientStatusCtlr.view.backgroundColor = [UIColor clearColor];

        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
            
            self.modalPresentationStyle = UIModalPresentationCurrentContext;
            
        } else {
            
            self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            recipientStatusCtlr.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            
        }
//        self.modalPresentationStyle = UIModalPresentationCurrentContext;
        
        [self presentViewController:recipientStatusCtlr animated:YES completion:nil];
    }
}

@end
