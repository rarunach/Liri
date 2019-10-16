//
//  AppTourViewController.m
//  Liri
//
//  Created by Varun Sankar on 19/09/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "AppTourViewController.h"
#import "SignupViewController.h"

@interface AppTourViewController ()
{
    NSArray *tourImages;
    UIPageControl *pageControl;
}
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation AppTourViewController

@synthesize scrollView = _scrollView;


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
    
    CGRect pageCtrlFrame, letsGetStartFrame;
    if(IS_IPHONE_5) {
        //do stuff for 4 inch iPhone screen
        pageCtrlFrame = CGRectMake(110, 530, 100, 37);
        letsGetStartFrame = CGRectMake(55, 465, 210, 70);
        tourImages = [[NSArray alloc] initWithObjects:@"01.-Secure-Messaging.png", @"02.-Unified-Contacts.png", @"03.-Cloud-File-Search.png", @"04.-Annotations.png", @"05.-Productivity-Management.png", @"06.-Discussion-Summary.png", nil];
    }
    else {
        //do stuff for 3.5 inch iPhone screen
        pageCtrlFrame = CGRectMake(110, 442, 100, 37);
        letsGetStartFrame = CGRectMake(55, 388, 210, 70);
        [self.scrollView setFrame:CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y, self.scrollView.frame.size.width, 480)];
        tourImages = [[NSArray alloc] initWithObjects:@"01.-Secure-Messaging-iPhone4.png", @"02.-Unified-Contacts-iPhone4.png", @"03.-Cloud-File-Search-iPhone4.png", @"04.-Annotations-iPhone4.png", @"05.-Productivity-Management-iPhone-4.png", @"06.-Discussion-Summary-iPhone-4.png", nil];

    }
    [self.navigationController.navigationBar setHidden:YES];
    
    pageControl = [[UIPageControl alloc] initWithFrame:pageCtrlFrame];
    
    [pageControl setNumberOfPages:6];
    
    [pageControl setUserInteractionEnabled:NO];
    
    [pageControl setCurrentPage:0];
    
    [pageControl setCurrentPageIndicatorTintColor:[UIColor whiteColor]];
    
    [pageControl setPageIndicatorTintColor:[UIColor darkGrayColor]];
    
    [self.view addSubview: pageControl];
    
    
    for (int i = 0; i < tourImages.count; i++) {

        CGFloat xOrigin = i * self.scrollView.frame.size.width;
        
        UIImageView *imgView = [[UIImageView alloc]initWithFrame:CGRectMake(xOrigin, self.scrollView.frame.origin.y, self.scrollView.frame.size.width, self.scrollView.frame.size.height)];
        
        [imgView setImage:[UIImage imageNamed:tourImages[i]]];
        
        [self.scrollView addSubview:imgView];
        
        if (tourImages.count == i + 1) {
            
            [imgView setUserInteractionEnabled:YES];
            
            UIButton *letsGetStarted = [UIButton buttonWithType:UIButtonTypeSystem];
            
            [letsGetStarted setFrame:letsGetStartFrame];
            
            [letsGetStarted setBackgroundImage:[UIImage imageNamed:@"App-Tour-Button.png"] forState:UIControlStateNormal];
            
            [letsGetStarted addTarget:self action:@selector(letsGetStarted:) forControlEvents:UIControlEventTouchUpInside];
            
            [imgView addSubview:letsGetStarted];
        }
        
    }
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width * tourImages.count, self.scrollView.frame.size.height)];
}

#pragma mark - UIScrollView Delegate Method
-(void) scrollViewDidEndDecelerating:(UIScrollView *)scrollViews  {
    NSInteger pageNumber = roundf(self.scrollView.contentOffset.x / (self.scrollView.frame.size.width));
    pageControl.currentPage = pageNumber;
}

#pragma mark - UIButton Action Methods
- (void)letsGetStarted:(id)sender
{
    SignupViewController *signupViewCtlr = [self.storyboard instantiateViewControllerWithIdentifier:@"SignupViewController"];
    [self.navigationController pushViewController:signupViewCtlr animated:YES];
}


#pragma mark - Hide Status Bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
