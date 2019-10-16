//
//  ImportSelectViewController.h
//  Liri
//
//  Created by Ramani Arunachalam on 6/13/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Buddy.h"

@interface ImportSelectViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

- (void)getDeviceContacts;
- (void)getContactsForSource:(NSString *)source;

@end
