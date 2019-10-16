//
//  FolderBrowserController.h
//  Liri
//
//  Created by Shankar Arunachalam on 7/29/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StackExtension.h"

@interface FolderBrowserController : UIViewController <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, retain) IBOutlet UILabel* navTitle;
@property (nonatomic, retain) IBOutlet UISearchBar* searchBar;
@property (nonatomic, retain) IBOutlet UITableView* dataTable;
@property (nonatomic, retain) NSString* externalSystem;
@property (nonatomic, retain) NSString* searchString;
@property (nonatomic, retain) NSMutableArray* data;
@property (nonatomic, retain) NSMutableDictionary* cache;
@property (nonatomic, retain) NSMutableArray* breadcrumbs;
@property (nonatomic, assign) int backCrumb;

- (IBAction)backAction:(id)sender;

@end
