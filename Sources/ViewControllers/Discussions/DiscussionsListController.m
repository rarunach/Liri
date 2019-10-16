//
//  DiscussionsListController.m
//  Liri
//
//  Created by Ramani Arunachalam on 7/17/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "DiscussionsListController.h"
#import "Discussion.h"
#import "APIManager.h"
#import "AppDelegate.h"
#import "DiscussionNotificationViewController.h"
#import "CRNInitialsImageView.h"
#import "MKNumberBadgeView.h"
#import "Flurry.h"
#import "Reachability.h"
#import "MyAvailabilityLightBoxViewController.h"
#import "Categories.h"
#import "TimestampsManager.h"

typedef void (^Process1On1DiscussionCompletionHandler)(DiscussionViewController *discussionCtlr, BOOL finished);
typedef void (^Process1On1UnknownBuddyCompletionHandler)(DiscussionViewController *discussionCtlr, BOOL finished);

@interface DiscussionsListController ()
{
    AppDelegate *delegate;
    UIAlertView *discAlertView, *msgAlertView;
    DiscussionViewController *rememberedDiscussCtlr;
    int failcount;
    BOOL refreshing;
    UIAlertView *alertView;
    UIButton *availabilityButton;
    BOOL networkReachable;
    BOOL pushAllowed;
}
@property (weak, nonatomic) IBOutlet UITableView *discussionsList;
@property (weak, nonatomic) IBOutlet UIView *offlineView;
@property (weak, nonatomic) IBOutlet UIButton *offlineViewClose;
@property (nonatomic) NSMutableArray *discussionCtlrs;
@property (nonatomic) Discussion *newdiscussion; // global variable? how do you handle multiple push notifications?
@property (nonatomic) NSString *pushDiscussionID, *pushDiscussionTitle;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBtn;
@property (nonatomic) Reachability *hostReachability;
@property (nonatomic) Reachability *wifiReachability;
@property (nonatomic, copy) Process1On1DiscussionCompletionHandler process1On1DiscussionCompletionHandler;
@property (nonatomic, copy) Process1On1UnknownBuddyCompletionHandler process1On1UnknownBuddyCompletionHandler;

@end

@implementation DiscussionsListController

@synthesize discussionCtlrs;
@synthesize discussionsList, newdiscussion;
@synthesize pushDiscussionID, pushDiscussionTitle;
@synthesize discussionsLoaded;

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        discussionCtlrs = [[NSMutableArray alloc] initWithCapacity:1];
        
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStyleBordered target:self action:nil];
        item.tintColor = [UIColor whiteColor];
        self.navigationItem.backBarButtonItem = item;
        
        // XMPP events
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageReceived:) name:kMessageReceivedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(annotationPosted:) name:kNewAnnotationNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startNewDiscussion:) name:kStartNewDiscussionNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startNew1On1Discussion:) name:kStartNew1On1DiscussionNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processPushNotification:) name:UIApplicationDidFinishLaunchingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processPushNotification:) name:
            kReceivedRemoteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(discussionReady:) name:kDiscussionReadyNotification object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(xmppAuthenticated:) name:kXMPPAuthenticatedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(xmppDisconnected:) name:kXMPPDisconnectedNotification object:nil];

        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lightBoxFinished:) name:kLightBoxFinishedNotification object:nil];
        

        discussionsLoaded = NO;
        refreshing = NO;
        networkReachable = YES;
        //if (self.navigationController.tabBarController.selectedIndex == 0) {
            alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Loading, please wait..."
                                  delegate:nil cancelButtonTitle:nil
                                  otherButtonTitles:nil];
            [alertView show];
        //}
        [self refreshDiscussions];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) lightBoxFinished:(NSNotification*)aNotification {
    
    NSDictionary *info = [aNotification userInfo];
    if ([info[@"className"] isEqualToString:@"DiscussionNotificationViewController"] || [info[@"className"] isEqualToString:@"MyAvailabilityLightBoxViewController"]) {
        if (self.isViewLoaded && self.view.window){
            [UIView animateWithDuration:0.3 animations:^(void) {
                self.view.alpha = 1.0;
            }];
            self.tabBarController.tabBar.hidden = NO;
            pushAllowed = YES;
            [self sortDiscussions];
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog (@"DiscussionListController:viewDidLoad");
    [[XMPPManager sharedInstance] registerOrLogin];
    
    self.offlineView.hidden = NO;
    NSString *remoteHostName = @"www.apple.com";
    
	self.hostReachability = [Reachability reachabilityWithHostName:remoteHostName];
	[self.hostReachability startNotifier];
	[self updateInterfaceWithReachability:self.hostReachability];

    self.wifiReachability = [Reachability reachabilityForLocalWiFi];
	[self.wifiReachability startNotifier];
	[self updateInterfaceWithReachability:self.wifiReachability];

    if (!discussionsLoaded) {
        [self refreshDiscussions];
    }
    // Do any additional setup after loading the view.
    [Flurry logEvent:@"Discussions List Screen"];
    
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editAction:)];
    
    UIBarButtonItem *fixedItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedItem.width = 40.0f; // or whatever you want
    
    availabilityButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [availabilityButton setFrame:CGRectMake(0, 0, 25, 25)];
    [availabilityButton setImage:[UIImage imageNamed:@"Status-Available-Icon@2x.png"] forState:UIControlStateNormal];
    [availabilityButton addTarget:self action:@selector(statusAction:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:availabilityButton];
    
    NSArray *barButtons= [[NSArray alloc] initWithObjects:editButton, fixedItem, barButton, nil];
    
    self.navigationItem.leftBarButtonItems = barButtons;
}


- (void)viewDidLayoutSubviews
{
    if(IS_IPHONE_5) {
        //do stuff for 4 inch iPhone screen
    }
    else {
        //do stuff for 3.5 inch iPhone screen
        [self.discussionsList setFrame:CGRectMake(self.discussionsList.frame.origin.x, self.discussionsList.frame.origin.y, self.discussionsList.frame.size.width, self.discussionsList.frame.size.height - 88)];
    }
}

- (void)updateInterfaceWithReachability:(Reachability *)reachability
{
    NetworkStatus netStatus = [reachability currentReachabilityStatus];
    
    switch (netStatus)
    {
        case NotReachable:
            self.offlineView.hidden = NO;
            break;
        
        default:
            self.offlineView.hidden = YES;
            break;
    }
}

- (void) reachabilityChanged:(NSNotification *)note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
	[self updateInterfaceWithReachability:curReach];
    NetworkStatus netStatus =[curReach currentReachabilityStatus];
    XMPPManager *xmppMgr = [XMPPManager sharedInstance];
    switch (netStatus) {
        case NotReachable:
            //reset all the room joins.
            xmppMgr.isNetworkReachable = NO;
            break;
        default:
            xmppMgr.isNetworkReachable = YES;
            NSLog(@"Network is now reachable");
            break;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = NO;
    //[self sortDiscussions];
    [discussionsList reloadData];

}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [UIView animateWithDuration:1.0 animations:^(void) {
        self.view.alpha = 1.0;
    }];
    NSLog(@"viewWillAppear:refreshing discussions");
    [self getUserAvailability];
    pushAllowed = YES;
    [self refreshDiscussions];
}

- (void)willEnterForeground:(NSNotification *)notification
{
     //if (self.navigationController.topViewController == self) {
        delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSLog(@"Show indicator...");
        [delegate showActivityIndicator];
        // reset all discussion join status.
        [self resetAllDiscussionJoinStatus];
        pushAllowed = YES;
        [self refreshDiscussions];
    //}
}

