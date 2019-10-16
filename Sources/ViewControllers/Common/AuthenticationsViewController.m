//
//  AuthenticationsViewController.m
//  Liri
//
//  Created by Shankar Arunachalam on 7/29/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "AuthenticationsViewController.h"
#import "Account.h"
#import "Flurry.h"

@interface AuthenticationsViewController ()

@end

@implementation AuthenticationsViewController
@synthesize webView, externalSystem, contentToLoad, appDelegate, backButton;

@synthesize isFromSetting = _isFromSetting;
@synthesize isFromContacts = _isFromContacts;

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
    [Flurry logEvent:@"Authentication Screen for External Sources"];
    Account *account = [Account sharedInstance];
    
    NSURL* baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"client_auth.html?email=%@&password=%@&system=%@&protocol=%@&hostname=%@&port=%@", account.email, account.password, externalSystem, @"https:", BACKEND_HOST_NAME, BACKEND_BASE_PORT]];
    NSLog([baseURL absoluteString]);
    [webView loadHTMLString:self.contentToLoad baseURL:baseURL];
    webView.autoresizingMask=(UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
}

- (void) viewDidLayoutSubviews {
//    if(self.isFromContacts) {
//        CGRect webViewFrame = self.webView.frame;
//        webViewFrame.origin.y = 0;
//        webViewFrame.size.height = webViewFrame.size.height + 64;
//        self.webView.frame = webViewFrame;
//        
//    }
    if(IS_IPHONE_5) {
        //do stuff for 4 inch iPhone screen
    }
    else {
        //do stuff for 3.5 inch iPhone screen
        [self.webView setFrame:CGRectMake(self.webView.frame.origin.x, self.webView.frame.origin.y, self.webView.frame.size.width, 416)];
    }
}

- (void)webViewDidStartLoad:(UIWebView *)wv
{
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate showActivityIndicator];
}

- (void)webViewDidFinishLoad:(UIWebView *)wv
{
    if([externalSystem isEqualToString:@"Zoho"]) {
        NSString *html = [wv stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"];
        if([wv.request.mainDocumentURL.host isEqualToString:@"accounts.zoho.com"] &&
           [html hasPrefix:@"<pre"]) {
            [self saveZohoAuth:html];
        }
    }
    [appDelegate hideActivityIndicator];
    if([wv.request.mainDocumentURL.path isEqualToString:@"/auth_success"]) {
	    if(self.isFromSetting) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kAuthenticationCompletedNotificationFromSetting
             object:self userInfo:@{@"externalSystem": self.externalSystem}];
        }else if([externalSystem isEqualToString:@"Asana"] ||
           [externalSystem isEqualToString:@"SalesforceTasks"] ||
           [externalSystem isEqualToString:@"Trello"]) {
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:kTaskAuthenticationCompletedNotification
                 object:self userInfo:@{@"externalSystem": self.externalSystem}];
        } else {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kAuthenticationCompletedNotification
             object:self userInfo:@{@"externalSystem": self.externalSystem}];
        }
    } else if([wv.request.mainDocumentURL.path isEqualToString:@"/auth_error"]) {
	    if(self.isFromSetting) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kAuthenticationFailedNotificationFromSetting
             object:self userInfo:@{@"externalSystem": self.externalSystem}];
        } else if([externalSystem isEqualToString:@"Asana"] ||
           [externalSystem isEqualToString:@"SalesforceTasks"] ||
           [externalSystem isEqualToString:@"Trello"]) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kTaskAuthenticationFailedNotification
             object:self userInfo:@{@"externalSystem": self.externalSystem}];
        } else {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kAuthenticationFailedNotification
             object:self userInfo:@{@"externalSystem": self.externalSystem}];
        }
    }
}

- (void) saveZohoAuth: (NSString *)data {
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
        if(self.isFromSetting) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kAuthenticationCompletedNotificationFromSetting
             object:self userInfo:@{@"externalSystem": self.externalSystem}];
        }else {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kAuthenticationCompletedNotification
             object:self userInfo:@{@"externalSystem": self.externalSystem}];
        }
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
        if(self.isFromSetting) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kAuthenticationFailedNotificationFromSetting
             object:self userInfo:@{@"externalSystem": self.externalSystem}];
        }else {
            NSLog(@"error message %@ and json %@", [responseJSON objectForKey:@"error"], responseJSON);
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kAuthenticationFailedNotification
             object:self userInfo:@{@"externalSystem": self.externalSystem}];
        }
    };
    [endpoint saveZohoAuth:data];
}

