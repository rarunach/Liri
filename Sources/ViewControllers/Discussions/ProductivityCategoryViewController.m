 //
//  AddCategoryViewController.m
//  Liri
//
//  Created by Varun Sankar on 30/06/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "ProductivityCategoryViewController.h"
#import "AppConstants.h"
#import "AppDelegate.h"
#import "Account.h"
#import "UserCategories.h"
#import "Categories.h"
#import <EventKit/EventKit.h>
#import "Flurry.h"

@interface ProductivityCategoryViewController ()
{
    BOOL isUpdateCategory, isCategoryTitleNotEmpty, editMode;
    
    int noOfUserCategory, selectedCategoryCounter;
    
    NSIndexPath *index;
    
    UIView *notesView;
    UITextView *summaryDescriptionTxtView;

    UIButton *checkBoxBtn, *editCategory;
    UIImageView *colorImageView;
    
    NSString *userCategory;
    
    NSMutableArray *categoryArray;
    NSMutableDictionary *categoryDict;
    int maxUserCategory, categoryLimit;
    CGFloat keyboardHeight;
}

@property (weak, nonatomic) IBOutlet UIView *categoryView;
@property (weak, nonatomic) IBOutlet UILabel *assignCategoryLbl;
@property (weak, nonatomic) IBOutlet UIImageView *lineImageView;
@property (weak, nonatomic) IBOutlet UITableView *categoryTableView;

@end

@implementation ProductivityCategoryViewController

@synthesize categoryView = _categoryView;
@synthesize assignCategoryLbl = _assignCategoryLbl;
@synthesize lineImageView = _lineImageView;
@synthesize categoryTableView = _categoryTableView;
@synthesize chatName = _chatName, chatMessage = _chatMessage, discussionId = _discussionId, messageId = _messageId;
@synthesize annotationImage = _annotationImage;
@synthesize categoriesArray = _categoriesArray;
@synthesize messageTimeStamp = _messageTimeStamp;

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lightBoxFinished:) name:kLightBoxFinishedNotification object:nil];
    
    [Flurry logEvent:@"Productivity Category Screen"];
    
    isUpdateCategory = NO;
    isCategoryTitleNotEmpty = NO;
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    maxUserCategory = (int)[standardUserDefaults integerForKey:@"MAX_UDC"];
    categoryLimit = (int)[standardUserDefaults integerForKey:@"CAT_LIMIT"];
    
    categoryArray = [[UserCategories sharedManager] categoryArray];
    
    
    // set categories counter value per message
    selectedCategoryCounter = self.categoriesArray.count;
    
    // set user defined categories counter value
    noOfUserCategory = categoryArray.count - 5;
    
    [self makeViewAlignment];
    
    self.categoryTableView.separatorInset = UIEdgeInsetsZero;    // <- any custom inset will do
    self.categoryTableView.separatorColor = [UIColor lightGrayColor];
        
}

- (void)viewDidAppear:(BOOL)animated
{
}

- (void)viewWillAppear:(BOOL)animated
{
    [UIView animateWithDuration:0.5f animations:^(void) {
        self.view.alpha = 1.0;
    }];
    //    [self goToBottom];
}

