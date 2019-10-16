//
//  MeetingViewController.h
//  Liri
//
//  Created by Varun Sankar on 29/07/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Meeting.h"

@protocol MeetingProtocol;

@interface MeetingViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate>


@property (nonatomic,retain) id <MeetingProtocol> delegate;

@property (nonatomic, retain)NSString *chatName;
@property (nonatomic, retain)NSString *chatMessage;
@property (nonatomic, retain) UIImage *annotationImg;

@property (nonatomic, retain)NSString *discussionId;
@property (nonatomic, retain)NSString *discussionTitle;
@property (nonatomic, retain)NSString *messageId;

@property (nonatomic) BOOL isEditMode;
@property (nonatomic, retain) Meeting *meeting;

@property (nonatomic, retain) NSDictionary *notificationDict;
@property (nonatomic, retain)NSString *messageTimeStamp;

@property (nonatomic) BOOL isNotCurrentUser;

@property (nonatomic, retain) NSArray *recipientStatusArray;

@end

@protocol MeetingProtocol <NSObject>

- (void)meetingCreatedWithSubject:(NSString *)subject toList:(NSString *)toList location:(NSString *)location allDayEvent:(BOOL)allDay startDate:(NSString *)startDate endDate:(NSString *)endDate repeatFrequency:(NSString *)repeatFrequency alert:(NSString *)alert secondAlert:(NSString *)secondAlert priority:(NSString *)priority filePath:(NSString *)filePath notes:(NSString *)notes calendarId:(NSString *)calendarId categoryType:(int)categoryType categoryId:(int)categoryId andEditMode:(BOOL)edited;

@end
