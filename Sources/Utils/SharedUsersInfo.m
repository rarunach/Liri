#import "SharedUsersInfo.h"
#import "AppDelegate.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

//file path for storing new whistles post notification
#define kFriedsUpdatesPlistPath [@"~/Documents/friends_badge.plist" stringByExpandingTildeInPath]

//file path for storing comments notifications
#define kCommentsNotificaitonPlistPath [@"~/Documents/comments_notifications.plist" stringByExpandingTildeInPath]

// Fine the device whether 4 or 5
#define IS_WIDESCREEN ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )


static SharedUsersInfo* _sharedManager = nil;

@implementation SharedUsersInfo
@synthesize _myEmail;
@synthesize _rechability;
@synthesize dic_userQuestion;
@synthesize screenHeight;

+(SharedUsersInfo*)sharedManager
{
	@synchronized([SharedUsersInfo class])
	{
		if (!_sharedManager){
			_sharedManager = [[self alloc] init];
        }
		return _sharedManager;
        
	}
	return nil;
}

+(id)alloc
{
	@synchronized([SharedUsersInfo class])
	{
		NSAssert(_sharedManager == nil, @"Attempted to allocate a second instance of a singleton.");
		_sharedManager = [super alloc];
		return _sharedManager;
	}
	return nil;
}

// Method to fix the device screen height
- (BOOL) isIOS5
{
    //return IS_WIDESCREEN;
    return true;
}

- (void) defineScreenHeight {
    screenHeight = [NSNumber numberWithInt:480];
    //if(IS_WIDESCREEN)
    if (true)
        screenHeight = [NSNumber numberWithInt:568];
    
}

-(id)init {
	self = [super init];
	if (self != nil)
    {
        [self defineScreenHeight];
        
        [self startReachabilityWatching];
        self._myEmail = nil;
	}
	return self;
}

//- (NSMutableArray *)usersWithOnlineStatuses
//{
//    
//    return _userStatusesArray;
//}
//
//- (void)addUserForOnlineStatus:(NSDictionary *)inUser
//{
//    NSString* user = [inUser objectForKey:@"user"];
//    int count = 0;
//    BOOL found = NO;
//    for (NSDictionary* userDict in _userStatusesArray)
//    {
//        NSString* existingUser = [userDict objectForKey:@"user"];
//        if ([existingUser isEqualToString:user]) {
//            found = YES;
//            [_userStatusesArray replaceObjectAtIndex:count withObject:inUser];
//            break;
//        }
//        count++;
//    }
//    
//    if (found == NO) {
//        [_userStatusesArray addObject:inUser];
//    }
//    
//    [[NSNotificationCenter defaultCenter]
//     
//     postNotificationName:@"statusUpdate"
//     
//     object:self userInfo:nil];
//}
//
//- (BOOL)isUserOnline:(NSDictionary *)inUser
//{
//    for (NSDictionary* userDict in _userStatusesArray)
//    {
//        NSString* user = [[[userDict objectForKey:@"user"] componentsSeparatedByString:@"@"] objectAtIndex:0];
//        if ([user isEqualToString:[inUser objectForKey:@"phone"]] && [[userDict objectForKey:@"isOnline"] boolValue]) {
//            return YES;
//        }
//    }
//    return NO;
//}
//
//- (BOOL)isUserOnlineCheckFromPhoneNumber:(NSString *)inPhoneNumber
//{
//    for (NSDictionary* userDict in _userStatusesArray)
//    {
//        NSString* user = [[[userDict objectForKey:@"user"] componentsSeparatedByString:@"@"] objectAtIndex:0];
//        if ([user isEqualToString:inPhoneNumber] && [[userDict objectForKey:@"isOnline"] boolValue]) {
//            return YES;
//        }
//    }
//    return NO;
//}

