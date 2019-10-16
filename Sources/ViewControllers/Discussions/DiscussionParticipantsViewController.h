//
//  DiscussionMemberViewController.h
//  Liri
//
//  Created by Varun Sankar on 17/11/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Discussion.h"

@interface DiscussionParticipantsViewController : UITableViewController
@property (nonatomic, strong) NSString *discussionId;
@property (nonatomic, strong) Discussion *discussion;
@end
