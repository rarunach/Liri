//
//  WebPreviewController.h
//  DoodleTop
//
//  Created by Shankar Arunachalam on 5/2/14.
//  Copyright (c) 2014 Penguin Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface WebPreviewController : UIViewController <UIWebViewDelegate> {
    NSString * path;
    UIButton *captureButton;
    UIImage* capturedImage;
}

- (IBAction)didPressCapture:(id)sender;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSString * source;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * token;
@property (nonatomic, retain) IBOutlet UILabel* sourceLabel;
@property (nonatomic, retain) IBOutlet UILabel* fileLabel;
@property (nonatomic, retain) IBOutlet UIButton* captureButton;
@property (nonatomic, retain) IBOutlet UIWebView* webView;
@property (nonatomic, retain) UIImage* capturedImage;
@property (nonatomic,retain) AppDelegate *appDelegate;

@end
