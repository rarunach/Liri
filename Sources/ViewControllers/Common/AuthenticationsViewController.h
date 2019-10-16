//
//  AuthenticationsViewController.h
//  Liri
//
//  Created by Shankar Arunachalam on 7/29/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface AuthenticationsViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, strong) NSString *contentToLoad;
@property (nonatomic, strong) NSString *externalSystem;
@property (nonatomic, retain) IBOutlet UIWebView* webView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* backButton;
@property (nonatomic,retain) AppDelegate *appDelegate;

@property (nonatomic, assign) BOOL isFromSetting;
@property (nonatomic, assign) BOOL isFromContacts;

- (IBAction)backAction:(id)sender;

@end