- (void)xmppAuthenticated:(NSNotification *)notification
{
    NSLog(@"Got xmppAuthenticated Notification in List controller");
    delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.isXMPPAuthenticated = YES;
    if (delegate.isDiscussionListReady) {
        [self joinAllDiscussions];
    }
    else {
        NSLog(@"Discussions have not loaded yet, starting a timer for 2 seconds");
        [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(joinAllDiscussions) userInfo:nil repeats:NO];
    }
    //[self refreshDiscussions];
}

- (void)xmppDisconnected:(NSNotification *)notification
{
    NSLog(@"Got xmppDisconnected Notification in List controller");
    delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!delegate.isXMPPAuthenticated)
        return;
    delegate.isXMPPAuthenticated = NO;
    [self resetAllDiscussionJoinStatus];
}


- (void)joinAllDiscussions
{
    delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (delegate.isDiscussionListReady && delegate.isXMPPAuthenticated) {
        //join all the rooms.
        for (DiscussionViewController *discussCtlr in discussionCtlrs) {
            if (discussCtlr.discussion.joinedRoom == NO)
                [discussCtlr.discussion joinDiscussion];
        }
    }
    else {
        NSLog(@"Discussions have not loaded yet, starting a timer for 2 seconds");
        // start another timer.
        [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(joinAllDiscussions) userInfo:nil repeats:NO];
    }
}

- (void)resetAllDiscussionJoinStatus
{
        //reset the join status for all the rooms.
        for (DiscussionViewController *discussCtlr in discussionCtlrs) {
            discussCtlr.discussion.joinedRoom = NO;
            discussCtlr.discussion.joiningRoom = NO;
        }
}

