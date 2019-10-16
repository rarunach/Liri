//
//  Meeting.h
//  Liri
//
//  Created by Varun Sankar on 29/07/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "Categories.h"

@interface Meeting : Categories

@property (nonatomic, retain) NSString *subject;
@property (nonatomic, retain) NSString *toList;
@property (nonatomic, retain) NSString *location;
@property (nonatomic) BOOL allDayEvent;
@property (nonatomic, retain) NSString *startDate;
@property (nonatomic, retain) NSString *endDate;
@property (nonatomic, retain) NSString *repeatFrequency;
@property (nonatomic, retain) NSString *alert;
@property (nonatomic, retain) NSString *secondAlert;
@property (nonatomic, retain) NSString *priority;
@property (nonatomic, retain) NSString *filePath;
@property (nonatomic, retain) NSString *calendarId;



+ (Meeting *)createMeetingWithData:(NSDictionary *)dict;

@end
