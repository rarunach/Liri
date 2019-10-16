//
//  ReminderViewController.h
//  Liri
//
//  Created by Varun Sankar on 04/07/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "Reminder.h"

@protocol ReminderProtocol;

@interface ReminderViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate, MPMediaPickerControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic,retain) id <ReminderProtocol> delegate;

@property (nonatomic, retain)NSString *chatName;
@property (nonatomic, retain)NSString *chatMessage;

@property (nonatomic, retain)NSString *discussionId;
@property (nonatomic, retain)NSString *messageId;
@property (nonatomic, retain) UIImage *annotationImg;


@property (nonatomic) BOOL isEditMode;
@property (nonatomic, retain) Reminder *reminder;
@property (nonatomic, retain)NSString *messageTimeStamp;

@end

@protocol ReminderProtocol <NSObject>

- (void)reminderCreatedWithSubject:(NSString *)subject time:(NSString*)time tone:(NSString*)tone frequency:(NSString*)frequency notes:(NSString *)notes priority:(NSString *)priority reminderId:(NSString *)reminderId categoryType:(int)categoryType categoryId:(int)categoryId andEditMode:(BOOL)edited;

@end