- (void)getUpdatedDiscussions
{
    if (refreshing)
        return;
    
    NSLog(@"Refreshing....");
    
    refreshing = YES;
    delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSString* lastSuccessfulUpdate = [standardUserDefaults objectForKey:@"LAST_UPDATED_DISCUSSIONS_CALL"];
    if(lastSuccessfulUpdate == nil) {
        lastSuccessfulUpdate = [Account convertLocalToGmtTimeZonePrecise:[NSDate date]];
    }

    NSDateFormatter *dateFormatterLocal = [[NSDateFormatter alloc] init];
    NSDateFormatter *dateFormatterExpected = [[NSDateFormatter alloc] init];
    [dateFormatterLocal setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [dateFormatterExpected setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    
    NSDate *tempDate = [dateFormatterLocal dateFromString:lastSuccessfulUpdate];
    lastSuccessfulUpdate = [dateFormatterExpected stringFromDate:tempDate];

    failcount = 0;
    id<APIAccessClient> endpoint1 =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint1.successJSON = ^(NSURLRequest *request,
                              id responseJSON){
        failcount = 0;
        NSDictionary *dict = (NSDictionary *)responseJSON;
        NSArray *discussionArray = [dict objectForKey:@"discussion_list"];
        

        [standardUserDefaults setObject:[Account convertLocalToGmtTimeZonePrecise:[NSDate date]] forKey:@"LAST_UPDATED_DISCUSSIONS_CALL"];
        [standardUserDefaults synchronize];
        
        Account *account = [Account sharedInstance];
        NSLog(@"ResponseJSON=%@",responseJSON);
        __block int discussionsCount = 0;
        __block int pending1On1Discussions = 0;
        for (NSDictionary *dict in discussionArray)
        {
            NSString *discussionId = [dict objectForKey:@"id"];
            NSString *discussionTitle = [dict objectForKey:@"name"];
            NSString *is1on1 = [dict objectForKey:@"is1on1"];
            if([[dict valueForKey:@"is1on1"] integerValue] == 1) {
                is1on1 = @"true";
            } else if([[dict valueForKey:@"is1on1"] integerValue] == 0) {
                is1on1 = @"false";
            }
            
            BOOL found = NO;
            for (DiscussionViewController *discussCtlr in discussionCtlrs) {
                if ([discussCtlr.discussion.discussionID isEqualToString:discussionId]) {
                    NSDate *discussionLastUpdatedDate = [TimestampsManager fetchForDiscussion:discussionId];
                    if(![[dict objectForKey:@"senderJID"] isEqualToString:account.mybuddy.jabberid]) {
                        [discussCtlr getUnreadMessages];
                       // NSString *gmtToLocalStartDate = [Account convertGmtToLocalTimeZonePrecise:[dict objectForKey:@"lastupdated"]];
                       // discussCtlr.lastUpdatedTimeFromApi = [NSDate dateWithISO8061Format:gmtToLocalStartDate];
                        discussCtlr.lastUpdatedTimeFromApi = [Account convertGmtToLocalTimeZonePrecise:[dict objectForKey:@"lastupdated"]];
                        NSLog(@"lastupdatedTimefromAPI=%@,discussionLastUpdatedDate=%@",discussCtlr.lastUpdatedTimeFromApi,discussionLastUpdatedDate);
                        if([discussCtlr.lastUpdatedTimeFromApi compare:discussionLastUpdatedDate] == NSOrderedDescending) {
                            [TimestampsManager updateForDiscussion:discussionId withDate:discussCtlr.lastUpdatedTimeFromApi];
                            discussCtlr.lastMessageStringFromApi = [dict objectForKey:@"lastmessage"];
                            discussCtlr.lastMessageSenderJID = [dict objectForKey:@"senderJID"];
                            //NSLog(@"Setting unreadmessages to YES for discusssion: %@",discussCtlr.discussion.title);
                            discussCtlr.hasUnreadMessages = YES;
                            discussionsCount++;
                        }
                    }
                    found = YES;
                }
            }
            if (!found) {
                // NSLog(@"#### Not Found disc id %@", discussionId);
                if ([discussionTitle isEqualToString:@"Liri Support"] &&
                    [account.email isEqualToString:@"ramani@vyaza.com"])
                    continue;
                Discussion *discussion;
                if ([is1on1 isEqualToString:@"false"]) {
                    discussion = [Discussion discussionWithID:discussionId title:discussionTitle
                                                    buddyList:nil];
                    DiscussionViewController *thisController = [self addDiscussionCtlr:discussion show:NO];
                    //NSString *gmtToLocalStartDate = [Account convertGmtToLocalTimeZonePrecise:[dict objectForKey:@"lastupdated"]];
                    //thisController.lastUpdatedTimeFromApi = [NSDate dateWithISO8061Format:gmtToLocalStartDate];
                    thisController.lastUpdatedTimeFromApi =[Account convertGmtToLocalTimeZonePrecise:[dict objectForKey:@"lastupdated"]];

                    if(![[dict objectForKey:@"senderJID"] isEqualToString:account.mybuddy.jabberid]) {
                        thisController.lastMessageStringFromApi = [dict objectForKey:@"lastmessage"];
                        thisController.lastMessageSenderJID = [dict objectForKey:@"senderJID"];
                        thisController.hasUnreadMessages = YES;
                        discussionsCount++;
                    }
                } else {
                    NSLog(@"Incrementing pending1on1 flag");
                    pending1On1Discussions++;
                    [self process1On1Discussion:discussionId withbuddy:nil andShow:NO andCompletion:^(DiscussionViewController *thisController, BOOL finished) {
                        if(finished) {
                            //NSString *gmtToLocalStartDate = [Account convertGmtToLocalTimeZonePrecise:[dict objectForKey:@"lastupdated"]];
                            //thisController.lastUpdatedTimeFromApi = [NSDate dateWithISO8061Format:gmtToLocalStartDate];
                            thisController.lastUpdatedTimeFromApi = [Account convertGmtToLocalTimeZonePrecise:[dict objectForKey:@"lastupdated"]];

                            if(![[dict objectForKey:@"senderJID"] isEqualToString:account.mybuddy.jabberid]) {
                                thisController.lastMessageStringFromApi = [dict objectForKey:@"lastmessage"];
                                thisController.lastMessageSenderJID = [dict objectForKey:@"senderJID"];
                                thisController.hasUnreadMessages = YES;
                                discussionsCount++;
                            }
                        }
                        pending1On1Discussions--;
                        NSLog(@"Decrementing pending1on1 flag");
                        if(pending1On1Discussions == 0) {
                            [self finalizeDiscussionsList:discussionsCount];
                        }
                    }];
                }
                
            }
        }
        
        if(pending1On1Discussions == 0) {
            [self finalizeDiscussionsList:discussionsCount];
        }
    };
    endpoint1.failureJSON = ^(NSURLRequest *request,
                              id responseJSON){
        /*
        failcount++;
        if (failcount < 5) {
            [endpoint1 getUpdatedDiscussions:lastSuccessfulUpdate];
        }
         */
        refreshing = NO;
        [delegate hideActivityIndicator];
    };
    
    [endpoint1 getUpdatedDiscussions:lastSuccessfulUpdate];
}

-(void)finalizeDiscussionsList:(int)badgeCount {
    /*
    if(badgeCount > 0) {
        [[[[[self tabBarController] tabBar] items] objectAtIndex:0] setBadgeValue:[NSString stringWithFormat:@"%lu", (unsigned long)badgeCount]];
    } else {
        [[[[[self tabBarController] tabBar] items] objectAtIndex:0] setBadgeValue:nil];
    }
     */
    NSLog(@"Finalizing Discussion List");
    Account *account = [Account sharedInstance];
    [account setDiscussionsBadgeValue];
    
    discussionsLoaded = YES;
    delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.isDiscussionListReady = YES;

    //[NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(sortDiscussions) userInfo:nil repeats:NO];
    [self sortDiscussions];
    
    [discussionsList reloadData];
}

- (void)refreshDiscussions
{
    if (refreshing)
    {
        NSLog(@"refreshDiscussion.. returning since we're still refreshing");
        return;
    }
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSString* lastSuccessfulUpdate = [standardUserDefaults objectForKey:@"LAST_UPDATED_DISCUSSIONS_CALL"];
    if(lastSuccessfulUpdate != nil && discussionsLoaded) {
        [self getUpdatedDiscussions];
        return;
    }
    if(lastSuccessfulUpdate == nil) {
        lastSuccessfulUpdate = [Account convertLocalToGmtTimeZonePrecise:[NSDate date]];
    }

    NSLog(@"Refreshing....");
    
    refreshing = YES;
    delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    failcount = 0;
    id<APIAccessClient> endpoint1 =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint1.successJSON = ^(NSURLRequest *request,
                              id responseJSON){
        failcount = 0;
        NSDictionary *dict = (NSDictionary *)responseJSON;
        NSArray *discussionArray = [dict objectForKey:@"discussion_list"];

        [standardUserDefaults setObject:[Account convertLocalToGmtTimeZonePrecise:[NSDate date]] forKey:@"LAST_UPDATED_DISCUSSIONS_CALL"];
        [standardUserDefaults synchronize];

        Account *account = [Account sharedInstance];
        
        NSDateFormatter *dateFormatterLocal = [[NSDateFormatter alloc] init];
        [dateFormatterLocal setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        
//        NSDate *localDate = [dateFormatterLocal dateFromString:lastSuccessfulUpdate];
       // NSString *localDateInLocalTimeStr = [Account convertGmtToLocalTimeZonePrecise:lastSuccessfulUpdate];
       // NSDate *localDateInLocalTime = [dateFormatterLocal dateFromString:localDateInLocalTimeStr];
        NSDate *localDateInLocalTime = [Account convertGmtToLocalTimeZonePrecise:lastSuccessfulUpdate];
        

#if 0
        if ([discussionArray count] == 0) {
            BuddyList *buddies = [[BuddyList alloc] init];

            Buddy *support = [Buddy buddyWithDisplayName:@"Ramani Arunachalam" email:@"ramani@vyaza.com" photo:nil isUser:YES];
            [buddies addBuddy:support];
            
            [account.buddyList addBuddy:support];

            newdiscussion = [Discussion discussionWithTitle:@"Liri Support" buddyList:buddies groups:nil];
            [alertView dismissWithClickedButtonIndex:0 animated:YES];

            return;
        }
#endif
        __block int newDiscussions = 0;
        __block int pending1On1Discussions = 0;
        for (NSDictionary *dict in discussionArray)
        {
            NSString *discussionId = [dict objectForKey:@"id"];
            NSString *discussionTitle = [dict objectForKey:@"name"];
            NSString *is1on1 = [dict objectForKey:@"is1on1"];
            NSString *lastupdated = [dict objectForKey:@"lastupdated"];
            
            //NSRange timezoneColon = [lastupdated rangeOfString:@":" options:NSBackwardsSearch];
            //lastupdated = [lastupdated stringByReplacingCharactersInRange:NSMakeRange(timezoneColon.location, 1) withString:@""];
            NSLog(@"Discussion last update date for %@: %@", discussionTitle, lastupdated);
            
            NSDateFormatter *dateFormatterRemote = [[NSDateFormatter alloc] init];
            [dateFormatterRemote setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
            NSDate *remoteDate = [dateFormatterRemote dateFromString:lastupdated];


            BOOL found = NO;
            for (DiscussionViewController *discussCtlr in discussionCtlrs) {
                if ([discussCtlr.discussion.discussionID isEqualToString:discussionId]) {
                    NSDate *discussionLastUpdatedDate = [TimestampsManager fetchForDiscussion:discussionId];
                    //NSString *gmtToLocalStartDate = [Account convertGmtToLocalTimeZonePrecise:lastupdated];
                    //discussCtlr.lastUpdatedTimeFromApi = [NSDate dateWithISO8061Format:gmtToLocalStartDate];
                    discussCtlr.lastUpdatedTimeFromApi =[Account convertGmtToLocalTimeZonePrecise:lastupdated];
                    if([remoteDate compare:discussionLastUpdatedDate] == NSOrderedDescending) {
                        [TimestampsManager updateForDiscussion:discussionId withDate:discussCtlr.lastUpdatedTimeFromApi];
                        discussCtlr.hasUnreadMessages = YES;
                        newDiscussions++;
                    }
                    found = YES;
                }
            }
            if (!found) {
                // NSLog(@"#### Not Found disc id %@", discussionId);
                if ([discussionTitle isEqualToString:@"Liri Support"] &&
                     [account.email isEqualToString:@"ramani@vyaza.com"])
                    continue;
                Discussion *discussion;
                if ([is1on1 isEqualToString:@"false"]) {
                    discussion = [Discussion discussionWithID:discussionId title:discussionTitle
                                                            buddyList:nil];
                    DiscussionViewController *thisController = [self addDiscussionCtlr:discussion show:NO];
                    //NSString *gmtToLocalStartDate = [Account convertGmtToLocalTimeZonePrecise:lastupdated];
                    //thisController.lastUpdatedTimeFromApi = [NSDate dateWithISO8061Format:gmtToLocalStartDate];
                    NSDate *discussionLastUpdatedDate = [TimestampsManager fetchForDiscussion:discussionId];
                    if([discussionLastUpdatedDate isEqualToDate:[NSDate distantPast]]) {
                        NSLog(@"check");
                        discussionLastUpdatedDate = localDateInLocalTime;
                    }
                    thisController.lastUpdatedTimeFromApi = [Account convertGmtToLocalTimeZonePrecise:lastupdated];
                    if([remoteDate compare:discussionLastUpdatedDate]== NSOrderedDescending) {
                        NSLog(@"remoteDate: %@, discussionLastUpdatedDate: %@", remoteDate, discussionLastUpdatedDate);
                        [TimestampsManager updateForDiscussion:discussionId withDate:thisController.lastUpdatedTimeFromApi];
                        thisController.hasUnreadMessages = YES;
                        newDiscussions++;
                    }
                } else {
                    pending1On1Discussions++;
                    [self process1On1Discussion:discussionId withbuddy:nil andShow:NO andCompletion:^(DiscussionViewController *thisController, BOOL finished) {
                        if(finished) {
                            //NSString *gmtToLocalStartDate = [Account convertGmtToLocalTimeZonePrecise:lastupdated];
                            //thisController.lastUpdatedTimeFromApi = [NSDate dateWithISO8061Format:gmtToLocalStartDate];
                            NSDate *discussionLastUpdatedDate = [TimestampsManager fetchForDiscussion:discussionId];
                            if([discussionLastUpdatedDate isEqualToDate:[NSDate distantPast]]) {
                                discussionLastUpdatedDate = localDateInLocalTime;
                            }
                            thisController.lastUpdatedTimeFromApi =[Account convertGmtToLocalTimeZonePrecise:lastupdated];

                            if([remoteDate compare:localDateInLocalTime]== NSOrderedDescending) {
                                NSLog(@"remoteDate: %@, discussionLastUpdatedDate: %@", remoteDate, discussionLastUpdatedDate);
                                [TimestampsManager updateForDiscussion:discussionId withDate:thisController.lastUpdatedTimeFromApi];
                                thisController.hasUnreadMessages = YES;
                                newDiscussions++;
                            }
                        }
                        pending1On1Discussions--;
                        if(pending1On1Discussions == 0) {
                            [self finalizeDiscussionsList:newDiscussions];
                        }
                    }];
                }

            }
        }
        
        if(pending1On1Discussions == 0) {
            [self finalizeDiscussionsList:newDiscussions];
        }
    };
    endpoint1.failureJSON = ^(NSURLRequest *request,
                              id responseJSON){
        failcount++;
        if (failcount < 5) {
            [endpoint1 getDiscussions];
        }
        
    };
    
    [endpoint1 getDiscussions];
}

/*- (void)processDiscussion:(NSString *)discussionId
{
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        NSDictionary *responseDict = (NSDictionary *)responseJSON;
        NSDictionary *infoDict = [responseDict objectForKey:@"discussion_info"];
        NSString *discussionTitle = [infoDict objectForKey:@"title"];
        BuddyList *discBuddyList = [[BuddyList alloc] init];
        Account *account = [Account sharedInstance];
        NSString *owner = [infoDict objectForKey:@"owner"];
        if ([owner isEqualToString:account.email]) {
            [discBuddyList addBuddy:[account getMyBuddy]];
        } else {
            Buddy *ownerbuddy = [account.buddyList findBuddyForEmail:owner];
            if (ownerbuddy != nil)
                [discBuddyList addBuddy:ownerbuddy];
        }
        for (NSString *email in [infoDict objectForKey:@"allmembers"]) {
            Buddy *buddy = [account.buddyList findBuddyForEmail:email];
            if (buddy != nil) {
                NSLog(@"buddy found for email %@", email);
                [discBuddyList addBuddy:buddy];
            }
        }
        [discBuddyList addBuddy:account.getMyBuddy];
        Discussion *discussion = [Discussion discussionWithID:discussionId title:discussionTitle
                                                    buddyList:discBuddyList];
        [discussions addObject:discussion];
        [self addDiscussionCtlr:discussion show:NO];
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
    };
    
    [endpoint getDiscussion:discussionId];
}*/

- (void)process1on1Discussion:(NSString *)discussionId withUnknownBuddy:(NSString *)email
                andCompletion:(Process1On1UnknownBuddyCompletionHandler)completionBlock
{
    self.process1On1UnknownBuddyCompletionHandler = completionBlock;
    Account *account = [Account sharedInstance];
    
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        
        NSDictionary *jsonDict = responseJSON[@"data"];
        
        NSString *firstName = jsonDict[@"first_name"];
        NSString *lastName = jsonDict[@"last_name"];
        NSString *name = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
        
        UIImage *photo = [account.s3Manager downloadImage:jsonDict[@"profile_pic"]];
   
        Buddy *buddy = [Buddy buddyWithDisplayName:name email:email photo:photo isUser:YES];
        [account.buddyList addBuddy:buddy];
        [account.buddyList saveBuddiesToUserDefaults];
        
        Discussion *discussion = [Discussion discussionWithID:discussionId buddy:buddy create:NO];
        DiscussionViewController *thisController = [self addDiscussionCtlr:discussion show:NO];
        thisController.lastUpdatedTimeFromApi = [NSDate date];
        [TimestampsManager updateForDiscussion:thisController.discussion.discussionID withDate:[NSDate date]];
        [discussion joinDiscussion];
        self.process1On1UnknownBuddyCompletionHandler(thisController, YES);

//        [discussionsList reloadData];
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        NSLog(@"error message %@ and json %@", responseJSON[@"error"], responseJSON);
        self.process1On1UnknownBuddyCompletionHandler(nil, NO);
    };
    
    [endpoint getUserProfile:email];
}

- (void)process1On1Discussion:(NSString *)discussionId withbuddy:(Buddy *)buddy andShow:(BOOL)showFlag
                andCompletion:(Process1On1DiscussionCompletionHandler)completionBlock
{
    self.process1On1DiscussionCompletionHandler = completionBlock;
    Account *account = [Account sharedInstance];
    
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
 
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        NSDictionary *infoDict = [responseJSON objectForKey:@"discussion_info"];

        NSString *owner = [infoDict objectForKey:@"owner"];
        Discussion *discussion;
        Buddy *buddy;
        if (![owner isEqualToString:account.email]) {
            buddy = [account.buddyList findBuddyForEmail:owner];
        } else {
            NSArray *members = [infoDict objectForKey:@"members"];
            buddy = [account.buddyList findBuddyForEmail:members[0]];
        }
        
        if (buddy == nil) {
            [self process1on1Discussion:discussionId withUnknownBuddy:owner andCompletion:^(DiscussionViewController *thisController, BOOL finished) {
                self.process1On1DiscussionCompletionHandler(thisController, finished);
            }];
        } else {
            discussion = [Discussion discussionWithID:discussionId buddy:buddy create:NO];
            DiscussionViewController *thisController = [self addDiscussionCtlr:discussion show:showFlag];
            thisController.lastUpdatedTimeFromApi = [NSDate date];
            [TimestampsManager updateForDiscussion:thisController.discussion.discussionID withDate:[NSDate date]];
            self.process1On1DiscussionCompletionHandler(thisController, YES);
        }
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        // If not found, create a new one
        Account *account = [Account sharedInstance];
        NSString *node = [NSString stringWithFormat:@"%@-%@", account.email, buddy.email];
        NSString *discID = [node stringByReplacingOccurrencesOfString:@"@" withString:@"."];
        
        newdiscussion = [Discussion discussionWithID:discID buddy:buddy create:YES];
        self.process1On1DiscussionCompletionHandler(nil, NO);
    };
    
    [endpoint getDiscussion:discussionId];
}

- (void)sortDiscussions
{
    //join all the discussion before sorting.
    [self joinAllDiscussions];
    for (DiscussionViewController *discussCtlr in discussionCtlrs) {
        if (!discussCtlr.messagesLoaded) {
            [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(sortDiscussions) userInfo:nil repeats:NO];
            NSLog(@"sortDiscussions returns because messages are not loaded yet");
            return;
        }
    }
    NSArray *tempArray = [discussionCtlrs sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
    
        NSDate *first = [(DiscussionViewController *)a getLastUpdatedTime];
        NSDate *second = [(DiscussionViewController *)b getLastUpdatedTime];
        return [second compare:first];
    }];
    [discussionCtlrs removeAllObjects];
    [discussionCtlrs addObjectsFromArray:tempArray];
    [discussionsList reloadData];
	if(IS_IPHONE_5) {
        //do stuff for 4 inch iPhone screen
    	[discussionsList layoutIfNeeded];
    }
    refreshing = NO;
    [delegate hideActivityIndicator];
    [alertView dismissWithClickedButtonIndex:0 animated:YES];
}

- (IBAction)offlineViewCloseAction:(id)sender {
    self.offlineView.hidden = YES;
}

- (IBAction)initiateAction:(id)sender {
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:kSelectContactsNotification
        object:self userInfo:nil];
    self.tabBarController.selectedIndex = CONTACTS_TAB_INDEX;
}

