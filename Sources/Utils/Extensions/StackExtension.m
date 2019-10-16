//
//  StackExtension.m
//  Liri
//
//  Created by Shankar Arunachalam on 8/5/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "StackExtension.h"

#import "StackExtension.h"

@implementation NSMutableArray (StackExtension)

- (void)push:(id)object {
    [self addObject:object];
}

- (id)pop {
    id lastObject = [self lastObject];
    [self removeLastObject];
    return lastObject;
}

@end
