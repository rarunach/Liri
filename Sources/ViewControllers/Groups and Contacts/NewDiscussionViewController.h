//
//  NewDiscussionViewController.h
//  Liri
//
//  Created by Ramani Arunachalam on 7/12/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BuddyList.h"

@interface NewDiscussionViewController : UIViewController

- (void)initWithBuddyList:(BuddyList *)list;
- (void)initWithGroups:(NSMutableArray *)groupsArr;

@end
