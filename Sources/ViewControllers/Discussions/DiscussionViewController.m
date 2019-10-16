//
//  DiscussionViewController.m
//  Liri
//
//  Created by Ramani Arunachalam on 4/4/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "DiscussionViewController.h"
#import "Message.h"
#import "Account.h"
#import "Discussion.h"
#import "Categories.h"
#import "XMPPManager.h"
#import "ProductivityCategoryViewController.h"
#import "AnnotationsViewController.h"
#import "AnnotationFullViewController.h"
#import "AuthenticationsViewController.h"
#import "FolderBrowserController.h"
#import "FileFolderMetadata.h"
#import "BrowserController.h"
#import "DiscussionSummaryViewController.h"
#import "CRNInitialsImageView.h"
#import "FavoritesListViewController.h"
#import "OwnershipDetailsViewController.h"
#import "DiscussionParticipantsViewController.h"
#import "Flurry.h"

typedef void (^GetUnknownBuddyCompletionHandler)(BOOL success);

@interface DiscussionViewController ()
{
    NSMutableArray *rowheights;
    CGRect messagesTableOrigFrame, messageFieldOrigFrame, annotationsButtonOrigFrame, sendButtonOrigFrame;
    CGRect messagesTablePrevFrame, messageFieldPrevFrame;
    int currentPage;
    BOOL isShown, waitingForAuth, annotationBeingViewed, gettingUnread, adjustedForKeyboard, keyboardAction;
    NSString *welcomeMsg;
    NSMutableSet *unknownBuddiesSet;
//    DiscussionSummaryViewController *discussionSummaryCtlr;
}

@property (weak, nonatomic) IBOutlet UITableView *messagesTableView;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
//@property (weak, nonatomic) IBOutlet UIButton *conversationBtn;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *conversationBtn;
@property (weak, nonatomic) IBOutlet UITextView *messageField;
@property (weak, nonatomic) IBOutlet UIButton *loadEarlierBtn;
@property (nonatomic, copy) GetUnknownBuddyCompletionHandler getUnknownBuddyCompletionHandler;

//- (IBAction)conversationBtnAction:(id)sender;
@end

@implementation DiscussionViewController
@synthesize messagesTableView;
@synthesize messageField;
@synthesize sendButton;
@synthesize discussion;
@synthesize annotationsButton;
@synthesize conversationBtn = _conversationBtn;
@synthesize messages, messagesLoaded;
@synthesize lastUpdatedTimeFromApi, lastMessageStringFromApi, hasUnreadMessages, lastMessageSenderJID;

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        messages = [[NSMutableArray alloc] initWithCapacity:1];
        rowheights = [[NSMutableArray alloc] initWithCapacity:1];
        messagesLoaded = NO;
        currentPage = 1;
        waitingForAuth = NO;
        gettingUnread = NO;
        adjustedForKeyboard = NO;
        unknownBuddiesSet = [NSMutableSet setWithCapacity:5];
    }
    return self;
}

- (void)initWithDiscussion:(Discussion *)newdiscussion welcomeMsg:(NSString *)msg
{
    discussion = newdiscussion;
    welcomeMsg = msg;
    [self getMessages:NO];
    //[discussion joinDiscussion];
}

- (void)getMessages:(BOOL)unreadOnly
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (self.navigationController.topViewController == self) {
        [delegate showActivityIndicator];
    }
    
    id<APIAccessClient> endpoint1 =
    (id<APIAccessClient>)[[APIManager
                                 sharedInstanceWithClientProtocol:
                                 @protocol(APIAccessClient)] client];
    
    endpoint1.successJSON = ^(NSURLRequest *request,
                              id responseJSON){
        
        NSArray *messagesArray = (NSArray *)[responseJSON objectForKey:@"messages"];
        
        if (!unreadOnly) {
            UIView *view = [self.view viewWithTag:1];
            if ([messagesArray count] == 25) {
                view.hidden = NO;
            } else {
                view.hidden = YES;
            }
        }
        __block int unknownBuddyCount = 0;
        BOOL waitingForBuddyInfo = NO;
        for (NSDictionary *dict in messagesArray) {
            if (dict == [NSNull null]) continue;
            NSString *fromjid = [dict objectForKey:@"fromJID"];
            Account *account = [Account sharedInstance];
            Buddy *sender = [account.buddyList findBuddyForJid:fromjid];
            if (sender == nil) {
                //NSLog(@"Could not find buddy for jid=%@, myjid=%@",fromjid,account.jid);
                if ([account.jid rangeOfString:fromjid].location == NSNotFound) {
                    waitingForBuddyInfo = YES;
                    [self getUnknownBuddyForMessage:fromjid andCompletion:^(BOOL success) {
                                NSLog(@"[Thread %@]:Inside getUnknownbuddy completion handler",[NSThread currentThread]);
                                [self finalizeMessages:messagesArray andUnread:unreadOnly andDelegate:delegate];
                        }];
                  }
            }
        }
        if(waitingForBuddyInfo == NO) {
            NSLog(@"[Thread %@]:No unknown buddies,so finalizing messages",[NSThread currentThread]);
            [self finalizeMessages:messagesArray andUnread:unreadOnly andDelegate:delegate];
        }
        else {
            NSLog(@"[Thread %@]Waiting for unknown buddy info",[NSThread currentThread]);
        }
    };
    endpoint1.failureJSON = ^(NSURLRequest *request,
                              id responseJSON){
        /*UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Unable to get the messages for this discussion"
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];*/
        gettingUnread = NO;

        [delegate hideActivityIndicator];
    };
    
    if (unreadOnly) {
        Message *lastmsg = [messages lastObject];
        [endpoint1 getUnreadMessages:discussion.discussionID lastRead:lastmsg.messageId];
    } else {
        [endpoint1 getMessages:discussion.discussionID page:currentPage];
    }
}

- (void) unknownBuddyAdded:(NSNotification*) info
{
    NSDictionary *userInfo = info.userInfo;
    NSString *buddyJID = [userInfo objectForKey:@"jid"];
    if (buddyJID != nil)
    {
        //NSLog(@"Got a buddy added notification for %@",buddyJID);
        // check if the notification is for one of our unknown buddies.
        BOOL result = [unknownBuddiesSet containsObject:buddyJID];
        if (result== YES)
        {
            NSLog(@"Unknown buddy %@ belongs to my discussion",buddyJID);
            // remove this jid from the set.
            [unknownBuddiesSet removeObject:buddyJID];
            if ([unknownBuddiesSet count] == 0)
            {
                self.getUnknownBuddyCompletionHandler(YES);
            }
            else
            {
                NSLog (@"Discussion:%@, waiting for unknown buddies count=%lu",self.discussion.discussionID,(unsigned long)[unknownBuddiesSet count]);
            }
        }
    }
    else {
        // ignore the notification.
    }
}