- (void)startNewDiscussion:(NSNotification *)notification
{    
    NSDictionary *dict = notification.userInfo;
    NSString *disctitle = [dict objectForKey:@"title"];
    NSString *welcomeMessage = [dict objectForKey:@"welcomeMessage"];
    UINavigationController *navCtlr = self.tabBarController.viewControllers[1];
    GroupsContactsViewController *groupsCtlr = (GroupsContactsViewController *)navCtlr.viewControllers[0];
    
    newdiscussion = [Discussion discussionWithTitle:disctitle welcomeMsg:welcomeMessage buddyList:groupsCtlr.selectedBuddies groups:groupsCtlr.selectedGroups];
}

- (void)discussionReady:(NSNotification *)notification
{
    BOOL flag = YES;
    
#if 0
    if ([newdiscussion.title isEqualToString:@"Liri Support"]) {
        flag = NO;
        //welcomeMessage = @"Welcome to Liri! Post your questions here..";
    }
#endif
    DiscussionViewController *thisController = [self addDiscussionCtlr:newdiscussion show:flag];
    //@@Naga: Using a global variable??
    thisController.lastUpdatedTimeFromApi = [NSDate date];
    [TimestampsManager updateForDiscussion:thisController.discussion.discussionID withDate:[NSDate date]];
}

