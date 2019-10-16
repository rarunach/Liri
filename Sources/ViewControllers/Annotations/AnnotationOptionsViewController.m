//
//  AnnotationOptionsViewController.m
//  Liri
//
//  Created by Shankar Arunachalam on 7/4/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "AnnotationOptionsViewController.h"
#import "Account.h"
#import "FolderBrowserController.h"
#import "FileFolderMetadata.h"
#import "Flurry.h"

@interface AnnotationOptionsViewController ()
@property (weak, nonatomic) IBOutlet UIView *annotationOptionView;
@property (weak, nonatomic) IBOutlet UIView *containerView;

@end

@implementation AnnotationOptionsViewController
@synthesize searchBar;
@synthesize annotationOptionView = _annotationOptionView;
@synthesize containerView = _containerView;

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
    [Flurry logEvent:@"Launch Annotation Options Screen"];
}

- (void)viewDidLayoutSubviews
{
    if(IS_IPHONE_5) {
        //do stuff for 4 inch iPhone screen
    }
    else {
        [self.annotationOptionView setFrame:CGRectMake(self.annotationOptionView.frame.origin.x, self.annotationOptionView.frame.origin.y, self.annotationOptionView.frame.size.width, 440)];
        [self.containerView setFrame:CGRectMake(self.containerView.frame.origin.x, self.containerView.frame.origin.y, self.containerView.frame.size.width, 357)];

    }
}
- (void) doCloudSearch:(NSString *)query {
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                                 sharedInstanceWithClientProtocol:
                                 @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                         id responseJSON){
        [delegate hideActivityIndicator];
        
        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
        FolderBrowserController *browserController =
        [storyBoard instantiateViewControllerWithIdentifier:@"FolderBrowserController"];
        browserController.view.backgroundColor = [UIColor clearColor];
        browserController.navTitle.text = @"Search results";
        browserController.externalSystem = @"Search results";
        browserController.searchString  = searchBar.text;
        searchBar.text = @"";
        browserController.data = [FileFolderMetadata getFileFolderMetadata:responseJSON forCloudSearch:true];
        
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
            
            self.modalPresentationStyle = UIModalPresentationCurrentContext;
            
        } else {
            
            self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            
            browserController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            
        }
        [self presentViewController:browserController animated:YES completion:nil];
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
    [endpoint cloudSearch:query];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)thisSearchBar {
    NSLog(@"User searched for %@", thisSearchBar.text);
    [thisSearchBar resignFirstResponder];
    [self doCloudSearch:thisSearchBar.text];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)thisSearchBar {
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) thisSearchBar {
    NSLog(@"User canceled search");
    [thisSearchBar resignFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backAction:(id)sender {
    [self dismissSelf];
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

@end
