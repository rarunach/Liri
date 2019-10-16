//
//  TimestampsManager.h
//  Liri
//
//  Created by Shankar Arunachalam on 11/20/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TimestampsManager : NSObject

+(void) updateForDiscussion:(NSString *)discussionId withDate:(NSDate *)updatedDate;
+(NSDate *) fetchForDiscussion:(NSString *)discussionId;
@property (nonatomic) BOOL updating;

@end