- (void)startNew1On1Discussion:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    Buddy *buddy = [dict objectForKey:@"buddy"];
    
    rememberedDiscussCtlr = nil;
    
    for (DiscussionViewController *discussCtlr in discussionCtlrs) {
        if (discussCtlr.discussion.type == TYPE_1ON1)
            if ([discussCtlr.discussion.buddyList findBuddyForEmail:buddy.email])
                rememberedDiscussCtlr = discussCtlr;
    }
    
    if (rememberedDiscussCtlr) {
        [self.navigationController.topViewController.view endEditing:YES];
        [self.navigationController popToRootViewControllerAnimated:NO];
        [self.navigationController setViewControllers:[NSArray arrayWithObjects:self, rememberedDiscussCtlr, nil] animated:NO];
        self.tabBarController.tabBar.hidden = YES;
        self.tabBarController.selectedIndex = DISCUSSIONS_TAB_INDEX;
    } else {
        // first check if the other guy already created a 1-on-1 discussion
        Account *account = [Account sharedInstance];
        NSString *node = [NSString stringWithFormat:@"%@-%@", buddy.email, account.email];
        NSString *discID = [node stringByReplacingOccurrencesOfString:@"@" withString:@"."];

        [self process1On1Discussion:discID withbuddy:buddy andShow:YES andCompletion:^(DiscussionViewController *thisController, BOOL finished) {
        }];
    }
}


- (void)processPushNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo == nil) {
        return;
    }
    [[XMPPManager sharedInstance] goOnline];

    NSString *notificationType = [userInfo objectForKey:@"type"];
    
    if ([notificationType isEqualToString:@"Task"] || [notificationType isEqualToString:@"Meeting"]) {
        [self processPushNotificationForTaskOrMeeting:userInfo];
    } else if ([notificationType isEqualToString:@"Disc"]) {
        [self processPushNotificationForDiscussion:userInfo];
    } else if (notificationType == nil) {
        NSString *alert = userInfo[@"aps"][@"alert"];
        NSRange range = [alert rangeOfString:@"invited"];
        if (range.location != NSNotFound)
            [self processPushNotificationForDiscussion:userInfo];
        else
            [self processPushNotificationForMessage:userInfo];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:[NSString stringWithFormat:@"Unknown notificationType: %@", notificationType]
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        NSLog(@"Unknown notificationType: %@", notificationType);
    }
}

- (void)processPushNotificationForDiscussion:(NSDictionary *)userInfo
{
    pushDiscussionID = [userInfo objectForKey:@"id"];
    if (pushDiscussionID == nil) {
        /*UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Discussion ID is missing for the discussion invite!!"
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];*/
        [self refreshDiscussions];
        return;
    }
    NSDictionary *dict = [userInfo objectForKey:@"aps"];
    NSString *titleWithDot = [[dict objectForKey:@"alert"] componentsSeparatedByString:@"discussion '"][1];
//    titleWithDot = [titleWithDot stringByReplacingOccurrencesOfString:@"'" withString:@""];
//    pushDiscussionTitle = [titleWithDot stringByReplacingOccurrencesOfString:@"." withString:@""];

    pushDiscussionTitle = [titleWithDot substringToIndex:[titleWithDot length] - 2];
    
    UIApplication *application = [UIApplication sharedApplication];
    if ( application.applicationState == UIApplicationStateActive ) {
        // app was already in the foreground
        discAlertView = [[UIAlertView alloc]
                                  initWithTitle:@"Invite Received"
                                  message:[NSString stringWithFormat:@"You have been invited to join the discussion %@. Do you want to join now?", pushDiscussionTitle]
                                  delegate:self cancelButtonTitle:@"No"
                                  otherButtonTitles:@"Yes", nil];
        [discAlertView show];
    } else {
        
        // app was just brought from background due to push notification
        Discussion *thisDiscussion = [Discussion discussionWithID:pushDiscussionID title:pushDiscussionTitle buddyList:nil];
        [TimestampsManager updateForDiscussion:thisDiscussion.discussionID withDate:[NSDate date]];
        //[discussions addObject:newdiscussion];
        DiscussionViewController *thisController = [self addDiscussionCtlr:thisDiscussion show:YES];
        
        thisController.lastUpdatedTimeFromApi = [NSDate date];
    }
}

