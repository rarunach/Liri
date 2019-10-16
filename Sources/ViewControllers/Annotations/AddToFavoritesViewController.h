//
//  AddToFavoritesViewController.h
//  Liri
//
//  Created by Shankar Arunachalam on 9/3/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddToFavoritesViewController : UIViewController

@property (nonatomic, retain) IBOutlet UIButton* cancelButton;
@property (nonatomic, retain) IBOutlet UIButton* saveButton;
@property (nonatomic, retain) IBOutlet UITextField* name;
@property (nonatomic, retain) NSString* urlText;

@end
