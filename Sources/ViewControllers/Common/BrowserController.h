//
//  BrowserController.h
//  Liri
//
//  Created by Shankar Arunachalam on 8/8/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface BrowserController : UIViewController <UIWebViewDelegate, UITextFieldDelegate>

- (IBAction)didPressCapture:(id)sender;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) IBOutlet UIButton* captureButton;
@property (nonatomic, retain) IBOutlet UIButton* favoritesButton;
@property (nonatomic, retain) IBOutlet UIWebView* webView;
@property (nonatomic, retain) UIImage* capturedImage;
@property (nonatomic,retain) AppDelegate *appDelegate;
@property (strong, nonatomic) UITextField *addressField;
@property (nonatomic,assign) BOOL *isFromFavorites;

@end
