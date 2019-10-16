//
//  AddToFavoritesViewController.m
//  Liri
//
//  Created by Shankar Arunachalam on 9/3/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "AddToFavoritesViewController.h"
#import "AppDelegate.h"
#import "APIClient.h"
#import "Flurry.h"

@interface AddToFavoritesViewController ()

@property (weak, nonatomic) IBOutlet UIView *favoritesView;
@end

@implementation AddToFavoritesViewController
@synthesize cancelButton, saveButton, name, urlText;
@synthesize favoritesView = _favoritesView;

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
    [Flurry logEvent:@"Add to Favorites Screen"];
}

- (void)viewDidLayoutSubviews
{
    if(IS_IPHONE_5) {
        //do stuff for 4 inch iPhone screen
    }
    else {
        [self.favoritesView setFrame:CGRectMake(self.favoritesView.frame.origin.x, 100, self.favoritesView.frame.size.width, self.favoritesView.frame.size.height)];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [UIView animateWithDuration:0.3 animations:^(void) {
        self.view.alpha = 1.0;
    }];
}

- (IBAction)didPressCancel:(id)sender {
    [self dismissSelf];
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

- (IBAction)didPressSave:(id)sender {
    if([name.text isEqualToString:@""]) {
        UIAlertView *failureAlert = [[UIAlertView alloc]
                                     initWithTitle:@""
                                     message:@"Please enter a name for your favorite link."
                                     delegate:self cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil];
        [failureAlert setTag:KFailureAlertTag];
        [failureAlert show];
    } else {
        AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [delegate showActivityIndicator];
        
        id<APIAccessClient> endpoint =
        (id<APIAccessClient>)[[APIManager
                               sharedInstanceWithClientProtocol:
                               @protocol(APIAccessClient)] client];
        
        endpoint.successJSON = ^(NSURLRequest *request,
                                 id responseJSON){
            [delegate hideActivityIndicator];
            [self dismissSelf];
        };
        endpoint.failureJSON = ^(NSURLRequest *request,
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
        [endpoint createBookmark:urlText withName:name.text];
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

@end
