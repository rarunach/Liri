//
//  Reminder.m
//  Liri
//
//  Created by Varun Sankar on 17/07/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "Reminder.h"

@implementation Reminder

@synthesize subject, reminderTime, ringtone, repeatFrequency, priority, reminderId;

+ (Reminder *)createReminderWithData:(NSDictionary *)dict
{
    Reminder *reminder = [[Reminder alloc] init];
    reminder.categoryType = [dict[@"category_type"] intValue];
    reminder.color = CAT_IMG_2;
    
    reminder.subject = dict[@"attributes"][@"subject"];
    reminder.reminderTime = dict[@"attributes"][@"reminder_time"];
    reminder.ringtone = dict[@"attributes"][@"ringtone"];
    reminder.repeatFrequency = dict[@"attributes"][@"repeat_frequency"];
    reminder.text = dict[@"attributes"][@"notes"];
    reminder.priority = dict[@"attributes"][@"priority"];
    reminder.reminderId = dict[@"attributes"][@"local_reminder_id"];
    return reminder;
}

@end
