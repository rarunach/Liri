//
//  AppDelegate.m
//  Liri
//
//

#import "AppDelegate.h"
#import "XMPPManager.h"
#import "Account.h"
#import "DiscussionViewController.h"
#import "ProfileViewController.h"
#import "ImportTableViewController.h"
#import "Flurry.h"
#import "AppConstants.h"

@implementation AppDelegate

@synthesize window, tabBarController, isDiscussionListReady, reachabilityAlert, reach;

//this code is helpful to trace the stack on crash, details will be displayed in debugger console
void uncaughtExceptionHandler(NSException *exception) {
    DebugLog(@"CRASH: %@", exception);
    DebugLog(@"Stack Trace: %@", [exception callStackSymbols]);
    // Internal error reporting
}

- (NSString *)stringFromStatus:(NetworkStatus) status {
    
    NSString *string;
    switch(status) {
        case NotReachable:
            string = @"Not Reachable";
            break;
        case ReachableViaWiFi:
            string = @"Reachable via WiFi";
            break;
        case ReachableViaWWAN:
            string = @"Reachable via WWAN";
            break;
        default:
            string = @"Unknown";
            break;
    }
    return string;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //note: iOS only allows one crash reporting tool per app; if using another, set to: NO
//    [Flurry setCrashReportingEnabled:YES];
    
    // Replace YOUR_API_KEY with the api key in the downloaded package
    [Flurry startSession:FLURRY_KEY];
    
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);

    self.window.tintColor = DEFAULT_UICOLOR;
    [application setApplicationIconBadgeNumber:0];
    
    reach = [Reachability reachabilityWithHostName: @"www.google.com"];
    NetworkStatus status = [reach currentReachabilityStatus];
    NSString *statusString = [self stringFromStatus:status];
    
    if([statusString isEqualToString:@"Not Reachable"] || [statusString isEqualToString:@"Unknown"]) {
        [reach startNotifier];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
        reachabilityAlert = [[UIAlertView alloc] initWithTitle:@"Network error"
                                                        message:@"Internet connection is not available. Please check your network and try again." delegate:nil
                                              cancelButtonTitle:nil otherButtonTitles:nil];
        [reachabilityAlert show];
    } else {
        [self performAppLaunch];
    }
    self.window.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;

    return YES;
}

