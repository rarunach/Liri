//
//  DiscussionSummaryViewController.m
//  Liri
//
//  Created by Varun Sankar on 01/08/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "DiscussionSummaryViewController.h"
#import "UserCategories.h"
#import "AppDelegate.h"
#import "Account.h"
#import "EmailComposerViewController.h"
#import "Flurry.h"

@interface DiscussionSummaryViewController ()
{
    BOOL isShown;
    
    NSString *bullet, *allCategories, *summaryPoint, *reminder, *task, *meetingInvite, *userDefined, *allMembers;
    
    NSMutableArray *categoryArray, *userCategoryArray;
    
    NSMutableArray *attributeStrArray;
    
    NSMutableArray *selectedItems;
    
    ChooseCategoryViewController *chooseCategoryCtlr;
}
@property (weak, nonatomic) IBOutlet UILabel *titleLbl;
@property (weak, nonatomic) IBOutlet UIButton *backBtn;
@property (weak, nonatomic) IBOutlet UIButton *pickerBtn;
@property (weak, nonatomic) IBOutlet UITextView *summaryTextView;
@property (weak, nonatomic) IBOutlet UIImageView *sendBtnAboveLine;
@property (weak, nonatomic) IBOutlet UIButton *sendMailBtn;

- (IBAction)backBtnAction:(id)sender;
- (IBAction)pickerBtnAction:(id)sender;
- (IBAction)emailBtnAction:(id)sender;
@end

@implementation DiscussionSummaryViewController

@synthesize discussionId = _discussionId;

@synthesize titleLbl = _titleLbl;

@synthesize pickerBtn = _pickerBtn;

@synthesize summaryTextView = _summaryTextView;

@synthesize sendMailBtn = _sendMailBtn;

@synthesize sendBtnAboveLine = _sendBtnAboveLine;

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
    [Flurry logEvent:@"Discussion Summary Screen"];
    
    bullet = @"●";
    
    [self.summaryTextView.layer setBorderColor:DEFAULT_CGCOLOR];
    
    selectedItems = [[NSMutableArray alloc] init];
    categoryArray = [[NSMutableArray alloc] init];
    userCategoryArray = [[NSMutableArray alloc] init];
    
    UserCategories *categories = [UserCategories sharedManager];
    [categoryArray addObject:@"All Categories"];
    for (NSDictionary *category in categories.categoryArray) {
        if (nil != category[@"sysCategory"]) {
            [categoryArray addObject: category[@"sysCategory"]];
        } else if (nil != category[@"userDefinedCategory"]) {
            [categoryArray addObject:category[@"userDefinedCategory"]];
            [userCategoryArray addObject:category[@"categoryType"]];
        }
    }
    [categoryArray removeLastObject];
    [userCategoryArray removeLastObject];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lightBoxFinished:) name:kLightBoxFinishedNotification object:nil];
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    [self getCategories];
}

- (void)viewDidLayoutSubviews
{
    if(!IS_IPHONE_5) {
        //do stuff for 3.5 inch iPhone screen
        [self.summaryTextView setFrame:CGRectMake(self.summaryTextView.frame.origin.x, self.summaryTextView.frame.origin.y, self.summaryTextView.frame.size.width, 305)];
        
        [self.sendBtnAboveLine setFrame:CGRectMake(self.sendBtnAboveLine.frame.origin.x, 425, self.sendBtnAboveLine.frame.size.width, self.sendBtnAboveLine.frame.size.height)];
        
        [self.sendMailBtn setFrame:CGRectMake(self.sendMailBtn.frame.origin.x, 440, self.sendMailBtn.frame.size.width, self.sendMailBtn.frame.size.height)];
    }
}