-(void)goToBottom
{
    NSIndexPath *lastIndexPath = [self lastIndexPath];
    [self.categoryTableView scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

-(NSIndexPath *)lastIndexPath
{
    NSInteger lastSectionIndex = MAX(0, [self.categoryTableView numberOfSections] - 1);
    NSInteger lastRowIndex = MAX(0, [self.categoryTableView numberOfRowsInSection:lastSectionIndex] - 1);
    return [NSIndexPath indexPathForRow:lastRowIndex inSection:lastSectionIndex];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private Methods
- (void)insertUserCategory:(UITextField *)textField
{
    UITableViewCell *cell;
    
    if([textField.superview.superview isKindOfClass:[UITableViewCell class]]) {
        cell = (UITableViewCell *) textField.superview.superview;
    } else {
        cell = (UITableViewCell *) textField.superview.superview.superview;
    }
    NSIndexPath *indexPath = [self.categoryTableView indexPathForCell:cell];
    colorImageView = (UIImageView *)[cell viewWithTag:200];
    
    // Add New User Defined Category
    if (noOfUserCategory <= maxUserCategory && [categoryArray count] <= maxUserCategory + 5 && ![textField.text isEqualToString:@""]) {
        
        if (isUpdateCategory) {
            NSMutableDictionary *dict = [categoryArray objectAtIndex:indexPath.row];
            int udcId = [[dict objectForKey:@"categoryType"] intValue];
            // Update server side...
            [self updateUserDefinedCategoryObjectWithName:textField.text andId:udcId andIndex:indexPath];
            
        } else {
            if (noOfUserCategory == maxUserCategory || [categoryArray count] == maxUserCategory + 5) {
                [self alertViewWithTitle:@"Alert" message:[NSString stringWithFormat: @"You need Liri Pro to add more than %d categories. To upgrade, please visit our site or contact us.", maxUserCategory] okButton:@"OK" cancelButton:nil andTag:0];
                textField.text = @"";
                            
            } else {
                
                // Insert data into server side...
                [self createUserDefinedCategoryObjectWithName:textField.text andColor:colorImageView.accessibilityIdentifier andIndex:indexPath];
                
            }
            
            
        }
    } else if([textField.text isEqualToString:@""] && isUpdateCategory) {
        
        [self alertViewWithTitle:@"Alert" message:@"Categories cannot be blank." okButton:@"OK" cancelButton:nil andTag:0];
        textField.text = userCategory;
        
    }
}

- (void)createUserDefinedCategoryObjectWithName:(NSString *)name andColor:(NSString *)color andIndex:(NSIndexPath *)userCategoryIndex;
{
    //do server action
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    // do create
    id<APIAccessClient> discussionsEndpoint =
    (id<APIAccessClient>)[[APIManager
                                 sharedInstanceWithClientProtocol:
                                 @protocol(APIAccessClient)] client];
    
    discussionsEndpoint.successJSON = ^(NSURLRequest *request,
                                        id responseJSON){
        
        noOfUserCategory++;
        
        categoryDict = [[NSMutableDictionary alloc] init];
        [categoryDict setObject:name forKey:@"userDefinedCategory"];
        [categoryDict setObject:[responseJSON objectForKey:@"category_id"] forKey:@"categoryType"];
        
        [categoryArray insertObject:categoryDict atIndex:userCategoryIndex.row];
        
        [self makeViewAlignment];
        
        [self.categoryTableView reloadData];
        [self.categoryTableView scrollToRowAtIndexPath:userCategoryIndex atScrollPosition:UITableViewScrollPositionTop animated:YES];
        [delegate hideActivityIndicator];

    };
    discussionsEndpoint.failureJSON = ^(NSURLRequest *request,
                                        id responseJSON){
        
        [self alertViewWithTitle:@"" message:[responseJSON objectForKey:@"error"] okButton:@"OK" cancelButton:nil andTag:KFailureAlertTag];
        
        NSLog(@"error message %@ and json %@", [responseJSON objectForKey:@"error"], responseJSON);
    };
    [discussionsEndpoint createUserDefinedCategoryWithName:name andColor:color];
}
- (void)updateUserDefinedCategoryObjectWithName:(NSString *)name andId:(int)udcId andIndex:(NSIndexPath *)userCategoryIndex
{
    //do server action
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    
    id<APIAccessClient> discussionsEndpoint =
    (id<APIAccessClient>)[[APIManager
                                 sharedInstanceWithClientProtocol:
                                 @protocol(APIAccessClient)] client];
    
    discussionsEndpoint.successJSON = ^(NSURLRequest *request,
                                        id responseJSON){
        
        NSMutableDictionary *dict = [categoryArray objectAtIndex:userCategoryIndex.row];
        [dict setObject:name forKey:@"userDefinedCategory"];
        [delegate hideActivityIndicator];
        
    };
    discussionsEndpoint.failureJSON = ^(NSURLRequest *request,
                                        id responseJSON){

        [self alertViewWithTitle:@"" message:[responseJSON objectForKey:@"error"] okButton:@"OK" cancelButton:nil andTag:KFailureAlertTag];
        NSLog(@"error message %@ and json %@", [responseJSON objectForKey:@"error"], responseJSON);
    };
    // do Update
    [discussionsEndpoint updateUserDefinedCategoryWithName:name andId:udcId];
}

- (void)deleteCategoryWithDiscussionId:(NSString *)discussionId messageId:(NSString *)msgId andCagtegoryType:(int)categoryType
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
        [editCategory setHidden:YES];
        [checkBoxBtn setBackgroundColor: nil];
        selectedCategoryCounter--;
        
        if (index.row == 1) {
            Reminder *myReminder = nil;
            NSUInteger indexVal = [self.categoriesArray indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop) {
                return [obj isKindOfClass:[Reminder class]];
            }];
            if (indexVal != NSNotFound){
                myReminder = [self.categoriesArray objectAtIndex:indexVal];
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
        } else if (index.row == 2) {
            Task *task = nil;
            NSUInteger indexVal = [self.categoriesArray indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop) {
                return [obj isKindOfClass:[Task class]];
            }];
            if (indexVal != NSNotFound){
                task = [self.categoriesArray objectAtIndex:indexVal];
                dispatch_async(dispatch_get_main_queue(), ^{
                EKEventStore *store = [[EKEventStore alloc] init];
                EKEvent* eventToRemove = [store eventWithIdentifier:task.calendarId];

//                EKCalendar *calendar = (EKCalendar *)[store calendarItemWithIdentifier:task.calendarId];
                
                NSError *err;
                BOOL success = [store removeEvent:eventToRemove span:EKSpanThisEvent error:&err];
                if (!success) {
                    NSLog(@"Error %@", err);
                }
                });
            }
        } else if (index.row == 3) {
            Meeting *meeting = nil;
            NSUInteger indexVal = [self.categoriesArray indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop) {
                return [obj isKindOfClass:[Meeting class]];
            }];
            if (indexVal != NSNotFound){
                meeting = [self.categoriesArray objectAtIndex:indexVal];
                dispatch_async(dispatch_get_main_queue(), ^{
                EKEventStore *store = [[EKEventStore alloc] init];
//                EKCalendar *calendar = (EKCalendar *)[store calendarItemWithIdentifier:meeting.calendarId];
                EKEvent* eventToRemove = [store eventWithIdentifier:meeting.calendarId];
                
                NSError *err;
//                BOOL success = [store removeCalendar:calendar commit:YES error:&err];
//                BOOL success = [store removeEvent:eventToRemove span:EKSpanThisEvent error:&err];
                BOOL success = [store removeEvent:eventToRemove span:EKSpanFutureEvents error:&err];
//                BOOL success = [store removeEvent:eventToRemove span:(eventToRemove.isDetached ? EKSpanFutureEvents : EKSpanThisEvent) commit:YES error:&err];
//                BOOL success [store removeEvent:firstEvent span:(firstEvent.isDetached ? EKSpanFutureEvents : desiredSpan) commit:YES error:nil];

                if (!success) {
                    NSLog(@"Error %@", err);
                }
                });
            }
        }
        for (Categories *localCategory in self.categoriesArray) {
            int categoryType = [[[categoryArray objectAtIndex:index.row] objectForKey:@"categoryType"] intValue];
            if (localCategory.categoryType == categoryType) {
                [self.categoriesArray removeObject:localCategory];
                break;
            }
        }
/*
        if (index.row == 1) {
            NSMutableDictionary *dict = [categoryArray objectAtIndex:index.row];
            EKEventStore *store = [[EKEventStore alloc] init];
            EKReminder *reminder = (EKReminder *)[store calendarItemWithIdentifier:[dict objectForKey:@"eventId"]];
            
            NSError *err;
            BOOL sucess = [store removeReminder:reminder commit:YES error:&err];
            if (!sucess) {
                NSLog(@"Error %@", err);
            }
        }
 */
        [self.categoryTableView reloadData];
        [delegate hideActivityIndicator];

    };
    discussionsEndpoint.failureJSON = ^(NSURLRequest *request,
                                        id responseJSON){

        [self alertViewWithTitle:@"" message:[responseJSON objectForKey:@"error"] okButton:@"OK" cancelButton:nil andTag:KFailureAlertTag];
        NSLog(@"error message %@ and json %@", [responseJSON objectForKey:@"error"], responseJSON);
    };
    [discussionsEndpoint deleteCategoryWithDiscussionId:discussionId MessageId:msgId CategoryType:categoryType];
}
- (void)deleteUserCategory
{
    // do the server call to delete user category content
    NSDictionary *dict = [categoryArray objectAtIndex:index.row];
    int categoryType = [[dict objectForKey:@"categoryType"] intValue];
    [self deleteCategoryWithDiscussionId:self.discussionId messageId:self.messageId andCagtegoryType:categoryType];
}
- (void)stopUserInteract
{
    [self.categoryTableView setUserInteractionEnabled:NO];
}