//-(void)updateUserContacts
//{
//    //get all contacts from address book
//    ABAddressBookRef ab = NULL;
//    // ABAddressBookCreateWithOptions is iOS 6 and up.
//    if (&ABAddressBookCreateWithOptions) {
//        NSError *error = nil;
//        ab = ABAddressBookCreateWithOptions(NULL, NULL);
//#if DEBUG
//        if (error) { DebugLog(@"%@", error); }
//#endif
//    }
//    if (ab == NULL) {
//        //        ab = ABAddressBookCreate();
//    }
//    if (ab) {
//        // ABAddressBookRequestAccessWithCompletion is iOS 6 and up.
//        //ABAddressBookGetAuthorizationStatus
//        if (&ABAddressBookRequestAccessWithCompletion) {
//            ABAddressBookRequestAccessWithCompletion(ab,
//                                                     ^(bool granted, CFErrorRef error) {
//                                                         if (granted) {
//                                                             NSArray *peopleArray = [[ NSArray alloc]initWithArray:(__bridge_transfer NSArray *)ABAddressBookCopyArrayOfAllPeople(ab)];
//                                                             
//                                                             if([_phoneContactsArray count]==0)
//                                                             {
//                                                                 int i=0;
//                                                                 peopleArray =(__bridge_transfer NSArray *)ABAddressBookCopyArrayOfAllPeople(ab);
//                                                                 [_phoneContactsArray removeAllObjects];
//                                                                 
//                                                                 for(i = 0; i < [peopleArray count]; i++) {
//                                                                     
//                                                                     ABRecordRef record =(__bridge ABRecordRef)[peopleArray objectAtIndex:i];
//                                                                     
//                                                                     NSString *personName=(__bridge_transfer NSString *)ABRecordCopyValue(record, kABPersonFirstNameProperty);
//                                                                     if([personName length]>0)
//                                                                     {
//                                                                     }
//                                                                     else{
//                                                                         personName = @"";
//                                                                     }
//                                                                     
//                                                                     NSString *personmiddleName = (__bridge_transfer NSString *)ABRecordCopyValue(record, kABPersonMiddleNameProperty);
//                                                                     if([personmiddleName length]>0)
//                                                                     {
//                                                                         personName =  [personName stringByAppendingString:@" "];
//                                                                         personName =   [personName stringByAppendingString:personmiddleName];
//                                                                     }
//                                                                     
//                                                                     NSString *personlastName = (__bridge_transfer NSString *)ABRecordCopyValue(record, kABPersonLastNameProperty);
//                                                                     if([personlastName length]>0)
//                                                                     {
//                                                                         personName =  [personName stringByAppendingString:@" "];
//                                                                         personName = [personName stringByAppendingString:personlastName];
//                                                                     }
//                                                                     ABMutableMultiValueRef multiPhone =ABRecordCopyValue(record,kABPersonPhoneProperty);
//                                                                     
//                                                                     if(multiPhone !=nil)
//                                                                     {
//                                                                         NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
//                                                                         
//                                                                         NSArray* array =(__bridge_transfer NSArray *) ABMultiValueCopyArrayOfAllValues(multiPhone);
//                                                                         
//                                                                         int count = [array count];
//                                                                         if(count!=0)
//                                                                         {
//                                                                             NSString *personPhoneNum = [[array objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
//                                                                             
//                                                                             personPhoneNum = [personPhoneNum stringByReplacingOccurrencesOfString:@"(" withString:@""];
//                                                                             personPhoneNum = [personPhoneNum stringByReplacingOccurrencesOfString:@")" withString:@""];
//                                                                             personPhoneNum = [personPhoneNum stringByReplacingOccurrencesOfString:@"-" withString:@""];
//                                                                             personPhoneNum = [personPhoneNum stringByReplacingOccurrencesOfString:@" " withString:@""];
//                                                                             personPhoneNum = [personPhoneNum stringByReplacingOccurrencesOfString:@"+1" withString:@""];
//                                                                             
//                                                                             
//                                                                             //                                                                             BOOL valid = [StringUtil validatePhone:personPhoneNum];
//                                                                             
//                                                                             //                                                                             NSString *phoneRegex = @"[012345689][0-9]{7}([0-9]{3})?";
//                                                                             //                                                                             NSPredicate *test = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", phoneRegex];
//                                                                             //                                                                             BOOL matches = [test evaluateWithObject:personPhoneNum];
//                                                                             
//                                                                             
//                                                                             //if(matches)
//                                                                             {
//                                                                                 NSString *tt = [[NSString alloc]initWithString:personPhoneNum];
//                                                                                 
//                                                                                 //validate phone number
//                                                                                 NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
//                                                                                 NSNumber *number = [formatter numberFromString:tt];
//                                                                                 
//                                                                                 if ([tt length] != 0 && number != nil)
//                                                                                 {
//                                                                                     if (![tt hasSuffix:[self myOwnNumber]]) {
//                                                                                         if ([tt hasPrefix:@"1"] == YES) {
//                                                                                             tt = [@"+" stringByAppendingString:tt];
//                                                                                         }
//                                                                                         else if ([tt hasPrefix:@"+1"] == NO) {
//                                                                                             tt = [@"+1" stringByAppendingString:tt];
//                                                                                         }
//                                                                                         [dict setObject:tt forKey:@"Mobnum"];
//                                                                                         [dict setObject:personName forKey:@"Name"];
//                                                                                         [dict setObject:[NSNumber numberWithBool:NO] forKey:@"State"];
//                                                                                         [_phoneContactsArray addObject:dict];
//                                                                                     }
//                                                                                 }
//                                                                                 else{
//                                                                                     //DebugLog(@"my phone muber found: :%@",tt);
//                                                                                 }
//                                                                             }
//                                                                         }
//                                                                     }
//                                                                 }
//                                                                 [[NSUserDefaults standardUserDefaults] setObject:_phoneContactsArray forKey:@"contacts"];
//                                                                 [[NSUserDefaults standardUserDefaults] synchronize];
//                                                                 [[NSNotificationCenter defaultCenter] postNotificationName:@"contactsUpdated" object:nil userInfo:nil];
//                                                             }
//                                                         }
//                                                         else {
//                                                             //                                                             CFRelease(ab);
//                                                             // Ignore the error
//                                                         }
//                                                     });
//        } else {
//        }
//    }
//}

