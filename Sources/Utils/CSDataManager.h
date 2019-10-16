//

#import <Foundation/Foundation.h>
@interface CSDataManager : NSObject <CLLocationManagerDelegate> {
	
    CLLocationManager *locationManager;
	double mLatitude;
	double mLongitude;
    
    NSMutableArray *arr;   // int menuState;

    BOOL _schoolScreenVisible;
}
@property (nonatomic, assign) BOOL _schoolScreenVisible;
@property (nonatomic, retain) CLLocation *currentLocation;
@property(nonatomic,assign) double mLatitude;
@property(nonatomic,assign) double mLongitude;
@property (nonatomic, retain) NSMutableArray *arr;

//@property(nonatomic,assign)int  menuState;
#pragma mark -

+ (CSDataManager *)sharedDataManager ;

- (void)getCurrentUserlocation;
-(UIImage*)getRotatedVersionOfImageFromImage:(UIImage*)inImage;
-(NSMutableDictionary*)clubDetails:(NSMutableDictionary*)inDictionary;
-(void)showCustomMenu:(UIViewController *)inViewController forButton:(UIButton*)inMenuButton;
-(void)dragButtonToShowMenu:(UIViewController *)inViewController andButton:(UIButton*)inButton;
-(NSString*)timeDifference:(NSString*)inString;
-(void)hideMenu:(UIView*)inView;
- (UIImage*)imageByScalingAndCroppingImage:(UIImage*)inImage ForSize:(CGSize)targetSize;
-(void)refreshSearchForMenu:(UIViewController *)inViewController;
-(void)showSearchMenuForParent:(UIView*)inParentView;
-(void) stop;
-(void) start;
@end
