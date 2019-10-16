//
//  ChooseCategoryViewController.h
//  Liri
//
//  Created by Varun Sankar on 14/08/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ChooseCategoryProtocol;

@interface ChooseCategoryViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic,retain) id <ChooseCategoryProtocol> delegate;
@end

@protocol ChooseCategoryProtocol <NSObject>
-(void)returnSelectedIndexPaths:(NSArray *)indexArray;
@end
