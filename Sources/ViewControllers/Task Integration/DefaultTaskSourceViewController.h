//
//  DefaultTaskSourceViewController.h
//  Liri
//
//  Created by Shankar Arunachalam on 9/10/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DefaultTaskSourceViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) NSMutableArray *taskSources;
@property (nonatomic, retain) NSMutableArray *taskSourceImages;

@end
