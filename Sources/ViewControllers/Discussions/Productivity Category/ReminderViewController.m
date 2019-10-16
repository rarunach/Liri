//
//  ReminderViewController.m
//  Liri
//
//  Created by Varun Sankar on 04/07/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "ReminderViewController.h"
#import "Account.h"
#import "XMPPManager.h"
#import "AppDelegate.h"
#import "AppConstants.h"
#import <EventKit/EventKit.h>
#import "Flurry.h"

@interface ReminderViewController ()
{
    UITextField *titleField;
    UIButton *reminderDateButton, *reminderAlarmButton, *reminderRepeatButton;
    UISegmentedControl *reminderPriority;
    UITextView *reminderNotes;
    
    NSInteger selectedIndex;
    UIDatePicker *datePicker;
    UIPickerView *pickerView;
    NSArray *pickerData;
    NSString *defaultDate, *defaultRepeat, *defaultTitle, *defaultNotes;
    int priorityIndex;
    
    BOOL reminderNotesAppear;
}
@property (weak, nonatomic) IBOutlet UITableView *reminderTable;
@property (weak, nonatomic) IBOutlet UIView *reminderView;

@property (weak, nonatomic) IBOutlet UILabel *reminderTitle;

- (IBAction)backAction:(id)sender;
- (IBAction)doneAction:(id)sender;

@end

@implementation ReminderViewController

@synthesize reminderTable = _reminderTable;
@synthesize chatName = _chatName, chatMessage = _chatMessage, discussionId = _discussionId, messageId = _messageId;
@synthesize reminderView = _reminderView;
@synthesize isEditMode = _isEditMode;
@synthesize reminder = _reminder;
@synthesize delegate = _delegate;
@synthesize annotationImg = _annotationImg;
@synthesize messageTimeStamp = _messageTimeStamp;

@synthesize reminderTitle = _reminderTitle;


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
    [Flurry logEvent:@"Remider Screen"];
    self.reminderTable.separatorInset = UIEdgeInsetsZero;    // <- any custom inset will do
    self.reminderTable.separatorColor = [UIColor lightGrayColor];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tableViewTapped:)];
    [tap setNumberOfTapsRequired:1];
    [self.reminderTable addGestureRecognizer:tap];
    
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
    
    if (self.isEditMode) {
        
        [self.reminderTitle setText:self.reminder.subject];
        
        defaultTitle = self.reminder.subject;
        defaultDate = self.reminder.reminderTime;
        defaultRepeat = self.reminder.repeatFrequency;
        if ([self.reminder.priority isEqualToString:@"None"]) {
            priorityIndex = 0;
        } else if ([self.reminder.priority isEqualToString:@"Low"]) {
            priorityIndex = 1;
        } else if ([self.reminder.priority isEqualToString:@"Med"]) {
            priorityIndex = 2;
        } else {
            priorityIndex = 3;
        }
        defaultNotes =self.reminder.text;
        
    } else {
        defaultTitle = @"";
        [self getDate];
        defaultRepeat = @"Never >";
        [reminderPriority setSelectedSegmentIndex:0];
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
    pickerData = [[NSArray alloc] initWithObjects:@"Never", @"Every day", @"Every week", @"Every 2 weeks", @"Every month", @"Every year", nil];
    
    
}

