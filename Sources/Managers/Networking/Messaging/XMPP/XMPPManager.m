#import <dispatch/dispatch.h>
#import <UIKit/UIKit.h>

#import "XMPPFramework.h"
#import "XMPPRosterCoreDataStorage.h"
#import "DDLog.h"
#import "DDTTYLogger.h"

#import "AppConstants.h"
#import "Account.h"
#import "Buddy.h"
#import "BuddyList.h"
#import "Message.h"
#import "AccountManager.h"
#import "MessageLogManager.h"
#import "XMPPManager.h"
#import "AppDelegate.h"
//#import "SharedUsersInfo.h"
#import "XMPPAutoPing.h"

// Log levels: off, error, warn, info, verbose
#if 1
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_WARN;
#endif

static const int MAX_RETRIES_PER_NODE = 5;
static const int DISCONNECT_TIMER_INTERVAL_START = 2;

static __strong XMPPManager *kSharedManager = nil;

@interface XMPPManager()
@property (atomic, strong) Account *account;
@property (atomic, strong) BuddyList *buddyList;
@property (atomic, strong) id<MessageLogStorage> storage;
@property (nonatomic, strong) XMPPStream *xmppStream;
@property (nonatomic, strong) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong) XMPPAutoPing *xmppAutoPing;
@property (nonatomic, assign) BOOL isXmppConnected;
@property (nonatomic, copy) NSString *password;
@property (nonatomic) int authFailCount, disconnectCount;

- (void)setupStream;
- (void)teardownStream;
- (BOOL)connectWithJID:(NSString *)JID password:(NSString *)password;
- (void)goOffline;
- (void)failedToConnect;
- (void)applicationWillResignActiveNotification:(NSNotification *)notification;
@end

@implementation XMPPManager

#pragma mark -
#pragma mark NSObject

- (id)init
{
    if ((self = [super init]) != nil) {
        // Configure logging framework
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
        // Setup the XMPP stream
        [self setupStream];
        self.buddyList = [[BuddyList alloc] init];
        self.authFailCount = 0;
        self.disconnectCount = 0;
        self.isNetworkReachable = YES;
        // conf notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(applicationWillResignActiveNotification:)
            name:UIApplicationWillResignActiveNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillResignActiveNotification:)
                                                     name:@"reloaded" object:nil];

    }
    return self;
}

- (void)dealloc
{
    [self teardownStream];
    [[NSNotificationCenter defaultCenter] removeObserver:self
        name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"reloaded" object:nil];

}

#pragma mark -
#pragma mark Singleton methods

