//
//  TaskDataLevel2.h
//  Liri
//
//  Created by Shankar Arunachalam on 9/9/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TaskDataLevel2 : NSObject

@property (nonatomic, retain) NSString *source;
@property (nonatomic, retain) NSString *idnum;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *parentId;

+(TaskDataLevel2 *) parseTaskDataLevel2: (NSDictionary *)result;

@end
