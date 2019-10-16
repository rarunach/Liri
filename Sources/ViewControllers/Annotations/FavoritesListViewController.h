//
//  FavoritesListViewController.h
//  Liri
//
//  Created by Shankar Arunachalam on 9/3/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FavoritesListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, retain) IBOutlet UITableView* dataTable;
@property (nonatomic, retain) NSMutableArray* data;

- (IBAction)backAction:(id)sender;

@end
