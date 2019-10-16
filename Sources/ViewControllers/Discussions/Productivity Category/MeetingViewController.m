//
//  MeetingViewController.m
//  Liri
//
//  Created by Varun Sankar on 29/07/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "MeetingViewController.h"
#import "Account.h"
#import <EventKit/EventKit.h>
#import "DefaultCalendarSelectorViewController.h"
#import "Flurry.h"
#import "RecipientStatusViewController.h"

@interface MeetingViewController ()
{
    BOOL meetingNotesAppear, isSender, defaultAllDayEvent;
    
    int priorityIndex, startOrEndDateSelection, selectionId;
    
    NSInteger selectedIndex;
    
    NSString *defaultSubject, *defaultContact, *defaultLocation, *defaultStartDate, *defaultEndDate, *defaultRepeat, *defaultAlert, *defaultSecondAlert, *defaultFilePath, *defaultNotes, *localToGmtStartDate, *localToGmtEndDate;
    
    NSArray *pickerData, *meetingRepeatData, *meetingAlertData;
    
    NSMutableArray *searchArray, *emailArr;

    UIDatePicker *datePicker;
    
    UIPickerView *pickerView;
    
    UITextField *subjectField, *contactField, *locationField;
    
    UISwitch *allDaySwitch;
    
    UIButton *meetingStartDateButton, *meetingEndDateButton, *meetingRepeatButton, *meetingAlertButton, *meetingSecondAlertButton, *meetingFilePathButton, *meetingFileArrowButton;

    UISegmentedControl *meetingPriority;
    
    UITextView *meetingNotes;

}

@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@property (weak, nonatomic) IBOutlet UIView *meetingView;

@property (weak, nonatomic) IBOutlet UITableView *meetingTable;

@property (weak, nonatomic) IBOutlet UITableView *contactTable;

@property (weak, nonatomic) IBOutlet UILabel *meetingTitle;

@property (weak, nonatomic) IBOutlet UIView *footerMeetingView;

@property (weak, nonatomic) IBOutlet UIButton *footerBtn;

- (IBAction)backAction:(id)sender;
- (IBAction)doneAction:(id)sender;
- (IBAction)footerBtnAction:(id)sender;
@end

@implementation MeetingViewController

@synthesize meetingView = _meetingView;

@synthesize backButton = _backButton, doneButton = _doneButton;

@synthesize meetingTable = _meetingTable, contactTable = _contactTable;

@synthesize isEditMode = _isEditMode;

@synthesize meeting = _meeting;

@synthesize chatName = _chatName, chatMessage = _chatMessage, discussionId = _discussionId, messageId = _messageId;

@synthesize delegate = _delegate;

@synthesize annotationImg = _annotationImg;

@synthesize notificationDict = _notificationDict;

@synthesize messageTimeStamp = _messageTimeStamp;

@synthesize isNotCurrentUser = _isNotCurrentUser;

@synthesize meetingTitle = _meetingTitle;