- (void) finalizeMessages: (NSArray *)messagesArray andUnread:(BOOL)unreadOnly andDelegate:(AppDelegate *)delegate
{
    NSInteger index;
    if (!unreadOnly) {
        index = 0;
    } else {
        self.unreadMessagesCount = [messagesArray count];
        
        index = [messages count];
    }
    for (NSDictionary *dict in messagesArray) {
        if (dict == [NSNull null]) continue;
        NSString *body = [dict objectForKey:@"body"];
        NSString *fromjid = [dict objectForKey:@"fromJID"];
        NSArray *components = [fromjid componentsSeparatedByString:@"@"];
        NSString *jid = components[0];
        NSString *msgId = [dict objectForKey:@"messageID"];
        Account *account = [Account sharedInstance];
        Buddy *sender = [account.buddyList findBuddyForJid:jid];
        Message *msg;
        if (sender == nil) {
            if (!([account.jid rangeOfString:jid].location == NSNotFound)) {
                msg = [Message outgoingMessage:body withId:msgId];
            }
        } else {
            if (!([account.jid rangeOfString:jid].location == NSNotFound))
                msg = [Message outgoingMessage:body withId:msgId];
            else
                msg = [Message incomingMessage:body withId:msgId from:sender];
        }
        if (msg != nil) {
            [msg setTimestamp:[dict objectForKey:@"sentDate"]];
            [messages insertObject:msg atIndex:index];
            NSNumber *height = [self getRowHeight:msg];
            [rowheights insertObject:height atIndex:index];
            index++;
        }
    }
    // for empty discussions
    if (messages.count > 0)
        lastUpdatedTimeFromApi = nil;
    
    
    messagesLoaded = YES;
    gettingUnread = NO;
    [messagesTableView reloadData];
    if (currentPage == 1)
        [self scrollToBottom];
    [delegate hideActivityIndicator];
}

- (void)getUnknownBuddyForMessage: (NSString *)fromjid
                andCompletion:(GetUnknownBuddyCompletionHandler)completionBlock
{
    self.getUnknownBuddyCompletionHandler = completionBlock;
    NSArray *components = [fromjid componentsSeparatedByString:@"@"];
    NSString *jid = components[0];
    Account *account = [Account sharedInstance];
    
    // check the buddy lookup Array if there's already a server lookup in progress.
    NSNumber *lookupInProgress = [account.buddyLookupArray objectForKey:fromjid];
    if ([lookupInProgress boolValue] == NO)
    {
        // set the in progress flag to true.
        [account.buddyLookupArray setValue:[NSNumber numberWithBool:YES] forKey:fromjid];
        id<APIAccessClient> endpoint =
        (id<APIAccessClient>)[[APIManager
                               sharedInstanceWithClientProtocol:
                               @protocol(APIAccessClient)] client];
        
        endpoint.successJSON = ^(NSURLRequest *request,
                                 id responseJSON){
            
            NSDictionary *jsonDict = responseJSON[@"data"];
            
            NSString *firstName = jsonDict[@"first_name"];
            NSString *lastName = jsonDict[@"last_name"];
            NSString *email = jsonDict[@"email"];
            NSString *name = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
            Account *account = [Account sharedInstance];
            NSLog(@"Downloading profile picture from s3:%@",email);
            UIImage *photo = [account.s3Manager downloadImage:jsonDict[@"profile_pic"]];
            
            Buddy *buddy = [Buddy buddyWithDisplayName:name email:email photo:photo isUser:YES];
            NSLog(@"Adding unknown buddy %@",email);
            Buddy *existingBuddy = [account.buddyList findBuddyForEmail:email];
            // check if the buddy exists, then update it.
            if (existingBuddy != nil)
            {
                existingBuddy.firstName = buddy.firstName;
                existingBuddy.lastName = buddy.lastName;
                existingBuddy.displayName =[NSString stringWithFormat:@"%@ %@", firstName, lastName];
                existingBuddy.profile_pic = jsonDict[@"profile_pic"];
                existingBuddy.photo = photo;
                // save the updated buddy info.
                [account.buddyList saveBuddiesToUserDefaults];
            }
            else
            {
                [account.buddyList addBuddy:buddy];
                // save the updated buddy info.
                [account.buddyList saveBuddiesToUserDefaults];
            }
            // remove this buddy from the lookup array list.
            [account.buddyLookupArray removeObjectForKey:fromjid];
            //self.getUnknownBuddyCompletionHandler(YES);
            NSDictionary *jidInfo = [NSDictionary dictionaryWithObject:fromjid forKey:@"jid"];
            // fire off the notification for all discussions waiting for this buddy info.
            [[NSNotificationCenter defaultCenter] postNotificationName:kUnknownBuddyAddedNotification
                                                                object:nil userInfo:jidInfo];
            
        };
        endpoint.failureJSON = ^(NSURLRequest *request,
                                 id responseJSON){
            NSLog(@"error message %@ and json %@", responseJSON[@"error"], responseJSON);
            NSDictionary *jidInfo = [NSDictionary dictionaryWithObject:fromjid forKey:@"jid"];
            // fire off the notification for all discussions waiting for this buddy info.
            [[NSNotificationCenter defaultCenter] postNotificationName:kUnknownBuddyAddedNotification
                                                                object:nil userInfo:jidInfo];
            //self.getUnknownBuddyCompletionHandler(YES);
        };
        
        [endpoint getUserProfileForJID:jid];
    }
    // add this to our unknown buddies list if it doesn't exist.
    if ([unknownBuddiesSet containsObject:fromjid] == NO)
    {
        [unknownBuddiesSet addObject:fromjid];
        NSLog(@"Registering a notification for unknown buddy jid=%@",fromjid);
        // register for the notification.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unknownBuddyAdded:) name:kUnknownBuddyAddedNotification object:nil];
    }

 }

- (void)getUnreadMessages
{
    if (!gettingUnread) {
        gettingUnread = YES;
        [self getMessages:YES];
    }
}

- (NSString *)getLastMessage
{
    Account *account = [Account sharedInstance];

    if(lastMessageStringFromApi != nil && ![lastMessageStringFromApi isEqualToString: @""]) {
        NSString *senderName = @"";
        if(lastMessageSenderJID == nil) {
            if(messages.count == 0) {
                senderName = @"";
            } else {
                Message *messageObj = [messages lastObject];
                senderName = messageObj.sender.firstName;
            }
        } else {
            Buddy *senderBuddy = [account.buddyList findBuddyForJid:lastMessageSenderJID];
            if(senderBuddy != nil && senderBuddy.firstName != nil) {
                senderName = senderBuddy.firstName;
            }
        }
        NSString *prefix = @"";
        prefix = [NSString stringWithFormat:@"%@: ", senderName];
        if ([lastMessageStringFromApi rangeOfString:@"liri-image"].location == NSNotFound) {
            if ([lastMessageStringFromApi length] > 50)
                return [NSString stringWithFormat:@"%@%@...", prefix, lastMessageStringFromApi];
            else
                return [NSString stringWithFormat:@"%@%@", prefix, lastMessageStringFromApi];
        }
        else return [NSString stringWithFormat:@"An annotated document was posted."];
    }
    if (messages.count == 0)
        return @"";
    Message *messageObj = [messages lastObject];
    NSString *msg = messageObj.message;
    
    NSRange stringRange = {0, MIN([msg length], 50)};
    // adjust the range to include dependent chars
    stringRange = [msg rangeOfComposedCharacterSequencesForRange:stringRange];
    
    NSString *lastmsg = [msg substringWithRange:stringRange];
    NSString *prefix = @"";
    
    if (discussion.type != TYPE_1ON1)
        prefix = [NSString stringWithFormat:@"%@: ", messageObj.sender.firstName];
    if (messageObj.messageType == MSG_TYPE_TEXT) {
        if ([msg length] > 50)
            return [NSString stringWithFormat:@"%@%@...", prefix, lastmsg];
        else
            return [NSString stringWithFormat:@"%@%@", prefix, lastmsg];
    }
    else return [NSString stringWithFormat:@"%@ posted an annotated document.", messageObj.sender.firstName];
}

