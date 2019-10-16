#import <Foundation/Foundation.h>
#import "Reachability.h"


@interface SharedUsersInfo : NSObject <UIAlertViewDelegate>
{
    NSString* _myEmail;
    Reachability*  _rechability;
    
    NSDictionary *dic_userQuestion;
    
    NSNumber *screenHeight;
}
@property (nonatomic, strong) Reachability*  _rechability;
@property (nonatomic, strong) NSString* _myEmail;
@property (nonatomic, strong) NSDictionary *dic_userQuestion;
@property (nonatomic, strong) NSNumber *screenHeight;

//returns shared instance
+(SharedUsersInfo*)sharedManager;

//add users to an array if particular user is online, this will be updated as an when friends come onle or go offline
//- (void)addUserForOnlineStatus:(NSDictionary *)inUser;

//returns array of friends online sttus
//- (NSMutableArray *)usersWithOnlineStatuses;

//check particular is online or no
//- (BOOL)isUserOnline:(NSDictionary *)inUser;

//fetchs all the address book contacts and places in an array
//-(void)updateUserContacts;

//returns own email
- (NSString *)myOwnEmail;
//returns internet availability
- (BOOL)isInterNetAvailable;
//alerview if no internet is available
- (void)showAlertForInternetNonAvailability;
- (BOOL) isIOS5;

@end
