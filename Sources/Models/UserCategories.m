//
//  AssignCategory.m
//  Liri
//
//  Created by Varun Sankar on 17/07/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "UserCategories.h"

@implementation UserCategories
@synthesize categoryArray = _categoryArray;

#pragma mark Singleton Methods

+ (id)sharedManager {
    static UserCategories *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        self.categoryArray = [[NSMutableArray alloc] init];
        NSMutableDictionary *categoryDict = [[NSMutableDictionary alloc] init];
        [categoryDict setObject:@"Summary point" forKey:@"sysCategory"];
        [categoryDict setObject:@"1" forKey:@"categoryType"];
        [self.categoryArray addObject:categoryDict];
        
        categoryDict = [[NSMutableDictionary alloc] init];
        [categoryDict setObject:@"Add reminder" forKey:@"sysCategory"];
        [categoryDict setObject:@"2" forKey:@"categoryType"];
        [self.categoryArray addObject:categoryDict];
        
        categoryDict = [[NSMutableDictionary alloc] init];
        [categoryDict setObject:@"Assign task" forKey:@"sysCategory"];
        [categoryDict setObject:@"3" forKey:@"categoryType"];
        [self.categoryArray addObject:categoryDict];
        
        categoryDict = [[NSMutableDictionary alloc] init];
        [categoryDict setObject:@"Send meeting invite" forKey:@"sysCategory"];
        [categoryDict setObject:@"4" forKey:@"categoryType"];
        [self.categoryArray addObject:categoryDict];
        
        categoryDict = [[NSMutableDictionary alloc] init];
        [categoryDict setObject:@"" forKey:@"userDefinedCategory"];
        [categoryDict setObject:@"" forKey:@"categoryId"];
        [categoryDict setObject:@"" forKey:@"categoryType"];
        [categoryDict setObject:@"Action-Categories-Green-Icon@2x" forKey:@"color"];
        [self.categoryArray addObject:categoryDict];
    }
    return self;
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
}
@end
