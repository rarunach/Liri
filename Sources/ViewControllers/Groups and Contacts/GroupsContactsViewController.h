//
//  GroupsContactsViewController.h
//  Liri
//
//  Created by Ramani Arunachalam on 6/13/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Buddy.h"
#import "DiscussionViewController.h"
#import <MessageUI/MessageUI.h>

@interface GroupsContactsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource, MFMailComposeViewControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UISearchBarDelegate>

@property (nonatomic) BOOL selectionMode;
@property (nonatomic, retain) NSMutableArray *selectedGroups;
@property (nonatomic, retain) BuddyList *selectedBuddies;

- (void)getAllContacts;
- (void)startSelectionMode;

@end