- (void)viewDidLayoutSubviews
{
    if(!IS_IPHONE_5) {
        //do stuff for 3.5 inch iPhone screen
        [self.reminderView setFrame:CGRectMake(self.reminderView.frame.origin.x, self.reminderView.frame.origin.y, self.reminderView.frame.size.width, 460)];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    selectedIndex = -1;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableView Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    return 6;
}
- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if(indexPath.row == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"reminderTitleCell"];
        
        titleField = (UITextField *)[cell viewWithTag:100];
        [titleField setText:defaultTitle];
        
    } else if (indexPath.row == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"reminderDateCell"];

        reminderDateButton = (UIButton *)[cell viewWithTag:300];
        [reminderDateButton addTarget:self action:@selector(reminderDateAction:event:) forControlEvents:UIControlEventTouchUpInside];
        if (selectedIndex == indexPath.row) {
            [reminderDateButton setTitle:defaultDate forState:UIControlStateNormal];
            [cell addSubview:datePicker];
        } else {
            [reminderDateButton setTitle:defaultDate forState:UIControlStateNormal];
        }
        
    } else if (indexPath.row == 2) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"reminderAlarmCell"];
        reminderAlarmButton = (UIButton *)[cell viewWithTag:400];
        [reminderAlarmButton addTarget:self action:@selector(reminderAlarmAction:) forControlEvents:UIControlEventTouchUpInside];
    } else if (indexPath.row == 3) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"reminderRepeatCell"];
        
        reminderRepeatButton = (UIButton *)[cell viewWithTag:500];
        [reminderRepeatButton addTarget:self action:@selector(reminderRepeatAction:event:) forControlEvents:UIControlEventTouchUpInside];
        if (selectedIndex == indexPath.row) {
            [cell addSubview:pickerView];
        } else {
            [reminderRepeatButton setTitle:defaultRepeat forState:UIControlStateNormal];
        }
        
    } else if (indexPath.row == 4) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"reminderPriorityCell"];
        reminderPriority = (UISegmentedControl *)[cell viewWithTag:600];
        [reminderPriority addTarget:self
                             action:@selector(reminderPriorityAction:)
                   forControlEvents:UIControlEventValueChanged];
        [reminderPriority setSelectedSegmentIndex:priorityIndex];
    } else if (indexPath.row == 5) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"reminderNoteCell"];
        reminderNotes = (UITextView *)[cell viewWithTag:700];
        [reminderNotes setText:defaultNotes];
        UIButton *clearNotesButton = (UIButton *)[cell viewWithTag:800];
        [clearNotesButton addTarget:self action:@selector(clearNotesAction:) forControlEvents:UIControlEventTouchUpInside];
        [clearNotesButton.layer setCornerRadius:clearNotesButton.frame.size.width/2];
        /*
        if (nil != self.annotationImg) {
            UIImageView *imgView = (UIImageView *)[cell viewWithTag:900];
            [imgView setImage: self.annotationImg];
            [imgView setHidden:NO];
            
            [reminderNotes setText:self.chatMessage];
            [reminderNotes setHidden:YES];
            
            [clearNotesButton setHidden:YES];
        }
         */
    }
    return cell;
}

#pragma mark - UITableView Delegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(selectedIndex == indexPath.row)
    {
        return 220;
    }
    if (indexPath.row == 5) {
        return 280;
    }
    return 44;
}

#pragma mark - UITextField Delegate Methods
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    defaultTitle = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > KMaxUserCategoryLength) ? NO : YES;
}
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    titleField = textField; //textfield reference
    return YES;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField;
{
    [textField resignFirstResponder];
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
    defaultNotes = textView.text;
    NSUInteger newLength = [textView.text length] + [text length] - range.length;
    return (newLength > KMaxSummaryPointDescriptionLength) ? NO : YES;
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
    defaultRepeat = [NSString stringWithFormat:@"%@ >",[pickerData objectAtIndex:row]];
    [reminderRepeatButton setTitle:[NSString stringWithFormat:@"%@ >",[pickerData objectAtIndex:row]] forState:UIControlStateNormal];
}

#pragma mark - Private Methods

- (void)getDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE, MM/dd/yy, h:mm a"];
    
    NSDate *currentDate = [NSDate date];
//    NSTimeInterval secondsInTwentyFourHours = 24 * 60 * 60;
//    NSDate *dateTwentyFourHoursAhead = [mydate dateByAddingTimeInterval:secondsInTwentyFourHours];
    NSString *stringFromDate = [dateFormatter stringFromDate:currentDate];
    defaultDate = stringFromDate;
}

- (void)getIndexPath:(id)sender event:(id)event
{
    [titleField resignFirstResponder];
    [self.reminderTable flashScrollIndicators];
    
    NSSet *touches = [event allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.reminderTable];
	NSIndexPath *indexPath = [self.reminderTable indexPathForRowAtPoint: currentTouchPosition];
    
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
        [self.reminderTable reloadRowsAtIndexPaths:indexArray withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)stopInteractTableView
{
    reminderNotesAppear = YES;
    [UIView animateWithDuration:0.2f animations:^{
        CGRect frame = self.reminderTable.frame;
        frame.origin.y -= 100;
        [self.reminderTable setFrame:frame];
    }];
}

- (void) AddMusicOrShowMusic: (id) sender
{
    MPMediaPickerController *picker =
    [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeMusic];
    picker.delegate = self;
    picker.allowsPickingMultipleItems   = NO;
    picker.prompt                       = NSLocalizedString (@"Add songs to play", "Prompt in media item picker");
    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleDefault animated: YES];
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)reminderPriorityAction: (id)sender
{
    priorityIndex = (int)reminderPriority.selectedSegmentIndex;
}