@synthesize recipientStatusArray = _recipientStatusArray;


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
    
    [Flurry logEvent:@"Meeting Invite Screen"];
    self.meetingTable.separatorInset = UIEdgeInsetsZero;    // <- any custom inset will do
    self.meetingTable.separatorColor = [UIColor lightGrayColor];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tableViewTapped:)];
    [tap setNumberOfTapsRequired:1];
    [self.meetingTable addGestureRecognizer:tap];

    self.contactTable.separatorInset = UIEdgeInsetsZero;
    self.contactTable.separatorColor = [UIColor lightGrayColor];
    
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
    
    pickerView = [[UIPickerView alloc]initWithFrame:CGRectMake(15, 30, 250, 200)];
    pickerView.showsSelectionIndicator = YES;
    pickerView.delegate = self;
    meetingRepeatData = [[NSArray alloc] initWithObjects:@"Never", @"Every day", @"Every week", @"Every 2 weeks", @"Every month", @"Every year", nil];
    meetingAlertData = [[NSArray alloc] initWithObjects:@"Never", @"At time of event", @"5 minutes before", @"15 minutes before", @"30 minutes before", @"1 hour before", @"2 hours before", @"1 day before", @"2 days before", @"1 week before", nil];
    [self emailContact];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultCalendarSet:) name:kDefaultCalendarSetNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lightBoxFinished:) name:kLightBoxFinishedNotification object:nil];
    
    if (self.isEditMode) {
        [self.meetingTitle setText:self.meeting.subject];
        
        if (self.isNotCurrentUser) {
            [self.backButton setTitle:@"Close" forState:UIControlStateNormal];
            [self.doneButton setHidden:YES];
        }
        if (nil != self.recipientStatusArray) {
            [self.footerMeetingView setHidden:NO];
            [self.footerBtn setHidden:NO];
        }
        
        defaultSubject = self.meeting.subject;
        defaultContact = self.meeting.toList;
        defaultLocation = self.meeting.location;
        defaultAllDayEvent = self.meeting.allDayEvent;
        
        if (defaultAllDayEvent) {
            [datePicker setDatePickerMode:UIDatePickerModeDateAndTime];
            defaultStartDate = self.meeting.startDate;
            
            defaultEndDate = self.meeting.endDate;
        } else {
            defaultStartDate = [Account convertGmtToLocalTimeZone:self.meeting.startDate];
            
            defaultEndDate = [Account convertGmtToLocalTimeZone:self.meeting.endDate];
        }
//        defaultStartDate = self.meeting.startDate;
//        defaultEndDate = self.meeting.endDate;
        defaultRepeat = self.meeting.repeatFrequency;
        defaultAlert = self.meeting.alert;
        defaultSecondAlert = self.meeting.secondAlert;

        if ([self.meeting.priority isEqualToString:@"None"]) {
            priorityIndex = 0;
        } else if ([self.meeting.priority isEqualToString:@"Low"]) {
            priorityIndex = 1;
        } else if ([self.meeting.priority isEqualToString:@"Med"]) {
            priorityIndex = 2;
        } else {
            priorityIndex = 3;
        }
        defaultFilePath = self.meeting.filePath;
        defaultNotes = self.meeting.text;
        
    } else if (nil != self.notificationDict) {
        
        [self.meetingTitle setText:[[self.notificationDict objectForKey:@"owner_editable"] objectForKey:@"subject"]];
        
        [subjectField setUserInteractionEnabled:NO];
        [contactField setUserInteractionEnabled:NO];
        [locationField setUserInteractionEnabled:NO];
        [allDaySwitch setUserInteractionEnabled:NO];
        
        [self.backButton setTitle:@"Close" forState:UIControlStateNormal];
        [self.doneButton setHidden:YES];
        
        defaultSubject = [[self.notificationDict objectForKey:@"owner_editable"] objectForKey:@"subject"];
        NSArray *toArray = [[self.notificationDict objectForKey:@"owner_editable"] objectForKey:@"to"];
        NSString *emailStr = @"";
        for (NSString *recipient in toArray) {
            emailStr = [emailStr stringByAppendingString:[NSString stringWithFormat:@"%@,",recipient]];
        }
        defaultContact = emailStr;
        
        defaultLocation = [[self.notificationDict objectForKey:@"owner_editable"] objectForKey:@"location"];

        defaultAllDayEvent = [[[self.notificationDict objectForKey:@"owner_editable"] objectForKey:@"alldayevent"] boolValue];
        if (defaultAllDayEvent) {
            [datePicker setDatePickerMode:UIDatePickerModeDateAndTime];
            defaultStartDate = self.notificationDict[@"owner_editable"][@"starttime"];
            
            defaultEndDate = self.notificationDict[@"owner_editable"][@"endtime"];
        } else {
            defaultStartDate = [Account convertGmtToLocalTimeZone:self.notificationDict[@"owner_editable"][@"starttime"]];
            
            defaultEndDate = [Account convertGmtToLocalTimeZone:self.notificationDict[@"owner_editable"][@"endtime"]];
        }

//        defaultStartDate = [[self.notificationDict objectForKey:@"owner_editable"] objectForKey:@"starttime"];
//        defaultEndDate = [[self.notificationDict objectForKey:@"owner_editable"] objectForKey:@"endtime"];

        defaultRepeat = [[self.notificationDict objectForKey:@"owner_editable"] objectForKey:@"repeat_frequency"];
        
        defaultAlert = [[self.notificationDict objectForKey:@"member_editable"] objectForKey:@"alert1"];
        defaultSecondAlert = [[self.notificationDict objectForKey:@"member_editable"] objectForKey:@"alert2"];
        
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
        
        defaultFilePath = [[self.notificationDict objectForKey:@"owner_editable"] objectForKey:@"filepath"];
        defaultNotes = [[self.notificationDict objectForKey:@"owner_editable"] objectForKey:@"notes"];
    } else {
        [self getDate];
        defaultSubject = @"";
        defaultRepeat = @"Never >";
        defaultAlert = @"Never >";
        defaultSecondAlert = @"Never >";
        [meetingPriority setSelectedSegmentIndex:0];
        defaultNotes = [NSString stringWithFormat:@"[%@] %@", self.chatName, self.chatMessage];
        priorityIndex = 0;
        if (nil != self.annotationImg) {
            defaultNotes = [NSString stringWithFormat:@"%@ posted an annotated picture.", self.chatName];
        } else if (defaultNotes.length > KMaxSummaryPointDescriptionLength){
            defaultNotes = [defaultNotes substringToIndex:[defaultNotes length] - KMaxSummaryPointDescriptionLength];
        }
    }
    
}

