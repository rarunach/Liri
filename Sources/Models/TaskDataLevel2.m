//
//  TaskDataLevel2.m
//  Liri
//
//  Created by Shankar Arunachalam on 9/9/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "TaskDataLevel2.h"

@implementation TaskDataLevel2

+(TaskDataLevel2 *) parseTaskDataLevel2: (NSDictionary *)result {
    TaskDataLevel2 *taskDataLevel2 = [[TaskDataLevel2 alloc] init];
    taskDataLevel2.source = [result objectForKey:@"source"];
    taskDataLevel2.name = [result objectForKey:@"name"];
    if ([[result objectForKey:@"id"] respondsToSelector:@selector(stringValue)]) {
        taskDataLevel2.idnum = [[result objectForKey:@"id"] stringValue];
    } else {
        taskDataLevel2.idnum = [result objectForKey:@"id"];
    }
    if([result objectForKey:@"workspace"] != nil) {
        if ([[result objectForKey:@"id"] respondsToSelector:@selector(stringValue)]) {
            taskDataLevel2.parentId = [[result objectForKey:@"workspace"] stringValue];
        } else {
            taskDataLevel2.parentId = [result objectForKey:@"workspace"];
        }
    } else {
        if ([[result objectForKey:@"id"] respondsToSelector:@selector(stringValue)]) {
            taskDataLevel2.parentId = [[result objectForKey:@"organization"] stringValue];
        } else {
            taskDataLevel2.parentId = [result objectForKey:@"organization"];
        }
    }
    return taskDataLevel2;
}

@end
