//
//  Group.h
//  Liri
//
//  Created by Ramani Arunachalam on 8/18/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BuddyList.h"

@interface Group : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *groupID;
@property (nonatomic) Buddy *owner;
@property (nonatomic, strong) BuddyList *memberlist;

+ (Group *)groupWithName:(NSString *)name;

- (id)init;
- (void)addMember:(Buddy *)buddy;
- (void)removeMember:(Buddy *)buddy;
- (BOOL)isMember:(NSString *)email;

@end
