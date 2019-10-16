//
//  DiscussionViewController.h
//  Liri
//
//  Created by Ramani Arunachalam on 4/4/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Buddy.h"
#import "BuddyList.h"
#import "Discussion.h"

@interface DiscussionViewController : UIViewController <UITextViewDelegate> {
    UIButton *annotationsButton;
}

- (IBAction)didPressAnnotations:(id)sender;

@property (nonatomic) BuddyList *buddyList;
@property (nonatomic) Discussion *discussion;
@property (nonatomic) NSMutableArray *messages;
@property (nonatomic) BOOL messagesLoaded;
@property (nonatomic) NSInteger unreadMessagesCount;
@property (nonatomic) NSDate *lastUpdatedTimeFromApi;
@property (nonatomic) NSString *lastMessageStringFromApi;
@property (nonatomic) NSString *lastMessageSenderJID;
@property (nonatomic) BOOL hasUnreadMessages;

@property (nonatomic, retain) IBOutlet UIButton* annotationsButton;

- (void)initWithDiscussion:(Discussion *)newdiscussion welcomeMsg:(NSString *)msg;
- (void)sendMessage:(NSString *)msg;
- (void)messageReceived:(Message *)messageObj;
- (void)getMessages:(BOOL)unreadOnly;
- (NSString *)getLastMessage;
- (NSDate *)getLastUpdatedTime;
- (void)getUnreadMessages;

@end