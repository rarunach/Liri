//
//  StackExtension.h
//  Liri
//
//  Created by Shankar Arunachalam on 8/5/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (StackExtension)

- (void)push:(id)object;
- (id)pop;

@end
