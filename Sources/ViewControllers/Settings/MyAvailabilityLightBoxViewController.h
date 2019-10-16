//
//  MyAvailabilityLightBoxViewController.h
//  Liri
//
//  Created by Varun Sankar on 15/10/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MyAvailabilityProtocol;

@interface MyAvailabilityLightBoxViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic,retain) id <MyAvailabilityProtocol> delegate;

@property (nonatomic) int existingStatus;

@end

@protocol MyAvailabilityProtocol <NSObject>

-(void)returnSelectedIndexPath:(int)index;

@end