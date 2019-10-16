//
//  Discussion.h
//  Liri
//
//  Created by Ramani Arunachalam on 7/1/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPRoom.h"
#import "BuddyList.h"

#define TYPE_1ON1 0
#define TYPE_GROUP 1

@interface Discussion : NSObject

@property (nonatomic, copy) NSString *discussionID;
@property (nonatomic, copy) NSString *discussionJID;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) XMPPRoom *xmppRoom;
@property (nonatomic, strong) Buddy *buddy; // 1-on-1
@property (nonatomic, strong) BuddyList *buddyList;
@property (nonatomic, strong) NSArray *groups;
@property (nonatomic) BOOL createFlag;
@property (nonatomic) BOOL joinedRoom;
@property (nonatomic) BOOL joiningRoom;
@property (nonatomic) NSInteger type;
@property (nonatomic) NSString *welcomeMsg;

+ (Discussion *)discussionWithTitle:(NSString *)theTitle
                         welcomeMsg:(NSString*) welcomeMsg
                         buddyList:(BuddyList *)buddyList
                             groups:(NSArray *)groups;
+ (Discussion *)discussionWithID:(NSString *)discID  title:(NSString *)theTitle
                        buddyList:(BuddyList *)buddyList;

- (void)sendMessage:(Message *)messageObj;
- (void)joinDiscussion;
- (void)leaveDiscussion;
- (void)updateDiscussionMembers:(NSMutableArray *)list;

// For 1-on-1 discussions
+ (Discussion *)discussionWithID:(NSString *)discID buddy:(Buddy *)buddy create:(BOOL)createFlag;

@end
