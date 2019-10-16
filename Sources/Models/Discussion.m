//
//  Discussion.m
//  Liri
//
//  Created by Ramani Arunachalam on 7/1/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "Discussion.h"
#import "Account.h"
#import "Group.h"
#import "XMPPManager.h"
#import "AppDelegate.h"

@implementation Discussion

+ (Discussion *)discussionWithTitle:(NSString *)theTitle
                         welcomeMsg:(NSString*)msg
                      buddyList:(BuddyList *)buddyList
                             groups:(NSArray *)groups
{
    return [[self alloc] initWithTitle:theTitle welcomeMsg:msg buddyList:buddyList groups:groups];
}

+ (Discussion *)discussionWithID:(NSString *)discID title:(NSString *)theTitle
                    buddyList:(BuddyList *)buddyList
{
    return [[self alloc] initWithDiscussionID:discID title:theTitle
                buddyList:buddyList];
}

- (id)initWithTitle:(NSString *)theTitle
         welcomeMsg:(NSString*)msg
                buddyList:(BuddyList *)buddyList
             groups:(NSArray *)groups
{
    if ((self = [super init]) != nil) {
        Account *account = [Account sharedInstance];
        NSString *domain = [account.email componentsSeparatedByString:@"@"][1];
        NSString *uuid = [[[NSUUID UUID] UUIDString] lowercaseString];
        self.discussionID = [NSString stringWithFormat:@"%@.%@", uuid, domain];
        self.discussionJID = [NSString stringWithFormat:@"%@@discussions.%@", self.discussionID,
                              kChatServerName];

        self.title = theTitle;
        self.welcomeMsg = msg;
        self.buddyList = buddyList;
        self.groups = groups;
        self.type = TYPE_GROUP;
        // set the joined room flag to false on init.
        self.joinedRoom = NO;
        self.joiningRoom = NO;
        
        if (groups) {
            for (Group *group in groups) {
                if (![group.owner.email isEqualToString: account.email])
                    [buddyList.allBuddies addObject:group.owner];

                for (Buddy *buddy in group.memberlist.allBuddies) {
                    // I am the owner
                    if (![buddy.email isEqualToString:account.email])
                        [buddyList.allBuddies addObject:buddy];
                }
            }
        }
        self.createFlag = YES;
        
        self.xmppRoom = [[XMPPManager sharedInstance] createRoomWithJID:self.discussionJID withSubject:self.title memberList:self.buddyList];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomReady:) name:kRoomReadyNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomJoined:) name:kRoomJoinedNotification object:nil];
    }
    return self;
}

- (id)initWithDiscussionID:(NSString *)discID title:(NSString *)theTitle
                 buddyList:(BuddyList *)buddyList
{
    if ((self = [super init]) != nil) {
        self.discussionID = discID;
        self.discussionJID = [NSString stringWithFormat:@"%@@discussions.%@", self.discussionID,
                              kChatServerName];
        self.title = theTitle;
        self.welcomeMsg = nil;
        self.buddyList = buddyList;
        self.createFlag = NO;
        self.type = TYPE_GROUP;
        // set the joined room flag to false on init.
        self.joinedRoom = NO;
        self.joiningRoom = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomJoined:) name:kRoomJoinedNotification object:nil];
    }
    return self;
}