- (NSDate *)getLastUpdatedTime
{
    if(lastUpdatedTimeFromApi) {
        return lastUpdatedTimeFromApi;
    }
    if (messages.count == 0) {
        return [NSDate distantPast];
    }
    Message *messageObj = [messages lastObject];
    return messageObj.date;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.discussion.type) {
        
        UIButton *participantsBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [participantsBtn setFrame:CGRectMake(0, 0, 32, 32)];
        [participantsBtn setImage:[UIImage imageNamed:@"Add-Icon.png"] forState:UIControlStateNormal];
        [participantsBtn addTarget:self action:@selector(addDiscussionMember) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *summarizeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [summarizeBtn setFrame:CGRectMake(0, 0, 32, 32)];
        [summarizeBtn setImage:[UIImage imageNamed:@"Summarize-Icon.png"] forState:UIControlStateNormal];
        [summarizeBtn addTarget:self action:@selector(summaryBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        
        UIBarButtonItem *rightBarBtn1 = [[UIBarButtonItem alloc] initWithCustomView:participantsBtn];
        
        UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        negativeSpacer.width = -15.0f;
        
        UIBarButtonItem *rightBarBtn2 = [[UIBarButtonItem alloc] initWithCustomView:summarizeBtn];
        
        UIBarButtonItem *positiveSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        positiveSpacer.width = 15.0f;
        
        NSArray *barButtons = [[NSArray alloc]initWithObjects:negativeSpacer, rightBarBtn1, rightBarBtn2, positiveSpacer, nil];
        self.navigationItem.rightBarButtonItems = barButtons;
    }
    
    
    [Flurry logEvent:@"Discussion Screen"];
    //self.navigationItem.hidesBackButton = YES;
    if (discussion.type == TYPE_GROUP)
        self.navigationItem.title = discussion.title;
    else
        self.navigationItem.title = discussion.buddy.displayName;
    
    [self getCategoriesForDiscussion];
    
    messageField.layer.cornerRadius=8.0f;
    messageField.layer.masksToBounds=YES;
    messageField.layer.borderColor=DEFAULT_CGCOLOR;
    messageField.layer.borderWidth= 2.0f;
    messageField.keyboardAppearance = UIKeyboardAppearanceAlert;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tableViewTapped:)];
    [tap setNumberOfTapsRequired:1];
    [messagesTableView addGestureRecognizer:tap];
    
    messageField.delegate = self;

    // Keyboard events

    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
    

    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(annotationOptionSelected:) name:kAnnotationOptionSelectedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(externalAuthenticationTriggered:) name:kExternalAuthenticationSelectedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationCompleted:) name:kAuthenticationCompletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationFailed:) name:kAuthenticationFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(browsingCompleted:) name:kBrowsingCompletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showBrowser:) name:kBrowserRequestedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showFavorites:) name:kFavoritesRequestedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(xmppAuthenticated:) name:kXMPPAuthenticatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(xmppRoomJoined:) name:kRoomJoinedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lightBoxFinished:) name:kLightBoxFinishedAtDiscussionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarFrameChanged:) name:kStatusBarChangeNotification object:nil];

    messagesTableOrigFrame = messagesTableView.frame;
    messageFieldOrigFrame = messageField.frame;
    annotationsButtonOrigFrame = annotationsButton.frame;
    sendButtonOrigFrame = sendButton.frame;
    
    [self scrollToBottom];
    
    if (welcomeMsg != nil && ![welcomeMsg isEqualToString:@""]) {
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(sendWelcomeMessage) userInfo:nil repeats:NO];
    }
    
#if 0
    if ([self.title isEqualToString:@"Liri Support"]) {
        
        NSString *msg = @"Welcome to Liri. You can post questions about Liri in this discussion. One of our team members will answer. You can also use this discussion to try Liri's features.";
        Buddy *naga = [Buddy buddyWithDisplayName:@"Naga Surendran" email:@"naga@vyaza.com" photo:nil isUser:YES];
        Message *messageObj = [Message incomingMessage:msg withId:[[NSUUID UUID] UUIDString] from:naga];
        [self messageReceived:messageObj];
        return;
    }
#endif
}
- (void)viewDidLayoutSubviews
{
    if(IS_IPHONE_5) {
        //do stuff for 4 inch iPhone screen
    }
    else {
        //do stuff for 3.5 inch iPhone screen
        if (!keyboardAction) {
            
            [self.messagesTableView setFrame:CGRectMake(self.messagesTableView.frame.origin.x, self.messagesTableView.frame.origin.y, self.messagesTableView.frame.size.width, 369)];
            
            [self.annotationsButton setFrame:CGRectMake(self.annotationsButton.frame.origin.x, 435, self.annotationsButton.frame.size.width, self.annotationsButton.frame.size.height)];//474
            
            [self.messageField setFrame:CGRectMake(self.messageField.frame.origin.x, 439, self.messageField.frame.size.width, self.messageField.frame.size.height)];//439
            
            [self.sendButton setFrame:CGRectMake(self.sendButton.frame.origin.x, 439, self.sendButton.frame.size.width, self.sendButton.frame.size.height)];//439
            messagesTableOrigFrame = messagesTableView.frame;
            messageFieldOrigFrame = messageField.frame;
            annotationsButtonOrigFrame = annotationsButton.frame;
            sendButtonOrigFrame = sendButton.frame;
        } else {
            keyboardAction = NO;
        }
        
    }
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillChangeFrameNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}
- (void) lightBoxFinished:(NSNotification*)aNotification {
    
    NSDictionary* info = [aNotification userInfo];
    
    if ([info[@"className"] isEqualToString:@"ProductivityCategoryViewController"] || [info[@"className"] isEqualToString:@"AnnotationFullViewController"] || [info[@"className"] isEqualToString:@"AnnotationOptionsViewController"] || [info[@"className"] isEqualToString:@"DiscussionViewController"]){
        [self lightBoxNotificationDidCalled];
    }
}

