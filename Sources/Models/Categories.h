//
//  Categories.h
//  Liri
//
//  Created by Varun Sankar on 17/07/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Categories : NSObject

@property (nonatomic) int categoryId;
@property (nonatomic) int categoryType;
@property (nonatomic, retain) NSString *color;
@property (nonatomic, retain) NSString *text;

+ (Categories *)createCategoriesWithData:(NSDictionary *)dict;


@end
