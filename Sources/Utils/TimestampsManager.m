//
//  TimestampsManager.m
//  Liri
//
//  Created by Shankar Arunachalam on 11/20/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "TimestampsManager.h"

@implementation TimestampsManager

+(void) updateForDiscussion:(NSString *)discussionId withDate:(NSDate *)updatedDate
{
    [[NSUserDefaults standardUserDefaults] setObject:updatedDate forKey:discussionId];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(NSDate *) fetchForDiscussion:(NSString *)discussionId {
    NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:discussionId];
    if(!date) {
        date = [NSDate distantPast];
    }
    return date;
}

@end
