//
//  WebViewController.h
//  Liri
//
//  Created by Varun Sankar on 07/10/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, retain) NSString *fullURL;
@property (nonatomic, retain) NSString *pageTitle;

@end