- (void) statusBarFrameChanged:(NSNotification*)aNotification
{
    CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
    if(statusBarFrame.size.height == 20)
    {
        [self adjustScreenForStatusBar:NO];
    } else if(statusBarFrame.size.height == 40)
    {
        [self adjustScreenForStatusBar:YES];
    }
}

- (void) adjustScreenForStatusBar: (BOOL)callStatusShown
{
    if(callStatusShown) {
        [self.messagesTableView setFrame:CGRectMake(self.messagesTableView.frame.origin.x, self.messagesTableView.frame.origin.y, self.messagesTableView.frame.size.width, self.messagesTableView.frame.size.height - 20)];
        [self.annotationsButton setFrame:CGRectMake(self.annotationsButton.frame.origin.x, self.annotationsButton.frame.origin.y - 20, self.annotationsButton.frame.size.width, self.annotationsButton.frame.size.height)];//474
        [self.messageField setFrame:CGRectMake(self.messageField.frame.origin.x, self.messageField.frame.origin.y - 20, self.messageField.frame.size.width, self.messageField.frame.size.height)];//439
        [self.sendButton setFrame:CGRectMake(self.sendButton.frame.origin.x, self.sendButton.frame.origin.y - 20, self.sendButton.frame.size.width, self.sendButton.frame.size.height)];//439
    } else {
        [self.messagesTableView setFrame:CGRectMake(self.messagesTableView.frame.origin.x, self.messagesTableView.frame.origin.y, self.messagesTableView.frame.size.width, self.messagesTableView.frame.size.height + 20)];
        [self.annotationsButton setFrame:CGRectMake(self.annotationsButton.frame.origin.x, self.annotationsButton.frame.origin.y + 20, self.annotationsButton.frame.size.width, self.annotationsButton.frame.size.height)];//474
        [self.messageField setFrame:CGRectMake(self.messageField.frame.origin.x, self.messageField.frame.origin.y + 20, self.messageField.frame.size.width, self.messageField.frame.size.height)];//439
        [self.sendButton setFrame:CGRectMake(self.sendButton.frame.origin.x, self.sendButton.frame.origin.y + 20, self.sendButton.frame.size.width, self.sendButton.frame.size.height)];//439
    }
    messagesTableOrigFrame = messagesTableView.frame;
    messageFieldOrigFrame = messageField.frame;
    annotationsButtonOrigFrame = annotationsButton.frame;
    sendButtonOrigFrame = sendButton.frame;
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [self.view setUserInteractionEnabled:YES];
    [UIView animateWithDuration:1.0 animations:^(void) {
        self.view.alpha = 1.0;
        [self.navigationController.navigationBar setAlpha:1.0];
    }];
    
    self.unreadMessagesCount = 0;
    [self updateDiscussionsListBadgeValue];
    self.hasUnreadMessages = NO;
    if (!annotationBeingViewed) {
        [self getUnreadMessages];
        //[discussion joinDiscussion];
    } else {
        annotationBeingViewed = NO;
    }
    if(discussion.joinedRoom) {
        [sendButton setEnabled:YES];
        [sendButton setTitleColor:[UIColor colorWithRed:51.0/255.0 green:204.0/255.0 blue:51.0/255.0 alpha:1] forState:UIControlStateNormal];
    } else {
        [sendButton setEnabled:NO];
        [sendButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    }
}

/* - (void)willEnterForeground:(NSNotification *)notification
{
    // join the discussion for all discussions so that we don't lose messages
    [discussion joinDiscussion];
    [self getUnreadMessages];
}*/

- (void)xmppAuthenticated:(NSNotification *)notification
{
    //NSLog(@"========= xmppAuthenticated");
    // Join all discussions after re-login

    if (self.navigationController.topViewController == self) {
        [discussion joinDiscussion];

        [self getUnreadMessages];
    }
    //AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    //[delegate hideActivityIndicator];
}

- (void)xmppRoomJoined:(NSNotification *)notification
{
    NSDictionary *notificationInfo = [notification userInfo];
    XMPPRoom* theRoom = [notificationInfo objectForKey:@"room"];
    if (theRoom == self.discussion.xmppRoom) {
        NSLog(@"Enabling Send button:%@!",self.discussion.discussionJID);
        [sendButton setEnabled:YES];
        [sendButton setTitleColor:[UIColor colorWithRed:51.0/255.0 green:204.0/255.0 blue:51.0/255.0 alpha:1] forState:UIControlStateNormal];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loadEarlierAction:(id)sender {
    currentPage++;
    [self getMessages:NO];
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
    return [messages count];
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    //UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


#define TEXTVIEW_MARGIN 15
#define BUBBLE_MARGIN 35
#define CELL_MARGIN 10
#define CHARS_PER_LINE 31
#define HEIGHT_PER_LINE 20

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    Message *messageObj = messages[indexPath.row];
    
    if (messageObj.messageType == MSG_TYPE_ANNOTATION)
        cell = [tableView dequeueReusableCellWithIdentifier:@"annotationMessageCell"];
    else
        cell = [tableView dequeueReusableCellWithIdentifier:@"textMessageCell"];
    cell.contentMode = UIViewContentModeBottom;
    cell.clipsToBounds = YES;
    
    UIImageView *photoView = (UIImageView *)[cell viewWithTag:100];
    photoView.layer.cornerRadius = photoView.frame.size.width / 2;
    photoView.clipsToBounds = YES;
    photoView.layer.borderWidth = 1;
    photoView.layer.borderColor = DEFAULT_CGCOLOR;
    //photoView.contentMode = UIViewContentModeScaleAspectFit;
    
    UILabel *lblName = (UILabel *)[cell viewWithTag:200];
    UILabel *timestamp = (UILabel *)[cell viewWithTag:300];
    lblName.text = messageObj.sender.displayName;

    UIImageView *chatBubble = (UIImageView *)[cell viewWithTag:500];
    if (messageObj.messageType == MSG_TYPE_ANNOTATION)
    {
        chatBubble.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(annotationTapped:)];
        [tap setNumberOfTapsRequired:1];
        [chatBubble addGestureRecognizer:tap];
    }
    
    //Assign Productivity Category Action
    UIImageView *categoryBubble = (UIImageView *) [cell viewWithTag:600];
    categoryBubble.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(categoryBubbleAction:)];
    [tap setNumberOfTapsRequired:1];
    [categoryBubble addGestureRecognizer:tap];
    
    int categoriesCount = (int)messageObj.categoriesArray.count;
    UIImageView *bubble1 = (UIImageView *) [cell viewWithTag:600];
    [bubble1 setImage:[UIImage imageNamed:@"Action-Categories-White-Icon.png"]];
    UIImageView *bubble2 = (UIImageView *) [cell viewWithTag:601];
    [bubble2 setHidden:YES];
    UIImageView *bubble3 = (UIImageView *) [cell viewWithTag:602];
    [bubble3 setHidden:YES];
    UIImageView *bubble4 = (UIImageView *) [cell viewWithTag:603];
    [bubble4 setHidden:YES];

    if(categoriesCount > 0) {
        int count = 0;
        for (int i = 0; i < categoriesCount; i++) {
            UIImageView *bubble = (UIImageView *) [cell viewWithTag:count+601];
            count++;
            
            Categories *category = [messageObj.categoriesArray objectAtIndex:i];
            [bubble setImage:[UIImage imageNamed:category.color]];
            [bubble setHidden:NO];
            [bubble setContentMode:UIViewContentModeScaleAspectFit];
        }
    }
    
    if (messageObj.sender.photo) {
        photoView.image = messageObj.sender.photo;
    } else {
        //photoView.image = [UIImage imageNamed:@"No-Photo-Icon.png"];
        CRNInitialsImageView *crnImageView = [[CRNInitialsImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        crnImageView.initialsBackgroundColor = [UIColor whiteColor];
        crnImageView.initialsTextColor = DEFAULT_UICOLOR;
        crnImageView.initialsFont = [UIFont boldSystemFontOfSize:18];
        crnImageView.useCircle = TRUE;
        crnImageView.firstName = messageObj.sender.firstName;
        crnImageView.lastName = messageObj.sender.lastName;
        [crnImageView drawImage];
        photoView.image = crnImageView.image;
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSDate *now = [NSDate date];
    [dateFormatter setDateFormat:@"MMM dd"];
    [dateFormatter setTimeZone:[NSTimeZone defaultTimeZone]];
    
    NSString *messageDay = [dateFormatter stringFromDate:messageObj.date];
    NSString *today = [dateFormatter stringFromDate:now];
    if (![messageDay isEqualToString:today]) {
        timestamp.text = messageDay;
    } else {
        [dateFormatter setDateFormat:@"hh:mm a"];
        timestamp.text = [dateFormatter stringFromDate:messageObj.date];
    }
        
    if (messageObj.messageType == MSG_TYPE_ANNOTATION)
    {
        UIImageView *annotationView = (UIImageView *)[cell viewWithTag:400];
        annotationView.contentMode = UIViewContentModeCenter;
        annotationView.contentMode = UIViewContentModeScaleAspectFit;
        if (messageObj.annotatedImage)
            annotationView.image = messageObj.annotatedImage;
        else {
            [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(getAnnotationImageForCell:) userInfo:cell repeats:NO];
            annotationView.image = [UIImage imageNamed:@"Loading-Icon.png"];
        }
    } else {
        UITextView *messageView = (UITextView *)[cell viewWithTag:400];
        messageView.text = messageObj.message;
        messageView.dataDetectorTypes = UIDataDetectorTypeAll;
        [messageView setFont:[UIFont fontWithName:@"Helvetica Neue" size:15]];
        
        CGRect frame1 = messageView.frame;
        CGRect frame2 = chatBubble.frame;
        
        frame1.size.height = [rowheights[indexPath.row] floatValue];
        messageView.frame = frame1;
        frame2.size.height = [rowheights[indexPath.row] floatValue] + BUBBLE_MARGIN;
        chatBubble.frame = frame2;
        
        CGRect f = photoView.frame;
        f.origin.y = frame2.size.height - f.size.height;
        photoView.frame = f;
    }
    
    UIEdgeInsets edgeInsets = UIEdgeInsetsMake(16, 16, 16, 16);
    
    if (messageObj.received) {
        if (messageObj.messageType == MSG_TYPE_ANNOTATION)
            chatBubble.image = [UIImage imageNamed:@"White Larger Chat Icon.png"];
        else
            chatBubble.image = [[UIImage imageNamed:@"White Chat Icon.png"] resizableImageWithCapInsets:edgeInsets];
    } else {
        if (messageObj.messageType == MSG_TYPE_ANNOTATION)
            chatBubble.image = [UIImage imageNamed:@"Green-Larger-Chat-Icon.png"];
        else
            chatBubble.image = [[UIImage imageNamed:@"Green Chat Icon.png"] resizableImageWithCapInsets:edgeInsets];
    }
    return cell;
}

- (void)getAnnotationImageForCell:(NSTimer *)timer
{
    UITableViewCell *cell = timer.userInfo;
    UIImageView *annotationView = (UIImageView *)[cell viewWithTag:400];
    NSIndexPath *indexPath = [messagesTableView indexPathForCell:cell];
    Message *messageObj = messages[indexPath.row];
    [messageObj getAnnotatedImage];
    annotationView.image = messageObj.annotatedImage;
}

- (CGFloat)tableView: (UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{

    Message *messageObj = [messages objectAtIndex:indexPath.row];
    if (messageObj.messageType == MSG_TYPE_ANNOTATION) {
        return 200;
    } else {
        CGFloat height = [rowheights[indexPath.row] floatValue];

        return CELL_MARGIN + BUBBLE_MARGIN + height;
    }
}

- (void)textViewDidChange:(UITextView *)textView
//- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    keyboardAction = YES;
    CGFloat fixedWidth = textView.frame.size.width;
    CGFloat prevHeight = textView.frame.size.height;
    CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    CGRect newFrame = textView.frame;
    newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);
    CGFloat diff = newSize.height - prevHeight;
    newFrame.origin.y -= diff;
    textView.frame = newFrame;
    
    CGRect messagesFrame = messagesTableView.frame;
    messagesFrame.size = CGSizeMake(messagesFrame.size.width, messagesFrame.size.height-diff);
    messagesTableView.frame = messagesFrame;
    //return YES;
}

#pragma mark - Keyboard events

- (void)keyboardWillChangeFrame:(NSNotification*)aNotification
{
    /* if (!adjustedForKeyboard)
     adjustedForKeyboard = YES;
     else return; */
    keyboardAction = YES;
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    //NSLog(@"###### keyboardWillChangeFrame, height %f", kbSize.height);
    
    [UIView animateWithDuration:0.2f animations:^{
        
        CGRect frame = messageFieldOrigFrame;
        frame.origin.y -= kbSize.height;
        messageField.frame = frame;
        messageFieldPrevFrame = frame;
        
        frame = sendButtonOrigFrame;
        frame.origin.y -= kbSize.height;
        sendButton.frame = frame;
        
        frame = annotationsButtonOrigFrame;
        frame.origin.y -= kbSize.height;
        self.annotationsButton.frame = frame;
        
        frame = messagesTableOrigFrame;
        frame.size.height -= kbSize.height;
        messagesTableView.frame = frame;
        messagesTablePrevFrame = frame;
        
        [self scrollToBottom];
    }];
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    //NSLog(@"###### keyboardWillBeHidden");
    keyboardAction = NO;
    adjustedForKeyboard = NO;
        
    [UIView animateWithDuration:0.2f animations:^{
        
        messageField.frame = messageFieldOrigFrame;
        
        messageFieldPrevFrame = messageFieldOrigFrame;
        
        sendButton.frame = sendButtonOrigFrame;
        
        self.annotationsButton.frame = annotationsButtonOrigFrame;
        
        messagesTableView.frame = messagesTableOrigFrame;
        
        messagesTablePrevFrame = messagesTableOrigFrame;
        
        [self scrollToBottom];
    }];
}

- (void)annotationOptionSelected:(NSNotification*)aNotification
{
    if (self.isViewLoaded && self.view.window){
//        [self lightBoxFinished];
        [[NSNotificationCenter defaultCenter]
         
         postNotificationName:kLightBoxFinishedNotification
         
         object:self userInfo:@{@"className" : NSStringFromClass([self class])}];
        
        [self dismissViewControllerAnimated:NO completion:nil];
        NSDictionary* info = [aNotification userInfo];
        AnnotationsViewController *annotationsController = [self.storyboard instantiateViewControllerWithIdentifier:@"AnnotationsViewController"];
        if(info != nil) {
            annotationsController.backgroundImage = [info objectForKey:@"pickedImage"];
        }
        [self presentViewController:annotationsController animated:YES completion:nil];
    }
}

- (void)externalAuthenticationTriggered:(NSNotification*)aNotification
{
    if (self.isViewLoaded && self.view.window){
        NSDictionary* info = [aNotification userInfo];
        NSString *dismissCurrent = [info objectForKey:@"dismissCurrent"];
        if(dismissCurrent != nil && [dismissCurrent isEqualToString:@"NO"]) {
        } else {
            [self dismissViewControllerAnimated:NO completion:nil];        
        }
        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
        AuthenticationsViewController *authenticationsController = [storyBoard instantiateViewControllerWithIdentifier:@"AuthenticationsViewController"];

        if(info != nil) {
            authenticationsController.contentToLoad = [info objectForKey:@"contentToLoad"];
            authenticationsController.externalSystem = [info objectForKey:@"externalSystem"];
        }
        [self presentViewController:authenticationsController animated:YES completion:nil];
    }
}

- (void)browsingCompleted:(NSNotification*)aNotification
{
    if (self.isViewLoaded && self.view.window){
//        [self lightBoxFinished];
        [[NSNotificationCenter defaultCenter]
         
         postNotificationName:kLightBoxFinishedNotification
         
         object:self userInfo:@{@"className" : NSStringFromClass([self class])}];
        [self didPressAnnotations:self];
    }
}

- (void) showBrowser:(NSNotification*)aNotification
{
    if (self.isViewLoaded && self.view.window){
        [self dismissViewControllerAnimated:NO completion:nil];
        
        UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
        rootViewController.modalPresentationStyle = UIModalPresentationNone;

        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
        BrowserController *browserController =
        [storyBoard instantiateViewControllerWithIdentifier:@"BrowserController"];
        browserController.path = @"http://www.google.com";
        browserController.isFromFavorites = false;
        [self presentViewController:browserController animated:YES completion:nil];
    }
}

- (void) showFavorites:(NSNotification*)aNotification
{
    if (self.isViewLoaded && self.view.window){
        [self dismissViewControllerAnimated:NO completion:nil];
        
        [UIView animateWithDuration:0.5 animations:^(void) {
            self.view.alpha = 0.5;
        }];
        UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
        
        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
        FavoritesListViewController *favoritesController =
        [storyBoard instantiateViewControllerWithIdentifier:@"FavoritesListViewController"];
        favoritesController.view.backgroundColor = [UIColor clearColor];

        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
            rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
        } else {
            rootViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            favoritesController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        }
        
        [self presentViewController:favoritesController animated:YES completion:nil];
    }
}

- (void)authenticationFailed:(NSNotification*)aNotification
{
    if (self.isViewLoaded && self.view.window){
        [self dismissViewControllerAnimated:NO completion:nil];
        NSDictionary* info = [aNotification userInfo];
        NSString *errorMessage = [NSString stringWithFormat:@"%@ authentication failed", [info objectForKey:@"externalSystem"]];
        UIAlertView *alertView = [[UIAlertView alloc]
        						  initWithTitle:@""
                                  message: errorMessage
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)authenticationCompleted:(NSNotification*)aNotification
{
//    if (self.isViewLoaded && self.view.window){
        [self dismissViewControllerAnimated:NO completion:nil];
        NSDictionary* info = [aNotification userInfo];
        Account *account = [Account sharedInstance];
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        NSString *externalSystem = [info objectForKey:@"externalSystem"];
        
        BOOL folderBrowsingNeeded = false;
        
        if([externalSystem isEqualToString:@"Box"]) {
            account.box_auth = true;
            [standardUserDefaults setBool:account.box_auth forKey:@"BOX_AUTH"];
            folderBrowsingNeeded = true;
        }
        else if([externalSystem isEqualToString:@"Dropbox"]) {
            account.dropbox_auth = true;
            [standardUserDefaults setBool:account.dropbox_auth forKey:@"DROPBOX_AUTH"];
            folderBrowsingNeeded = true;
        }
        else if([externalSystem isEqualToString:@"Google"]) {
            account.google_auth = true;
            [standardUserDefaults setBool:account.google_auth forKey:@"GOOGLE_AUTH"];
            folderBrowsingNeeded = true;
        }
        else if ([externalSystem isEqualToString:@"Salesforce"]) {
            account.salesforce_auth = true;
            [standardUserDefaults setBool:account.salesforce_auth forKey:@"SALESFORCE_AUTH"];
        }
        else if ([externalSystem isEqualToString:@"Asana"]) {
            account.asana_auth = true;
            [standardUserDefaults setBool:account.google_auth forKey:@"ASANA_AUTH"];
        }
        else if ([externalSystem isEqualToString:@"Trello"]) {
            account.trello_auth = true;
            [standardUserDefaults setBool:account.zoho_auth forKey:@"TRELLO_AUTH"];
        }

        [UIView animateWithDuration:0.5 animations:^(void) {
            self.view.alpha = 0.5;
        }];
        UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
        
        if(folderBrowsingNeeded) {
            UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
            FolderBrowserController *browserController =
            [storyBoard instantiateViewControllerWithIdentifier:@"FolderBrowserController"];
            browserController.view.backgroundColor = [UIColor clearColor];
            browserController.navTitle.text = externalSystem;
            if([externalSystem isEqualToString:@"Google"]) {
                browserController.navTitle.text = @"Google Drive";
            }
            browserController.externalSystem = externalSystem;
            browserController.data = nil;
            
            if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
                rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
            } else {
                rootViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
                browserController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            }
            [self presentViewController:browserController animated:YES completion:nil];
        } else {
            UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Tasks" bundle:nil];
            OwnershipDetailsViewController *detailsController = [storyBoard instantiateViewControllerWithIdentifier:@"OwnershipDetailsViewController"];
            detailsController.view.backgroundColor = [UIColor clearColor];
            detailsController.taskSource = [info objectForKey:@"externalSystem"];
            if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
                rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
            } else {
                rootViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
                detailsController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            }
            [self presentViewController:detailsController animated:YES completion:nil];
        }
//    }
}

-(void) scrollToBottom
{
    int offset = messagesTableView.contentSize.height - messagesTableView.bounds.size.height;
    if (offset < 0) offset = 0;

    CGPoint bottomOffset = CGPointMake(0, offset);
    [messagesTableView setContentOffset:bottomOffset animated:NO];
}

#pragma mark - UITapGesture Action

- (void)categoryBubbleAction:(UIGestureRecognizer *)gesture
{
    [self.view setUserInteractionEnabled:NO];

    UIImageView *imageView = (UIImageView *)gesture.view;
    UITableViewCell *cell;
    
    if([imageView.superview.superview isKindOfClass:[UITableViewCell class]]) {
        cell = (UITableViewCell *) imageView.superview.superview;
    } else {
        cell = (UITableViewCell *) imageView.superview.superview.superview;
    }
    NSIndexPath *indexPath = [self.messagesTableView indexPathForCell:cell];
    Message *messageObj = messages[indexPath.row];
    [self performSegueWithIdentifier:@"ProductivityCategoryIdentifier" sender:messageObj];
}

- (void)annotationTapped:(UIGestureRecognizer *)gesture
{
    [self.view setUserInteractionEnabled:NO];

    annotationBeingViewed = YES;
    UIImageView *imageView = (UIImageView *)gesture.view;
    UITableViewCell *cell;
    
    if([imageView.superview.superview isKindOfClass:[UITableViewCell class]]) {
        cell = (UITableViewCell *) imageView.superview.superview;
    } else {
        cell = (UITableViewCell *) imageView.superview.superview.superview;
    }
    
    NSIndexPath *indexPath = [self.messagesTableView indexPathForCell:cell];
    Message *messageObj = messages[indexPath.row];
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Discussion" bundle:nil];
    
    [UIView animateWithDuration:0.5 animations:^(void) {
        self.view.alpha = 0.5;
        [self.navigationController.navigationBar setAlpha:0.3];
        
    }];
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    AnnotationFullViewController *fullCtlr = [storyBoard instantiateViewControllerWithIdentifier:@"AnnotationFullViewController"];
    fullCtlr.imageToShow = messageObj.annotatedImage;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        [rootViewController setModalPresentationStyle:UIModalPresentationCurrentContext];
    } else {
        rootViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        fullCtlr.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    }
    [self presentViewController:fullCtlr animated:YES completion:nil];
}

- (void)tableViewTapped:(UIGestureRecognizer *)gesture
{
    [[self view] endEditing:YES];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(Message *)messageObj
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    
    if ([segue.identifier isEqualToString:@"ProductivityCategoryIdentifier"]) {
        [UIView animateWithDuration:0.5 animations:^(void) {
            self.view.alpha = 0.5;
            [self.navigationController.navigationBar setAlpha:0.3];
        }];
        
        
        
        ProductivityCategoryViewController *categoryController = segue.destinationViewController;
        
        categoryController.chatName = messageObj.sender.displayName;
        categoryController.chatMessage = messageObj.message;
        categoryController.annotationImage = messageObj.annotatedImage;
        
        categoryController.discussionId = discussion.discussionID;
        categoryController.discussionTitle = discussion.title;
        categoryController.messageId = messageObj.messageId;
        categoryController.categoriesArray = messageObj.categoriesArray;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
//        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZZZ"];
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss"];

        [dateFormatter setTimeZone:[NSTimeZone defaultTimeZone]];
        NSString *messageDay = [dateFormatter stringFromDate:messageObj.date];
        categoryController.messageTimeStamp = messageDay;
        
        UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
        categoryController.view.backgroundColor = [UIColor clearColor];
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
            rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
        } else {
            rootViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            categoryController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        }

/*    } else if ([segue.identifier isEqualToString:@"conversationSummaryIdentifier"]) {
        DiscussionSummaryViewController *summaryController = segue.destinationViewController;
        summaryController.discussionId = self.discussion.discussionID; */
    }
}

