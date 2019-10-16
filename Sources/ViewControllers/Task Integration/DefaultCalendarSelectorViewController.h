//
//  DefaultCalendarSelectorViewController.h
//  Liri
//
//  Created by Shankar Arunachalam on 9/10/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DefaultCalendarSelectorViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, retain) NSMutableDictionary *localCalendarsDict;
@property (nonatomic, retain) NSMutableArray *localCalendars;
@property (nonatomic, retain) IBOutlet UIButton* calendarsButton;
@property (nonatomic, retain) IBOutlet UIPickerView* calendarsPicker;

@end