- (void)viewDidLayoutSubviews
{
    if(!IS_IPHONE_5) {
        //do stuff for 3.5 inch iPhone screen
        [self.meetingView setFrame:CGRectMake(self.meetingView.frame.origin.x, self.meetingView.frame.origin.y, self.meetingView.frame.size.width, 460)];
        [self.contactTable setFrame:CGRectMake(self.contactTable.frame.origin.x, self.contactTable.frame.origin.y, self.contactTable.frame.size.width, 105)];
        [self.footerMeetingView setFrame:CGRectMake(self.footerMeetingView.frame.origin.x, 420, self.footerMeetingView.frame.size.width, 40)];
        [self.footerBtn setFrame:CGRectMake(self.footerBtn.frame.origin.x, self.footerBtn.frame.origin.y, self.footerBtn.frame.size.width, 40)];
    }
}

- (void) lightBoxFinished:(NSNotification*)aNotification {
    NSDictionary *info = [aNotification userInfo];
    if ([info[@"className"] isEqualToString:@"RecipientStatusViewController"] || [info[@"className"] isEqualToString:@"MeetingViewController"]) {
        
        selectedIndex = -1;
        [UIView animateWithDuration:0.3 animations:^(void) {
            self.view.alpha = 1.0;
        }];
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
/*
    NSDate *mydate = [NSDate date];
    NSTimeInterval secondsInTwentyFourHours = 24 * 60 * 60;
    NSDate *dateTwentyFourHoursAhead = [mydate dateByAddingTimeInterval:secondsInTwentyFourHours];
    NSString *stringFromDate = [dateFormatter stringFromDate:dateTwentyFourHoursAhead];
    defaultStartDate = stringFromDate;
    
    secondsInTwentyFourHours = 25 * 60 * 60;
    NSDate *dateTwentyFiveHoursAhead = [mydate dateByAddingTimeInterval:secondsInTwentyFourHours];
    stringFromDate = [dateFormatter stringFromDate:dateTwentyFiveHoursAhead];
    defaultEndDate = stringFromDate;
*/
    NSDate *mydate = [NSDate date];
    NSString *stringFromDate = [dateFormatter stringFromDate:mydate];
    defaultStartDate = stringFromDate;
    
    NSTimeInterval secondsInOneHour = 1 * 60 * 60;
    NSDate *dateTwentyFiveHoursAhead = [mydate dateByAddingTimeInterval:secondsInOneHour];
    stringFromDate = [dateFormatter stringFromDate:dateTwentyFiveHoursAhead];
    defaultEndDate = stringFromDate;
}

- (void)getIndexPath:(id)sender event:(id)event
{
    [pickerView reloadAllComponents];
    [subjectField resignFirstResponder];
    [contactField resignFirstResponder];
    [locationField resignFirstResponder];
    [self.meetingTable flashScrollIndicators];
    
    NSSet *touches = [event allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.meetingTable];
	NSIndexPath *indexPath = [self.meetingTable indexPathForRowAtPoint: currentTouchPosition];
    
    
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
        [self.meetingTable reloadRowsAtIndexPaths:indexArray withRowAnimation:UITableViewRowAnimationAutomatic];
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
//            [emailArr addObject:dict];
            if (![emailArr containsObject:dict]) {
                [emailArr addObject:dict];
            }
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
        self.contactTable.hidden = NO;
    } else {
        self.contactTable.hidden = YES;
    }
    
    [self.contactTable reloadData];
}