- (NSNumber *)getRowHeight:(Message *)messageObj
{
#if 0
    long length = [messageObj.message length];
    NSArray *components = [messageObj.message componentsSeparatedByString:@"\n"];
    long numlines = (length/CHARS_PER_LINE) + [components count];
    //NSLog(@"numlines = %ld", numlines);
    return [NSNumber numberWithLong:(TEXTVIEW_MARGIN + numlines * HEIGHT_PER_LINE)];
#else
    CGRect frame;
    UITableView *cell = [messagesTableView dequeueReusableCellWithIdentifier:@"textMessageCell"];
    UITextView *messageView = (UITextView *)[cell viewWithTag:400];
    messageView.text = messageObj.message;
    
    frame.size = [messageView sizeThatFits:CGSizeMake(messageView.frame.size.width, MAXFLOAT)];
    //NSLog(@"height is %f", frame.size.height);
    return [NSNumber numberWithFloat:frame.size.height];
#endif
}

- (void)sendWelcomeMessage
{
    if (welcomeMsg != nil)
    [self sendMessage:welcomeMsg];
}

- (void)sendMessage:(NSString *)msg
{
    
    Message *messageObj = [Message outgoingTextMessage:msg];
    [messages addObject:messageObj];
    NSNumber *height = [self getRowHeight:messageObj];
    [rowheights addObject:height];

    lastMessageStringFromApi = messageObj.message;
    lastUpdatedTimeFromApi = messageObj.date;
    lastMessageSenderJID = messageObj.sender.jabberid;
    
    [messagesTableView reloadData];
    [self scrollToBottom];
    [discussion sendMessage:messageObj];
}

