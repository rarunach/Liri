//
//  TaskDataLevel1.h
//  Liri
//
//  Created by Shankar Arunachalam on 9/9/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TaskDataLevel1 : NSObject

@property (nonatomic, retain) NSString *source;
@property (nonatomic, retain) NSString *idnum;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSMutableArray *level2Data;

+(NSMutableArray *) parseTaskDataLevel1: (NSMutableArray *)level1data andLevel2: (NSMutableArray *)level2data forSource:(NSString *)source;

@end