+ (XMPPManager *)sharedInstance
{
    @synchronized (self) {
        if (kSharedManager == nil)
            kSharedManager = [[super allocWithZone:nil] init];
    }
    return kSharedManager;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized (self) {
        if (kSharedManager == nil)
            kSharedManager = [super allocWithZone:zone];
        return kSharedManager;
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (void)registerOrLogin
{
    self.authFailCount = 0;
    
    Account* account =  [Account sharedInstance];
    NSNumber *pin = account.chatPin;
    if(pin == nil) {
        pin = account.password;
    }
    NSLog(@"Connecting with JID = %@, Password = %@",[account getUUID], pin);
    [self disconnect];
    [self connectWithJID:[account getUUID] password:[pin stringValue]];
}


- (BOOL)goOnline
{
    // This returns true even if the socket is not alive
    if (![self.xmppStream isConnected]) {
        return NO;
    }
    // type="available" is implicit
    XMPPPresence *presence = [XMPPPresence presence];
    XMPPElementReceipt *receipt;
    [self.xmppStream sendElement:presence andGetReceipt:&receipt];
    if (![receipt wait:2]) {
        return NO;
    }
    return YES;
}

- (void)goOffline
{
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    
    [self.xmppStream sendElement:presence];
}

- (void)sendMessage:(Message *)messageObj
{
    NSString *messageStr = messageObj.message;
    
    if ([messageStr length] > 0)
    {
        NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
        
        [body setStringValue:messageStr];
        
        NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
        
        [message addAttributeWithName:@"subject" stringValue:@"subjectName"];
        
        Account *account = [Account sharedInstance];
        NSString *name = [NSString stringWithFormat:@"%@ %@", account.firstName, account.lastName];
        [message addAttributeWithName:@"senderName" stringValue:name];
        
        [message addAttributeWithName:@"type" stringValue:@"chat"];
        [message addAttributeWithName:@"to" stringValue:messageObj.sender.jabberid];
        [message addAttributeWithName:@"id" stringValue:messageObj.messageId];
        
        NSXMLElement * receiptRequest =
        [NSXMLElement elementWithName:@"request"];
        
        [receiptRequest addAttributeWithName:@"xmlns"
                                 stringValue:@"urn:xmpp:receipts"];
        [message addChild:receiptRequest];
        [message addChild:body];
        [self.xmppStream sendElement:message];
        [self.storage addMessage:messageObj];
    }
}

- (BOOL)changePassword:(NSString *)JIDStr password:(NSString *)thePassword
{
//    if (JIDStr == nil || thePassword == nil) {
//        // TODO should raise an exception here or err
//        NSLog(@"JID and password must be set before connecting!");
//        return NO;
//    }
//    
//    Account *account = [Account sharedInstance];
//    account.email = [standardUserDefaults objectForKey:@"USEREMAIL"];
//    account.jid = JIDStr;
//    account.password = [NSNumber numberWithInteger:[thePassword integerValue]];
//    account.serverToken = [standardUserDefaults objectForKey:@"SERVERTOKEN"];
    
//    [[XMPPManager sharedInstance] registerOrLogin];

//    self.xmppStream.myJID = [XMPPJID jidWithString:JIDStr resource:nil];
//    NSError *error = [[NSError alloc] init];
//
//    if (![self.xmppStream registerWithPassword:thePassword error:&error])
//    {
//        DDLogError(@"Error changing password: %@", error);
//        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Change passwd failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//        [alertView show];
//    }
    return YES;
}

- (void)disconnect
{
    [self goOffline];
    [self.xmppStream disconnect];
    /*
    [self.xmppRosterStorage
        clearAllUsersAndResourcesForXMPPStream:self.xmppStream];
    */
}

#pragma mark -
#pragma mark <XMPPStreamDelegate>

/**
 * This method is called after registration of a new user has successfully finished.
 * If registration fails for some reason, the xmppStream:didNotRegister: method will be called instead.
 **/
- (void)xmppStreamDidRegister:(XMPPStream *)sender
{
    NSLog(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    NSError *error = nil;
    
    if (![self.xmppStream authenticateWithPassword:self.password error:&error]) {
        DDLogError(@"Error authenticating: %@", error);
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Authentication failed after new registration" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        
        self.isXmppConnected = NO;
        return;
    } else {
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        [standardUserDefaults setObject:@"YES" forKey:@"XMPP_REG_DONE"];
        [standardUserDefaults synchronize];
        self.isXmppConnected = YES;
    }
    //[self goOnline];
}

/**
 * This method is called if registration fails.
 **/
- (void)xmppStream:(XMPPStream *)sender didNotRegister:(NSXMLElement *)error
{
    NSLog(@"%@: %@", THIS_FILE, THIS_METHOD);
/*  UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"XMPP Registration failed, user may be registered already." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];*/
    
    // let's try authenticating anyway
    if (![self.xmppStream authenticateWithPassword:self.password error:nil]) {
        DDLogError(@"Error authenticating: %@", error);
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Authentication failed after new registration" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        
        self.isXmppConnected = NO;
        return;
    } else {
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        [standardUserDefaults setObject:@"YES" forKey:@"XMPP_REG_DONE"];
        [standardUserDefaults synchronize];
        self.isXmppConnected = YES;
    }
}


- (void)xmppStream:(XMPPStream *)sender
  socketDidConnect:(GCDAsyncSocket *)socket
{
    //DDLogVerbose(@"%@: %@, %@, %@", THIS_FILE, THIS_METHOD, sender, socket);
    NSLog(@"socketDidConnect");
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    self.disconnectCount = 0;
    
    NSError *error = nil;

    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSString *status = [standardUserDefaults objectForKey:@"XMPP_REG_DONE"];
    if (![status isEqual:@"YES"]) {
        NSLog(@"Trying to register with password %@", self.password);
        if (![self.xmppStream registerWithPassword:self.password error:&error])
        {
            DDLogError(@"Error registering: %@", error);
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Registration failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
            
            self.isXmppConnected = NO;
            return;
        }

    } else if (![self.xmppStream authenticateWithPassword:self.password error:&error]) {
        DDLogError(@"Error authenticating: %@", error);
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Authentication error" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];

        self.isXmppConnected = NO;
        return;
    } else self.isXmppConnected = YES;
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [self goOnline];
    self.isXmppAuthenticated = YES;
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.isXMPPAuthenticated = YES;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kXMPPAuthenticatedNotification
                                                        object:self userInfo:nil];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)xmlerror
{
    NSError *error = nil;

    DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, xmlerror);
    [self failedToConnect];
    self.authFailCount++;
    
    if (self.authFailCount == 50) {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Unable to authenticate with Chat server. Please close and re-open the app." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        self.isXmppAuthenticated = NO;
    } else if (![self.xmppStream authenticateWithPassword:self.password error:&error]) {
        DDLogError(@"Error authenticating: %@", error);
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Authentication error" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return;
    }

}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    if ([message isMessageWithBody])
    {
        //DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, message);

        // Parse the message
        NSString *body = [[message elementForName:@"body"] stringValue];
        NSString *senderemail = [[message attributeForName:@"senderemail"] stringValue];
        NSString *sendername = [[message attributeForName:@"sendername"] stringValue];
        NSString *msgId = [[message attributeForName:@"id"] stringValue];
        NSString *jid = [[message from] bare];
        
        // room echoes our messages, skip them
        Account *account = [Account sharedInstance];
        if (([senderemail isEqualToString:account.email]) ||
             (senderemail == nil)) {
            // ignore echo messages sent by us or room announcements
            return;
        }
        Buddy *buddy = [account.buddyList findBuddyForEmail:senderemail];
        if (buddy == nil) {
            NSLog(@"Buddy not found!! adding...");
            buddy = [Buddy buddyWithDisplayName:sendername email:senderemail profile_pic:nil isUser:YES];
            [account.buddyList addBuddy:buddy];
            [account.buddyList saveBuddiesToUserDefaults];
        }
        Message *incomingMessage = [Message incomingMessage:body withId:msgId from:buddy];
        incomingMessage.discussionJID = jid;
        
        //[buddy receiveMessage:incomingMessage];
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kMessageReceivedNotification
         object:self userInfo:@{@"messageObj": incomingMessage}];

        /*[self.storage addMessage:incomingMessage];
        
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"updateMessageBadgeCount"
         object:self userInfo:nil];*/

    }
}

