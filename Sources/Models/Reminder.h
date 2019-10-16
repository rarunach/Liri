//
//  Reminder.h
//  Liri
//
//  Created by Varun Sankar on 17/07/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "Categories.h"

@interface Reminder : Categories


@property (nonatomic, retain) NSString *subject;
@property (nonatomic, retain) NSString *reminderTime;
@property (nonatomic, retain) NSString *ringtone;
@property (nonatomic, retain) NSString *repeatFrequency;
@property (nonatomic, retain) NSString *priority;
@property (nonatomic, retain) NSString *reminderId;

+ (Reminder *)createReminderWithData:(NSDictionary *)dict;

@end