- (void) lightBoxFinished:(NSNotification*)aNotification {
    NSDictionary *info = [aNotification userInfo];
    if ([info[@"className"] isEqualToString:@"ChooseCategoryViewController"]) {
        [UIView animateWithDuration:0.3 animations:^(void) {
            self.view.alpha = 1.0;
            [self.navigationController.view setAlpha:1.0];
        }];
    }
}
- (void)viewDidAppear:(BOOL)animated
{
    [UIView animateWithDuration:1.0 animations:^(void) {
        self.view.alpha = 1.0;
        [self.navigationController.view setAlpha:1.0];
    }];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
    NSLog(@"text %@ and url %@", textView.text, URL);
    return NO;
}
#pragma mark - Private Methods
- (void)getCategories
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // do create
    id<APIAccessClient> discussionsEndpoint =
    (id<APIAccessClient>)[[APIManager
                                 sharedInstanceWithClientProtocol:
                                 @protocol(APIAccessClient)] client];
    
    discussionsEndpoint.successJSON = ^(NSURLRequest *request,
                                        id responseJSON){
        [self setSummaryFormat:responseJSON[@"categories"]];
        [delegate hideActivityIndicator];
    };
    discussionsEndpoint.failureJSON = ^(NSURLRequest *request,
                                        id responseJSON){
        [delegate hideActivityIndicator];
        /*UIAlertView *failureAlert = [[UIAlertView alloc]
                                     initWithTitle:@""
                                     message:responseJSON[@"error"]
                                     delegate:self cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil];
        [failureAlert setTag:KFailureAlertTag];
        [failureAlert show];*/
        
        NSLog(@"error message %@ and json %@", responseJSON[@"error"], responseJSON);
    };
    
    [discussionsEndpoint getDiscussionSummaryByDiscussionId:self.discussionId];
}

