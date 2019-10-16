//
//  DiscussionSummaryViewController.h
//  Liri
//
//  Created by Varun Sankar on 01/08/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChooseCategoryViewController.h"
@interface DiscussionSummaryViewController : UIViewController<ChooseCategoryProtocol>

@property (nonatomic, retain) NSString *discussionId;

@end