- (NSString *)myOwnEmail
{
    if (self._myEmail != nil) {
        return self._myEmail;
    }
    
    NSString* email = [[NSUserDefaults standardUserDefaults] objectForKey:@"USEREMAIL"];
    if (email == nil) {
        return nil;
    }
    self._myEmail = email;
    return email;
}

#pragma mark - Network Reachability check

- (BOOL)isInterNetAvailable
{
    
    NetworkStatus remoteHostStatus = [_rechability currentReachabilityStatus];
    
    
    if(remoteHostStatus == NotReachable)
    {
        return NO;
    }
    
    return YES;
}

- (void)startReachabilityWatching
{
    _rechability = [Reachability reachabilityForInternetConnection];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleReachability: )
                                                 name:kReachabilityChangedNotification object:nil];
    [_rechability startNotifier];
    
    NetworkStatus remoteHostStatus = [_rechability currentReachabilityStatus];
    
    
    if(remoteHostStatus == NotReachable)
    {
        [self showAlertForInternetNonAvailability];
    }
}

- (void) handleReachability:(NSNotification *) reach {
    
    NetworkStatus remoteHostStatus = [_rechability currentReachabilityStatus];
    
    if(remoteHostStatus == NotReachable) {
        [self showAlertForInternetNonAvailability];
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    BOOL connectionStatus = [self isInterNetAvailable];
    if (connectionStatus == NO) {
        [self showAlertForInternetNonAvailability];
    }
}

- (void)showAlertForInternetNonAvailability
{
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Chirrup requires internet connection" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alertView show];
    
}

@end