- (void)startUserInteract
{
    [self.categoryTableView setUserInteractionEnabled:YES];
}

- (BOOL)userDefinedCategoryValidation:(UITextField *)textField
{
    for (NSMutableDictionary *dict in categoryArray) {
        if ([[dict objectForKey:@"userDefinedCategory"] isEqualToString:textField.text]) {
            if (isUpdateCategory) {
                textField.text = userCategory;
            } else {
                [textField setText:@""];
            }
            return NO;
        }
    }
    return YES;
}

- (void)alertViewWithTitle:(NSString *)title message:(NSString *)msg okButton:(NSString *)ok cancelButton:(NSString *)cancel andTag:(int)tag
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate hideActivityIndicator];
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:title
                          message:msg
                          delegate:self cancelButtonTitle:ok
                          otherButtonTitles:cancel, nil];
    alert.tag = tag;
    [alert show];
}

- (void)makeViewAlignment
{
    CGFloat categoryViewHeight, categoryTableHeight;
    if (IS_IPHONE_5) {
        keyboardHeight = 200;
        categoryViewHeight = 440;
        categoryTableHeight = 390;
    } else {
        keyboardHeight = 150;
        categoryViewHeight = 352;
        categoryTableHeight = 302;
    }
    CGRect frame = self.categoryView.frame;
    frame.size.height = MIN((categoryArray.count * 44) + 50, categoryViewHeight);
    frame.origin.y = (self.view.frame.size.height - frame.size.height) / 2;
    self.categoryView.frame = frame;
    
    frame = self.categoryTableView.frame;
    frame.size.height = MIN((categoryArray.count * 44), categoryTableHeight);
    self.categoryTableView.frame = frame;
}

- (void) lightBoxFinished:(NSNotification*)aNotification {
    
    NSDictionary *info = [aNotification userInfo];
    if ([info[@"className"] isEqualToString:@"SummaryPointViewController"] || [info[@"className"] isEqualToString:@"ReminderViewController"] || [info[@"className"] isEqualToString:@"TaskViewController"] || [info[@"className"] isEqualToString:@"MeetingViewController"] || [info[@"className"] isEqualToString:@"UserDefinedCategoryViewController"]) {
        
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
             
             postNotificationName:kLightBoxFinishedAtDiscussionNotification
             
             object:self userInfo:@{@"className" : NSStringFromClass([self class])}];
            
        }];
        
    }
    
}

#pragma mark - UITableView Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
//    return [categoryList count];
    return [categoryArray count];
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    UITableViewCell *cell;
     if(indexPath.row < [categoryArray count] - 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"mySysCategoriesCell"];
         
        UIButton *categoryButton = (UIButton *)[cell viewWithTag:100];
         [categoryButton addTarget:self action:@selector(categoryCheckAction:event:) forControlEvents:UIControlEventTouchUpInside];
        [categoryButton.layer setBorderColor:DEFAULT_CGCOLOR];
        [categoryButton.layer setBorderWidth:2.0f];
        
         
         UIImageView *categoryImageView = (UIImageView *)[cell viewWithTag:200];
         if (indexPath.row == 0) {
             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_1]];
         } else if (indexPath.row == 1) {
             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_2]];
         } else if (indexPath.row == 2) {
             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_3]];
         } else if (indexPath.row == 3) {
             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_4]];
         } else if (indexPath.row == 4) {
             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_5]];
             [categoryImageView setAccessibilityIdentifier:CAT_IMG_5];
         } else if (indexPath.row == 5) {
             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_6]];
             [categoryImageView setAccessibilityIdentifier:CAT_IMG_6];
         } else if (indexPath.row == 6) {
             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_7]];
             [categoryImageView setAccessibilityIdentifier:CAT_IMG_7];
         } else if (indexPath.row == 7) {
             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_8]];
             [categoryImageView setAccessibilityIdentifier:CAT_IMG_8];
         } else if (indexPath.row == 8) {
             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_9]];
             [categoryImageView setAccessibilityIdentifier:CAT_IMG_9];
         } else if (indexPath.row == 9) {
             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_10]];
             [categoryImageView setAccessibilityIdentifier:CAT_IMG_10];
         } else if (indexPath.row == 10) {
             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_11]];
             [categoryImageView setAccessibilityIdentifier:CAT_IMG_11];
         } else if (indexPath.row == 11) {
             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_12]];
             [categoryImageView setAccessibilityIdentifier:CAT_IMG_12];
         } else if (indexPath.row == 12) {
             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_13]];
             [categoryImageView setAccessibilityIdentifier:CAT_IMG_13];
         } else if (indexPath.row == 13) {
             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_14]];
             [categoryImageView setAccessibilityIdentifier:CAT_IMG_14];
         } else if (indexPath.row == 14) {
             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_15]];
             [categoryImageView setAccessibilityIdentifier:CAT_IMG_15];
         } else if (indexPath.row == 15) {
             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_16]];
             [categoryImageView setAccessibilityIdentifier:CAT_IMG_16];
         } else if (indexPath.row == 16) {
             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_17]];
             [categoryImageView setAccessibilityIdentifier:CAT_IMG_17];
         } else if (indexPath.row == 17) {
             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_18]];
             [categoryImageView setAccessibilityIdentifier:CAT_IMG_18];
         } else if (indexPath.row == 18) {
             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_19]];
             [categoryImageView setAccessibilityIdentifier:CAT_IMG_19];
         } else if (indexPath.row == 19) {
             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_20]];
             [categoryImageView setAccessibilityIdentifier:CAT_IMG_20];
         } else if (indexPath.row == 20) {
             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_21]];
             [categoryImageView setAccessibilityIdentifier:CAT_IMG_21];
         } else if (indexPath.row == 21) {
             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_22]];
             [categoryImageView setAccessibilityIdentifier:CAT_IMG_22];
         } else if (indexPath.row == 22) {
             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_23]];
             [categoryImageView setAccessibilityIdentifier:CAT_IMG_23];
         } else if (indexPath.row == 23) {
             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_24]];
             [categoryImageView setAccessibilityIdentifier:CAT_IMG_24];
         } else if (indexPath.row == 24) {
             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_25]];
             [categoryImageView setAccessibilityIdentifier:CAT_IMG_25];
