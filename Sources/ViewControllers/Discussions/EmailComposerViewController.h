//
//  EmailComposerViewController.h
//  Liri
//
//  Created by Varun Sankar on 05/08/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EmailComposerViewController : UIViewController<UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) NSString *summaryContent;
@property (nonatomic, retain) NSMutableArray *attrArray;
@property (nonatomic, retain) NSString *summaryTitle;
@end