- (void)stopInteractTableView
{
    meetingNotesAppear = YES;
    [UIView animateWithDuration:0.2f animations:^{
        CGRect frame = self.meetingTable.frame;
        frame.origin.y -= 180;
        [self.meetingTable setFrame:frame];
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
    UIBezierPath *exclusionPath = [UIBezierPath bezierPathWithRect:CGRectMake(CGRectGetMinX(imageView.frame), CGRectGetMinY(imageView.frame), CGRectGetWidth(meetingNotes.frame), CGRectGetHeight(imageView.frame))];
    meetingNotes.textContainer.exclusionPaths = @[exclusionPath];
    [meetingNotes addSubview:imageView];
}

- (NSString *)setDateFormatter
{
    NSString *dateFormat;
    if (allDaySwitch.isOn) {
        dateFormat = @"MM/dd/yy";
    }else {
        dateFormat = @"EEE, MM/dd/yy, h:mm a";
    }
    return dateFormat;
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

- (void)addMeetingToCalender
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
                    thisEvent  = [eventStore eventWithIdentifier:self.meeting.calendarId];
	                if (nil == thisEvent) {
                    
	                    thisEvent  = [EKEvent eventWithEventStore:eventStore];
	                }
                } else {
                    thisEvent  = [EKEvent eventWithEventStore:eventStore];
                }
                
                //Title
                thisEvent.title = subjectField.text;
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:[self setDateFormatter]];
                
                NSDate* date1 = [dateFormatter dateFromString:meetingStartDateButton.titleLabel.text];
                NSDate* date2 = [dateFormatter dateFromString:meetingEndDateButton.titleLabel.text];
                //get Difference betwenn 2 DATE Values
                NSTimeInterval distanceBetweenDates = [date2 timeIntervalSinceDate:date1];
                
                thisEvent.startDate = date1;
                thisEvent.endDate   = [date1 initWithTimeInterval:distanceBetweenDates sinceDate:thisEvent.startDate];
                
                //        thisEvent.startDate = [dateFormatter dateFromString:meetingStartDateButton.titleLabel.text];
                //
                //        [dateFormatter setDateFormat:@"h:mm a"];
                //        thisEvent.endDate = [dateFormatter dateFromString:meetingEndDateButton.titleLabel.text];
                
                NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
                NSString *calendarPreference = [standardUserDefaults objectForKey:@"CALENDAR_PREFERENCE"];

                [thisEvent setCalendar:[eventStore calendarWithIdentifier:calendarPreference]];
                thisEvent.allDay = allDaySwitch.isOn;
                
                //setting the Reuccurence rule
                //Repeat
                NSString *repeatText = meetingRepeatButton.titleLabel.text;
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
                
                if (![meetingAlertButton.titleLabel.text isEqualToString:@"Never >"]) {
                    EKAlarm *alarm1 = [EKAlarm alarmWithRelativeOffset:[self configureAlarm:meetingAlertButton.titleLabel.text]];
                    [myAlarmsArray addObject:alarm1];
                }
                
                if (![meetingSecondAlertButton.titleLabel.text isEqualToString:@"Never >"]) {
                    EKAlarm *alarm2 = [EKAlarm alarmWithRelativeOffset:[self configureAlarm:meetingSecondAlertButton.titleLabel.text]];
                    [myAlarmsArray addObject:alarm2];
                }
                if (myAlarmsArray.count > 0) {
                    thisEvent.alarms = myAlarmsArray;
                }
                
                
                //Notes
                thisEvent.notes = meetingNotes.text;
                
                
                NSError *err;
                
                
                BOOL success = [eventStore saveEvent:thisEvent span:EKSpanFutureEvents error:&err];
                if (!success) {
                    NSLog(@"error in calender event %@", err);
                    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                    [delegate hideActivityIndicator];
                } else {
                    [self createMeeting:thisEvent.eventIdentifier];
                }
                NSLog(@"calendar id %@", thisEvent.eventIdentifier);
            });
        }
    }];
}

