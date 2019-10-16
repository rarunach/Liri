//
//  SelectFieldsViewController.h
//  Liri
//
//  Created by Shankar Arunachalam on 9/9/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SelectFieldsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, retain) NSString *taskSource;
@property (nonatomic, retain) NSString *valueLevel;
@property (nonatomic, retain) NSMutableArray *values;
@property (nonatomic, retain) IBOutlet UILabel* taskSourceTitle;
@property (nonatomic, retain) IBOutlet UITableView* valuesTable;

@end
