//
//  ToDoListViewController.h
//  Liri
//
//  Created by Varun Sankar on 19/08/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MKNumberBadgeView.h"
#import "ReminderViewController.h"
#import "MeetingViewController.h"
#import "TaskViewController.h"

@interface ToDoListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, ReminderProtocol, MeetingProtocol, TaskProtocol>

//@property (nonatomic, retain) MKNumberBadgeView *badgeTask;
//@property (nonatomic, retain) MKNumberBadgeView *badgeMeeting;
//@property (nonatomic, retain) MKNumberBadgeView *badgeReminder;
@end