#pragma mark - Actions
- (IBAction)messageSent:(id)sender {
    
    NSString *msg = [messageField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (msg.length == 0 || [msg isEqualToString:@""]) return;
    [self sendMessage:messageField.text];
    
    messageField.frame = messageFieldPrevFrame;
    messagesTableView.frame = messagesTablePrevFrame;
 
    messageField.text = @"";
    //[messageField setKeyboardType:UIKeyboardTypeASCIICapable];
}

- (void)messageReceived:(Message *)messageObj
{
    //NSLog(@"#### DiscussionViewController::messageReceived");
    if (self.navigationController.topViewController != self) {
        self.unreadMessagesCount++;
        hasUnreadMessages = YES;
        Account *account = [Account sharedInstance];
        [account setDiscussionsBadgeValue];
    }
    // if it is an annotation, get the image from s3
    [messageObj getAnnotatedImage];
    [messages addObject:messageObj];
    lastMessageStringFromApi = messageObj.message;
    lastUpdatedTimeFromApi = messageObj.date;
    lastMessageSenderJID = messageObj.sender.jabberid;
    
    // check if profile pic exists for the sender, else get profile info from API.
    if (messageObj.sender.photo == nil)
    {
        // check if the buddy does not exist.
        Account *account = [Account sharedInstance];
        [self getUnknownBuddyForMessage:lastMessageSenderJID andCompletion:^(BOOL success) {
            NSLog(@"[Thread %@]:Inside getUnknownbuddy completion handler",[NSThread currentThread]);
            NSNumber *height = [self getRowHeight:messageObj];
            [rowheights addObject:height];
            
            [messagesTableView reloadData];
            [self scrollToBottom];
        }];
    }
    else
    {
        NSNumber *height = [self getRowHeight:messageObj];
        [rowheights addObject:height];

        [messagesTableView reloadData];
        [self scrollToBottom];
    }
}

- (IBAction)didPressAnnotations:(id)sender {
    [self.view endEditing:YES];
    [UIView animateWithDuration:0.5 animations:^(void) {
        self.view.alpha = 0.5;
    }];
//    self.modalPresentationStyle = UIModalPresentationCurrentContext;
//    self.navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;
    
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    
    UIViewController *annotationsController = [self.storyboard instantiateViewControllerWithIdentifier:@"AnnotationOptionsController"];
    annotationsController.view.backgroundColor = [UIColor clearColor];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
    } else {
        rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
        annotationsController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    }
    
    [self presentViewController:annotationsController animated:YES completion:nil];

//    [self performSegueWithIdentifier:@"annotationOptionsSegue" sender:self];
}