//         } else {
//             [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_11]];
//             [categoryImageView setAccessibilityIdentifier:CAT_IMG_11];
         }

         
         UILabel *categoryLabel = (UILabel *)[cell viewWithTag:300];
         if(indexPath.row < 4) {
             [categoryLabel setText:[[categoryArray objectAtIndex:indexPath.row] objectForKey:@"sysCategory"]];
         } else {
             [categoryLabel setText:[[categoryArray objectAtIndex:indexPath.row] objectForKey:@"userDefinedCategory"]];
         }
        
         UIButton *editCategoryButton = (UIButton *)[cell viewWithTag:500];
         [editCategoryButton addTarget:self action:@selector(accessoryButtonAction:event:) forControlEvents:UIControlEventTouchUpInside];
         
         for (Categories *localCategory in self.categoriesArray) {
             int categoryType = [[[categoryArray objectAtIndex:indexPath.row] objectForKey:@"categoryType"] intValue];
             if (localCategory.categoryType == categoryType) {
                 [categoryButton setBackgroundColor: DEFAULT_UICOLOR];
                 [editCategoryButton setHidden:NO];
                 [editCategoryButton addTarget:self action:@selector(accessoryButtonAction:event:) forControlEvents:UIControlEventTouchUpInside];
                 break;
             } else {
                 [categoryButton setBackgroundColor: nil];
                 [editCategoryButton setHidden:YES];
             }
         }
         
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"myUserdefinedCategoriesCell"];
        
        UIButton *userCategoryButton = (UIButton *)[cell viewWithTag:100];
        [userCategoryButton addTarget:self action:@selector(categoryCheckAction:event:) forControlEvents:UIControlEventTouchUpInside];
        [userCategoryButton.layer setBorderColor:DEFAULT_CGCOLOR];
        [userCategoryButton.layer setBorderWidth:2.0f];
        
        UIImageView *userCategoryImageView = (UIImageView *)[cell viewWithTag:200];
        
        if (indexPath.row == 4) {
            [userCategoryImageView setImage:[UIImage imageNamed:CAT_IMG_5]];
            [userCategoryImageView setAccessibilityIdentifier:CAT_IMG_5];
        } else if (indexPath.row == 5) {
            [userCategoryImageView setImage:[UIImage imageNamed:CAT_IMG_6]];
            [userCategoryImageView setAccessibilityIdentifier:CAT_IMG_6];
        } else if (indexPath.row == 6) {
            [userCategoryImageView setImage:[UIImage imageNamed:CAT_IMG_7]];
            [userCategoryImageView setAccessibilityIdentifier:CAT_IMG_7];
        } else if (indexPath.row == 7) {
            [userCategoryImageView setImage:[UIImage imageNamed:CAT_IMG_8]];
            [userCategoryImageView setAccessibilityIdentifier:CAT_IMG_8];
        } else if (indexPath.row == 8) {
            [userCategoryImageView setImage:[UIImage imageNamed:CAT_IMG_9]];
            [userCategoryImageView setAccessibilityIdentifier:CAT_IMG_9];
        } else if (indexPath.row == 9) {
            [userCategoryImageView setImage:[UIImage imageNamed:CAT_IMG_10]];
            [userCategoryImageView setAccessibilityIdentifier:CAT_IMG_10];
        } else if (indexPath.row == 10) {
            [userCategoryImageView setImage:[UIImage imageNamed:CAT_IMG_11]];
            [userCategoryImageView setAccessibilityIdentifier:CAT_IMG_11];
        } else if (indexPath.row == 11) {
            [userCategoryImageView setImage:[UIImage imageNamed:CAT_IMG_12]];
            [userCategoryImageView setAccessibilityIdentifier:CAT_IMG_12];
        } else if (indexPath.row == 12) {
            [userCategoryImageView setImage:[UIImage imageNamed:CAT_IMG_13]];
            [userCategoryImageView setAccessibilityIdentifier:CAT_IMG_13];
        } else if (indexPath.row == 13) {
            [userCategoryImageView setImage:[UIImage imageNamed:CAT_IMG_14]];
            [userCategoryImageView setAccessibilityIdentifier:CAT_IMG_14];
        } else if (indexPath.row == 14) {
            [userCategoryImageView setImage:[UIImage imageNamed:CAT_IMG_15]];
            [userCategoryImageView setAccessibilityIdentifier:CAT_IMG_15];
        } else if (indexPath.row == 15) {
            [userCategoryImageView setImage:[UIImage imageNamed:CAT_IMG_16]];
            [userCategoryImageView setAccessibilityIdentifier:CAT_IMG_16];
        } else if (indexPath.row == 16) {
            [userCategoryImageView setImage:[UIImage imageNamed:CAT_IMG_17]];
            [userCategoryImageView setAccessibilityIdentifier:CAT_IMG_17];
        } else if (indexPath.row == 17) {
            [userCategoryImageView setImage:[UIImage imageNamed:CAT_IMG_18]];
            [userCategoryImageView setAccessibilityIdentifier:CAT_IMG_18];
        } else if (indexPath.row == 18) {
            [userCategoryImageView setImage:[UIImage imageNamed:CAT_IMG_19]];
            [userCategoryImageView setAccessibilityIdentifier:CAT_IMG_19];
        } else if (indexPath.row == 19) {
            [userCategoryImageView setImage:[UIImage imageNamed:CAT_IMG_20]];
            [userCategoryImageView setAccessibilityIdentifier:CAT_IMG_20];
        } else if (indexPath.row == 20) {
            [userCategoryImageView setImage:[UIImage imageNamed:CAT_IMG_21]];
            [userCategoryImageView setAccessibilityIdentifier:CAT_IMG_21];
        } else if (indexPath.row == 21) {
            [userCategoryImageView setImage:[UIImage imageNamed:CAT_IMG_22]];
            [userCategoryImageView setAccessibilityIdentifier:CAT_IMG_22];
        } else if (indexPath.row == 22) {
            [userCategoryImageView setImage:[UIImage imageNamed:CAT_IMG_23]];
            [userCategoryImageView setAccessibilityIdentifier:CAT_IMG_23];
        } else if (indexPath.row == 23) {
            [userCategoryImageView setImage:[UIImage imageNamed:CAT_IMG_24]];
            [userCategoryImageView setAccessibilityIdentifier:CAT_IMG_24];
        } else if (indexPath.row == 24) {
            [userCategoryImageView setImage:[UIImage imageNamed:CAT_IMG_25]];
            [userCategoryImageView setAccessibilityIdentifier:CAT_IMG_25];
        }
        
        
        UITextField *categoryField = (UITextField *)[cell viewWithTag:400];
        [categoryField setText:[[categoryArray objectAtIndex:indexPath.row] objectForKey:@"userDefinedCategory"]];
        
        UIButton *editCategoryButton = (UIButton *)[cell viewWithTag:500];
        [editCategoryButton addTarget:self action:@selector(accessoryButtonAction:event:) forControlEvents:UIControlEventTouchUpInside];
        
        
        for (Categories *localCategory in self.categoriesArray) {
            int categoryType = [[[categoryArray objectAtIndex:indexPath.row] objectForKey:@"categoryType"] intValue];
            if (localCategory.categoryType == categoryType) {
                [userCategoryButton setBackgroundColor: DEFAULT_UICOLOR];
                [editCategoryButton setHidden:NO];
                [editCategoryButton addTarget:self action:@selector(accessoryButtonAction:event:) forControlEvents:UIControlEventTouchUpInside];
                break;
            } else {
                [userCategoryButton setBackgroundColor: nil];
                [editCategoryButton setHidden:YES];
            }
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
//    
//    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
//    UITextField *userCategoryField = (UITextField *)[cell viewWithTag:400];
//    
//    [userCategoryField becomeFirstResponder];
   
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    UIButton *editCategoryButton = (UIButton *)[cell viewWithTag:500];
    if (!editCategoryButton.isHidden) {
        editMode = YES;
    } else {
        editMode = NO;
    }
    [self showCategoryDetails:indexPath];
}