- (void)addMyReminderToReminder
{

    EKEventStore *store = [[EKEventStore alloc] init];

    [store requestAccessToEntityType:EKEntityTypeReminder completion:^(BOOL granted, NSError *error) {
        if (!granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alertView = [[UIAlertView alloc]
                                          initWithTitle:@""
                                          message:@"Reminders access to Liri app is turned off in your device. Please enable this access from Settings > Privacy > Reminders so that you can create reminders in Liri."
                                          delegate:self cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
                alertView.tag = KLocalResourceAccessFailureTag;
                [alertView show];
            });
        } else {
            [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
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
                    EKReminder *myReminder;
                    if (self.isEditMode) {
                        myReminder= (EKReminder *)[store calendarItemWithIdentifier:self.reminder.reminderId];
                        if (nil == myReminder) {
                            myReminder = [EKReminder reminderWithEventStore:store];
                        }
                    } else {
                        myReminder = [EKReminder reminderWithEventStore:store];
                    }
                    //Title
                    myReminder.title = titleField.text;
                    
                    //Date
                    myReminder.calendar = [store defaultCalendarForNewReminders];
                    
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:@"EEE, MM/dd/yy, h:mm a"];
                    
                    EKAlarm *alarm = [EKAlarm alarmWithAbsoluteDate:[dateFormatter dateFromString:reminderDateButton.titleLabel.text]];
                    [myReminder addAlarm:alarm];
                    
                    //Repeat
                    
                    EKRecurrenceFrequency recurrenceFrequency;
                    NSString *repeatText = reminderRepeatButton.titleLabel.text;
                    repeatText = [repeatText substringToIndex:[repeatText length] - 2];
                    
                    int interval = 1;
                    
                    if ([repeatText isEqualToString: @"Every day"]) {
                        recurrenceFrequency = EKRecurrenceFrequencyDaily;
                        myReminder.dueDateComponents = [self setDueDateComponentsWithReminder:myReminder andRecurrence:recurrenceFrequency andInterval:interval];
                    } else if([repeatText isEqualToString: @"Every week"]) {
                        recurrenceFrequency = EKRecurrenceFrequencyWeekly;
                        myReminder.dueDateComponents = [self setDueDateComponentsWithReminder:myReminder andRecurrence:recurrenceFrequency andInterval:interval];
                    } else if([repeatText isEqualToString: @"Every 2 weeks"]) {
                        recurrenceFrequency = EKRecurrenceFrequencyWeekly;
                        myReminder.dueDateComponents = [self setDueDateComponentsWithReminder:myReminder andRecurrence:recurrenceFrequency andInterval:interval];
                        interval = 2;
                    } else if([repeatText isEqualToString: @"Every month"]) {
                        recurrenceFrequency = EKRecurrenceFrequencyMonthly;
                        myReminder.dueDateComponents = [self setDueDateComponentsWithReminder:myReminder andRecurrence:recurrenceFrequency andInterval:interval];
                    } else if([repeatText isEqualToString: @"Every year"]) {
                        recurrenceFrequency = EKRecurrenceFrequencyYearly;
                        myReminder.dueDateComponents = [self setDueDateComponentsWithReminder:myReminder andRecurrence:recurrenceFrequency andInterval:interval];
                    } else {
                        recurrenceFrequency = FALSE;
                    }
                    
                    // Priority
                    int priority;
                    NSString *priorityText = [reminderPriority titleForSegmentAtIndex:reminderPriority.selectedSegmentIndex];
                    if ([priorityText isEqualToString:@"Low"]) {
                        priority = 9;
                    } else if ([priorityText isEqualToString:@"Med"]) {
                        priority = 5;
                    } else if ([priorityText isEqualToString:@"High"]) {
                        priority = 1;
                    } else {
                        priority = 0;
                    }
                    [myReminder setPriority:priority];
                    
                    //Notes
                    [myReminder setNotes:reminderNotes.text];
                    NSError *err;
                    BOOL success = [store saveReminder:myReminder commit:YES error:&err];
                    
                    if (!success) {
                        // Handle failure here, look at error instance
                        NSLog(@"error %@", err);
                    } else {
                        [self createReminder:myReminder.calendarItemIdentifier];
                    }
                }
            }];
        }
    }];
}

- (NSDateComponents *)setDueDateComponentsWithReminder:(EKReminder *)myReminder andRecurrence:(EKRecurrenceFrequency)recurrenceFrequency andInterval:(int)interval
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE, MM/dd/yy, h:mm a"];
    
    NSCalendar *calendar =
    [NSCalendar currentCalendar];
    
    NSUInteger unitFlags = NSEraCalendarUnit |
    
    NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    
    NSDateComponents *dueDateComponents = [calendar components:unitFlags fromDate:[dateFormatter dateFromString:reminderDateButton.titleLabel.text]];
    
    EKRecurrenceRule * recurrenceRule = [[EKRecurrenceRule alloc]
                                         initRecurrenceWithFrequency:recurrenceFrequency
                                         interval:interval
                                         end:nil];
    
    [myReminder addRecurrenceRule:recurrenceRule];
    return dueDateComponents;
}