- (void)processPushNotificationForMessage:(NSDictionary *)userInfo
{
    /* NSString *pushDiscussionJID = [userInfo objectForKey:@"jid"];
    if (pushDiscussionJID == nil) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Discussion JID is missing for the message!!"
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        return;
    } */
    
    NSString *alert = userInfo[@"aps"][@"alert"];
    NSArray *components = [alert componentsSeparatedByString:@":"];
    NSString *title = components[0];
    rememberedDiscussCtlr = nil;
    for (DiscussionViewController *openDiscussCtlr in discussionCtlrs) {
        // Group chat messages come from the room JID
        if ([openDiscussCtlr.discussion.title isEqualToString:title]) {
            rememberedDiscussCtlr = openDiscussCtlr;
            break;
        }
    }
    
    UIApplication *application = [UIApplication sharedApplication];
    if ( application.applicationState == UIApplicationStateActive ) {
        // app was already in the foreground
        /*msgAlertView = [[UIAlertView alloc]
                                  initWithTitle:@"Message Received"
                                  message:[NSString stringWithFormat:@"New message received for the discussion \"%@\". Would you like to view the discussion?", title]
                                  delegate:self cancelButtonTitle:@"No"
                                  otherButtonTitles:@"Yes", nil];
        [msgAlertView show]; */
        if (rememberedDiscussCtlr == nil) {
            [self create1on1DiscussionUsingTitle:title];
        } else {
            rememberedDiscussCtlr.unreadMessagesCount++;
        }
        return;
    }
    
    if (rememberedDiscussCtlr == nil) {
        [self create1on1DiscussionUsingTitle:title];
        // User may not have clicked on the discussion invite but a later msg that was sent to the discussion.
        /*NSLog(@"discussCtlr not found for %@, adding...", pushDiscussionJID);
        NSArray *components = [pushDiscussionJID componentsSeparatedByString:@"."];
        NSString *discussionId = components[0];
        id<APIAccessClient> endpoint =
        (id<APIAccessClient>)[[APIManager
                               sharedInstanceWithClientProtocol:
                               @protocol(APIAccessClient)] client];
        
        endpoint.successJSON = ^(NSURLRequest *request,
                                 id responseJSON){
            NSDictionary *responseDict = (NSDictionary *)responseJSON;
            NSDictionary *infoDict = [responseDict objectForKey:@"discussion_info"];
            NSString *discussionTitle = [infoDict objectForKey:@"title"];
            Discussion *discussion = [Discussion discussionWithID:discussionId title:discussionTitle buddyList:nil];
            [discussions addObject:discussion];
            [self addDiscussionCtlr:discussion show:YES];
        };
        endpoint.failureJSON = ^(NSURLRequest *request,
                                 id responseJSON){
        };
        
        [endpoint getDiscussion:discussionId];*/
    } else {
//        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
//        NSDate* currentDate = [NSDate date];
//        [standardUserDefaults setObject:[Account convertLocalToGmtTimeZonePrecise:currentDate] forKey:@"LAST_UPDATED_DISCUSSIONS_CALL"];
//        [standardUserDefaults synchronize];

        [TimestampsManager updateForDiscussion:rememberedDiscussCtlr.discussion.discussionID withDate:[NSDate date]];
        
        [self.navigationController.topViewController.view endEditing:YES];
        [self.navigationController popToRootViewControllerAnimated:NO];
        [self.navigationController setViewControllers:[NSArray arrayWithObjects:self, rememberedDiscussCtlr, nil] animated:NO];
        self.tabBarController.tabBar.hidden = YES;
        self.tabBarController.selectedIndex = DISCUSSIONS_TAB_INDEX;
    }
}


// Case: Discussion invite or message received while within the app
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.cancelButtonIndex == buttonIndex && alertView != discAlertView) {
        return;
    }
    if (alertView == discAlertView) {
        
        rememberedDiscussCtlr = nil;
        for (DiscussionViewController *openDiscussCtlr in discussionCtlrs) {
            // Group chat messages come from the room JID
            if ([openDiscussCtlr.discussion.title isEqualToString:pushDiscussionTitle]) {
                rememberedDiscussCtlr = openDiscussCtlr;
                break;
            }
        }
//        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
//        [standardUserDefaults setObject:[Account convertLocalToGmtTimeZonePrecise:[NSDate date]] forKey:@"LAST_UPDATED_DISCUSSIONS_CALL"];
//        [standardUserDefaults synchronize];

        [TimestampsManager updateForDiscussion:pushDiscussionID withDate:[NSDate date]];

        if (nil == rememberedDiscussCtlr) {
            Discussion *thisDiscussion = [Discussion discussionWithID:pushDiscussionID title:pushDiscussionTitle buddyList:nil];
            if(alertView.cancelButtonIndex == buttonIndex) {
                DiscussionViewController *thisController = [self addDiscussionCtlr:thisDiscussion show:NO];
                thisController.lastUpdatedTimeFromApi = [NSDate date];
                [thisDiscussion joinDiscussion];
            } else {
                DiscussionViewController *thisController = [self addDiscussionCtlr:thisDiscussion show:YES];
                thisController.lastUpdatedTimeFromApi = [NSDate date];
            }
        } else {
            if(alertView.cancelButtonIndex != buttonIndex) {
                [self.navigationController.topViewController.view endEditing:YES];
                [self.navigationController popToRootViewControllerAnimated:NO];
                [self.navigationController setViewControllers:[NSArray arrayWithObjects:self, rememberedDiscussCtlr, nil] animated:NO];
                self.tabBarController.tabBar.hidden = YES;
                self.tabBarController.selectedIndex = DISCUSSIONS_TAB_INDEX;
    //            [self addDiscussionCtlr:rememberedDiscussCtlr.discussion show:YES];
            }
        }
        
    } else if (alertView == msgAlertView) {
        [self.navigationController.topViewController.view endEditing:YES];
        [self.navigationController popToRootViewControllerAnimated:NO];
        [self.navigationController setViewControllers:[NSArray arrayWithObjects:self, rememberedDiscussCtlr, nil] animated:NO];
        self.tabBarController.tabBar.hidden = YES;
        self.tabBarController.selectedIndex = DISCUSSIONS_TAB_INDEX;
    }
}