#pragma mark - UIButton Actions

- (IBAction)backAction:(id)sender
{
    [self dismissSelf];
}

- (void)categoryCheckAction:(id)sender event:(id)event
{
    NSSet *touches = [event allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.categoryTableView];
	NSIndexPath *indexPath = [self.categoryTableView indexPathForRowAtPoint: currentTouchPosition];
    if(indexPath != nil) {
        UITableViewCell *cell = [self.categoryTableView cellForRowAtIndexPath:indexPath];
        
        editCategory = (UIButton *)[cell viewWithTag:500];
        colorImageView = (UIImageView *)[cell viewWithTag:200];
        
        checkBoxBtn = (UIButton *)sender;
        index = indexPath;
        NSLog(@"indexpath %d", indexPath.row);
        if (![checkBoxBtn backgroundColor]) {
            if (indexPath.row == maxUserCategory + 4) {//'4' - userDefinedCategory Count
                [self alertViewWithTitle:@"Alert" message:[NSString stringWithFormat: @"You should upgrade to premium account to add more than %d categories.", maxUserCategory] okButton:@"OK" cancelButton:nil andTag:0];
            } else {
                if (selectedCategoryCounter < categoryLimit) {
                    if (indexPath.row == 0) {
                        [self performSegueWithIdentifier:@"summaryPointIdentifier" sender:self];
                    } else if (indexPath.row == 1) {
                        [self performSegueWithIdentifier:@"ReminderIdentifier" sender:self];
                    } else if (indexPath.row == 2) {
                        [self performSegueWithIdentifier:@"TaskIdentifier" sender:self];
                    } else if (indexPath.row == 3) {
                        [self performSegueWithIdentifier:@"MeetingIdentifier" sender:self];
                    } else {
                        //UITextField *categoryField = (UITextField *)[cell viewWithTag:400];
                        UILabel *categoryLabel = (UILabel *)[cell viewWithTag:300];
                        if (![categoryLabel.text isEqualToString:@""]) {
                            [self performSegueWithIdentifier:@"userCategoryIdentifier" sender:self];
                        } else {
                            [self alertViewWithTitle:@"Alert" message:@"Please provide a name for this category." okButton:@"OK" cancelButton:nil andTag:0];
                        }
                    }
                } else {
                    [self alertViewWithTitle:@"Alert" message:[NSString stringWithFormat:@"Cannot assign more than %d categories to a message.",categoryLimit] okButton:@"OK" cancelButton:nil andTag:0];
                }
            }
        } else {
            [self alertViewWithTitle:@"Confirm Delete" message:@"Do you want to delete the category?" okButton:@"Cancel" cancelButton:@"Ok" andTag:KDeleteAlertTag];
        }
    }
}
- (IBAction)accessoryButtonAction:(id)sender event:(id)event
{
    editMode = YES;
    NSSet *touches = [event allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.categoryTableView];
	NSIndexPath *indexPath = [self.categoryTableView indexPathForRowAtPoint: currentTouchPosition];
    index = indexPath;
    
    if (indexPath.row == 0) {
        [self performSegueWithIdentifier:@"summaryPointIdentifier" sender:self];
    } else if (indexPath.row == 1) {
        [self performSegueWithIdentifier:@"ReminderIdentifier" sender:self];
    } else if (indexPath.row == 2) {
        [self performSegueWithIdentifier:@"TaskIdentifier" sender:self];
    } else if (indexPath.row == 3) {
        [self performSegueWithIdentifier:@"MeetingIdentifier" sender:self];
    } else {
        [self performSegueWithIdentifier:@"userCategoryIdentifier" sender:self];
    }
}

