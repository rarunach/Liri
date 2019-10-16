//
//  AppDelegate.h
//  Liri
//
//

#import <UIKit/UIKit.h>
#import "XMPPManager.h"
#import "Reachability.h"
#import "GroupsContactsViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    UIActivityIndicatorView* activityView;
    UIView* activityContainerView;
    BOOL isDiscussionListReady;
}

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, copy) NSDictionary *userInfo;
@property (strong, nonatomic) UITabBarController *tabBarController;
@property (nonatomic, assign) BOOL isDiscussionListReady;
@property (nonatomic, assign) BOOL isXMPPAuthenticated;
@property (nonatomic, retain) UIAlertView *reachabilityAlert;
@property (nonatomic, retain) Reachability *reach;

- (void)showActivityIndicator;
- (void)hideActivityIndicator;

@end
