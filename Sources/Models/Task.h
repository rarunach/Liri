//
//  Task.h
//  Liri
//
//  Created by Varun Sankar on 22/07/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "Categories.h"

@interface Task : Categories

@property (nonatomic, retain) NSString *subject;
@property (nonatomic, retain) NSString *toList;
@property (nonatomic, retain) NSString *actionCategory;
@property (nonatomic, retain) NSString *reminderTime;
@property (nonatomic, retain) NSString *alert;
@property (nonatomic, retain) NSString *secondAlert;
@property (nonatomic, retain) NSString *repeatFrequency;
@property (nonatomic, retain) NSString *priority;
@property (nonatomic, retain) NSString *calendarId;


+ (Task *)createTaskWithData:(NSDictionary *)dict;

@end