- (void) showCategoryDetails: (NSIndexPath *) indexPath {
    UITableViewCell *cell = [self.categoryTableView cellForRowAtIndexPath:indexPath];
    
    editCategory = (UIButton *)[cell viewWithTag:500];
    colorImageView = (UIImageView *)[cell viewWithTag:200];
    
    index = indexPath;
    if (editMode) {
        [self presentCategoryView:indexPath];
    } else {
    if (selectedCategoryCounter < categoryLimit) {
        if (indexPath.row == 0) {
            [self performSegueWithIdentifier:@"summaryPointIdentifier" sender:self];
        } else if (indexPath.row == 1) {
            [self performSegueWithIdentifier:@"ReminderIdentifier" sender:self];
        } else if (indexPath.row == 2) {
            [self performSegueWithIdentifier:@"TaskIdentifier" sender:self];
        } else if (indexPath.row == 3) {
            [self performSegueWithIdentifier:@"MeetingIdentifier" sender:self];
        } else {
            //UITextField *categoryField = (UITextField *)[cell viewWithTag:400];
            UILabel *categoryLabel = (UILabel *)[cell viewWithTag:300];
            if (![categoryLabel.text isEqualToString:@""]) {
                [self performSegueWithIdentifier:@"userCategoryIdentifier" sender:self];
            } else {
                [self alertViewWithTitle:@"Alert" message:@"Please provide a name for this category." okButton:@"OK" cancelButton:nil andTag:0];
            }
        }
    } else {
        [self alertViewWithTitle:@"Alert" message:[NSString stringWithFormat:@"Cannot assign more than %d categories to a message.",categoryLimit] okButton:@"OK" cancelButton:nil andTag:0];
    }
    }
}

- (void)presentCategoryView:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        [self performSegueWithIdentifier:@"summaryPointIdentifier" sender:self];
    } else if (indexPath.row == 1) {
        [self performSegueWithIdentifier:@"ReminderIdentifier" sender:self];
    } else if (indexPath.row == 2) {
        [self performSegueWithIdentifier:@"TaskIdentifier" sender:self];
    } else if (indexPath.row == 3) {
        [self performSegueWithIdentifier:@"MeetingIdentifier" sender:self];
    } else {
        [self performSegueWithIdentifier:@"userCategoryIdentifier" sender:self];
    }
}
#pragma mark - UITextField Delegate method

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    UITableViewCell *cell;
    
    if([textField.superview.superview isKindOfClass:[UITableViewCell class]]) {
        cell = (UITableViewCell *) textField.superview.superview;
    } else {
        cell = (UITableViewCell *) textField.superview.superview.superview;
    }
    NSIndexPath *indexPath = [self.categoryTableView indexPathForCell:cell];
    //    if (noOfUserCategory == maxUserCategory || [categoryArray count] == maxUserCategory + 5) {
    if (indexPath.row == maxUserCategory + 4) {
        
        [self alertViewWithTitle:@"Alert" message:[NSString stringWithFormat: @"You should upgrade to premium account to add more than %d categories.", maxUserCategory] okButton:@"OK" cancelButton:nil andTag:0];
        return NO;
        
    } else {
        userCategory = textField.text;
        [self stopUserInteract];
        /*
        [UIView animateWithDuration:0.2f animations:^{
            CGRect frame = self.categoryTableView.frame;
            frame.origin.y = frame.origin.y - 90;
            [self.categoryTableView setFrame:frame];
        }];
        */
        [UIView animateWithDuration:0.2f animations:^{
            CGRect frame = self.categoryTableView.frame;
            frame.origin.y -= self.categoryView.frame.size.height - keyboardHeight; //225 keyboard height
            [self.categoryTableView setFrame:frame];
        }];
        
        if (![textField.text isEqualToString:@""]) {
            isUpdateCategory = YES;
            isCategoryTitleNotEmpty = NO;
        } else {
            isUpdateCategory = NO;
            isCategoryTitleNotEmpty = YES;
        }
    }
    return YES;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField;
{
    if (![textField.text isEqualToString:@""]) {
        if ([self userDefinedCategoryValidation:textField]) {
            [self insertUserCategory:textField];
        } else {
            
            [self alertViewWithTitle:@"Alert" message:@"This category already exists." okButton:@"OK" cancelButton:nil andTag:0];
            
        }
    }else if([textField.text isEqualToString:@""] && isUpdateCategory) {
        
        [self alertViewWithTitle:@"Alert" message:@"Categories cannot be blank." okButton:@"OK" cancelButton:nil andTag:0];

        textField.text = userCategory;
        
    }
    [self startUserInteract];
    [textField resignFirstResponder];
    /*
    [UIView animateWithDuration:0.2f animations:^{
        CGRect frame = self.categoryTableView.frame;
        frame.origin.y = frame.origin.y + 90;
        [self.categoryTableView setFrame:frame];
    }];
     */
    [UIView animateWithDuration:0.2f animations:^{
        CGRect frame = self.categoryTableView.frame;
        frame.origin.y += self.categoryView.frame.size.height - keyboardHeight; //225 keyboard height
        [self.categoryTableView setFrame:frame];
    }];
    return YES;
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > KMaxUserCategoryLength) ? NO : YES;
}

#pragma mark - UIAlertView Delegate Method
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1 && alertView.tag == KDeleteAlertTag) {
        [self deleteUserCategory];
    }
}

#pragma mark - UITouches Delegate Method
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    if (touch.view == self.view) {
        [self dismissSelf];
    }
}

#pragma mark - Summary Point Delegate Method
- (void)summaryPointCreatedWithCategoryType:(int)categoryType categoryId:(int)categoryId categoryText:(NSString *)text andEditMode:(BOOL)edited
{
    if (edited) {
        for (Categories *summaryPoint in self.categoriesArray) {
            if (summaryPoint.categoryType == categoryType) {
                summaryPoint.text = text;
                break;
            }
        }
    } else {
        
        selectedCategoryCounter++;
        
        Categories *summary = [[Categories alloc]init];
        summary.categoryType = categoryType;
        summary.text = text;
        summary.color = CAT_IMG_1;
        [self.categoriesArray addObject:summary];
    }
    [self.categoryTableView reloadData];
}