- (void)createReminder:(NSString *)localReminderId
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
        
        if ([self.delegate respondsToSelector:@selector(reminderCreatedWithSubject:time:tone:frequency:notes:priority:reminderId:categoryType:categoryId:andEditMode:)]) {
            [self.delegate reminderCreatedWithSubject:titleField.text time:reminderDateButton.titleLabel.text tone:reminderAlarmButton.titleLabel.text frequency:reminderRepeatButton.titleLabel.text notes:reminderNotes.text priority:[reminderPriority titleForSegmentAtIndex:reminderPriority.selectedSegmentIndex] reminderId:localReminderId categoryType:2 categoryId:2 andEditMode:self.isEditMode];
        }
        
        [delegate hideActivityIndicator];
//        [self dismissViewControllerAnimated:YES completion:nil];
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
    
    NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:titleField.text, @"subject", reminderDateButton.titleLabel.text, @"reminder_time", reminderAlarmButton.titleLabel.text, @"ringtone", reminderRepeatButton.titleLabel.text, @"repeat_frequency", reminderNotes.text, @"notes", [reminderPriority titleForSegmentAtIndex:reminderPriority.selectedSegmentIndex], @"priority", localReminderId, @"local_reminder_id", nil];
    
//    [discussionsEndpoint createReminderWithDiscussionId:self.discussionId MessageId:self.messageId CategoryType:2 andAttributes:attributes];
    [discussionsEndpoint createReminderWithDiscussionId:self.discussionId MessageId:self.messageId CategoryType:2 MsgTimeStamp:self.messageTimeStamp andAttributes:attributes];

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

#pragma mark - UIButton Actions
- (void)reminderDateAction:(id)sender event:(id)event
{
    [self getIndexPath:sender event:event];
}

- (void)reminderAlarmAction:(id)sender
{
//    [self AddMusicOrShowMusic:sender];
}

- (void)reminderRepeatAction:(id)sender event:(id)event
{
    [self getIndexPath:sender event:event];
}

- (void)clearNotesAction:(id)sender
{
    [reminderNotes setText:@""];
}

- (void)dateValueChanged:(id)sender
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE, MM/dd/yy, h:mm a"];

    NSString *stringFromDate = [dateFormatter stringFromDate:[datePicker date]];
    
    defaultDate = stringFromDate;
    [reminderDateButton setTitle:stringFromDate forState:UIControlStateNormal];
}

- (IBAction)backAction:(id)sender
{
//    [self dismissViewControllerAnimated:YES completion:nil];
    [self dismissSelf];
}

- (IBAction)doneAction:(id)sender
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE, MM/dd/yy, h:mm a"];
    
    NSDate *checkDate = [dateFormatter dateFromString:reminderDateButton.titleLabel.text];
    if ([titleField.text isEqualToString:@""]) {
        [delegate hideActivityIndicator];
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Alert"
                              message:@"Please provide reminder subject."
                              delegate:self cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
    } else if ([checkDate timeIntervalSinceNow] < 0.0) {
        // Date has passed
        [delegate hideActivityIndicator];
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Alert"
                              message:@"Reminder date cannot be in the past."
                              delegate:self cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
    } else {
        [self addMyReminderToReminder];
    }
}

#pragma mark - UITapGesture Method
- (void)tableViewTapped:(UIGestureRecognizer *)gesture
{
    [[self view] endEditing:YES];
    if (reminderNotesAppear) {
        reminderNotesAppear = NO;
        [UIView animateWithDuration:0.2f animations:^{
            CGRect frame = self.reminderTable.frame;
            frame.origin.y += 100;
            [self.reminderTable setFrame:frame];
        }];
    }
    
}

#pragma mark - MPMediaPickerController Methods
- (void) mediaPicker: (MPMediaPickerController *) mediaPicker didPickMediaItems: (MPMediaItemCollection *) mediaItemCollection
{
    [self dismissViewControllerAnimated:YES completion:nil];
    MPMediaEntity *item = [[mediaItemCollection items] objectAtIndex:0];
    NSURL *url = [item valueForProperty:MPMediaItemPropertyAssetURL];
    NSLog(@"url : %@",url);
}
- (void) mediaPickerDidCancel: (MPMediaPickerController *) mediaPicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
//    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque animated: YES];
}

#pragma mark - UIAlertView Delegate Method
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0 && alertView.tag == KSuccessAlertTag) {
//        [self dismissViewControllerAnimated:YES completion:nil];
        [self dismissSelf];
    } else if (alertView.tag == KFailureAlertTag) {
//        [self dismissViewControllerAnimated:YES completion:nil];
        [self dismissSelf];
    }
    if (buttonIndex == 0 && alertView.tag == KLocalResourceAccessFailureTag) {
//        [self createReminder:@""];
        AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [delegate hideActivityIndicator];
        
//        [self dismissViewControllerAnimated:YES completion:nil];
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


@end
