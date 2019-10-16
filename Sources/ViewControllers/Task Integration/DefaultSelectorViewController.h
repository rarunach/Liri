//
//  DefaultSelectorViewController.h
//  Liri
//
//  Created by Shankar Arunachalam on 9/4/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DefaultSelectorViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) NSMutableDictionary *localCalendarsDict;
@property (nonatomic, retain) NSMutableArray *localCalendars;
@property (nonatomic, retain) NSMutableArray *taskSources;
@property (nonatomic, retain) NSMutableArray *taskSourceImages;
@property (nonatomic, retain) IBOutlet UIButton* calendarsButton;
@property (nonatomic, retain) IBOutlet UIPickerView* calendarsPicker;

@end