- (void)setSummaryFormat:(NSDictionary *)summaries
{
    [self.titleLbl setText:summaries[@"name"]];
    NSArray *allMembersArray = summaries[@"allmembers"];
    NSString *attendees = @"";
    for (NSString *str in allMembersArray) {
        attendees =  [attendees stringByAppendingString:[NSString stringWithFormat:@"%@, ", str]];
    }
    attendees = [attendees substringToIndex:attendees.length - 2];
    allMembers = [NSString stringWithFormat:@"Attendees\n%@\n\n",attendees];
    
    allCategories = @"";
    
    allCategories = [allCategories stringByAppendingString:[NSString stringWithFormat:@"%@", allMembers]];
    
    NSString *localStr = @"";

    NSArray *localArray = summaries[@"data"][@"summary"];
    for (NSDictionary *dictionary in localArray) {
        if([dictionary[@"value"][@"notes"] hasPrefix:@"liri-image:"]) {
            localStr =[localStr stringByAppendingString:[NSString stringWithFormat:@"%@ New Annotated image has been received.\n\n", bullet]];
        } else {
            localStr =  [localStr stringByAppendingString:[NSString stringWithFormat:@"%@ %@\n\n", bullet, dictionary[@"value"][@"notes"]]];
        }
    }
    if (![localStr isEqualToString:@""]) {
        allCategories = [allCategories stringByAppendingString:[NSString stringWithFormat:@"Summary Point\n%@", localStr]];
        [selectedItems addObject:[NSString stringWithFormat:@"Summary Point\n%@", localStr]];
    } else {
        [selectedItems addObject:[NSString stringWithFormat:@""]];
    }
    summaryPoint = [NSString stringWithFormat:@"%@Summary Point\n%@", allMembers, localStr];

    localArray = summaries[@"data"][@"reminder"];
    localStr = @"";
    for (NSDictionary *dictionary in localArray) {
        NSString *reminderTime = [Account convertGmtToLocalTimeZone:dictionary[@"value"][@"attributes"][@"reminder_time"]];
        localStr =  [localStr stringByAppendingString:[NSString stringWithFormat:@"%@ On %@; ", bullet, reminderTime]];
        if (![dictionary[@"value"][@"attributes"][@"repeat_frequency"] isEqualToString:@"Never >"]) {
            localStr = [localStr stringByAppendingString:[NSString stringWithFormat:@"repeat reminder %@; ", dictionary[@"value"][@"attributes"][@"repeat_frequency"]]];
        }
        if (![dictionary[@"value"][@"attributes"][@"priority"] isEqualToString:@"None"]) {
            localStr = [localStr stringByAppendingString:[NSString stringWithFormat:@"%@ Priority; ", dictionary[@"value"][@"attributes"][@"priority"]]];
        }
        if (![dictionary[@"value"][@"attributes"][@"subject"] isEqualToString:@""]) {
            localStr = [localStr stringByAppendingString:[NSString stringWithFormat:@"%@\n\n", dictionary[@"value"][@"attributes"][@"subject"]]];
        }
    }
    if (![localStr isEqualToString:@""]) {
        allCategories = [allCategories stringByAppendingString:[NSString stringWithFormat:@"Reminders\n%@",localStr]];
        [selectedItems addObject:[NSString stringWithFormat:@"Reminders\n%@", localStr]];
    } else {
        [selectedItems addObject:[NSString stringWithFormat:@""]];
    }
    reminder = [NSString stringWithFormat:@"%@Reminders\n%@", allMembers, localStr];

    Account *account = [Account sharedInstance];
    localArray = summaries[@"data"][@"task"];
    localStr = @"";
    for (NSDictionary *dictionary in localArray) {
        NSArray *toArray = dictionary[@"value"][@"owner_editable"][@"to"];
        NSString *recipient = @"";
        if ([dictionary[@"value"][@"creator"] isEqualToString:account.email]) {
            for (NSDictionary *toDict in toArray) {
                recipient = [recipient stringByAppendingString:[NSString stringWithFormat:@"%@,", [self getRecipientNameByMailId:toDict[@"user"]]]];
            }
        } else {
            for (NSString *str in toArray) {
                recipient = [recipient stringByAppendingString:[NSString stringWithFormat:@"%@,", [self getRecipientNameByMailId:str]]];
            }
        }
        NSString *reminderTime = [Account convertGmtToLocalTimeZone:dictionary[@"value"][@"owner_editable"][@"remindertime"]];
        localStr =  [localStr stringByAppendingString:[NSString stringWithFormat:@"%@ Task assigned to %@ %@ %@; ", bullet, recipient, dictionary[@"value"][@"owner_editable"][@"actioncategory"], reminderTime]];
        
        if (![dictionary[@"value"][@"owner_editable"][@"repeat_frequency"] isEqualToString:@"Never >"]) {
            localStr = [localStr stringByAppendingString:[NSString stringWithFormat:@"repeat task %@; ", dictionary[@"value"][@"owner_editable"][@"repeat_frequency"]]];
        }
        if (![dictionary[@"value"][@"owner_editable"][@"priority"] isEqualToString:@"None"]) {
            if ([dictionary[@"value"][@"owner_editable"][@"priority"] isEqualToString:@"Med"]) {
                localStr = [localStr stringByAppendingString:@"Medium Priority; "];

            } else {
                localStr = [localStr stringByAppendingString:[NSString stringWithFormat:@"%@ Priority; ", dictionary[@"value"][@"owner_editable"][@"priority"]]];
            }
        }
        if (![dictionary[@"value"][@"owner_editable"][@"subject"] isEqualToString:@""]) {
            localStr = [localStr stringByAppendingString:[NSString stringWithFormat:@"%@\n\n", dictionary[@"value"][@"owner_editable"][@"subject"]]];
        }
    }
    if (![localStr isEqualToString:@""]) {
        
        allCategories = [allCategories stringByAppendingString:[NSString stringWithFormat:@"Task\n%@",localStr]];
        [selectedItems addObject:[NSString stringWithFormat:@"Task\n%@", localStr]];
    } else {
        [selectedItems addObject:[NSString stringWithFormat:@""]];
    }
    task = [NSString stringWithFormat:@"%@Task\n%@", allMembers, localStr];
    
    localArray = summaries[@"data"][@"invite"];
    localStr = @"";
    for (NSDictionary *dictionary in localArray) {
        NSArray *toArray = dictionary[@"value"][@"owner_editable"][@"to"];
        NSString *recipient = @"";
        if ([dictionary[@"value"][@"creator"] isEqualToString:account.email]) {
            for (NSDictionary *toDict in toArray) {
                recipient = [recipient stringByAppendingString:[NSString stringWithFormat:@"%@,", [self getRecipientNameByMailId:toDict[@"user"]]]];
            }
        } else {
            for (NSString *str in toArray) {
                recipient = [recipient stringByAppendingString:[NSString stringWithFormat:@"%@,", [self getRecipientNameByMailId:str]]];
            }
        }
        localStr =  [localStr stringByAppendingString:[NSString stringWithFormat:@"%@ Meeting invite sent to %@", bullet, recipient]];
        BOOL isAllday = [dictionary[@"value"][@"owner_editable"][@"alldayevent"] boolValue];
        if (isAllday) {
            localStr =  [localStr stringByAppendingString:[NSString stringWithFormat:@" on %@ (all-day event)", dictionary[@"value"][@"owner_editable"][@"starttime"]]];
        } else {
            NSString *starttime = [Account convertGmtToLocalTimeZone:dictionary[@"value"][@"owner_editable"][@"starttime"]];
            NSString *endtime = [Account convertGmtToLocalTimeZone:dictionary[@"value"][@"owner_editable"][@"endtime"]];
            localStr =  [localStr stringByAppendingString:[NSString stringWithFormat:@" from %@ to %@", starttime, endtime]];
        }
        if (![dictionary[@"value"][@"owner_editable"][@"location"] isEqualToString:@""]) {
            localStr = [localStr stringByAppendingString:[NSString stringWithFormat:@" in location %@", dictionary[@"value"][@"owner_editable"][@"location"]]];
        }
        bool semiColonPut = false;
        if (![dictionary[@"value"][@"owner_editable"][@"repeat_frequency"] isEqualToString:@"Never >"]) {
            localStr = [localStr stringByAppendingString:[NSString stringWithFormat:@" repeat meeting invite %@;", dictionary[@"value"][@"owner_editable"][@"repeat_frequency"]]];
            semiColonPut = true;
        }
        if (![dictionary[@"value"][@"owner_editable"][@"priority"] isEqualToString:@"None"]) {
            if ([dictionary[@"value"][@"owner_editable"][@"priority"] isEqualToString:@"Med"]) {
                localStr = [localStr stringByAppendingString:@" Medium Priority;"];
                
            } else {
                localStr = [localStr stringByAppendingString:[NSString stringWithFormat:@" %@ Priority;", dictionary[@"value"][@"owner_editable"][@"priority"]]];
            }
            semiColonPut = true;
        }
        if (![dictionary[@"value"][@"owner_editable"][@"subject"] isEqualToString:@""]) {
            if(!semiColonPut) {
                localStr = [localStr stringByAppendingString:[NSString stringWithFormat:@"; %@\n\n", dictionary[@"value"][@"owner_editable"][@"subject"]]];
            } else {
            localStr = [localStr stringByAppendingString:[NSString stringWithFormat:@" %@\n\n", dictionary[@"value"][@"owner_editable"][@"subject"]]];
            }
        }
    }
    if (![localStr isEqualToString:@""]) {
        allCategories = [allCategories stringByAppendingString:[NSString stringWithFormat:@"Meeting Invite\n%@",localStr]];
        [selectedItems addObject:[NSString stringWithFormat:@"Meeting Invite\n%@", localStr]];
    } else {
        [selectedItems addObject:[NSString stringWithFormat:@""]];
    }
    meetingInvite = [NSString stringWithFormat:@"%@Meeting Invite\n%@", allMembers, localStr];
    
    
    for (int i = 0; i < userCategoryArray.count; i++) {
        localStr = @"";
        NSArray *localArray = summaries[@"data"][[NSString stringWithFormat:@"%@",userCategoryArray[i]]];
        
        for (NSDictionary *dictionary in localArray) {
            if([dictionary[@"value"][@"notes"] hasPrefix:@"liri-image:"]) {
                localStr =[localStr stringByAppendingString:[NSString stringWithFormat:@"%@ New Annotated image has been received.\n\n", bullet]];
            } else {
                localStr =  [localStr stringByAppendingString:[NSString stringWithFormat:@"%@ %@\n\n", bullet, dictionary[@"value"][@"notes"]]];
            }
        }
        if (![localStr isEqualToString:@""]) {
            allCategories = [allCategories stringByAppendingString:[NSString stringWithFormat:@"%@\n%@", categoryArray[i+5], localStr]];
            [selectedItems addObject:[NSString stringWithFormat:@"%@\n%@", categoryArray[i+5], localStr]];
        } else {
            [selectedItems addObject:[NSString stringWithFormat:@""]];
        }
    }
    
    [self.summaryTextView setText:allCategories];
    [self setAttributeString];
}

