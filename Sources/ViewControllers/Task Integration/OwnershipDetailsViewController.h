//
//  OwnershipDetailsViewController.h
//  Liri
//
//  Created by Shankar Arunachalam on 9/4/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OwnershipDetailsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, retain) NSString *taskSource;
@property (nonatomic, retain) NSString *selectedLevel1Value;
@property (nonatomic, retain) NSString *selectedLevel1Id;
@property (nonatomic, retain) NSString *selectedLevel2Value;
@property (nonatomic, retain) NSString *selectedLevel2Id;
@property (nonatomic, retain) NSString *selectedLevel3Value;
@property (nonatomic, retain) NSString *selectedLevel3Id;
@property (nonatomic, retain) NSMutableArray *fields;
@property (nonatomic, retain) NSMutableArray *values;
@property (nonatomic, retain) NSMutableArray *records;
@property (nonatomic, retain) IBOutlet UILabel* taskSourceTitle;
@property (nonatomic, retain) IBOutlet UITableView* fieldsTable;

@end