- (BOOL)webView:(UIWebView*)wv shouldStartLoadWithRequest:(NSURLRequest*)request
 navigationType:(UIWebViewNavigationType)navigationType {
    if(request.mainDocumentURL.absoluteString != nil &&
       [request.mainDocumentURL.absoluteString rangeOfString:@"crmapi"].location != NSNotFound &&
       wv.request.mainDocumentURL.absoluteString != nil &&
       [wv.request.mainDocumentURL.absoluteString rangeOfString:@"accounts.zoho.com/login"].location != NSNotFound) {
        NSOperationQueue *mainQueue = [[NSOperationQueue alloc] init];
        [mainQueue setMaxConcurrentOperationCount:5];
        
        [NSURLConnection sendAsynchronousRequest:request queue:mainQueue completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
            NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
            if (!error) {
                NSLog(@"Status Code: %li %@", (long)urlResponse.statusCode, [NSHTTPURLResponse localizedStringForStatusCode:urlResponse.statusCode]);
                NSString *responseBody = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                NSLog(@"Response Body: %@", responseBody);
                [self saveZohoAuth:responseBody];
            }
            else {
                NSLog(@"An error occured, Status Code: %li", (long)urlResponse.statusCode);
                NSLog(@"Description: %@", [error localizedDescription]);
                NSLog(@"Response Body: %@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
            }
        }];
        return NO;
    } else {
        return YES;
    }
}

- (void)webView:(UIWebView *)wv didFailLoadWithError:(NSError *)error {
    [appDelegate hideActivityIndicator];
    if([wv.request.mainDocumentURL.path isEqualToString:@"/auth_success"]) {
	    if(self.isFromSetting) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kAuthenticationCompletedNotificationFromSetting
             object:self userInfo:@{@"externalSystem": self.externalSystem}];
        }else if([externalSystem isEqualToString:@"Asana"] ||
                 [externalSystem isEqualToString:@"SalesforceTasks"] ||
                 [externalSystem isEqualToString:@"Trello"]) {
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:kTaskAuthenticationCompletedNotification
                 object:self userInfo:@{@"externalSystem": self.externalSystem}];
        } else {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kAuthenticationCompletedNotification
             object:self userInfo:@{@"externalSystem": self.externalSystem}];
        }
    } else if([wv.request.mainDocumentURL.path isEqualToString:@"/auth_error"]) {
	    if(self.isFromSetting) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kAuthenticationFailedNotificationFromSetting
             object:self userInfo:@{@"externalSystem": self.externalSystem}];
        } else if([externalSystem isEqualToString:@"Asana"] ||
                  [externalSystem isEqualToString:@"SalesforceTasks"] ||
                  [externalSystem isEqualToString:@"Trello"]) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kTaskAuthenticationFailedNotification
             object:self userInfo:@{@"externalSystem": self.externalSystem}];
        } else {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kAuthenticationFailedNotification
             object:self userInfo:@{@"externalSystem": self.externalSystem}];
        }
    } else if([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102) {
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Alert" message: @"Could not complete authentication. Please try again later." delegate:self cancelButtonTitle: @"OK" otherButtonTitles: nil];
        [alert show];
    }
}

- (IBAction)backAction:(id)sender
{
    if ([[webView stringByEvaluatingJavaScriptFromString:@"document.readyState"] isEqualToString:@"complete"]) {
        [webView stopLoading];
        if(self.isFromContacts) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self dismissViewControllerAnimated:NO completion:^{
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:kBrowsingCompletedNotification
                 object:self userInfo:@{@"externalSystem": self.externalSystem}];
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:kLightBoxFinishedNotification
                 object:self userInfo:@{@"className" : NSStringFromClass([self class])}];
            }];
        }
    }
}

#pragma mark - UIAlertView Delegate Methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(self.isFromSetting) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kAuthenticationFailedNotificationFromSetting
         object:self userInfo:@{@"externalSystem": self.externalSystem}];
    } else if([externalSystem isEqualToString:@"Asana"] ||
              [externalSystem isEqualToString:@"SalesforceTasks"] ||
              [externalSystem isEqualToString:@"Trello"]) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kTaskAuthenticationFailedNotification
         object:self userInfo:@{@"externalSystem": self.externalSystem}];
    } else {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kAuthenticationFailedNotification
         object:self userInfo:@{@"externalSystem": self.externalSystem}];
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
