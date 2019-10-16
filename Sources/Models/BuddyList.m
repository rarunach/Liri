#import "BuddyList.h"
#import "Account.h"

@implementation BuddyList

#pragma mark -
#pragma mark NSObject

- (id)init
{
    if ((self = [super init]) != nil)
        self.allBuddies = [[NSMutableArray alloc] init];
    return self;
}

#pragma mark -
#pragma mark BuddyList

@synthesize allBuddies;

- (void)addBuddy:(Buddy *)buddy
{
    if (nil != buddy) {
        [self.allBuddies addObject:buddy];
    }
}

- (void)removeBuddy:(Buddy *)buddy
{
    [self.allBuddies removeObject:buddy];
}

- (Buddy *)findBuddyForName:(NSString *)name
{
    for (Buddy *buddy in allBuddies) {
        if ([buddy.displayName isEqualToString:name])
            return buddy;
    }
    return nil;
}

- (Buddy *)findBuddyForEmail:(NSString *)email
{
    for (Buddy *buddy in allBuddies) {
        if ([buddy.email isEqualToString:email])
            return buddy;
    }
    return nil;
}

- (Buddy *)findBuddyForJid:(NSString *)jid
{
    // remove the domain.
    NSRange atPos = [jid rangeOfString:@"@"];
    NSString *lookupJID = jid;
    if (atPos.location != NSNotFound)
    {
        lookupJID = [jid substringToIndex:atPos.location];
        //range.location is start of substring
        //range.length is length of substring
    }
    for (Buddy *buddy in allBuddies) {
        NSString *jidstr = [Account emailToBareJid:buddy.email];
        if (!([jidstr rangeOfString:lookupJID].location == NSNotFound))
            return buddy;
    }
    return nil;
}

- (void)saveBuddiesToUserDefaults
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:allBuddies] forKey:@"BUDDYLIST"];
}

- (void)restoreBuddiesFromUserDefaults
{
    NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
    NSData *dataRepresentingSavedArray = [currentDefaults objectForKey:@"BUDDYLIST"];
    if (dataRepresentingSavedArray != nil)
    {
        NSArray *oldSavedArray = [NSKeyedUnarchiver unarchiveObjectWithData:dataRepresentingSavedArray];
        if (oldSavedArray != nil)
            allBuddies = [[NSMutableArray alloc] initWithArray:oldSavedArray];
        else
            allBuddies = [[NSMutableArray alloc] init];
    }
}
@end
