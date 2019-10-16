//
//  SourceInfoTableTableViewController.h
//  Liri
//
//  Created by Varun Sankar on 03/09/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SourceInfoTableTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) NSString *sourceTxt;

@property (nonatomic, retain) UIImage *sourceImg;

@property (nonatomic, assign) BOOL isAccountAvailable;

@end