- (void) reachabilityChanged:(NSNotification *)note
{
    Reachability* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    NetworkStatus netStatus =[curReach currentReachabilityStatus];
    switch (netStatus) {
        case NotReachable:
            break;
        default:
            [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
            [reachabilityAlert dismissWithClickedButtonIndex:0 animated:YES];
            [self performAppLaunch];
            break;
    }
}

- (void) performAppLaunch
{
    //-- Set Notification
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
    {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    else
    {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
         (UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert)];
    }
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    BOOL isVerification = [standardUserDefaults boolForKey:@"VERIFICATION_IN_PROGRESS"];
    
    if ([standardUserDefaults objectForKey:@"SERVERTOKEN"] != nil && !isVerification)
    {
        Account *account = [Account sharedInstance];
        account.email = [standardUserDefaults objectForKey:@"USEREMAIL"];
        account.jid = [Account emailToJid:account.email];
        account.password = [standardUserDefaults objectForKey:@"USERPASS"];
        account.chatPin = [standardUserDefaults objectForKey:@"CHAT_PIN"];
        account.serverToken = [standardUserDefaults objectForKey:@"SERVERTOKEN"];
        
        isDiscussionListReady = NO;
        self.isXMPPAuthenticated = NO;
        
        account.firstName = [standardUserDefaults objectForKey:@"FIRSTNAME"];
        
        if (account.firstName) {
            account.lastName = [standardUserDefaults objectForKey:@"LASTNAME"];
            NSData *imageData = [standardUserDefaults objectForKey:@"PHOTO"];
            account.photo = [UIImage imageWithData:imageData];
            
            UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Tabs" bundle:nil];
            tabBarController = [storyBoard instantiateInitialViewController];
            tabBarController.selectedIndex = DISCUSSIONS_TAB_INDEX;
            [self.window setRootViewController:tabBarController];
            
        } else {
            UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
            UIViewController *profileCtlr = [storyBoard instantiateViewControllerWithIdentifier:@"ProfileViewController"];
            [self.window setRootViewController:profileCtlr];
        }
        //[[XMPPManager sharedInstance] registerOrLogin];
        account.box_auth = [[standardUserDefaults objectForKey:@"BOX_AUTH"] integerValue] == 1;
        account.dropbox_auth = [[standardUserDefaults objectForKey:@"DROPBOX_AUTH"] integerValue] == 1;
        account.google_auth = [[standardUserDefaults objectForKey:@"GOOGLE_AUTH"] integerValue] == 1;
        account.salesforce_auth = [[standardUserDefaults objectForKey:@"SALESFORCE_AUTH"] integerValue] == 1;
        account.asana_auth = [[standardUserDefaults objectForKey:@"ASANA_AUTH"] integerValue] == 1;
        account.trello_auth = [[standardUserDefaults objectForKey:@"TRELLO_AUTH"] integerValue] == 1;
        account.zoho_auth = [[standardUserDefaults objectForKey:@"ZOHO_AUTH"] integerValue] == 1;
        account.linkedin_auth = [[standardUserDefaults objectForKey:@"LINKEDIN_AUTH"] integerValue] == 1;
        
        [account getConfiguration:NO];
        
        [account getUserCategoriesCount];
        
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kReceivedRemoteNotification
     object:self userInfo:userInfo];
}

- (void)application:(UIApplication *)application didChangeStatusBarFrame:(CGRect)oldStatusBarFrame
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kStatusBarChangeNotification
                                                        object:self
                                                      userInfo:nil];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[XMPPManager sharedInstance] goOffline];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[XMPPManager sharedInstance] goOffline];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    /* BOOL result = [[XMPPManager sharedInstance] goOnline];
    if (!result) {
        // re-login, need to wait for auth to complete
        [self showActivityIndicator];
        [[XMPPManager sharedInstance] registerOrLogin];
    } */
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];

    BOOL isVerification = [standardUserDefaults boolForKey:@"VERIFICATION_IN_PROGRESS"];
    if ([standardUserDefaults objectForKey:@"SERVERTOKEN"] != nil && !isVerification)
    {
        [self showActivityIndicator];
        isDiscussionListReady = NO;
        self.isXMPPAuthenticated = NO;

        [[XMPPManager sharedInstance] registerOrLogin];

        Account *account = [Account sharedInstance];
        [account getUserCategoriesCount];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    //if (application.applicationState != UIApplicationStateActive) {
    //    [[XMPPManager sharedInstance] goOnline];
    //}
    application.applicationIconBadgeNumber = 0;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[XMPPManager sharedInstance] goOffline];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString* tokenstr = [[[[deviceToken description]
                                stringByReplacingOccurrencesOfString: @"<" withString: @""]
                               stringByReplacingOccurrencesOfString: @">" withString: @""]
                              stringByReplacingOccurrencesOfString: @" " withString: @""];
    
    NSLog(@"token=%@", tokenstr);
    Account *account = [Account sharedInstance];
    account.deviceToken = tokenstr;
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{

}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Failed to register for push notifications");
    //maybe simulator
    Account *account = [Account sharedInstance];
    account.deviceToken = @"";
}

//show - global activity indicator, used across the app to show the waiting and block user interation
- (void)showActivityIndicator
{
    if (![activityContainerView superview])
    {
        activityContainerView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        activityView = [[UIActivityIndicatorView alloc] init];
        activityView.center = self.window.center;
        activityView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        activityView.color = [UIColor blackColor];
        [activityView setHidesWhenStopped:YES];

        [activityContainerView addSubview:activityView];
    }
    
    [self.window addSubview:activityContainerView];

    activityView.hidden = NO;
    //dispatch_async(dispatch_get_main_queue(), ^{
        [activityView startAnimating];
    //});

}

//hide - global activity indicator, used across the app to show the waiting and block user interation
- (void)hideActivityIndicator
{
    [activityView stopAnimating];
    activityView.hidden = YES;
    [activityContainerView removeFromSuperview];
}


@end
