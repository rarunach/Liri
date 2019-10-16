//
//  AddCategoryViewController.h
//  Liri
//
//  Created by Varun Sankar on 30/06/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SummaryPointViewController.h"
#import "ReminderViewController.h"
#import "TaskViewController.h"
#import "MeetingViewController.h"
#import "UserDefinedCategoryViewController.h"

@interface ProductivityCategoryViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, SummaryPointProtocol, ReminderProtocol, TaskProtocol, MeetingProtocol, UserCategoryProtocol>

@property (nonatomic, retain)NSString *chatName;
@property (nonatomic, retain)NSString *chatMessage;
@property (nonatomic, retain) UIImage *annotationImage;

@property (nonatomic, retain)NSString *discussionId;
@property (nonatomic, retain)NSString *messageId;
@property (nonatomic, retain)NSString *discussionTitle;

@property (nonatomic, assign)NSMutableArray *categoriesArray;

@property (nonatomic, retain)NSString *messageTimeStamp;

@end