- (void)reminderCreatedWithSubject:(NSString *)subject time:(NSString*)time tone:(NSString*)tone frequency:(NSString*)frequency notes:(NSString *)notes priority:(NSString *)priority reminderId:(NSString *)reminderId categoryType:(int)categoryType categoryId:(int)categoryId andEditMode:(BOOL)edited
{
    if (edited) {
        for (Reminder *reminder in self.categoriesArray) {
            if (reminder.categoryType == categoryType) {
                reminder.subject = subject;
                reminder.reminderTime = time;
                reminder.ringtone = tone;
                reminder.repeatFrequency = frequency;
                reminder.text = notes;
                reminder.priority = priority;
                reminder.reminderId = reminderId;
                
                NSMutableDictionary *dict = [categoryArray objectAtIndex:1];
                [dict setObject:reminderId forKey:@"eventId"];
                break;
            }
        }
    } else {
        selectedCategoryCounter++;
        
        Reminder *reminder = [[Reminder alloc] init];
        reminder.categoryType = 2;
        reminder.color = CAT_IMG_2;
        
        reminder.subject = subject;
        reminder.reminderTime = time;
        reminder.ringtone = tone;
        reminder.repeatFrequency = frequency;
        reminder.text = notes;
        reminder.priority = priority;
        reminder.reminderId = reminderId;
        [self.categoriesArray addObject:reminder];
        
        NSMutableDictionary *dict = [categoryArray objectAtIndex:1];
        [dict setObject:reminderId forKey:@"eventId"];
    }
    [self.categoryTableView reloadData];
}

- (void)taskCreatedWithSubject:(NSString *)subject toList:(NSString*)toList category:(NSString*)category reminderTime:(NSString*)reminderTime alert:(NSString *)alert secondAlert:(NSString *)secondAlert repeatFrequency:(NSString *)repeatFrequency priority:(NSString *)priority notes:(NSString *)notes calendarId:(NSString *)calendarId categoryType:(int)categoryType categoryId:(int)categoryId andEditMode:(BOOL)edited
{
    if (edited) {
        for (Task *task in self.categoriesArray) {
            if (task.categoryType == categoryType) {
                
                task.subject = subject;
                task.toList = toList;
                task.actionCategory = category;
                task.reminderTime = reminderTime;
                task.alert = alert;
                task.secondAlert = secondAlert;
                task.repeatFrequency = repeatFrequency;
                task.priority = priority;
                task.text = notes;
                task.calendarId = calendarId;

                NSMutableDictionary *dict = [categoryArray objectAtIndex:2];
                [dict setObject:calendarId forKey:@"eventId"];
                break;
            }
        }
    } else {
        selectedCategoryCounter++;
        Task *task = [[Task alloc] init];
        task.categoryType = 3;
        task.color = CAT_IMG_3;
        
        task.subject = subject;
        task.toList = toList;
        task.actionCategory = category;
        task.reminderTime = reminderTime;
        task.alert = alert;
        task.secondAlert = secondAlert;
        task.repeatFrequency = repeatFrequency;
        task.priority = priority;
        task.text = notes;
        task.calendarId = calendarId;
        [self.categoriesArray addObject:task];
        
        NSMutableDictionary *dict = [categoryArray objectAtIndex:2];
        [dict setObject:calendarId forKey:@"eventId"];
    }
    [self.categoryTableView reloadData];
}

- (void)meetingCreatedWithSubject:(NSString *)subject toList:(NSString *)toList location:(NSString *)location allDayEvent:(BOOL)allDay startDate:(NSString *)startDate endDate:(NSString *)endDate repeatFrequency:(NSString *)repeatFrequency alert:(NSString *)alert secondAlert:(NSString *)secondAlert priority:(NSString *)priority filePath:(NSString *)filePath notes:(NSString *)notes calendarId:(NSString *)calendarId categoryType:(int)categoryType categoryId:(int)categoryId andEditMode:(BOOL)edited
{
    if (edited) {
        for (Meeting *meeting in self.categoriesArray) {
            if (meeting.categoryType == categoryType) {
                
                meeting.subject = subject;
                meeting.toList = toList;
                meeting.location = location;
                meeting.allDayEvent = allDay;
                meeting.startDate = startDate;
                meeting.endDate = endDate;
                meeting.repeatFrequency = repeatFrequency;
                meeting.alert = alert;
                meeting.secondAlert = secondAlert;
                meeting.priority = priority;
                meeting.filePath = filePath;
                meeting.text = notes;
                meeting.calendarId = calendarId;
                
                NSMutableDictionary *dict = [categoryArray objectAtIndex:3];
                [dict setObject:calendarId forKey:@"eventId"];
                break;
            }
        }
    } else {
        selectedCategoryCounter++;
        Meeting *meeting = [[Meeting alloc] init];
        meeting.categoryType = 4;
        meeting.color = CAT_IMG_4;
        
        meeting.subject = subject;
        meeting.toList = toList;
        meeting.location = location;
        meeting.allDayEvent = allDay;
        meeting.startDate = startDate;
        meeting.endDate = endDate;
        meeting.repeatFrequency = repeatFrequency;
        meeting.alert = alert;
        meeting.secondAlert = secondAlert;
        meeting.priority = priority;
        meeting.filePath = filePath;
        meeting.text = notes;
        meeting.calendarId = calendarId;
        [self.categoriesArray addObject:meeting];
        
        NSMutableDictionary *dict = [categoryArray objectAtIndex:3];
        [dict setObject:calendarId forKey:@"eventId"];
    }
    [self.categoryTableView reloadData];
}

