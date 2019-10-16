//
//  DiscussionsListController.h
//  Liri
//
//  Created by Ramani Arunachalam on 7/17/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Account.h"
#import "MyAvailabilityLightBoxViewController.h"
@interface DiscussionsListController : UIViewController <UITableViewDelegate, UITableViewDataSource, MyAvailabilityProtocol>

@property (nonatomic) BOOL discussionsLoaded;

- (int)getTotalUnreadMessagesCount;

- (void)deleteCategoryUsingDiscussionId:(NSString *)discussionId messageId:(NSString *)msgId andCategoryType:(int)categoryType;
@end
