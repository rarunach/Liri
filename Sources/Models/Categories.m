//
//  Categories.m
//  Liri
//
//  Created by Varun Sankar on 17/07/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "Categories.h"
#import "UserCategories.h"

@implementation Categories

@synthesize categoryId, categoryType, color, text;

+ (Categories *)createCategoriesWithData:(NSDictionary *)dict
{
    Categories *category = [[Categories alloc] init];
    category.categoryType = [dict[@"category_type"] intValue];
    category.text = dict[@"notes"];
    
    if (category.categoryType == 1) {
        category.color = CAT_IMG_1;
    } else {
        UserCategories *categories = [UserCategories sharedManager];
        for (NSDictionary *localDict in categories.categoryArray) {
            int localType = [localDict[@"categoryType"] intValue];
            if (localType == category.categoryType) {
                category.color = localDict[@"color"];
                break;
            }
        }
    }
    
    return category;
}

@end
