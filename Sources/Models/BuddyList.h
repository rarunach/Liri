#import <Foundation/Foundation.h>

#import "Buddy.h"

@interface BuddyList: NSObject

@property (nonatomic, strong) NSMutableArray *allBuddies;

- (void)addBuddy:(Buddy *)buddy;
- (void)removeBuddy:(Buddy *)buddy;
- (Buddy *)findBuddyForName:(NSString *)name;
- (Buddy *)findBuddyForEmail:(NSString *)email;
- (Buddy *)findBuddyForJid:(NSString *)jid;
- (void)saveBuddiesToUserDefaults;
- (void)restoreBuddiesFromUserDefaults;

@end