- (void)processPushNotificationForTaskOrMeeting:(NSDictionary *)userInfo
{
    NSString *notificationId = userInfo[@"id"];
    NSString *type = userInfo[@"type"];
    NSDictionary *dict = userInfo[@"aps"];
    NSString *name = [dict[@"alert"] componentsSeparatedByString:@" has"][0];
    
    delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    // do create
    id<APIAccessClient> discussionsEndpoint =
    (id<APIAccessClient>)[[APIManager
                                 sharedInstanceWithClientProtocol:
                                 @protocol(APIAccessClient)] client];
    
    discussionsEndpoint.successJSON = ^(NSURLRequest *request,
                                        id responseJSON){
        NSDictionary *jsonDict = responseJSON[@"category_details"];
        UIApplication *application = [UIApplication sharedApplication];
        if ( application.applicationState == UIApplicationStateActive || application.applicationState == UIApplicationStateBackground || application.applicationState == UIApplicationStateInactive ) {
            
            //Update To-Do badge value
            Account *account = [Account sharedInstance];
            if ([type isEqualToString:@"Task"]) {
                int taskCount = [Account getTaskCount];
                [Account setTaskCount:taskCount + 1];
                account.badgeTask.value = [Account getTaskCount];
            } else {
                int meetingInviteCount = [Account getMeetingInviteCount];
                [Account setMeetingInviteCount:meetingInviteCount + 1];
                account.badgeMeetingInvite.value = [Account getMeetingInviteCount];
            }
            
            NSString *toDoCountStr = [Account getCategoriesCount];
            int toDoCount = [toDoCountStr intValue];
            
            [Account setCategoriesCount:[NSString stringWithFormat:@"%d", toDoCount + 1]];
            
            [[[[[self tabBarController] tabBar] items] objectAtIndex:2] setBadgeValue:[Account getCategoriesCount]];
            
            UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
            
            [UIView animateWithDuration:0.5 animations:^(void) {
                rootViewController.view.alpha = 0.5;
            }];
            
            UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Discussion" bundle:nil];
            
            DiscussionNotificationViewController *discussNotificationController = [storyBoard instantiateViewControllerWithIdentifier:@"DiscussionNotificationController"];
            
            NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:jsonDict, @"jsonData", notificationId, @"notificationId", name, @"senderName", type, @"notificationType", nil];
            [[Account sharedInstance].notificationsHistory addObject:dict];
            
            discussNotificationController.view.backgroundColor = [UIColor clearColor];
            if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
                rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
            } else {
                rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
                discussNotificationController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            }
            
            [rootViewController presentViewController:discussNotificationController animated:YES completion:nil];
            
            [delegate hideActivityIndicator];
        }
    };
    discussionsEndpoint.failureJSON = ^(NSURLRequest *request,
                                        id responseJSON){
        [delegate hideActivityIndicator];
        /* UIAlertView *failureAlert = [[UIAlertView alloc]
                                     initWithTitle:@""
                                     message:responseJSON[@"error"]
                                     delegate:self cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil];
        [failureAlert setTag:KFailureAlertTag];
        [failureAlert show]; */
        
        NSLog(@"error message %@ and json %@", responseJSON[@"error"], responseJSON);
    };
    if ([type isEqualToString:@"Task"]) {
        [discussionsEndpoint getCategoryTask:notificationId];
    } else {
        [discussionsEndpoint getCategoryMeeting:notificationId];
    }
}


- (DiscussionViewController *)addDiscussionCtlr:(Discussion *)discussion show:(BOOL)showFlag
{
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Discussion" bundle:nil];
    DiscussionViewController *discussCtlr = [storyBoard instantiateViewControllerWithIdentifier:@"DiscussionViewController"];
    [discussCtlr initWithDiscussion:discussion welcomeMsg:discussion.welcomeMsg];
    [discussionCtlrs addObject:discussCtlr];
    
    //[discussionsList reloadData];
    
    if (showFlag) {
        [discussion joinDiscussion];
        [self.navigationController.topViewController.view endEditing:YES];
        [self.navigationController popToRootViewControllerAnimated:NO];
        [self.navigationController setViewControllers:[NSArray arrayWithObjects:self, discussCtlr, nil] animated:NO];
        self.tabBarController.tabBar.hidden = YES;
        self.tabBarController.selectedIndex = DISCUSSIONS_TAB_INDEX;
    }
    return discussCtlr;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private Methods
- (void)create1on1DiscussionUsingTitle:(NSString *)title
{
    Account *account = [Account sharedInstance];
    Buddy *buddy = [account.buddyList findBuddyForName:title];
    if (buddy) {
        // 1-on-1
        Account *account = [Account sharedInstance];
        NSString *node = [NSString stringWithFormat:@"%@-%@", buddy.email, account.email];
        NSString *discID = [node stringByReplacingOccurrencesOfString:@"@" withString:@"."];
        
        Discussion *discussion = [Discussion discussionWithID:discID buddy:buddy create:NO];
        rememberedDiscussCtlr = [self addDiscussionCtlr:discussion show:YES];
        rememberedDiscussCtlr.lastUpdatedTimeFromApi = [NSDate date];
    } else {
        [self refreshDiscussions];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UITableView
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    return [discussionCtlrs count];
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"discussionsCell"];
    DiscussionViewController *discussCtlr = (DiscussionViewController *)discussionCtlrs[indexPath.row];

    UIImageView *imgview = (UIImageView *)[cell viewWithTag:100];
    UIImageView *unreadimgview = (UIImageView *)[cell viewWithTag:400];
    UILabel *title = (UILabel *)[cell viewWithTag:200];

    imgview.layer.cornerRadius = imgview.frame.size.width/2;
    imgview.layer.masksToBounds = YES;

    if (discussCtlr.discussion.type == TYPE_1ON1) {
        imgview.layer.borderColor = DEFAULT_CGCOLOR;
        
        UIImage *photo = discussCtlr.discussion.buddy.photo;
        if (photo) {
            imgview.image = photo;
            imgview.layer.borderWidth = 1;
        } else {
            imgview.layer.borderWidth = 2;

            CRNInitialsImageView *crnImageView = [[CRNInitialsImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
            crnImageView.initialsBackgroundColor = [UIColor whiteColor];
            crnImageView.initialsTextColor = DEFAULT_UICOLOR;
            crnImageView.initialsFont = [UIFont fontWithName:@"HelveticaNeue" size:18];
            crnImageView.useCircle = TRUE;
            crnImageView.firstName = discussCtlr.discussion.buddy.firstName;
            crnImageView.lastName = discussCtlr.discussion.buddy.lastName;
            [crnImageView drawImage];
            imgview.image = crnImageView.image;
        }
        title.text = discussCtlr.discussion.buddy.displayName;
    } else {
        imgview.layer.borderWidth = 0;
        imgview.image = [UIImage imageNamed:@"Groups-Icon.png"];
        title.text = discussCtlr.discussion.title;
    }
    UITextView *lastMessage = (UITextView *)[cell viewWithTag:300];

    lastMessage.text = [discussCtlr getLastMessage];
    [lastMessage setFont:[UIFont fontWithName:@"Helvetica Neue" size:13]];
    [lastMessage setTextColor:[UIColor grayColor]];
    lastMessage.userInteractionEnabled = NO;
    
    NSInteger count = discussCtlr.unreadMessagesCount;
    if(count > 0) {
       // discussCtlr.hasUnreadMessages = YES;
    }
    //NSLog(@"row %d, count %d", indexPath.row, count);
    
//    MKNumberBadgeView *unreadMsgBadge = (MKNumberBadgeView *)[cell viewWithTag:11];
//    unreadMsgBadge.value = count;
    
    if(discussCtlr.hasUnreadMessages) {
        unreadimgview.hidden = NO;
    } else {
        unreadimgview.hidden = YES;
    }
    
    return cell;
}

- (void)tableView: (UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(pushAllowed) {
        pushAllowed = NO;
        DiscussionViewController *discussCtlr = (DiscussionViewController *)discussionCtlrs[indexPath.row];
        self.tabBarController.tabBar.hidden = YES;
        [self.navigationController pushViewController:discussCtlr animated:YES];
    } else {
        NSLog(@"Caught double touch");
    }

}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    DiscussionViewController *discussCtlr = (DiscussionViewController *)discussionCtlrs[indexPath.row];

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [discussionCtlrs removeObjectAtIndex:indexPath.row];

        [tableView reloadData];
        
        id<APIAccessClient> endpoint =
        (id<APIAccessClient>)[[APIManager
                               sharedInstanceWithClientProtocol:
                               @protocol(APIAccessClient)] client];
        
        endpoint.successJSON = ^(NSURLRequest *request,
                                 id responseJSON){
        };
        endpoint.failureJSON = ^(NSURLRequest *request,
                                 id responseJSON){
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:@""
                                      message:@"Unable to delete the discussion permanently because you are not the owner of this discussion."
                                      delegate:nil cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
            [alertView show];
        };
        
        [endpoint deleteDiscussion:discussCtlr.discussion.discussionID];
    }
}

- (void)messageReceived:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    Message *messageObj = [dict objectForKey:@"messageObj"];
    
    //NSLog(@"messageReceived: %@", messageObj.message);
    Account *account = [Account sharedInstance];
    if ((messageObj.sender.displayName == nil) ||
        ([messageObj.sender.displayName isEqualToString:@""]) ||
        ([messageObj.sender.displayName isEqualToString:[account getName]]))
        return;
    
    DiscussionViewController *discussCtlr = nil;
    int index = 0;
    for (DiscussionViewController *openDiscussCtlr in discussionCtlrs) {
        // Group chat messages come from the room JID
        //NSLog(@"%@, %@", openDiscussCtlr.discussion.discussionJID, openDiscussCtlr.discussion.title);
        
        if ([openDiscussCtlr.discussion.discussionJID isEqualToString:messageObj.discussionJID]) {
            discussCtlr = openDiscussCtlr;
            break;
        }
        index++;
    }
    
    if (discussCtlr) {
//        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
//        NSDate* currentDate = [NSDate date];
//        [standardUserDefaults setObject:[Account convertLocalToGmtTimeZonePrecise:currentDate] forKey:@"LAST_UPDATED_DISCUSSIONS_CALL"];
//        [standardUserDefaults synchronize];
        [TimestampsManager updateForDiscussion:discussCtlr.discussion.discussionID withDate:[NSDate date]];

        [discussCtlr messageReceived:messageObj];
        [discussionsList reloadData];
    } else {
        // 1-on-1 case, receiving side, just join the discussion
        /* Discussion *discussion = [Discussion discussionWithBuddy:messageObj.sender create:NO];
        discussCtlr = [self addDiscussionCtlr:discussion show:YES];
        [discussCtlr messageReceived:messageObj]; */
    }
}

