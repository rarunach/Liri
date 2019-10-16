//
//  WebViewController.m
//  Liri
//
//  Created by Varun Sankar on 07/10/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "WebViewController.h"
#import "AppDelegate.h"

@interface WebViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation WebViewController

@synthesize fullURL = _fullURL;
@synthesize pageTitle = _pageTitle;
@synthesize webView = _webView;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = self.pageTitle;
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : DEFAULT_UICOLOR}];
    
    self.navigationItem.hidesBackButton = NO;
    
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    
    NSURL *url = [NSURL URLWithString:self.fullURL];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    self.webView.opaque = NO;
    [self.webView loadRequest:requestObj];
}
- (void)viewDidLayoutSubviews
{
    if(IS_IPHONE_5) {
        //do stuff for 4 inch iPhone screen
    }
    else {
        //do stuff for 3.5 inch iPhone screen
        
        [self.webView setFrame:CGRectMake(self.webView.frame.origin.x, self.webView.frame.origin.y, self.webView.frame.size.width, 480)];
    }
}
- (void)webViewDidStartLoad:(UIWebView *)wv
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate showActivityIndicator];
}

- (void)webViewDidFinishLoad:(UIWebView *)wv
{
    
    if ([wv.request.mainDocumentURL.path isEqualToString:@"/privacypolicy.html"]) {
        self.title = @"Privacy Policy";
    } else if ([wv.request.mainDocumentURL.path isEqualToString:@"/termsandconditions.html"]) {
        self.title = @"Terms and Conditions";
    } else if ([wv.request.mainDocumentURL.path isEqualToString:@"/frequently-asked-questions.html"]) {
        self.title = @"Help";
    } else {
        self.title = @"";
    }
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate hideActivityIndicator];
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate hideActivityIndicator];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