- (void)xmppStream:(XMPPStream *)sender
    didReceivePresence:(XMPPPresence *)presence
{
/*
    DDLogVerbose(@"%@: %@ - %@\nType: %@\nShow: %@\nStatus: %@", THIS_FILE,
                 
                 THIS_METHOD, [presence from], [presence type], [presence show],
                 
                 [presence status]);*/
    
    if ([presence from] == nil)
        return;
    
    NSString *presenceType = [presence type]; // online/offline
    
    NSString *myUsername = [[sender myJID] user];
    
    NSString *presenceFromUser = [[presence from] user];
    
    BOOL isOnline = NO;
    
    if (![presenceFromUser isEqualToString:myUsername]) {
        
        if ([presenceType isEqualToString:@"available"])
        {
            isOnline = YES;
        }
        else if ([presenceType isEqualToString:@"unavailable"])
        {
            isOnline = NO;
        }
/*
        NSDictionary* userDict = [NSDictionary dictionaryWithObjectsAndKeys:[[presence from] bare],@"user",[NSNumber numberWithBool:isOnline],@"isOnline", nil];
       [[SharedUsersInfo sharedManager] addUserForOnlineStatus:userDict];*/
        
    }
/*
    [[NSNotificationCenter defaultCenter]
     
     postNotificationName:kStatusUpdateNotification
     
     object:self userInfo:@{@"user": [[presence from] bare]}];*/
}


- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kXMPPDisconnectedNotification
                                                        object:self userInfo:nil];

    NSLog(@"%@: %@ Error %@", THIS_FILE, THIS_METHOD, error);
    self.disconnectCount++;
    if (!self.isXmppConnected)
    {
        DDLogError(@"Unable to connect to server. Check xmppStream.hostName");
        [self failedToConnect];
    }
    NSLog(@"Error code=%ld", error.code);
    
    [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(handleDisconnectTimer:) userInfo:@{@"primary" : @YES} repeats:NO];
    //if (error.code == NS_ERROR_CONNECTION_REFUSED)
}