- (void)annotationPosted:(NSNotification *)notification
{
    NSDictionary* info = [notification userInfo];
    if(info == nil) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Annotation could not be posted"
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        [self dismissViewControllerAnimated:NO completion:nil];
        return;
    }
    NSString* imageName = [info objectForKey:@"postedImageName"];
    UIImage* image = [info objectForKey:@"postedImage"];

    NSLog(@"Posting annotation message for %@", imageName);

    DiscussionViewController *discussCtlr = (DiscussionViewController *)[self.navigationController topViewController];

    Message* messageObj = [Message outgoingAnnotationMessageWithName:imageName image:image];
    // do both local posting and send message to discussion
    [discussCtlr.discussion sendMessage:messageObj];
    [discussCtlr messageReceived:messageObj];
}


- (IBAction)editAction:(id)sender {
    if (![discussionsList isEditing]) {
        [discussionsList setEditing:YES];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(editAction:)];
        
    } else {
        [discussionsList setEditing:NO];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editAction:)];
    }
}
- (IBAction)statusAction:(id)sender {
    
    [UIView animateWithDuration:0.5 animations:^(void) {
        self.view.alpha = 0.5;
    }];
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Settings" bundle:nil];
    MyAvailabilityLightBoxViewController *myAvailabilityCtlr = [storyBoard instantiateViewControllerWithIdentifier:@"MyAvailabilityLightBoxViewController"];
    
    myAvailabilityCtlr.delegate = self;
    
    NSString *status = availabilityButton.accessibilityIdentifier;
    
    if ([status isEqualToString:@"Status-Available-Icon@2x.png"]) {
        myAvailabilityCtlr.existingStatus = 0;
    } else if ([status isEqualToString:@"Status-Away-Icon@2x.png"]) {
        myAvailabilityCtlr.existingStatus = 1;
    } else if ([status isEqualToString:@"Status-Busy-Icon@2x.png"]) {
        myAvailabilityCtlr.existingStatus = 2;
    } else { // Delete else statement after clean up the junk data on server side
        myAvailabilityCtlr.existingStatus = 0;
    }
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    myAvailabilityCtlr.view.backgroundColor = [UIColor clearColor];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
    } else {
        rootViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        myAvailabilityCtlr.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    }
    [self presentViewController:myAvailabilityCtlr animated:YES completion:nil];
}

-(void)returnSelectedIndexPath:(int)index
{
    if (index == 0) {
        [availabilityButton setImage:[UIImage imageNamed:@"Status-Available-Icon@2x.png"] forState:UIControlStateNormal];
        [availabilityButton setAccessibilityIdentifier:@"Status-Available-Icon@2x.png"];
    } else if (index == 1) {
        [availabilityButton setImage:[UIImage imageNamed:@"Status-Away-Icon@2x.png"] forState:UIControlStateNormal];
        [availabilityButton setAccessibilityIdentifier:@"Status-Away-Icon@2x.png"];
    } else {
        [availabilityButton setImage:[UIImage imageNamed:@"Status-Busy-Icon@2x.png"] forState:UIControlStateNormal];
        [availabilityButton setAccessibilityIdentifier:@"Status-Busy-Icon@2x.png"];
    }
}
- (void)getUserAvailability
{
    [delegate showActivityIndicator];
    
    // do create
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        NSString *status = responseJSON[@"availability_status"];
        if ([status isEqualToString:@"Available"]) {
            [availabilityButton setImage:[UIImage imageNamed:@"Status-Available-Icon@2x.png"] forState:UIControlStateNormal];
            [availabilityButton setAccessibilityIdentifier:@"Status-Available-Icon@2x.png"];
        } else if ([status isEqualToString:@"Away"]) {
            [availabilityButton setImage:[UIImage imageNamed:@"Status-Away-Icon@2x.png"] forState:UIControlStateNormal];
            [availabilityButton setAccessibilityIdentifier:@"Status-Away-Icon@2x.png"];
        } else if ([status isEqualToString:@"Busy"]) {
            [availabilityButton setImage:[UIImage imageNamed:@"Status-Busy-Icon@2x.png"] forState:UIControlStateNormal];
            [availabilityButton setAccessibilityIdentifier:@"Status-Busy-Icon@2x.png"];
        } else { // Delete else statement after clean up the junk data on server side
            [availabilityButton setImage:[UIImage imageNamed:@"Status-Available-Icon@2x.png"] forState:UIControlStateNormal];
            [availabilityButton setAccessibilityIdentifier:@"Status-Available-Icon@2x.png"];
        }
        [delegate hideActivityIndicator];
        
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
        NSLog(@"error message %@ and json %@", responseJSON[@"error"], responseJSON);
    };
    [endpoint getUserAvailability];
}

- (int)getTotalUnreadMessagesCount
{
    int unreadMsgCount = 0;
    for (DiscussionViewController *openDiscussCtlr in discussionCtlrs) {
        if (openDiscussCtlr.hasUnreadMessages)
            unreadMsgCount ++;
    }
    return unreadMsgCount;
}

- (void)deleteCategoryUsingDiscussionId:(NSString *)discussionId messageId:(NSString *)msgId andCategoryType:(int)categoryType
{
    BOOL stopLoop = NO;
    for (DiscussionViewController *discussCtlr in discussionCtlrs) {
        if ([discussCtlr.discussion.discussionID isEqualToString:discussionId]) {
            for (Message *message in discussCtlr.messages) {
                if ([message.messageId isEqualToString:msgId]) {
                    for (Categories *category in message.categoriesArray) {
                        if (category.categoryType == categoryType) {
                            [message.categoriesArray removeObject:category];
                            stopLoop = YES;
                            break;
                        }
                    }
                    if(stopLoop) {
                        break;
                    }
                }
            }
            if(stopLoop) {
                break;
            }
        }
    }
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
