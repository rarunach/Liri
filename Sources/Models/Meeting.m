//
//  Meeting.m
//  Liri
//
//  Created by Varun Sankar on 29/07/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "Meeting.h"
#import "Account.h"

@implementation Meeting

@synthesize subject = _subject;
@synthesize toList = _toList;
@synthesize location = _location;
@synthesize allDayEvent = _allDayEvent;
@synthesize startDate = _startDate;
@synthesize endDate = _endDate;
@synthesize repeatFrequency = _repeatFrequency;
@synthesize alert = _alert;
@synthesize secondAlert = _secondAlert;
@synthesize priority = _priority;
@synthesize filePath = _filePath;
@synthesize calendarId = _calendarId;


+ (Meeting *)createMeetingWithData:(NSDictionary *)dict
{
    Meeting *meeting = [[Meeting alloc] init];
    meeting.categoryType = [dict[@"category_type"] intValue];
    meeting.color = CAT_IMG_4;
    
    meeting.subject = dict[@"owner_editable"][@"subject"];
    
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
    meeting.toList = recipient;
    
    meeting.location = dict[@"owner_editable"][@"location"];
    meeting.allDayEvent = [dict[@"owner_editable"][@"alldayevent"] boolValue];
    meeting.startDate = dict[@"owner_editable"][@"starttime"];
    meeting.endDate = dict[@"owner_editable"][@"endtime"];
    meeting.repeatFrequency = dict[@"owner_editable"][@"repeat_frequency"];
    meeting.alert = dict[@"member_editable"][@"alert1"];
    meeting.secondAlert = dict[@"member_editable"][@"alert2"];
    meeting.priority = dict[@"owner_editable"][@"priority"];
    meeting.text = dict[@"owner_editable"][@"notes"];
    meeting.calendarId = dict[@"owner_editable"][@"local_calendar_id"];
    
    return meeting;
}
@end