- (void)handleDisconnectTimer:(NSTimer*)timer
{
        // Connect to the other server.
        Account* account =  [Account sharedInstance];
        NSNumber *pin = account.chatPin;
        if(pin == nil) {
            pin = account.password;
        }
        
        if ([self.xmppStream.hostName isEqualToString:kHostDomain])
        {
            // If network interface has failed, then don't try to switch servers.
            // try primary again, then secondary.
            if (self.disconnectCount <= MAX_RETRIES_PER_NODE || (self.isNetworkReachable == NO))
                [self connectWithJID:[account getUUID] password:[pin stringValue]];
            else
                [self connectWithJIDToSecondary:[account getUUID] password:[pin stringValue]];
        }
        else {
            // try secondary again, then primary.
            if (self.disconnectCount <= MAX_RETRIES_PER_NODE|| (self.isNetworkReachable == NO))
                [self connectWithJIDToSecondary:[account getUUID] password:[pin stringValue]];
            else
                [self connectWithJID:[account getUUID] password:[pin stringValue]];
        }
}

/*
 ************** Room related methods *****************
 */

- (XMPPRoom *)createRoomWithJID:(NSString *)jidstr withSubject:(NSString *)subject memberList:(BuddyList *)list
{
    XMPPRoomMemoryStorage * _roomMemory = [[XMPPRoomMemoryStorage alloc] init];
    
    XMPPJID * roomJID = [XMPPJID jidWithString:jidstr];
    XMPPRoom* xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:_roomMemory
                                                           jid:roomJID
                                                 dispatchQueue:dispatch_get_main_queue()];
    [xmppRoom activate:self.xmppStream];
    [xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    Account *account = [Account sharedInstance];
    [xmppRoom joinRoomUsingNickname:[account getName] history:nil password:nil];
    if (subject) {
        [xmppRoom changeRoomSubject:subject];
    }
    
    [xmppRoom fetchConfigurationForm];

    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:1];
    
    for (Buddy *buddy in list.allBuddies) {
        XMPPJID *memberJID = [XMPPJID jidWithString:[Account emailToJid:buddy.email]];
        
        NSXMLElement *item = [XMPPRoom itemWithAffiliation:@"member" jid:memberJID];
        [items addObject:item];
    }
    
    [xmppRoom editRoomPrivileges:items];
    return xmppRoom;
}

- (XMPPRoom *)joinRoomWithJID:(NSString *)jidstr
{
    NSLog(@"Joining room with JID %@", jidstr);
    XMPPRoomMemoryStorage * _roomMemory = [[XMPPRoomMemoryStorage alloc] init];
    Account *account = [Account sharedInstance];
    
    XMPPJID * roomJID = [XMPPJID jidWithString:jidstr];
    XMPPRoom* xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:_roomMemory
                                                           jid:roomJID
                                                 dispatchQueue:dispatch_get_main_queue()];
    [xmppRoom activate:self.xmppStream];
    [xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];

    [xmppRoom joinRoomUsingNickname:[account getName] history:nil password:nil];
    //[xmppRoom fetchConfigurationForm];
    return xmppRoom;
}

- (void)leaveRoom:(XMPPRoom *)xmppRoom
{
    [xmppRoom leaveRoom];
}

- (void)updateRoomMembersForRoom:(XMPPRoom *)xmppRoom memberList:(NSMutableArray *)list
{
    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:1];
    
    for (NSString *email in list) {
        XMPPJID *memberJID = [XMPPJID jidWithString:[Account emailToJid:email]];
        
        NSXMLElement *item = [XMPPRoom itemWithAffiliation:@"member" jid:memberJID];
        [items addObject:item];
    }
    
    [xmppRoom editRoomPrivileges:items];
}

- (void)sendMessageToRoom:(NSString *)jidstr message:(Message *)messageObj
{
    NSString *messageStr = messageObj.message;
    
    if ([messageStr length] > 0)
    {
        NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
        
        [body setStringValue:messageStr];
        
        NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
        
        
        Account *account = [Account sharedInstance];

        [message addAttributeWithName:@"type" stringValue:@"groupchat"];
        [message addAttributeWithName:@"to" stringValue:jidstr];
        [message addAttributeWithName:@"id" stringValue:messageObj.messageId];
        [message addAttributeWithName:@"senderemail" stringValue:account.email];
        [message addAttributeWithName:@"sendername" stringValue:[account getName]];

        [message addChild:body];
        
        /*NSXMLElement * receiptRequest =
            [NSXMLElement elementWithName:@"request"];
        
        [receiptRequest addAttributeWithName:@"xmlns"
                                 stringValue:@"urn:xmpp:receipts"];
        [message addChild:receiptRequest];*/
        
        XMPPElementReceipt *receipt;
        [self.xmppStream sendElement:message andGetReceipt:&receipt];

        //[self.storage addMessage:messageObj];
    }
}

