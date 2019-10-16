//
//  Task.m
//  Liri
//
//  Created by Varun Sankar on 22/07/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "Task.h"
#import "Account.h"

@implementation Task

@synthesize subject, toList, actionCategory, reminderTime, alert, secondAlert, repeatFrequency, priority, calendarId;


+ (Task *)createTaskWithData:(NSDictionary *)dict
{
    Task *task = [[Task alloc] init];
    task.categoryType = [dict[@"category_type"] intValue];
    task.color = CAT_IMG_3;
    
    task.subject = dict[@"owner_editable"][@"subject"];
    
    Account *account = [Account sharedInstance];
    NSArray *toArray = dict[@"owner_editable"][@"to"];
    NSString *recipient = @"";
    if ([dict[@"creator"] isEqualToString:account.email]) {
        for (NSDictionary *toDict in toArray) {
            recipient = [recipient stringByAppendingString:[NSString stringWithFormat:@"%@,", toDict[@"user"]]];
        }
    } else {
        for (NSString *str in toArray) {
            recipient = [recipient stringByAppendingString:[NSString stringWithFormat:@"%@,", str]];
        }
    }
    task.toList = recipient;
    
    task.actionCategory = dict[@"owner_editable"][@"actioncategory"];
    task.reminderTime = dict[@"owner_editable"][@"remindertime"];
    task.alert = dict[@"member_editable"][@"alert1"];
    task.secondAlert = dict[@"member_editable"][@"alert2"];
    task.repeatFrequency = dict[@"owner_editable"][@"repeat_frequency"];
    task.priority = dict[@"owner_editable"][@"priority"];
    task.text = dict[@"owner_editable"][@"notes"];
    task.calendarId = dict[@"owner_editable"][@"local_calendar_id"];
    
    return task;
}


@end
