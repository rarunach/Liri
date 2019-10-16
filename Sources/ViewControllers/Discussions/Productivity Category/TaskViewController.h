//
//  TaskViewController.h
//  Liri
//
//  Created by Varun Sankar on 22/07/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Task.h"

@protocol TaskProtocol;

@interface TaskViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic,retain) id <TaskProtocol> delegate;

@property (nonatomic, retain)NSString *chatName;
@property (nonatomic, retain)NSString *chatMessage;
@property (nonatomic, retain) UIImage *annotationImg;

@property (nonatomic, retain)NSString *discussionId;
@property (nonatomic, retain)NSString *discussionTitle;
@property (nonatomic, retain)NSString *messageId;

@property (nonatomic) BOOL isEditMode;
@property (nonatomic, retain) Task *task;

@property (nonatomic, retain) NSDictionary *notificationDict;
@property (nonatomic, retain)NSString *messageTimeStamp;

@property (nonatomic) BOOL isNotCurrentUser;

@property (nonatomic, retain) NSArray *recipientStatusArray;

@property (nonatomic) BOOL completeTask;

@property (nonatomic, retain) NSDictionary *editTaskDict;

@property (nonatomic, retain) NSDictionary *taskExternalSource;

@end

@protocol TaskProtocol <NSObject>

- (void)taskCreatedWithSubject:(NSString *)subject toList:(NSString*)toList category:(NSString*)category reminderTime:(NSString*)reminderTime alert:(NSString *)alert secondAlert:(NSString *)secondAlert repeatFrequency:(NSString *)repeatFrequency priority:(NSString *)priority notes:(NSString *)notes calendarId:(NSString *)calendarId categoryType:(int)categoryType categoryId:(int)categoryId andEditMode:(BOOL)edited;

@optional

- (void)markTaskAsCompleted;

@end