- (void)xmppRoomDidCreate:(XMPPRoom *)sender {
    DDLogVerbose(@"%@: %@ -> %@", THIS_FILE, THIS_METHOD, sender.roomSubject);
}

// Also called for newly created room
- (void)xmppRoomDidJoin:(XMPPRoom *)sender {
    DDLogVerbose(@"%@: %@ -> %@,%@", THIS_FILE, THIS_METHOD, sender.roomJID, sender.roomSubject);
    
    NSDictionary *roomInfo = [NSDictionary dictionaryWithObject:sender forKey:@"room"];
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kRoomJoinedNotification object:self userInfo:roomInfo];
}

- (void)xmppRoom:(XMPPRoom *)sender didEditPrivileges:(XMPPIQ *)iqResult {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}
- (void)xmppRoom:(XMPPRoom *)sender didNotEditPrivileges:(XMPPIQ *)iqError {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    DDLogVerbose(@"Error: %@", iqError);
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchConfigurationForm:(NSXMLElement *)configForm {
    DDLogVerbose(@"%@: %@ -> %@", THIS_FILE, THIS_METHOD, sender.roomSubject);

    NSXMLElement *newConfig = [configForm copy];
    //DDLogVerbose(@"Configuration: %@", newConfig);
    BOOL owner = (sender.roomSubject != nil);
    NSArray* fields = [newConfig elementsForName:@"field"];
    for (NSXMLElement *field in fields) {
        NSString *var = [field attributeStringValueForName:@"var"];

        if ([var isEqualToString:@"muc#roomconfig_roomdesc"]) {
            if  (!owner) {
                // non-owner gets the description
                [sender changeRoomSubject:[field attributeStringValueForName:@"label"]];
                NSLog(@"roomSubject is now %@", sender.roomSubject);
            } else {
                // owner sets the description
                [field removeChildAtIndex:0];
                [field addChild:[NSXMLElement elementWithName:@"value" stringValue:sender.roomSubject]];
            }
        }
    }
    if (owner) {
        [sender configureRoomUsingOptions:newConfig];
    }
}

- (void)xmppRoom:(XMPPRoom *)sender didConfigure:(XMPPIQ *)iqResult
{
    DDLogVerbose(@"%@: %@ -> %@", THIS_FILE, THIS_METHOD, sender.roomSubject);

    [[NSNotificationCenter defaultCenter]
     postNotificationName:kRoomReadyNotification object:self];
}

- (void)xmppRoom:(XMPPRoom *)sender didNotConfigure:(XMPPIQ *)iqResult
{
    DDLogVerbose(@"%@: %@ -> %@", THIS_FILE, THIS_METHOD, sender.roomSubject);

}

- (void)xmppRoom:(XMPPRoom *)sender occupantDidJoin:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence
{
    //DDLogVerbose(@"%@: %@ -> %@", THIS_FILE, THIS_METHOD, sender.roomSubject);
}

- (void)xmppRoom:(XMPPRoom *)sender occupantDidLeave:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence
{
    //DDLogVerbose(@"%@: %@ -> %@", THIS_FILE, THIS_METHOD, sender.roomSubject);
}

#pragma mark -
#pragma mark XMPPManager

//@synthesize account;
@synthesize buddyList;
@synthesize storage;
@synthesize xmppStream;
@synthesize xmppReconnect;
@synthesize isXmppConnected;
@synthesize isXmppAuthenticated;
@synthesize password;

- (id<MessageLogStorage>)storage
{
    @synchronized(self) {
        if (storage == nil) {
            storage = [[MessageLogManager sharedInstance] storage];
        }
    }
    return storage;
}

- (void)setupStream
{
    NSAssert(self.xmppStream == nil,
        @"Method setupStream invoked multiple times");
        
    // Setup xmpp stream
    // 
    // The XMPPStream is the base class for all activity.
    // Everything else plugs into the xmppStream, such as modules/extensions
    // and delegates.
    
    self.xmppStream = [[XMPPStream alloc] init];
    
#if !TARGET_IPHONE_SIMULATOR
    // Want xmpp to run in the background?
    // 
    // P.S. - The simulator doesn't support backgrounding yet.
    //        When you try to set the associated property on the simulator,
    //        it simply fails.
    //        And when you background an app on the simulator,
    //        it just queues network traffic til the app is foregrounded
    //        again.
    //        We are patiently waiting for a fix from Apple.
    //        If you do enableBackgroundingOnSocket on the simulator,
    //        you will simply see an error message from the xmpp stack when
    //        it fails to set the property.
    self.xmppStream.enableBackgroundingOnSocket = YES;
#endif
    
    // Setup reconnect
    // 
    // The XMPPReconnect module monitors for "accidental disconnections" and
    // automatically reconnects the stream for you.
    // There's a bunch more information in the XMPPReconnect header file.
    
    self.xmppReconnect = [[XMPPReconnect alloc] init];
    [self.xmppReconnect activate:self.xmppStream];
    [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    /*self.xmppAutoPing = [[XMPPAutoPing alloc] initWithDispatchQueue:dispatch_get_main_queue()];
    self.xmppAutoPing.pingInterval = 10;
    self.xmppAutoPing.pingTimeout = 10;
    [self.xmppAutoPing addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self.xmppAutoPing activate:self.xmppStream]; */

}

- (void)teardownStream
{
    [self.xmppStream removeDelegate:self];
    [self.xmppStream disconnect];
}

- (BOOL)registerWithPassword:(NSString *)passwd
{
    if (![self.xmppStream supportsInBandRegistration]) {
        NSLog(@"In band registration not supported!");
        return NO;
    }
    NSError *error = [[NSError alloc] init];
    return [self.xmppStream registerWithPassword:passwd error:&error];
}

- (BOOL)connectWithJID:(NSString *)JIDStr password:(NSString *)thePassword
{
    /* if (![self.xmppStream isDisconnected]) {
        // TODO should raise an exception here or err

        return NO;
    } */
    if (JIDStr == nil || thePassword == nil) {
        // TODO should raise an exception here or err
        DDLogWarn(@"JID and password must be set before connecting!");
        return NO;
    }
//    [appdelegate showGrayWaitingView];
    self.xmppStream.myJID = [XMPPJID jidWithString:JIDStr resource:nil];
    self.xmppStream.hostName = kHostDomain;
    self.xmppStream.hostPort = kChatPort;
    self.password = thePassword;
    
    NSLog(@"Connecting with JID = %@, Password = %@, host = %@", JIDStr, thePassword,
          self.xmppStream.hostName);
    NSError *error = nil;

    //if (![self.bridge connectBridge:&error])
    if (![self.xmppStream connectWithTimeout:10 error:&error])
    {
    }
    return YES;
}

- (BOOL)connectWithJIDToSecondary:(NSString *)JIDStr password:(NSString *)thePassword
{
    /* if (![self.xmppStream isDisconnected]) {
     // TODO should raise an exception here or err
     
     return NO;
     } */
    if (JIDStr == nil || thePassword == nil) {
        // TODO should raise an exception here or err
        DDLogWarn(@"JID and password must be set before connecting!");
        return NO;
    }
    //    [appdelegate showGrayWaitingView];
    self.xmppStream.myJID = [XMPPJID jidWithString:JIDStr resource:nil];
    self.xmppStream.hostName = kHostDomain2;
    self.xmppStream.hostPort = kChatPort;
    self.password = thePassword;
    
    NSLog(@"Connecting with JID = %@, Password = %@, host = %@", JIDStr, thePassword,
          self.xmppStream.hostName);
    NSError *error = nil;
    
    //if (![self.bridge connectBridge:&error])
    if (![self.xmppStream connectWithTimeout:10 error:&error])
    {
        NSLog(@"Got a connect Timeout trying to connect to %@",kHostDomain2);
    }
    return YES;
}

- (NSString *)getChatDomain
{
    return self.xmppStream.hostName;
}

- (void)failedToConnect
{
/*    [[NSNotificationCenter defaultCenter]
     postNotificationName:kProtocolLoginFailNotification object:self];*/
}

- (void)applicationWillResignActiveNotification:(NSNotification *)notification
{
    // Reset the roster
    self.buddyList = [[BuddyList alloc] init];
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
    /*
     * Properly secure your connection by setting kCFStreamSSLPeerName
     * to your server domain name
     */
    NSLog(@"willSecureWithSettings");
    [settings setObject:xmppStream.myJID.domain forKey:(NSString *)kCFStreamSSLPeerName];

    settings[GCDAsyncSocketManuallyEvaluateTrust] = @(YES);
}

- (void)xmppStream:(XMPPStream *)sender
   didReceiveTrust:(SecTrustRef)trust
 completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler
{
    NSLog(@"didReceiveTrust");
    completionHandler(YES);
}

@end
