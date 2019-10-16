//
//  AssignCategory.h
//  Liri
//
//  Created by Varun Sankar on 17/07/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserCategories : NSObject


@property (nonatomic, retain) NSMutableArray *categoryArray;

+ (id)sharedManager;

@end
