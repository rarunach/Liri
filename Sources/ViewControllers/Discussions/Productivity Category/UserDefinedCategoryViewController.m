//
//  UserDefinedCategoryViewController.m
//  Liri
//
//  Created by Varun Sankar on 03/07/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "UserDefinedCategoryViewController.h"
#import "AppDelegate.h"
#import "Account.h"
#import "XMPPManager.h"
#import "Flurry.h"

@interface UserDefinedCategoryViewController ()

- (IBAction)backAction:(id)sender;
- (IBAction)clearDescription:(id)sender;
- (IBAction)addCategoryAction:(id)sender;

@property (weak, nonatomic) IBOutlet UIView *userCategoryView;
@property (weak, nonatomic) IBOutlet UIButton *clearDescriptionButton;
@property (weak, nonatomic) IBOutlet UIButton *addCategoryButton;
@property (weak, nonatomic) IBOutlet UIImageView *annotationImgView;
@property (weak, nonatomic) IBOutlet UIView *udcView;


@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *userCategoryTitle;
@property (weak, nonatomic) IBOutlet UITextView *userCategoryDescription;
@end

@implementation UserDefinedCategoryViewController

@synthesize backButton = _backButton, clearDescriptionButton = _clearDescriptionButton, addCategoryButton = _addCategoryButton;
@synthesize userCategoryTitle = _userCategoryTitle;
@synthesize userCategoryDescription = _userCategoryDescription;
@synthesize userCategoryView = _userCategoryView, udcView = _udcView;
@synthesize userNotesTitle = _userNotesTitle, chatMessage = _chatMessage, discussionId = _discussionId, messageId = _messageId;
@synthesize categoryType = _categoryType;
@synthesize delegate = _delegate;
@synthesize isEditMode = _isEditMode;
@synthesize userDefinedCategory = _userDefinedCategory;
@synthesize annotationImg = _annotationImg;
@synthesize annotationImgView = _annotationImgView;
@synthesize chatName = _chatName;
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
    
    [Flurry logEvent:@"User-defined Category Screen"];
    [self.userCategoryView.layer setBorderWidth:1.0f];
    [self.userCategoryView.layer setBorderColor:[[UIColor grayColor] CGColor]];
    
    [self.clearDescriptionButton.layer setCornerRadius:self.clearDescriptionButton.frame.size.width/2];
    
    self.chatMessage = [NSString stringWithFormat:@"[%@] %@", self.chatName, self.chatMessage];
    
    if (self.isEditMode) {
        [self.userCategoryDescription setText:self.userDefinedCategory.text];
    } else {
        if (nil != self.annotationImg) {
            self.chatMessage = [NSString stringWithFormat:@"%@ posted an annotated picture.", self.chatName];
        } else if ([self.chatMessage length] > KMaxSummaryPointDescriptionLength){
            self.chatMessage = [self.chatMessage substringToIndex:[self.chatMessage length] - KMaxSummaryPointDescriptionLength];
        }
        [self.userCategoryDescription setText:self.chatMessage];
    }
    [self.userCategoryTitle setText:self.userNotesTitle];
/*
    if (nil != self.annotationImg) {
        
        [self.annotationImgView setHidden:NO];
        
        [self.annotationImgView setImage:self.annotationImg];
        
        [self.userCategoryDescription setText:self.chatMessage];
        
        [self.userCategoryDescription setHidden:YES];
        
        [self.clearDescriptionButton setHidden:YES];
    }
*/
}

- (void)viewDidLayoutSubviews
{
    if (IS_IPHONE_5) {
        
    } else {
        [self.udcView setFrame:CGRectMake(self.udcView.frame.origin.x, 40, self.udcView.frame.size.width, self.udcView.frame.size.height)];
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

#pragma mark - UIButton Action Methods
- (IBAction)backAction:(id)sender {
//    [self dismissViewControllerAnimated:YES completion:nil];
    [self dismissSelf];
}

- (IBAction)clearDescription:(id)sender {
    [self.userCategoryDescription setText:@""];
}

- (IBAction)addCategoryAction:(id)sender {
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
        
        
        
//        NSString *message = [responseJSON valueForKey:@"message"];
        if ([self.delegate respondsToSelector:@selector(userCategoryInstanceCreatedWithCategoryType:categoryId:categoryText:andEditMode:)]) {
            [self.delegate userCategoryInstanceCreatedWithCategoryType:self.categoryType categoryId:self.categoryType categoryText:self.userCategoryDescription.text andEditMode:self.isEditMode];
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
    
//    [discussionsEndpoint createUserDefinedCategoryInstanceWithDiscussionId:self.discussionId MessageId:self.messageId CategoryType:self.categoryType andNotes:self.userCategoryDescription.text];
    [discussionsEndpoint createUserDefinedCategoryInstanceWithDiscussionId:self.discussionId MessageId:self.messageId CategoryType:self.categoryType MsgTimeStamp:self.messageTimeStamp andNotes:self.userCategoryDescription.text];

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
}
@end