- (void)createMeeting:(NSString *)localCalendarId
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
        
        if ([self.delegate respondsToSelector:@selector(meetingCreatedWithSubject:toList:location:allDayEvent:startDate:endDate:repeatFrequency:alert:secondAlert:priority:filePath:notes:calendarId:categoryType:categoryId:andEditMode:)]) {

            [self.delegate meetingCreatedWithSubject:subjectField.text toList:contactField.text location:locationField.text allDayEvent:allDaySwitch.isOn startDate:localToGmtStartDate endDate:localToGmtEndDate repeatFrequency:meetingRepeatButton.titleLabel.text alert:meetingAlertButton.titleLabel.text secondAlert:meetingSecondAlertButton.titleLabel.text priority:[meetingPriority titleForSegmentAtIndex:meetingPriority.selectedSegmentIndex] filePath:meetingFilePathButton.titleLabel.text notes:meetingNotes.text calendarId:localCalendarId categoryType:4 categoryId:4 andEditMode:self.isEditMode];
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
        [failureAlert setTag:KFailureAlertTag];
        [failureAlert show];
        
        NSLog(@"error message %@ and json %@", [responseJSON objectForKey:@"error"], responseJSON);
    };
    
    NSMutableArray *toListArray = (NSMutableArray *)[contactField.text componentsSeparatedByString:@","];
    if ([[toListArray lastObject] isEqualToString:@""]) {
        [toListArray removeLastObject];
    }
//    NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:subjectField.text, @"subject", toListArray, @"to", locationField.text, @"location", [NSNumber numberWithBool:allDaySwitch.isOn], @"alldayevent", meetingStartDateButton.titleLabel.text, @"starttime", meetingEndDateButton.titleLabel.text, @"endtime", meetingRepeatButton.titleLabel.text, @"repeat_frequency", meetingAlertButton.titleLabel.text, @"alert1", meetingSecondAlertButton.titleLabel.text, @"alert2", [meetingPriority titleForSegmentAtIndex:meetingPriority.selectedSegmentIndex], @"priority", meetingFilePathButton.titleLabel.text, @"filepath", meetingNotes.text, @"notes", localCalendarId, @"local_calendar_id", nil];
    
    if (allDaySwitch.isOn) {
        localToGmtStartDate = meetingStartDateButton.titleLabel.text;
        
        localToGmtEndDate = meetingEndDateButton.titleLabel.text;
    } else {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:[self setDateFormatter]];
        
        NSDate *localDate = [dateFormatter dateFromString:meetingStartDateButton.titleLabel.text];
        
        localToGmtStartDate = [Account convertLocalToGmtTimeZone:localDate];
        
        localDate = [dateFormatter dateFromString:meetingEndDateButton.titleLabel.text];
        
        localToGmtEndDate = [Account convertLocalToGmtTimeZone:localDate];
    }
    NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:subjectField.text, @"subject", toListArray, @"to", locationField.text, @"location", [NSNumber numberWithBool:allDaySwitch.isOn], @"alldayevent", localToGmtStartDate, @"starttime", localToGmtEndDate, @"endtime", meetingRepeatButton.titleLabel.text, @"repeat_frequency", meetingAlertButton.titleLabel.text, @"alert1", meetingSecondAlertButton.titleLabel.text, @"alert2", [meetingPriority titleForSegmentAtIndex:meetingPriority.selectedSegmentIndex], @"priority", @"", @"filepath", meetingNotes.text, @"notes", localCalendarId, @"local_calendar_id", nil];
    
//    [discussionsEndpoint createMeetingWithDiscussionId:self.discussionId MessageId:self.messageId CategoryType:4 andAttributes:attributes];
    [discussionsEndpoint createMeetingWithDiscussionId:self.discussionId MessageId:self.messageId CategoryType:4 MsgTimeStamp:self.messageTimeStamp andAttributes:attributes];

}

- (void)changeDateFormat
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    if (allDaySwitch.isOn) {
        [dateFormatter setDateFormat:@"EEE, MM/dd/yy, h:mm a"];
//        dateFormat = @"MM/dd/yy";
    }else {
        [dateFormatter setDateFormat:@"MM/dd/yy"];
//        dateFormat = @"EEE, MM/dd/yy, h:mm a";
    }
    
//    [dateFormatter setDateFormat:@"EEE, MM/dd/yy, h:mm a"];
    
    NSDate *startDate = [dateFormatter dateFromString: meetingStartDateButton.titleLabel.text];
    
    NSDate *endDate = [dateFormatter dateFromString: meetingEndDateButton.titleLabel.text];
    
    if (allDaySwitch.isOn) {
        [dateFormatter setDateFormat:@"MM/dd/yy"];
        //        dateFormat = @"MM/dd/yy";
    }else {
        [dateFormatter setDateFormat:@"EEE, MM/dd/yy, h:mm a"];
        
        //        dateFormat = @"EEE, MM/dd/yy, h:mm a";
    }
