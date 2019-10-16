//
//  WebPreviewController.m
//  DoodleTop
//
//  Created by Shankar Arunachalam on 5/2/14.
//  Copyright (c) 2014 Penguin Labs. All rights reserved.
//

#import "WebPreviewController.h"
#import "AppConstants.h"
#import "Flurry.h"

@interface WebPreviewController ()
@property (weak, nonatomic) IBOutlet UIView *captureView;

@end

@implementation WebPreviewController
@synthesize path, source, name, token, sourceLabel, fileLabel, captureButton, capturedImage, webView, appDelegate;
@synthesize captureView = _captureView;

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
    [Flurry logEvent:@"Document View Screen"];
    sourceLabel.text = source;
    if([source isEqualToString:@"Google"]) {
        sourceLabel.text = @"Google Drive";
    }
    fileLabel.text = name;
    [self showDocument];
}

- (void)viewDidLayoutSubviews
{
    if(IS_IPHONE_5) {
        //do stuff for 4 inch iPhone screen
    }
    else {
        //do stuff for 3.5 inch iPhone screen
        double oldWidth = self.webView.frame.size.width;
        double newWidth = self.webView.frame.size.width * 310 / 400;
        [self.webView setFrame:CGRectMake(self.webView.frame.origin.x + (oldWidth - newWidth) / 2, self.webView.frame.origin.y, newWidth, 310)];
        [self.captureView setFrame:CGRectMake(self.captureView.frame.origin.x, 416, self.captureView.frame.size.width, self.captureView.frame.size.height)];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didPressCapture:(id)sender {
    CGSize imageSize = CGSizeMake(self.webView.bounds.size.width, self.webView.bounds.size.height);
    UIGraphicsBeginImageContextWithOptions(imageSize, NO , 0.0f);
    [self.webView.layer renderInContext:UIGraphicsGetCurrentContext()];
    capturedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self dismissViewControllerAnimated:NO completion:^{
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kAnnotationOptionSelectedNotification
         object:self userInfo:@{@"pickedImage": self.capturedImage}];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
}

- (IBAction)backAction:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)webViewDidStartLoad:(UIWebView *)wv
{
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate showActivityIndicator];
}

- (void)webViewDidFinishLoad:(UIWebView *)wv
{
    [appDelegate hideActivityIndicator];
//    NSString *html = [wv stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"];
}

- (void)showDocument
{
     webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
     webView.scalesPageToFit = YES;
     NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[self URLEncodeString:path]]];
     [webView loadRequest:request];
}

-(NSString *) URLEncodeString:(NSString *) str
{
    NSMutableString *tempStr = [NSMutableString stringWithString:str];
    return [[NSString stringWithFormat:@"%@",tempStr] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL)webView:(UIWebView *)wv shouldStartLoadWithRequest:(NSMutableURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    BOOL shouldNavigate = NO;
    NSString *existingAuthValue = [request valueForHTTPHeaderField:@"Authorization"];
    if (existingAuthValue == nil)
    {
        NSString *authValue = [NSString stringWithFormat:@"Bearer %@", token];
        [request setValue:authValue forHTTPHeaderField:@"Authorization"];
        [wv loadRequest:request];
    }
    else
    {
        shouldNavigate = YES;
    }
    return shouldNavigate;
}
@end
