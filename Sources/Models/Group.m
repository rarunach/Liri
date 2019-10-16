//
//  Group.m
//  Liri
//
//  Created by Ramani Arunachalam on 8/18/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "Group.h"
#import "Account.h"

@implementation Group

#pragma mark -
#pragma mark NSObject

+ (Group *)groupWithName:(NSString *)name
{
    return [[self alloc] initWithName:name];
}

- (id)init
{
    if ((self = [super init]) != nil) {
        self.memberlist = [[BuddyList alloc] init];
    }
    return self;
}

- (id)initWithName:(NSString *)name
{
    if ((self = [super init]) != nil) {
        self.memberlist = [[BuddyList alloc] init];
        self.name = name;
    }
    return self;
}


- (void)addMember:(Buddy *)buddy
{
    [self.memberlist addBuddy:buddy];
}

- (void)removeMember:(Buddy *)buddy
{
    [self.memberlist removeBuddy:buddy];
}

- (BOOL)isMember:(NSString *)email
{
    return ([self.memberlist findBuddyForEmail:email] != nil);
}

@end