//    [dateFormatter setDateFormat:@"MM/dd/yy"];
    
    defaultStartDate  = [dateFormatter stringFromDate:startDate];
    
    [meetingStartDateButton setTitle:defaultStartDate forState:UIControlStateNormal];
    
    defaultEndDate = [dateFormatter stringFromDate:endDate];
    
    [meetingEndDateButton setTitle:defaultEndDate forState:UIControlStateNormal];
}

#pragma mark - UIButton Actions
- (void)dateValueChanged:(id)sender
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:[self setDateFormatter]];
    
    NSString *stringFromDate = [dateFormatter stringFromDate:[datePicker date]];
    
    if (startOrEndDateSelection == 1) {
        defaultStartDate = stringFromDate;
        [meetingStartDateButton setTitle:stringFromDate forState:UIControlStateNormal];

        NSTimeInterval secondsInEightHours = 60 * 60;
        NSDate *dateOneHourAhead = [[datePicker date] dateByAddingTimeInterval:secondsInEightHours];
        
        stringFromDate = [dateFormatter stringFromDate:dateOneHourAhead];
        
        defaultEndDate = stringFromDate;
        [meetingEndDateButton setTitle:stringFromDate forState:UIControlStateNormal];
    } else if (startOrEndDateSelection == 2) {
        defaultEndDate = stringFromDate;
        [meetingEndDateButton setTitle:stringFromDate forState:UIControlStateNormal];
    }
}

- (void) flip: (id) sender {
    UISwitch *onoff = (UISwitch *) sender;

    defaultAllDayEvent = onoff.isOn;
    
    if (onoff.isOn) {
        
        [datePicker setDatePickerMode:UIDatePickerModeDate];
    } else {
        [datePicker setDatePickerMode:UIDatePickerModeDateAndTime];
    }
    
    [self changeDateFormat];
}

- (void)meetingStartDateAction:(id)sender event:(id)event
{
    startOrEndDateSelection = 1;
    [self getIndexPath:sender event:event];
}

- (void)meetingEndDateAction:(id)sender event:(id)event
{
    startOrEndDateSelection = 2;
    [self getIndexPath:sender event:event];
}

- (void)meetingRepeatButton:(id)sender event:(id)event
{
    selectionId = 1;
    pickerData = meetingRepeatData;
    [self getIndexPath:sender event:event];
}

- (void)meetingAlertButton:(id)sender event:(id)event
{
    selectionId = 2;
    pickerData = meetingAlertData;
    [self getIndexPath:sender event:event];
}

- (void)meetingSecondAlertButton:(id)sender event:(id)event
{
    selectionId = 3;
    pickerData = meetingAlertData;
    [self getIndexPath:sender event:event];
}

- (void)meetingPriorityAction:(id)sender
{
    priorityIndex = (int)meetingPriority.selectedSegmentIndex;
}

- (void)meetingFilePathAction:(id)sender
{
    // do Shankar's stuff here
}
- (void)clearNotesAction:(id)sender
{
    [meetingNotes setText:@""];
}


#pragma mark - IBAction Methods
- (IBAction)backAction:(id)sender
{
    if (self.isEditMode || nil != self.notificationDict) {
        [self dismissSelf];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Do you really want to cancel this Meeting Invite?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        [alert setTag:KWarningAlertTag];
        [alert show];
    }
}

- (IBAction)doneAction:(id)sender
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:[self setDateFormatter]];
    
    NSDate *startDate = [dateFormatter dateFromString:meetingStartDateButton.titleLabel.text];
    NSDate *endDate = [dateFormatter dateFromString:meetingEndDateButton.titleLabel.text];

    
    if ([subjectField.text isEqualToString:@""]) {
        [self validationAlertWithTitle:@"Alert" andMessage:@"Please provide meeting subject."];
    } else if ([contactField.text isEqualToString:@""]) {
        [self validationAlertWithTitle:@"Alert" andMessage:@"You should add atleast one recipient for the meeting invite."];
    } else if (![self contactFieldValidation]) {
        [self validationAlertWithTitle:@"Alert" andMessage:@"Recipient list contains invalid email addresses. Please correct the mistake."];
//    } else if ([startDate timeIntervalSinceNow] < 0.0) {
//        // Date has passed
//        [self validationAlertWithTitle:@"Alert" andMessage:@"Meeting start date cannot be in the past."];
    } else if ([startDate compare:endDate] == NSOrderedDescending) {
        // start date is later than end date
        [self validationAlertWithTitle:@"Alert" andMessage:@"Meeting end date cannot be in the past than start date."];
    } else {
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
                defaultsController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            }
            [self presentViewController:defaultsController animated:YES completion:nil];
        } else {
            [self addMeetingToCalender];
        }
    }
}

