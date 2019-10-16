//
//  BrowserController.m
//  Liri
//
//  Created by Shankar Arunachalam on 8/8/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "BrowserController.h"
#import "AddToFavoritesViewController.h"
#import "Flurry.h"

@interface BrowserController ()

@property (weak, nonatomic) IBOutlet UIView *captureView;
@end

@implementation BrowserController

@synthesize path, captureButton, favoritesButton, capturedImage, webView, appDelegate, addressField, isFromFavorites;
@synthesize captureView = _captureView;

static const CGFloat kLeftMargin = 10.0f;
static const CGFloat kTopMargin = 57.0f;
static const CGFloat kAddressHeight = 32.0f;

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
    [Flurry logEvent:@"Website Browser Screen"];
    
    CGRect addressFrame = CGRectMake(kLeftMargin, kTopMargin,
                                     300, kAddressHeight);
    UITextField *address = [[UITextField alloc] initWithFrame:addressFrame];
    address.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    address.borderStyle = UITextBorderStyleRoundedRect;
    address.font = [UIFont systemFontOfSize:15];
    address.keyboardType = UIKeyboardTypeURL;
    address.autocapitalizationType = UITextAutocapitalizationTypeNone;
    address.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.view addSubview:address];
    self.addressField = address;
    address.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lightBoxFinished:) name:kLightBoxFinishedNotification object:nil];

    //webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    //webView.scalesPageToFit = YES;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:path]];
    addressField.text = path;
    [webView loadRequest:request];
}

- (void)viewDidLayoutSubviews
{
    if(IS_IPHONE_5) {
        //do stuff for 4 inch iPhone screen
    }
    else {
        //do stuff for 3.5 inch iPhone screen
        [self.webView setFrame:CGRectMake(self.webView.frame.origin.x, self.webView.frame.origin.y, self.webView.frame.size.width, 310)];
        [self.captureView setFrame:CGRectMake(self.captureView.frame.origin.x, 416, self.captureView.frame.size.width, self.captureView.frame.size.height)];
    }
}

- (void) lightBoxFinished:(NSNotification*)aNotification {
    
    NSDictionary *info = [aNotification userInfo];
    
    if ([info[@"className"] isEqualToString:@"AddToFavoritesViewController"]) {
        [UIView animateWithDuration:0.3 animations:^(void) {
            self.view.alpha = 1.0;
        }];
    }
    
}

-(void)viewDidAppear:(BOOL)animated {
    [UIView animateWithDuration:0.3 animations:^(void) {
        self.view.alpha = 1.0;
    }];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    webView.delegate = self;
    
    if ([addressField.text hasPrefix:@"http://"] || [addressField.text hasPrefix:@"https://"]) {
        
        [webView loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString:addressField.text]]];
        [addressField resignFirstResponder];
        return NO;
        
    } else if ([self isProbablyURL:addressField.text]) {
        
        NSString *query = [addressField.text stringByReplacingOccurrencesOfString:@" " withString:@"+"];
        NSURL *urlQuery = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", query]];
        NSURLRequest *request = [NSURLRequest requestWithURL:urlQuery];
        [webView loadRequest:request];
        [addressField resignFirstResponder];
        return NO;
        
    } else {
        
        ([self performGoogleSearchWithText:addressField.text]);
        [addressField resignFirstResponder];
        return YES;
        
    }
}

- (void)performGoogleSearchWithText:(NSString *)text {
    NSString *query = [text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *urlQuery = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.google.com/search?hl=en&site=&source=hp&q=%@", query]];
    NSURLRequest *request = [NSURLRequest requestWithURL:urlQuery];
    [webView loadRequest:request];
}

- (BOOL)isProbablyURL:(NSString *)text {
    
    // do something smart and return YES or NO
    NSString *urlRegEx =
    @"((\\w)*|(m.)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|(m.)*|([0-9]*)|([-|_])*))+";
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    return [urlTest evaluateWithObject:addressField.text];
    //return NO;
    
}

- (IBAction)didPressAddToFavorites:(id)sender {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    AddToFavoritesViewController *addToFavoritesController = [storyBoard instantiateViewControllerWithIdentifier:@"AddToFavoritesViewController"];
    if ([addressField.text hasPrefix:@"http://"] || [addressField.text hasPrefix:@"https://"]) {
        addToFavoritesController.urlText = addressField.text;
    } else if ([self isProbablyURL:addressField.text]) {
        addToFavoritesController.urlText = [NSString stringWithFormat:@"http://%@", addressField.text];
    } else {
        return;
    }
    if(isFromFavorites) {
        UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
        rootViewController.modalPresentationStyle = UIModalPresentationNone;
    } else {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
            self.modalPresentationStyle = UIModalPresentationCurrentContext;
            self.navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;
        } else {
            self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            self.navigationController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            addToFavoritesController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        }
    }
    
    [UIView animateWithDuration:0.5 animations:^(void) {
        self.view.alpha = 0.5;
    }];

    addToFavoritesController.view.backgroundColor = [UIColor clearColor];
    [self presentViewController:addToFavoritesController animated:YES completion:nil];
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

- (IBAction)backAction:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:^{
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kBrowsingCompletedNotification
         object:self userInfo:nil];
    }];
}

- (void)webViewDidStartLoad:(UIWebView *)wv
{
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate showActivityIndicator];
}

- (void)webViewDidFinishLoad:(UIWebView *)wv
{
    [appDelegate hideActivityIndicator];
    addressField.text = wv.request.mainDocumentURL.absoluteString;
//    CGSize contentSize = wv.scrollView.contentSize;
//    CGSize viewSize = self.webView.bounds.size;
//    
//    float rw = viewSize.width / contentSize.width;
//    
//    wv.scrollView.minimumZoomScale = rw;
//    wv.scrollView.maximumZoomScale = rw;
//    wv.scrollView.zoomScale = rw;
    //    NSString *html = [wv stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"];
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
