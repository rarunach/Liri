//
//  TaskDataLevel1.m
//  Liri
//
//  Created by Shankar Arunachalam on 9/9/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "TaskDataLevel1.h"
#import "TaskDataLevel2.h"

@implementation TaskDataLevel1

+(NSMutableArray *) parseTaskDataLevel1: (NSMutableArray *)level1data andLevel2: (NSMutableArray *)level2data forSource:(NSString *)source {
    NSMutableArray *level1Array = [[NSMutableArray alloc] init];
    for(int i = 0; i < level1data.count; i++) {
        TaskDataLevel1 *taskDataLevel1 = [[TaskDataLevel1 alloc] init];
        taskDataLevel1.level2Data  = [[NSMutableArray alloc] init];
        NSDictionary *thisData = [level1data objectAtIndex:i];
        taskDataLevel1.source = [thisData objectForKey:@"source"];
        taskDataLevel1.name = [thisData objectForKey:@"name"];
        if ([[thisData objectForKey:@"id"] respondsToSelector:@selector(stringValue)]) {
            taskDataLevel1.idnum = [[thisData objectForKey:@"id"] stringValue];
        } else {
            taskDataLevel1.idnum = [thisData objectForKey:@"id"];
        }
        [level1Array addObject:taskDataLevel1];
    }
    TaskDataLevel1 *defaultLevel1ForTrello;
    if([source isEqualToString:@"Trello"]) {
        defaultLevel1ForTrello = [[TaskDataLevel1 alloc] init];
        defaultLevel1ForTrello.level2Data  = [[NSMutableArray alloc] init];
        defaultLevel1ForTrello.source = @"Trello";
        defaultLevel1ForTrello.name = @"Default";
        defaultLevel1ForTrello.idnum = @"TrelloDefault";
        [level1Array addObject:defaultLevel1ForTrello];
    }
    for(int i = 0; i < level2data.count; i++) {
        TaskDataLevel2 *taskDataLevel2 = [TaskDataLevel2 parseTaskDataLevel2:[level2data objectAtIndex:i]];
        BOOL level1Found = false;
        for(int j = 0; j < level1Array.count; j++) {
            TaskDataLevel1 *thisLevel1 = [level1Array objectAtIndex:j];
            if([thisLevel1.idnum isEqualToString:taskDataLevel2.parentId]) {
                [thisLevel1.level2Data addObject:taskDataLevel2];
                level1Found = true;
                break;
            }
        }
        if(!level1Found && [source isEqualToString:@"Trello"]) {
            [defaultLevel1ForTrello.level2Data addObject:taskDataLevel2];
        }
    }
    return level1Array;
}

@end