- (void)defaultCalendarSet:(NSNotification*)aNotification
{
//    [self lightBoxFinished];
    [[NSNotificationCenter defaultCenter]
     
     postNotificationName:kLightBoxFinishedNotification
     
     object:self userInfo:@{@"className" : NSStringFromClass([self class])}];
    [self addMeetingToCalender];
}

#pragma mark - UITableView DataSource Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    if (self.meetingTable == tableView) {
        return 12;
    } else {
        return [searchArray count];
    }
}
- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    if (self.meetingTable == tableView) {
        UITableViewCell *cell;
        if(indexPath.row == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"meetingSubjectCell"];
            
            subjectField = (UITextField *)[cell viewWithTag:100];
            [subjectField setText:defaultSubject];
            
        } else if (indexPath.row == 1) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"meetingContactCell"];
            
            contactField = (UITextField *)[cell viewWithTag:200];
            [contactField setText:defaultContact];
            
        } else if (indexPath.row == 2) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"meetingLocationCell"];
            
            locationField = (UITextField *)[cell viewWithTag:300];
            [locationField setText:defaultLocation];
            
        } else if (indexPath.row == 3) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"meetingAllDayCell"];
            
            allDaySwitch = (UISwitch *)[cell viewWithTag:400];
            [allDaySwitch setOn:defaultAllDayEvent];
            [allDaySwitch addTarget:self action:@selector(flip:) forControlEvents:UIControlEventValueChanged];
            
        } else if (indexPath.row == 4) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"meetingStartCell"];
            
            meetingStartDateButton = (UIButton *)[cell viewWithTag:500];
            
            [meetingStartDateButton addTarget:self action:@selector(meetingStartDateAction:event:) forControlEvents:UIControlEventTouchUpInside];
            [meetingStartDateButton setTitle:defaultStartDate forState:UIControlStateNormal];

            if (selectedIndex == indexPath.row) {
                [cell addSubview:datePicker];
            }
            
        } else if (indexPath.row == 5) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"meetingEndCell"];
            
            meetingEndDateButton = (UIButton *)[cell viewWithTag:600];
            
            [meetingEndDateButton addTarget:self action:@selector(meetingEndDateAction:event:) forControlEvents:UIControlEventTouchUpInside];
            [meetingEndDateButton setTitle:defaultEndDate forState:UIControlStateNormal];

            if (selectedIndex == indexPath.row) {
                [cell addSubview:datePicker];
            }
            
        } else if (indexPath.row == 6) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"meetingAlarmCell"];
            
            meetingRepeatButton = (UIButton *)[cell viewWithTag:700];
            [meetingRepeatButton addTarget:self action:@selector(meetingRepeatButton:event:) forControlEvents:UIControlEventTouchUpInside];
            if (selectedIndex == indexPath.row) {
                [cell addSubview:pickerView];
            } else {
                [meetingRepeatButton setTitle:defaultRepeat forState:UIControlStateNormal];
            }
        } else if (indexPath.row == 7) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"meetingAlertCell"];
            
            meetingAlertButton = (UIButton *)[cell viewWithTag:800];
            [meetingAlertButton addTarget:self action:@selector(meetingAlertButton:event:) forControlEvents:UIControlEventTouchUpInside];
            if (selectedIndex == indexPath.row) {
                [cell addSubview:pickerView];
            } else {
                [meetingAlertButton setTitle:defaultAlert forState:UIControlStateNormal];
            }
        } else if (indexPath.row == 8) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"meetingSecondAlertCell"];
            
            meetingSecondAlertButton = (UIButton *)[cell viewWithTag:900];
            [meetingSecondAlertButton addTarget:self action:@selector(meetingSecondAlertButton:event:) forControlEvents:UIControlEventTouchUpInside];
            if (selectedIndex == indexPath.row) {
                [cell addSubview:pickerView];
            } else {
                [meetingSecondAlertButton setTitle:defaultSecondAlert forState:UIControlStateNormal];
            }
        } else if (indexPath.row == 9) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"meetingPriorityCell"];
            
            meetingPriority = (UISegmentedControl *)[cell viewWithTag:1000];
            [meetingPriority addTarget:self
                             action:@selector(meetingPriorityAction:)
                   forControlEvents:UIControlEventValueChanged];
            [meetingPriority setSelectedSegmentIndex:priorityIndex];
        } else if (indexPath.row == 10) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"meetingFilePathCell"];
            cell.hidden = YES;
