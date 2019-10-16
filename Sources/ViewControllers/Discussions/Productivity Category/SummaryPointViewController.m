//
//  SummayPointViewController.m
//  Liri
//
//  Created by Varun Sankar on 03/07/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "SummaryPointViewController.h"
#import "AppConstants.h"
#import "Account.h"
#import "XMPPManager.h"
#import "AppDelegate.h"
#import "Flurry.h"

@interface SummaryPointViewController ()

- (IBAction)backAction:(id)sender;
- (IBAction)doneAction:(id)sender;
- (IBAction)clearSpDescriptionAction:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *summaryPointLabel;
@property (weak, nonatomic) IBOutlet UIView *spNotesView;

@property (weak, nonatomic) IBOutlet UITextView *spDescriptionTextView;
@property (weak, nonatomic) IBOutlet UIButton *clearSpDescriptionBtn;
@property (weak, nonatomic) IBOutlet UIImageView *annotationImgView;
@property (weak, nonatomic) IBOutlet UIView *summaryPointView;

@end

@implementation SummaryPointViewController

@synthesize backButton = _backButton, clearSpDescriptionBtn = _clearSpDescriptionBtn;
@synthesize summaryPointLabel = _summaryPointLabel;
@synthesize spDescriptionTextView = _spDescriptionTextView;
@synthesize spNotesView = _spNotesView, summaryPointView = _summaryPointView;
@synthesize chatName = _chatName, chatMessage = _chatMessage, discussionId = _discussionId, messageId = _messageId;
@synthesize delegate = _delegate;
@synthesize isEditMode = _isEditMode;
@synthesize summaryPoint = _summaryPoint;
@synthesize annotationImg = _annotationImg;
@synthesize annotationImgView = _annotationImgView;
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
    [Flurry logEvent:@"Summary Point Screen"];
    
    [self.spNotesView.layer setBorderWidth:1.0f];
    [self.spNotesView.layer setBorderColor:[[UIColor grayColor] CGColor]];
    
    [self.clearSpDescriptionBtn.layer setCornerRadius:self.clearSpDescriptionBtn.frame.size.width/2];
    
    
    NSString *summaryNotes = [NSString stringWithFormat:@"[%@] %@", self.chatName, self.chatMessage];
    
    if (self.isEditMode) {
        summaryNotes = self.summaryPoint.text;
    } else {
        if (nil != self.annotationImg) {
            summaryNotes = [NSString stringWithFormat:@"%@ posted an annotated picture.", self.chatName];
        } else if (summaryNotes.length > KMaxSummaryPointDescriptionLength){
            summaryNotes = [summaryNotes substringToIndex:[summaryNotes length] - KMaxSummaryPointDescriptionLength];
        }
    }
    [self.spDescriptionTextView setText:summaryNotes];
/*
    if (nil != self.annotationImg) {
        
        [self.annotationImgView setHidden:NO];
        
        [self.annotationImgView setImage:self.annotationImg];
        
        [self.spDescriptionTextView setText:self.chatMessage];
        
        [self.spDescriptionTextView setHidden:YES];
        
        [self.clearSpDescriptionBtn setHidden:YES];
    }
*/
//    [self getSummaryPoint];
    
}

- (void)viewDidLayoutSubviews
{
    if (IS_IPHONE_5) {
        
    } else {
        [self.summaryPointView setFrame:CGRectMake(self.summaryPointView.frame.origin.x, 40, self.summaryPointView.frame.size.width, self.summaryPointView.frame.size.height)];
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

#pragma mark - Private Methods
- (void)getSummaryPoint
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    // do get Summary point
    id<APIAccessClient> discussionsEndpoint =
    (id<APIAccessClient>)[[APIManager
                                 sharedInstanceWithClientProtocol:
                                 @protocol(APIAccessClient)] client];
    
    discussionsEndpoint.successJSON = ^(NSURLRequest *request,
                                        id responseJSON){
        [delegate hideActivityIndicator];
        NSString *message = [responseJSON valueForKey:@"message"];
        if ([message isEqualToString:@"category get successfully"]) {
            [self.spDescriptionTextView setText:[responseJSON objectForKey:@"category"]];
        }
    };
    discussionsEndpoint.failureJSON = ^(NSURLRequest *request,
                                        id responseJSON){
        [delegate hideActivityIndicator];

        
        NSLog(@"error message %@", responseJSON);
    };
    
    [discussionsEndpoint getSummaryPointWithDiscussionId:@"discId" MessageId:@"msgId" CategoryType:01];
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
- (IBAction)backAction:(id)sender {
//    [self dismissViewControllerAnimated:YES completion:nil];
    [self dismissSelf];
}

- (IBAction)doneAction:(id)sender {
    
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
        
        if ([self.delegate respondsToSelector:@selector(summaryPointCreatedWithCategoryType:categoryId:categoryText:andEditMode:)]) {
            [self.delegate summaryPointCreatedWithCategoryType:1 categoryId:1 categoryText:self.spDescriptionTextView.text andEditMode:self.isEditMode];
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
    
//    [discussionsEndpoint createSummaryWithDiscussionId:self.discussionId MessageId:self.messageId CategoryType:1 andNotes:self.spDescriptionTextView.text];
    [discussionsEndpoint createSummaryWithDiscussionId:self.discussionId MessageId:self.messageId CategoryType:1 MsgTimeStamp:self.messageTimeStamp andNotes:self.spDescriptionTextView.text];
    
}

- (IBAction)clearSpDescriptionAction:(id)sender {
    [self.spDescriptionTextView setText:@""];
}

#pragma mark - UITextView Delegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSUInteger newLength = [textView.text length] + [text length] - range.length;
    return (newLength > KMaxSummaryPointDescriptionLength) ? NO : YES;
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