- (void)setAttributeString
{
    NSMutableAttributedString * attrString = [[NSMutableAttributedString alloc] initWithString:self.summaryTextView.text];
    NSRange foundRangeFull = [self.summaryTextView.text rangeOfString:[attrString string]];
    [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithName:FONT_HELVETICA_NEUE size:FONT_SIZE] range:foundRangeFull];

    attributeStrArray = [[NSMutableArray alloc] init];
    NSRange foundRange1 = [self.summaryTextView.text rangeOfString:@"Attendees"];
    [attributeStrArray addObject:@"Attendees"];
    NSRange foundRange2 = [self.summaryTextView.text rangeOfString:@"Summary Point"];
    [attributeStrArray addObject:@"Summary Point"];
    NSRange foundRange3 = [self.summaryTextView.text rangeOfString:@"Reminders"];
    [attributeStrArray addObject:@"Reminders"];
    NSRange foundRange4 = [self.summaryTextView.text rangeOfString:@"Task"];
    [attributeStrArray addObject:@"Task"];
    NSRange foundRange5 = [self.summaryTextView.text rangeOfString:@"Meeting Invite"];
    [attributeStrArray addObject:@"Meeting Invite"];
    
    //    if (foundRange1.location != NSNotFound) {
    [attrString beginEditing];
    
    [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithName:FONT_HELVETICA_NEUE_BOLD size:FONT_SIZE] range:foundRange1];
    [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithName:FONT_HELVETICA_NEUE_BOLD size:FONT_SIZE] range:foundRange2];
    [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithName:FONT_HELVETICA_NEUE_BOLD size:FONT_SIZE] range:foundRange3];
    [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithName:FONT_HELVETICA_NEUE_BOLD size:FONT_SIZE] range:foundRange4];
    [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithName:FONT_HELVETICA_NEUE_BOLD size:FONT_SIZE] range:foundRange5];
    
    for (int i = 0; i < userCategoryArray.count; i++) {
        NSRange foundRange = [self.summaryTextView.text rangeOfString:[NSString stringWithFormat:@"%@", categoryArray[i+5]]];
        [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithName:FONT_HELVETICA_NEUE_BOLD size:FONT_SIZE] range:foundRange];
        [attributeStrArray addObject:[NSString stringWithFormat:@"%@", categoryArray[i+5]]];
    }
    
    [attrString endEditing];
    //    }
    [self.summaryTextView setAttributedText:attrString];
}

