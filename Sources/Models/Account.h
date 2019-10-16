#import <Foundation/Foundation.h>
#import "APIManager.h"
#import "BuddyList.h"
#import "S3Manager.h"
#import "MKNumberBadgeView.h"

@interface Account: NSObject

@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *jid;
@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, copy) NSString *deviceToken;
@property (nonatomic, copy) NSString *serverToken;
@property (nonatomic, copy) NSNumber *password;
@property (nonatomic, copy) NSNumber *chatPin;
@property (nonatomic, copy) UIImage *photo;
@property (nonatomic, assign) bool box_auth;
@property (nonatomic, assign) bool dropbox_auth;
@property (nonatomic, assign) bool google_auth;
@property (nonatomic, assign) bool salesforce_auth;
@property (nonatomic, assign) bool asana_auth;
@property (nonatomic, assign) bool trello_auth;
@property (nonatomic, assign) bool linkedin_auth;
@property (nonatomic, assign) bool zoho_auth;
@property (nonatomic, retain) NSMutableArray *notificationsHistory;
@property (nonatomic, retain) Buddy *mybuddy;
@property (nonatomic, retain) BuddyList *buddyList;
@property (nonatomic, retain) S3Manager *s3Manager;
@property (nonatomic) BOOL deviceContactsImported;
@property (nonatomic, strong) NSMutableDictionary *buddyLookupArray;


//@property (nonatomic, retain)MKNumberBadgeView *badgeToDoList;
@property (nonatomic, retain)MKNumberBadgeView *badgeTask;
@property (nonatomic, retain)MKNumberBadgeView *badgeMeetingInvite;
+ (Account *)sharedInstance;
+ (BOOL)verifyEmail:(NSString *)email;
+ (void)replaceInstance:(Account *)instance;
+ (NSString *)emailToJid:(NSString *)email;
+ (NSString *)emailToBareJid:(NSString *)email;
- (NSString *)getUUID;
- (NSString *)getName;
- (Buddy *)getMyBuddy;

- (void)getConfiguration:(BOOL)isSignUp;

- (void)getUserCategoriesCount;

+ (void)setCategoriesCount:(NSString *)count;
+ (NSString *)getCategoriesCount;

+ (void)setTaskCount:(int)count;
+ (int)getTaskCount;

+ (void)setMeetingInviteCount:(int)count;
+ (int)getMeetingInviteCount;

+ (NSString *)convertGmtToLocalTimeZone:(NSString *)gmtString;
+ (NSString *)convertLocalToGmtTimeZone:(NSDate *)localString;
+ (NSDate *)convertGmtToLocalTimeZonePrecise:(NSString *)gmtString;
+ (NSString *)convertLocalToGmtTimeZonePrecise:(NSDate *)localString;

- (void)setDiscussionsBadgeValue;
@end