- (IBAction)summaryBtnAction:(id)sender {
//    [self performSegueWithIdentifier:@"conversationSummaryIdentifier" sender:self];
    
    
//    if (!isShown) {
        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Discussion" bundle:nil];
        DiscussionSummaryViewController *discussionSummaryCtlr = [storyBoard instantiateViewControllerWithIdentifier:@"DiscussionSummaryViewController"];
        discussionSummaryCtlr.discussionId = self.discussion.discussionID;
        isShown = YES;
//    }
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    rootViewController.modalPresentationStyle = UIModalPresentationNone;
    [self presentViewController:discussionSummaryCtlr animated:YES completion:nil];
}

- (IBAction)addDiscussionMember
{
    DiscussionParticipantsViewController *discussionMemberCtlr = [self.storyboard instantiateViewControllerWithIdentifier:@"DiscussionParticipantsViewController"];
    discussionMemberCtlr.discussionId = self.discussion.discussionID;
    discussionMemberCtlr.discussion = self.discussion;
    [self.navigationController pushViewController:discussionMemberCtlr animated:YES];
//    [self presentViewController:discussionMemberCtlr animated:YES completion:nil];
//    [self performSegueWithIdentifier:@"DiscussionMemberViewController" sender:self];
}

#pragma mark - Private Methods
- (void)getCategoriesForDiscussion
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    // do get Summary point
    id<APIAccessClient> discussionsEndpoint =
    (id<APIAccessClient>)[[APIManager
                                 sharedInstanceWithClientProtocol:
                                 @protocol(APIAccessClient)] client];
    
    discussionsEndpoint.successJSON = ^(NSURLRequest *request,
                                        id responseJSON){
        
            NSDictionary *dict = responseJSON[@"categories"][@"data"];
            
            for(id key in dict) {
                
                NSArray *array = [dict objectForKey:key];
                for (int i = 0; i < array.count; i++) {
                    NSString *msgId = [array[i][@"value"][@"message_id"] uppercaseString];
                    //NSLog(@"Finding match for %@ with type %@", msgId, array[i][@"value"][@"category_type"]);

                    for (Message *msg in messages) {
                        if ([msg.messageId isEqualToString:msgId]) {
                            //NSLog(@"Match found");
                            if ([array[i][@"value"][@"category_type"] intValue] == 1 || [array[i][@"value"][@"category_type"] intValue] > 4) {
                                
                                if (![self compareCategories:msg.categoriesArray andCategoryType:[array[i][@"value"][@"category_type"] intValue]]) {
                                    [msg.categoriesArray addObject:[Categories createCategoriesWithData:array[i][@"value"]]];
                                    
                                }
                                
                            } else if ([array[i][@"value"][@"category_type"] intValue] == 2) {
                                if (![self compareCategories:msg.categoriesArray andCategoryType:[array[i][@"value"][@"category_type"] intValue]]) {
                                    [msg.categoriesArray addObject:[Reminder createReminderWithData:array[i][@"value"]]];
                                    
                                }
                                
                                
                            } else if ([array[i][@"value"][@"category_type"] intValue] == 3) {
                                if (![self compareCategories:msg.categoriesArray andCategoryType:[array[i][@"value"][@"category_type"] intValue]]) {
                                    [msg.categoriesArray addObject:[Task createTaskWithData:array[i][@"value"]]];

                                }
                            } else if ([array[i][@"value"][@"category_type"] intValue] == 4) {
                                
                                if (![self compareCategories:msg.categoriesArray andCategoryType:[array[i][@"value"][@"category_type"] intValue]]) {
                                    [msg.categoriesArray addObject:[Meeting createMeetingWithData:array[i][@"value"]]];
                                    
                                }
                                
                
                            }
                            
                        }
                    }
                }
            }
        [messagesTableView reloadData];
        [delegate hideActivityIndicator];

    };
    discussionsEndpoint.failureJSON = ^(NSURLRequest *request,
                                        id responseJSON){
        [delegate hideActivityIndicator];
        
        NSLog(@"error message %@", responseJSON);
    };
    
    [discussionsEndpoint getDiscussionSummaryByDiscussionId:self.discussion.discussionID];
}

