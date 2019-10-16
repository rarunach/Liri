//
//  RecipientStatusViewController.h
//  Liri
//
//  Created by Varun Sankar on 18/09/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecipientStatusViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) NSArray *recipientStatusArray;

@end
