//
//  CreateGroupViewController.m
//  Liri
//
//  Created by Ramani Arunachalam on 8/18/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "CreateGroupViewController.h"
#import "Flurry.h"

@interface CreateGroupViewController ()
@property (weak, nonatomic) IBOutlet UITextField *groupNameField;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, retain) Group *group;

@end

@implementation CreateGroupViewController
@synthesize groupNameField, group, navigationBar;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : DEFAULT_UICOLOR}];

    [Flurry logEvent:@"Create Group Screen"];
    groupNameField.layer.borderColor=DEFAULT_CGCOLOR;
    groupNameField.layer.borderWidth= 2.0f;
    
    // Do any additional setup after loading the view.
    [self.groupNameField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initWithGroup:(Group *)thegroup
{
    group = thegroup;
}

- (IBAction)createAction:(id)sender {
    
    if ([groupNameField.text isEqualToString:@""]) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Enter a name for the group"
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }
    // Call API
    group.name = groupNameField.text;
    [self dismissViewControllerAnimated:NO completion:^{
        
        [[NSNotificationCenter defaultCenter]
         
         postNotificationName:kBackFromCreateGroupNotification
         
         object:self userInfo:@{@"group" : @"create"}];
        
    }];
}

- (IBAction)cancelAction:(id)sender {
    [self dismissViewControllerAnimated:NO completion:^{
        
        [[NSNotificationCenter defaultCenter]
         
         postNotificationName:kBackFromCreateGroupNotification
         
         object:self userInfo:@{@"group" : @"cancel"}];
        
    }];
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
