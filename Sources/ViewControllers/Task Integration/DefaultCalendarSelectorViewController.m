//
//  DefaultCalendarSelectorViewController.m
//  Liri
//
//  Created by Shankar Arunachalam on 9/10/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "DefaultCalendarSelectorViewController.h"
#import <EventKit/EventKit.h>
#import "AppDelegate.h"
#import "Account.h"
#import "Flurry.h"

@interface DefaultCalendarSelectorViewController ()
@property (weak, nonatomic) IBOutlet UIView *chooseCalendarView;

@end

@implementation DefaultCalendarSelectorViewController
@synthesize localCalendars, localCalendarsDict, calendarsButton, calendarsPicker;
@synthesize chooseCalendarView = _chooseCalendarView;

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
    [Flurry logEvent:@"Default Calendar Selector Screen"];
}


- (void)viewDidAppear:(BOOL)animated
{
    [UIView animateWithDuration:0.5f animations:^(void) {
        self.view.alpha = 1.0;
    }];
    //    [self goToBottom];
    [self getCalendars];
}
- (void)viewDidLayoutSubviews
{
    [self.chooseCalendarView setCenter:self.view.center];
}
- (void) getCalendars {
    EKEventStore * eventStore = [[EKEventStore alloc] init];
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
		if (!granted) {
            AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [delegate hideActivityIndicator];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated:NO completion:^{
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:kDefaultCalendarSetNotification
                     object:self userInfo:nil];
                }];
            });
        } else {
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
            dispatch_async(dispatch_get_main_queue(), ^{
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
            });
        }
    }];
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