-(NSString *)getRecipientNameByMailId:(NSString *)mailId
{
    Account *account = [Account sharedInstance];
    for (Buddy *buddy in account.buddyList.allBuddies) {
        if ([buddy.email isEqualToString:mailId]) {
            return buddy.displayName;
        }
    }
    return mailId;
}
#pragma mark - IBAction Methods
- (IBAction)backBtnAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)pickerBtnAction:(id)sender {
    
    [UIView animateWithDuration:0.5 animations:^(void) {
        self.view.alpha = 0.5;
    }];
    
    if (!isShown) {
        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Discussion" bundle:nil];
        chooseCategoryCtlr = [storyBoard instantiateViewControllerWithIdentifier:@"ChooseCategoryViewController"];
        chooseCategoryCtlr.delegate = self;
        isShown = YES;
    }
    
    chooseCategoryCtlr.view.backgroundColor = [UIColor clearColor];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        self.modalPresentationStyle = UIModalPresentationCurrentContext;
    } else {
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        chooseCategoryCtlr.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    }
    [self presentViewController:chooseCategoryCtlr animated:YES completion:nil];

}

- (IBAction)emailBtnAction:(id)sender {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Discussion" bundle:nil];
    
    EmailComposerViewController *emailComposerController = [storyBoard instantiateViewControllerWithIdentifier:@"EmailComposerViewController"];
    emailComposerController.summaryContent = self.summaryTextView.text;
    emailComposerController.attrArray = attributeStrArray;
    emailComposerController.summaryTitle = self.titleLbl.text;
    [self presentViewController:emailComposerController animated:YES completion:nil];
}

#pragma mark - Choose category Delegate Method
-(void)returnSelectedIndexPaths:(NSArray *)indexArray
{
     if ([indexArray count] > 0) {
        NSString *appendString = allMembers;
        NSString *copyString;
        for (NSIndexPath *indexPath in indexArray)
        {
            if (indexPath.row != 0) {
                appendString = [appendString stringByAppendingString:[NSString stringWithFormat:@"%@",selectedItems[indexPath.row - 1]]];
                copyString = appendString;
            } else {
                copyString = allCategories;
                break;
            }
        }
        [self.summaryTextView setText:copyString];

        if ([indexArray count] == 1) {
            NSIndexPath *index = indexArray[0];
            [self.pickerBtn setTitle:categoryArray[index.row] forState:UIControlStateNormal];
        } else if ([indexArray count] < [selectedItems count]) {
            [_pickerBtn setTitle:@"Multiple Items" forState:UIControlStateNormal];
        } else {
            [_pickerBtn setTitle:@"All Categories" forState:UIControlStateNormal];
        }
    } else {
        [self.summaryTextView setText:allMembers];
        [_pickerBtn setTitle:@"None" forState:UIControlStateNormal];
    }
    
    [self setAttributeString];
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
