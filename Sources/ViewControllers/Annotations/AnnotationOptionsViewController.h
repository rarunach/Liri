//
//  AnnotationOptionsViewController.h
//  Liri
//
//  Created by Shankar Arunachalam on 7/4/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AnnotationOptionsViewController : UIViewController <UISearchBarDelegate> {
}

@property (nonatomic, retain) IBOutlet UISearchBar* searchBar;
- (IBAction)backAction:(id)sender;

@end
