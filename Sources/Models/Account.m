#import "AppConstants.h"
#import "Account.h"
#import "AppDelegate.h"
#import "UserCategories.h"
#import "DiscussionsListController.h"

static __strong Account *kSharedInstance = nil;
NSString *totalCategoriesCount;
int taskCount, meetingInviteCount;

@implementation Account

#pragma mark -
#pragma mark Singleton methods

-(id)init
{
    self = [super init];
    if (self) {
        self.deviceContactsImported = NO;
        self.buddyList = [[BuddyList alloc] init];
        [self.buddyList restoreBuddiesFromUserDefaults];
        self.s3Manager = [[S3Manager alloc] init];
        //self.photo = [UIImage imageNamed:@"No-Photo-Icon.png"];
        self.notificationsHistory = [[NSMutableArray alloc] init];
//        self.badgeToDoList = [[MKNumberBadgeView alloc] init];
        self.buddyLookupArray = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    return self;
}


+ (Account *)sharedInstance
{
    if (kSharedInstance == nil)
    {
        kSharedInstance = [[super allocWithZone:nil] init];
    }
    return kSharedInstance;
}

+ (void)replaceInstance:(Account *)instance
{
    kSharedInstance = instance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    if (kSharedInstance == nil) {
        kSharedInstance = [super allocWithZone:zone];
        return kSharedInstance;
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

#pragma mark -
#pragma mark Account

@synthesize email, password;

+ (BOOL) verifyEmail:(NSString*) emailString {
    NSString *regExPattern = @"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}$";
    NSRegularExpression *regEx = [[NSRegularExpression alloc] initWithPattern:regExPattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSUInteger regExMatches = [regEx numberOfMatchesInString:emailString options:0 range:NSMakeRange(0, [emailString length])];
    if (regExMatches == 0) {
        return NO;
    } else
        return YES;
}

+ (NSString *)emailToJid:(NSString *)email {
    NSString *emailmod = [email stringByReplacingOccurrencesOfString:@"@" withString:@"."];
    //return [emailmod stringByAppendingFormat:@"@%@", [[XMPPManager sharedInstance] getChatDomain]];
    return [emailmod stringByAppendingFormat:@"@%@", kChatServerName];
}

+ (NSString *)emailToBareJid:(NSString *)email {
    NSString *emailmod = [email stringByReplacingOccurrencesOfString:@"@" withString:@"."];
    //return [emailmod stringByAppendingFormat:@"@%@", [[XMPPManager sharedInstance] getChatDomain]];
    //return [emailmod stringByAppendingFormat:@"@%@", kChatServerName];
    return emailmod;
}

- (NSString *)getUUID
{
    NSString *emailmod = [self.email stringByReplacingOccurrencesOfString:@"@" withString:@"."];
    //return [emailmod stringByAppendingFormat:@"@%@", kHostDomain];
    return [emailmod stringByAppendingFormat:@"@%@", kChatServerName];
}

- (NSString *)getName
{
    return [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
}

- (Buddy *)getMyBuddy
{
    if (self.mybuddy == nil) {
        self.mybuddy = [Buddy buddyWithDisplayName:[self getName] email:self.email photo:self.photo isUser:YES];
    }
    return self.mybuddy;
}

- (void)getConfiguration:(BOOL)isSignUp
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    // get maximum no of user defined category
    id<APIAccessClient> discussionsEndpoint =
    (id<APIAccessClient>)[[APIManager
                                 sharedInstanceWithClientProtocol:
                                 @protocol(APIAccessClient)] client];
    
    discussionsEndpoint.successJSON = ^(NSURLRequest *request,
                                        id responseJSON){
        [delegate hideActivityIndicator];
        
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
//        int maxUserCategory = [[[responseJSON objectForKey:@"configuration"] objectForKey:@"number_of_UDCs"] intValue];
//        [standardUserDefaults setInteger:maxUserCategory forKey:@"MAX_UDC"];
        
        int categoryLimit = [[[responseJSON objectForKey:@"configuration"] objectForKey:@"categories_per_message"] intValue];
        [standardUserDefaults setInteger:categoryLimit forKey:@"CAT_LIMIT"];
        
        NSDictionary *planDetails = responseJSON[@"configuration"][@"plan_details"];
        
        int maxUserCategory = [planDetails[CATEGORIES_CONFIG] intValue];
        [standardUserDefaults setInteger:maxUserCategory forKey:@"MAX_UDC"];
        
        BOOL asana = [planDetails[ASANA_CONFIG] boolValue];
        [standardUserDefaults setBool:asana forKey:ASANA_CONFIG];
        
        BOOL salesforce = [planDetails[SALESFORCE_CONFIG] boolValue];
        [standardUserDefaults setBool:salesforce forKey:SALESFORCE_CONFIG];
        
        BOOL trello = [planDetails[TRELLO_CONFIG] boolValue];
        [standardUserDefaults setBool:trello forKey:TRELLO_CONFIG];
        
        BOOL zoho = [planDetails[ZOHO_CONFIG] boolValue];
        [standardUserDefaults setBool:zoho forKey:ZOHO_CONFIG];
        
        [standardUserDefaults synchronize];
        
        if (!isSignUp) {
            [self getAssignCategoryData];
        }
        
    };
    discussionsEndpoint.failureJSON = ^(NSURLRequest *request,
                                        id responseJSON){
        [delegate hideActivityIndicator];
        
        
        NSLog(@"error message %@", responseJSON);
    };
    [discussionsEndpoint getMaximumUDCValue];
}

-(void)getAssignCategoryData
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    // get user defined category data
    id<APIAccessClient> discussionsEndpoint =
    (id<APIAccessClient>)[[APIManager
                                 sharedInstanceWithClientProtocol:
                                 @protocol(APIAccessClient)] client];
    
    discussionsEndpoint.successJSON = ^(NSURLRequest *request,
                                        id responseJSON){
        [delegate hideActivityIndicator];
        
        UserCategories *userCategory = [UserCategories sharedManager];
        NSMutableArray *categoryArray = userCategory.categoryArray;
        
        NSArray *responseArray = [responseJSON objectForKey:@"user_defined_categories"];
        
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        int maxUserCategory = [standardUserDefaults integerForKey:@"MAX_UDC"];
        
        for (int i = 0; i < responseArray.count; i++) {
            if (i < maxUserCategory) {
                if (nil != [responseArray objectAtIndex:i]) {
                    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
                    
                    [dict setObject:[[responseArray objectAtIndex:i] objectForKey:@"name"] forKey:@"userDefinedCategory"];
                    [dict setObject:[[responseArray objectAtIndex:i] objectForKey:@"id"] forKey:@"categoryType"];
                    [dict setObject:[[responseArray objectAtIndex:i] objectForKey:@"colour"] forKey:@"color"];
                    [categoryArray insertObject:dict atIndex:i+4];
                }
            }
            
        }
    };
    discussionsEndpoint.failureJSON = ^(NSURLRequest *request,
                                        id responseJSON){
        [delegate hideActivityIndicator];
        
        
        NSLog(@"error message %@", responseJSON);
    };
    
    [discussionsEndpoint getUDCData];
}

- (void)getUserCategoriesCount
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    //[delegate showActivityIndicator];
    
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        
        int meetingInviteCount = [responseJSON[@"categories_count"][@"invites"] intValue];
        int taskCount = [responseJSON[@"categories_count"][@"tasks"] intValue];
        
        NSString *countStr = [NSString stringWithFormat:@"%d",meetingInviteCount + taskCount];
        
        [Account setCategoriesCount:countStr];
        [Account setTaskCount:taskCount];
        [Account setMeetingInviteCount:meetingInviteCount];
        
        Account *account = [Account sharedInstance];
        account.badgeTask.value = [Account getTaskCount];
        account.badgeMeetingInvite.value = [Account getMeetingInviteCount];
        
        [[[[[delegate tabBarController] tabBar] items] objectAtIndex:2] setBadgeValue:[Account getCategoriesCount]];
        
        [delegate hideActivityIndicator];
        
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
//        UIAlertView *failureAlert = [[UIAlertView alloc]
//                                     initWithTitle:@""
//                                     message:[responseJSON objectForKey:@"error"]
//                                     delegate:self cancelButtonTitle:@"OK"
//                                     otherButtonTitles:nil];
//        [failureAlert setTag:KFailureAlertTag];
//        [failureAlert show];
        
        NSLog(@"error message %@ and json %@", [responseJSON objectForKey:@"error"], responseJSON);
    };
    [endpoint getCategoriesCount];
}

+ (void)setCategoriesCount:(NSString *)count
{
    if ([count isEqualToString:@"0"]) {
        totalCategoriesCount = nil;
    } else {
        totalCategoriesCount = count;
    }
}

+ (NSString *)getCategoriesCount
{
    return totalCategoriesCount;
}

+ (void)setTaskCount:(int)count
{
    taskCount = count;
}

+ (int)getTaskCount
{
    return taskCount;
}

+ (void)setMeetingInviteCount:(int)count
{
    meetingInviteCount = count;
}

+ (int)getMeetingInviteCount
{
    return meetingInviteCount;
}

+ (NSDate *)convertGmtToLocalTimeZonePrecise:(NSString *)gmtString
{
    NSLog(@"gmtString=%@",gmtString);
    NSDateFormatter *dateFormatterForApiData = [[NSDateFormatter alloc] init];
    [dateFormatterForApiData setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
    
    NSDateFormatter *dateFormatterForLocalTimestamp = [[NSDateFormatter alloc] init];
    [dateFormatterForLocalTimestamp setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

    NSDate *gmtDate = [dateFormatterForApiData dateFromString:gmtString];

    NSDate *localDate;
    if(gmtDate) {
        NSLog (@"gmtDate=%@",gmtDate);
        return gmtDate;
        /*
        NSTimeInterval timeZoneOffset = [[NSTimeZone systemTimeZone] secondsFromGMTForDate:gmtDate];
        localDate = [gmtDate dateByAddingTimeInterval:timeZoneOffset];
        NSLog (@"localDate=%@",localDate);
         */
    } else {
        gmtDate = [dateFormatterForLocalTimestamp dateFromString:gmtString];
        NSLog (@"gmtDate=%@",gmtDate);
        return gmtDate;
        /*
        NSTimeInterval timeZoneOffset = [[NSTimeZone systemTimeZone] secondsFromGMTForDate:gmtDate];
        localDate = [gmtDate dateByAddingTimeInterval:timeZoneOffset];
        NSLog (@"localDate=%@",localDate);
         */
    }
    //return localDate;
}

+ (NSString *)convertLocalToGmtTimeZonePrecise:(NSDate *)localDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [dateFormatter setTimeZone:gmt];
    
    return [dateFormatter stringFromDate:localDate];
}

+ (NSString *)convertGmtToLocalTimeZone:(NSString *)gmtString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE, MM/dd/yy, h:mm a"];

    NSDate *localDate = [dateFormatter dateFromString:gmtString];
    NSTimeInterval timeZoneOffset = [[NSTimeZone systemTimeZone] secondsFromGMTForDate:localDate];
    NSDate *gmtDate = [localDate dateByAddingTimeInterval:timeZoneOffset];

    return [dateFormatter stringFromDate:gmtDate];
}

+ (NSString *)convertLocalToGmtTimeZone:(NSDate *)localDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE, MM/dd/yy, h:mm a"];
    
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [dateFormatter setTimeZone:gmt];
    
    return [dateFormatter stringFromDate:localDate];
}

- (void)setDiscussionsBadgeValue
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UITabBarController *tabBarCtrl = [delegate tabBarController];
    if (nil != tabBarCtrl && tabBarCtrl.viewControllers.count > 0) {
        
        UINavigationController *navCtlr = tabBarCtrl.viewControllers[0];
        
        if (nil != navCtlr) {
            
            if (navCtlr.childViewControllers.count > 0) {
                
                DiscussionsListController * discussionListCtrl = (DiscussionsListController *)navCtlr.childViewControllers[0];
                
                if (nil != discussionListCtrl) {
                    
                    int unreadMsgCount = [discussionListCtrl getTotalUnreadMessagesCount];
                    
                    if (unreadMsgCount >= 1) {
                        
                        NSString *badgeValue = [NSString stringWithFormat:@"%d",unreadMsgCount];
                        
                        [[[[tabBarCtrl tabBar] items] objectAtIndex:0] setBadgeValue:badgeValue];
                    } else {
                        
                        [[[[tabBarCtrl tabBar] items] objectAtIndex:0] setBadgeValue:nil];
                    }
                }
                
            }
            
        }
        
    }
}
@end