-(BOOL)compareCategories:(NSArray *)msgArray andCategoryType:(int)categoryType
{
    if (msgArray.count > 0) {
        for (Categories *category in msgArray) {
            if (categoryType == category.categoryType) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)lightBoxNotificationDidCalled
{
    if (self.isViewLoaded && self.view.window){
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
            [self.view setUserInteractionEnabled:YES];
            [UIView animateWithDuration:0.3 animations:^(void) {
                self.view.alpha = 1.0;
                [self.navigationController.navigationBar setAlpha:1.0];
            }];
            [self updateDiscussionsBadgeValue];
            self.unreadMessagesCount = 0;
            if (!annotationBeingViewed) {
                [self getUnreadMessages];
                //[discussion joinDiscussion];
            } else {
                annotationBeingViewed = NO;
            }
        }
    }
}

- (void)updateDiscussionsListBadgeValue {
    NSInteger badgeCount = [[[[[self.tabBarController tabBar] items] objectAtIndex:0] badgeValue] integerValue];
    if (badgeCount <= 1) {
        [[[[self.tabBarController tabBar] items] objectAtIndex:0] setBadgeValue:nil];
    } else {
        NSString *badgeValue = [NSString stringWithFormat:@"%ld",badgeCount - 1];
        [[[[self.tabBarController tabBar] items] objectAtIndex:0] setBadgeValue:badgeValue];
    }
}

- (void)updateDiscussionsBadgeValue
{
    NSInteger badgeCount = [[[[[self.tabBarController tabBar] items] objectAtIndex:0] badgeValue] integerValue];
    if (badgeCount == self.unreadMessagesCount) {
        [[[[self.tabBarController tabBar] items] objectAtIndex:0] setBadgeValue:nil];
    } else if (badgeCount > self.unreadMessagesCount) {
        
        NSString *badgeValue = [NSString stringWithFormat:@"%ld",badgeCount - self.unreadMessagesCount];
        
        [[[[self.tabBarController tabBar] items] objectAtIndex:0] setBadgeValue:badgeValue];
    }
}
@end
