//
#import "CSDataManager.h"
static CSDataManager *gSharedDataManager = nil;

@implementation CSDataManager

@synthesize mLatitude;
@synthesize mLongitude;
@synthesize arr;
@synthesize currentLocation;
@synthesize _schoolScreenVisible;
//@synthesize menuState;
#pragma mark -

- (id) init
{
	self = [super init];
	if (self != nil) {
        
        
        _schoolScreenVisible = NO;
        arr = [[NSMutableArray alloc]init];
        CLLocation *location = [[CLLocation alloc] init];
		self.currentLocation = location;//[[CLLocation alloc] init];
		locationManager = [[CLLocationManager alloc] init];
		locationManager.delegate = self;
		locationManager.desiredAccuracy = kCLLocationAccuracyBest;
		locationManager.distanceFilter = 10;
//		if([CLLocationManager locationServicesEnabled])
//		{
//			[locationManager startUpdatingLocation];
//			[self getCurrentUserlocation];
//			
//		}
	}
	return self;
}

+ (CSDataManager *)sharedDataManager
{
	@synchronized(self)
	{
		if(nil == gSharedDataManager)
		{		
			[[self alloc] init];
		}
		
	}
	return gSharedDataManager;
}

+ (id)allocWithZone:(NSZone *)zone
{
	@synchronized(self)
	{
		if(nil == gSharedDataManager)
		{
			gSharedDataManager = [super allocWithZone:zone];
			return gSharedDataManager;
		}
	}
	return nil;
}

- (id)copyWithZone:(NSZone*)zone
{
	return self;
}

//- (id)retain
//{
//	return self;
//}
//
//- (unsigned)retainCount
//{
//	return UINT_MAX;
//}

//- (void)release
//{	
//}



#pragma mark -
#pragma mark Location Manager Delegate

-(void)getCurrentUserlocation
{
    [self start];
    return;
	
	if ([CLLocationManager locationServicesEnabled])
		
	{
		
		CLLocation *location=locationManager.location;
		mLatitude = location.coordinate.latitude;
		mLongitude = location.coordinate.longitude;
        
        DebugLog(@"getCurrentUserlocation mLatitude = %f ---%f",mLatitude,mLongitude);
		
		
	}
	
	else
		
	{
		
		
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"Location Services" message:@"Chirrup App needs permission to see your location. Please turn on location services in Settings!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		
		[alert show];;
		
		
		
	}	
	
	
}

-(void) start {
		if([CLLocationManager locationServicesEnabled])
		{
            [locationManager startUpdatingLocation];
        }
}

-(void) stop {
    [locationManager stopUpdatingLocation];
}



- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
}



- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	
	mLatitude = newLocation.coordinate.latitude;
	mLongitude = newLocation.coordinate.longitude;
    
    if (mLongitude != 0 && mLatitude != 0)
    {
        [self stop];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"LocationUpdated" object:nil userInfo:nil];
    }
}



#pragma mark rotate image

@end