//            meetingFilePathButton = (UIButton *)[cell viewWithTag:1100];
//            [meetingFilePathButton addTarget:self action:@selector(meetingFilePathAction:) forControlEvents:UIControlEventTouchUpInside];
//            
//            meetingFileArrowButton = (UIButton *)[cell viewWithTag:1101];
//            [meetingFileArrowButton addTarget:self action:@selector(meetingFilePathAction:) forControlEvents:UIControlEventTouchUpInside];
            
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"meetingNoteCell"];
            
            meetingNotes = (UITextView *)[cell viewWithTag:1200];
            [meetingNotes setText:defaultNotes];
            
            UIButton *clearNotesButton = (UIButton *)[cell viewWithTag:1201];
            [clearNotesButton addTarget:self action:@selector(clearNotesAction:) forControlEvents:UIControlEventTouchUpInside];
            [clearNotesButton.layer setCornerRadius:clearNotesButton.frame.size.width/2];
            /*
            if (nil != self.annotationImg) {
                
                UIImageView *imgView = (UIImageView *)[cell viewWithTag:1202];
                [imgView setImage: self.annotationImg];
                [imgView setHidden:NO];
                
                [meetingNotes setText:self.chatMessage];
                [meetingNotes setHidden:YES];
                
                [clearNotesButton setHidden:YES];
            }
             */
        }
        if (nil != self.notificationDict  || self.isNotCurrentUser) {
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
    if (self.meetingTable == tableView) {
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
        self.contactTable.hidden = YES;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.meetingTable == tableView) {
        if(selectedIndex == indexPath.row)
        {
            return 220;
        }
        if (indexPath.row == 10) {
            return 0;
        }
        if (indexPath.row == 11) {
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
        defaultRepeat = [NSString stringWithFormat:@"%@ >",[pickerData objectAtIndex:row]];
        [meetingRepeatButton setTitle:defaultRepeat forState:UIControlStateNormal];
    } else if (selectionId == 2) {
        defaultAlert = [NSString stringWithFormat:@"%@ >",[pickerData objectAtIndex:row]];
        [meetingAlertButton setTitle:defaultAlert forState:UIControlStateNormal];
    } else if (selectionId == 3) {
        defaultSecondAlert = [NSString stringWithFormat:@"%@ >",[pickerData objectAtIndex:row]];
        [meetingSecondAlertButton setTitle:defaultSecondAlert forState:UIControlStateNormal];
    }
}

#pragma mark - UITextField Delegate Methods
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == contactField) {
        
        if ([string isEqualToString:@" "] && self.contactTable.hidden) {
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
    } else if (textField == locationField) {
        defaultLocation = [textField.text stringByReplacingCharactersInRange:range withString:string];
    } else {
        defaultSubject = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        return (newLength > KMaxUserCategoryLength) ? NO : YES;
    }
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField == subjectField || textField == locationField) {
        [self.contactTable setHidden:YES];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField;
{
    [textField resignFirstResponder];
    [self.contactTable setHidden:YES];

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
    defaultNotes = [textView.text stringByReplacingCharactersInRange:range withString:text];
    NSUInteger newLength = [textView.text length] + [text length] - range.length;
    return (newLength > KMaxSummaryPointDescriptionLength) ? NO : YES;
}

#pragma mark - UITapGesture Method
- (void)tableViewTapped:(UIGestureRecognizer *)gesture
{
    [[self view] endEditing:YES];
    if (meetingNotesAppear) {
        meetingNotesAppear = NO;
        [UIView animateWithDuration:0.2f animations:^{
            CGRect frame = self.meetingTable.frame;
            frame.origin.y += 180;
            [self.meetingTable setFrame:frame];
        }];
    }
    
}

#pragma mark - UIAlertView Delegate Method
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == KWarningAlertTag && buttonIndex == 1) {
        [self dismissSelf];
    } else if (alertView.tag == KFailureAlertTag) {
        [self dismissSelf];
    }
    if (alertView.tag == KLocalResourceAccessFailureTag && buttonIndex == 0) {
        [self createMeeting:@""];
    }
    
}

- (IBAction)footerBtnAction:(id)sender {
    
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
    
    [self presentViewController:recipientStatusCtlr animated:YES completion:nil];
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
