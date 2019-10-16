//
//  GroupViewController.h
//  Liri
//
//  Created by Ramani Arunachalam on 8/18/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Group.h"

@interface GroupViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

- (void)initWithGroup:(Group *)thegroup new:(BOOL)newFlag;

- (void)initWithUpdateGroup:(Group *)theGroup;

@end
