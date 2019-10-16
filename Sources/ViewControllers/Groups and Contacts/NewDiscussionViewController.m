//
//  NewDiscussionViewController.m
//  Liri
//
//  Created by Ramani Arunachalam on 7/12/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "NewDiscussionViewController.h"
#import "AppConstants.h"
#import "Flurry.h"

@interface NewDiscussionViewController ()
@property (weak, nonatomic) IBOutlet UITextField *titleField;
@property (weak, nonatomic) IBOutlet UITextField *groupField;
@property (weak, nonatomic) IBOutlet UITextView *welcomeField;
@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;
@property (weak, nonatomic) IBOutlet UIButton *startDiscussionBtn;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, retain) BuddyList *buddyList;
@property (nonatomic, retain) NSMutableArray *groups;

@end

@implementation NewDiscussionViewController

@synthesize titleField, groupField, welcomeField, cancelBtn, startDiscussionBtn, navigationBar;

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        self.groups = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [Flurry logEvent:@"New Discussion Screen"];
    self.navigationItem.title = @"New Discussion";
    
    [self.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : DEFAULT_UICOLOR}];
    
    titleField.layer.cornerRadius=8.0f;
    titleField.layer.masksToBounds=YES;
    titleField.layer.borderColor=DEFAULT_CGCOLOR;
    titleField.layer.borderWidth= 2.0f;
    
    groupField.layer.cornerRadius=8.0f;
    groupField.layer.masksToBounds=YES;
    groupField.layer.borderColor=DEFAULT_CGCOLOR;
    groupField.layer.borderWidth= 2.0f;
    
    welcomeField.layer.cornerRadius=8.0f;
    welcomeField.layer.masksToBounds=YES;
    welcomeField.layer.borderColor=DEFAULT_CGCOLOR;
    welcomeField.layer.borderWidth= 2.0f;
    
    [titleField becomeFirstResponder];
}

- (void)initWithBuddyList:(BuddyList *)list
{
    self.buddyList = list;
}

- (void)initWithGroups:(NSMutableArray *)groupsArr
{
    self.groups = groupsArr;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelAction:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)startDiscussionAction:(id)sender {

    if ([titleField.text isEqualToString:@""]) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Please provide a title for the discussion."
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    NSLog(@"groups count: %ld, groups: %@", [self.groups count], self.groups);
    
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:titleField.text, @"title", welcomeField.text, @"welcomeMessage", nil];
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kStartNewDiscussionNotification
     object:self userInfo:dict];
    
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[self view] endEditing:YES];
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