- (void)roomReady:(NSNotification *)notification
{
    NSLog(@"Room Ready!");
    // set the joined room flag to true on XMPP room ready.
    self.joinedRoom = YES;
    self.joiningRoom = NO;
    
    if (self.createFlag) {
        id<APIAccessClient> endpoint =
        (id<APIAccessClient>)[[APIManager
                                 sharedInstanceWithClientProtocol:
                                 @protocol(APIAccessClient)] client];
        endpoint.successJSON = ^(NSURLRequest *request,
                                         id responseJSON){
            [[NSNotificationCenter defaultCenter]
                postNotificationName:kDiscussionReadyNotification object:self];
        };
        endpoint.failureJSON = ^(NSURLRequest *request,
                                         id responseJSON){
            NSLog(@"Discussion create failed ...");
            //For 1-on-1, discussion may have been created by the other guy already which could cause this api to fail.
            /*if (self.type == TYPE_GROUP) {
                UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:@""
                                      message:@"Couldn't create the discussion. Please try again."
                                      delegate:nil cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
                [alertView show];
            }*/
        };
    
        NSMutableArray *memberList = [[NSMutableArray alloc] initWithCapacity:self.buddyList.allBuddies.count];

        for (Buddy *buddy in self.buddyList.allBuddies) {
            [memberList addObject:buddy.email];
        }
        
        NSMutableArray *groupList = [[NSMutableArray alloc] initWithCapacity:self.groups.count];
        
        for (Group *group in self.groups) {
            [groupList addObject:[NSString stringWithFormat:@"g::%@", group.groupID]];
        }
    
        if (self.type == TYPE_1ON1)
            [endpoint createDiscussionWithID:self.discussionID title:self.title members:memberList groups:groupList is1on1:@"true"];
        else
            [endpoint createDiscussionWithID:self.discussionID title:self.title members:memberList groups:groupList is1on1:@"false"];

    }
}

- (void)roomJoined:(NSNotification *)notification
{
    NSDictionary *notificationInfo = [notification userInfo];
    XMPPRoom* theRoom = [notificationInfo objectForKey:@"room"];
    if (theRoom == self.xmppRoom) {
        NSLog(@"Room %@ Joined!",self.discussionJID);
        self.joinedRoom = YES;
        self.joiningRoom = NO;
    }
}

- (void)sendMessage:(Message *)messageObj
{
    [[XMPPManager sharedInstance] sendMessageToRoom:self.discussionJID message:messageObj];
}

- (void)joinDiscussion
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (delegate.isXMPPAuthenticated)
    {
        if (self.joinedRoom == NO)
        {
            if (!self.joiningRoom) {
                self.joiningRoom = YES;
                if (self.xmppRoom == nil) {
                    // if a xmpp room doesn't exist create one.
                    self.xmppRoom = [[XMPPManager sharedInstance] joinRoomWithJID:self.discussionJID];
                }
                else {
                    // room already exists, just need to send the presence event.
                    NSLog(@"Sending a presence to %@",self.xmppRoom.roomJID);
                    Account *account = [Account sharedInstance];
                    [self.xmppRoom joinRoomUsingNickname:[account getName] history:nil password:nil];
                }
            }
        }
        else {
            NSLog(@"Room %@ has already joined",self.discussionJID);
        }
    }
    else
    {
        NSLog(@"Waiting for XMPP authentication to complete");
    }
}

- (void)updateDiscussionMembers:(NSMutableArray *)list
{
    [[XMPPManager sharedInstance] updateRoomMembersForRoom:self.xmppRoom memberList:list];
}

- (void)leaveDiscussion
{
    [[XMPPManager sharedInstance] leaveRoom:self.xmppRoom];
}

+ (Discussion *)discussionWithID:(NSString *)discID buddy:(Buddy *)buddy create:(BOOL)createFlag
{
    return [[self alloc] initWithDiscussionID:discID buddy:buddy create:createFlag];
}

- (id)initWithDiscussionID:(NSString *)discID buddy:(Buddy *)buddy create:(BOOL)createFlag
{
    if ((self = [super init]) != nil) {
        self.discussionID = discID;
        self.discussionJID = [NSString stringWithFormat:@"%@@1on1.%@", self.discussionID,
                              kChatServerName];
        self.title = buddy.displayName;
        self.buddy = buddy;
        self.buddyList = [[BuddyList alloc] init];
        [self.buddyList addBuddy:buddy];
        self.createFlag = createFlag;
        self.joinedRoom = NO;
        self.joiningRoom = NO;
        self.type = TYPE_1ON1;
        
        if (createFlag) {
            Account *account = [Account sharedInstance];

            NSString *description = [NSString stringWithFormat:@"%@ - %@", [account getName], buddy.displayName];
            self.xmppRoom = [[XMPPManager sharedInstance] createRoomWithJID:self.discussionJID withSubject:description memberList:self.buddyList];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomReady:) name:kRoomReadyNotification object:nil];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomJoined:) name:kRoomJoinedNotification object:nil];

    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