- (void)userCategoryInstanceCreatedWithCategoryType:(int)categoryType categoryId:(int)categoryId categoryText:(NSString *)text andEditMode:(BOOL)edited
{
    if (edited) {
        for (Categories *userDefinedcategory in self.categoriesArray) {
            if (userDefinedcategory.categoryType == categoryType) {
                userDefinedcategory.text = text;
                break;
            }
        }
    } else {
        selectedCategoryCounter++;
        
        Categories *userDefinedcategory = [[Categories alloc]init];
        userDefinedcategory.categoryType = categoryType;
        userDefinedcategory.categoryId = categoryId;
        userDefinedcategory.color = colorImageView.accessibilityIdentifier;
        userDefinedcategory.text = text;
        
        [self.categoriesArray addObject:userDefinedcategory];
        
        NSMutableDictionary *dict = [categoryArray objectAtIndex:index.row];
        [dict setObject:[NSString stringWithFormat:@"%@",[dict objectForKey:@"categoryId"]] forKey:@"categoryId"];
    }
    [self.categoryTableView reloadData];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    [UIView animateWithDuration:0.5 animations:^(void) {
        self.view.alpha = 0;
    }];
    
    if ([segue.identifier isEqualToString:@"summaryPointIdentifier"]) {
        
        SummaryPointViewController *spController = segue.destinationViewController;
        spController.delegate = self;
        spController.chatName = self.chatName;
        spController.chatMessage = self.chatMessage;
        spController.discussionId = self.discussionId;
        spController.messageId = self.messageId;
        spController.annotationImg = self.annotationImage;
        spController.messageTimeStamp = self.messageTimeStamp;
        
        spController.isEditMode = editMode;
        if (editMode) {
            for (Categories *localCategory in self.categoriesArray) {
                int categoryType = [[[categoryArray objectAtIndex:index.row] objectForKey:@"categoryType"] intValue];
                if (localCategory.categoryType == categoryType) {
                    spController.summaryPoint = localCategory;
                    break;
                }
            }
        }
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
            
            self.modalPresentationStyle = UIModalPresentationCurrentContext;
            
        } else {
            
            self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            
            spController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            
        }
        spController.view.backgroundColor = [UIColor clearColor];
//        self.modalPresentationStyle = UIModalPresentationCurrentContext;
        
    } else if ([segue.identifier isEqualToString:@"ReminderIdentifier"]) {
        
        ReminderViewController *reminderController = segue.destinationViewController;
        reminderController.delegate = self;
        reminderController.chatName = self.chatName;
        reminderController.chatMessage = self.chatMessage;
        reminderController.discussionId = self.discussionId;
        reminderController.messageId = self.messageId;
        reminderController.annotationImg = self.annotationImage;
        reminderController.messageTimeStamp = self.messageTimeStamp;
        
        reminderController.isEditMode = editMode;
        if (editMode) {
            for (Reminder *localReminder in self.categoriesArray) {
                int categoryType = [[[categoryArray objectAtIndex:index.row] objectForKey:@"categoryType"] intValue];
                if (localReminder.categoryType == categoryType) {
                    reminderController.reminder = localReminder;
                    break;
                }
            }
        }
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
            
            self.modalPresentationStyle = UIModalPresentationCurrentContext;
            
        } else {
            
            self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            
            reminderController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            
        }
        reminderController.view.backgroundColor = [UIColor clearColor];
//        self.modalPresentationStyle = UIModalPresentationCurrentContext;
        
    } else if ([segue.identifier isEqualToString:@"TaskIdentifier"]) {
        
        TaskViewController *taskController = segue.destinationViewController;
        taskController.delegate = self;
        taskController.chatName = self.chatName;
        taskController.chatMessage = self.chatMessage;
        taskController.annotationImg = self.annotationImage;
        
        taskController.discussionId = self.discussionId;
        taskController.discussionTitle = self.discussionTitle;
        taskController.messageId = self.messageId;
        taskController.messageTimeStamp = self.messageTimeStamp;
        
        taskController.isEditMode = editMode;
        if (editMode) {
            for (Task *task in self.categoriesArray) {
                int categoryType = [[[categoryArray objectAtIndex:index.row] objectForKey:@"categoryType"] intValue];
                if (task.categoryType == categoryType) {
                    taskController.task = task;
                    break;
                }
            }
        }
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
            
            self.modalPresentationStyle = UIModalPresentationCurrentContext;
            
        } else {
            
            self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            
            taskController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            
        }
        taskController.view.backgroundColor = [UIColor clearColor];
//        self.modalPresentationStyle = UIModalPresentationCurrentContext;
        
    } else if ([segue.identifier isEqualToString:@"MeetingIdentifier"]) {
        
        MeetingViewController *meetingController = segue.destinationViewController;
        meetingController.delegate = self;
        meetingController.chatName = self.chatName;
        meetingController.chatMessage = self.chatMessage;
        meetingController.annotationImg = self.annotationImage;
        
        meetingController.discussionId = self.discussionId;
        meetingController.discussionTitle = self.discussionTitle;
        meetingController.messageId = self.messageId;
        meetingController.messageTimeStamp = self.messageTimeStamp;
        
        meetingController.isEditMode = editMode;
        
        if (editMode) {
            for (Meeting *meeting in self.categoriesArray) {
                int categoryType = [[[categoryArray objectAtIndex:index.row] objectForKey:@"categoryType"] intValue];
                if (meeting.categoryType == categoryType) {
                    meetingController.meeting = meeting;
                    break;
                }
            }
        }
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
            
            self.modalPresentationStyle = UIModalPresentationCurrentContext;
            
        } else {
            
            self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            
            meetingController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            
        }
        meetingController.view.backgroundColor = [UIColor clearColor];
//        self.modalPresentationStyle = UIModalPresentationCurrentContext;
        
    } else if ([segue.identifier isEqualToString:@"userCategoryIdentifier"]) {
        
        UserDefinedCategoryViewController *userController = segue.destinationViewController;
        userController.delegate = self;
        
        UITableViewCell *cell = [self.categoryTableView cellForRowAtIndexPath:index];
        //UITextField *categoryField = (UITextField *)[cell viewWithTag:400];
        UILabel *categoryLabel = (UILabel *)[cell viewWithTag:300];
        
        int categoryType = [[[categoryArray objectAtIndex:index.row] objectForKey:@"categoryType"] intValue];
        
        NSLog(@"categoryType %@", [[categoryArray objectAtIndex:index.row] objectForKey:@"categoryId"]);
        NSLog(@"catID %@", [categoryArray objectAtIndex:index.row]);
        userController.userNotesTitle = categoryLabel.text;
        
        userController.chatName = self.chatName;
        userController.chatMessage = self.chatMessage;
        userController.discussionId = self.discussionId;
        userController.messageId = self.messageId;
        userController.categoryType = categoryType;
        
        userController.annotationImg = self.annotationImage;
        userController.messageTimeStamp = self.messageTimeStamp;
        
        userController.isEditMode = editMode;
        
        if (editMode) {
            for (Categories *localUDCategory in self.categoriesArray) {
                int categoryType = [[[categoryArray objectAtIndex:index.row] objectForKey:@"categoryType"] intValue];
                if (localUDCategory.categoryType == categoryType) {
                    userController.userDefinedCategory = localUDCategory;
                    break;
                }
            }
        }
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
            
            self.modalPresentationStyle = UIModalPresentationCurrentContext;
            
        } else {
            
            self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            
            userController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            
        }
        userController.view.backgroundColor = [UIColor clearColor];
//        self.modalPresentationStyle = UIModalPresentationCurrentContext;
    }
    editMode = NO;
}
@end
