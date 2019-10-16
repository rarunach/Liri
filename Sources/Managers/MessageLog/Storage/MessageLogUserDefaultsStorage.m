#import "AppConstants.h"

#import "MessageLogUserDefaultsStorage.h"

static NSString *const kStorageKey = @"MessageLogStorage";
static NSString *const kMessageKey = @"message";
static NSString *const kJIDKey = @"jid";
static NSString *const kDisplayNameKey = @"displayName";
static NSString *const kPhotoKey = @"photo";
static NSString *const kReceivedKey = @"received";
static NSString *const kUnreadKey = @"unread";
static NSString *const kDateKey = @"date";

@interface MessageLogUserDefaultsStorage()

@property (nonatomic, strong) NSMutableArray *storageMessages;

- (void)loadFromStorage;
- (void)saveToStorage;
@end

@implementation MessageLogUserDefaultsStorage

#pragma mark -
#pragma mark NSObject

- (id)init
{
    if ((self = [super init]) != nil) {
        self.storageMessages = [[NSMutableArray alloc] init];
        [self loadFromStorage];
    }
    return self;
}

#pragma mark -
#pragma mark <MessageLogStorage>

- (NSArray *)messages
{
    return self.storageMessages;
}


- (NSArray *)messagesForBuddy:(Buddy *)buddy
{
    return [[self messages] filteredArrayUsingPredicate:
        [NSPredicate predicateWithFormat:@"buddy.accountName like %@",
        buddy.jabberid]];
}

- (NSArray *)messagesForBuddy:(Buddy *)buddy
               sortDescriptors:(NSArray *)sortDescriptors
{
    return [[self messagesForBuddy:buddy]
       sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray *)messagesForBuddyAccountName:(NSString *)accountName
               sortDescriptors:(NSArray *)sortDescriptors
{
    NSPredicate *predicate =
        [NSPredicate predicateWithFormat:@"buddy.accountName like %@",
        accountName];

    return [[[self messages] filteredArrayUsingPredicate:predicate]
        sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray *)messagesWithSortDescriptors:(NSArray *)sortDescriptors
{
    return [[self messages] sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSInteger)countUnreadMessagesForBuddy:(Buddy *)buddy
{
    NSPredicate *predicate = [NSPredicate 
        predicateWithFormat:@"(buddy.accountName like %@) AND (unread == YES)",
        buddy.jabberid];

    return [[[self messages] filteredArrayUsingPredicate:predicate] count];
}

- (NSInteger)countUnreadMessages
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"unread == YES"];
    
    return [[[self messages] filteredArrayUsingPredicate:predicate] count];
}


- (NSArray *)buddiesByMessagesWithSortDescriptors:(NSArray *)sortDescriptors
{
    NSArray *sortedMessages =
        [self messagesWithSortDescriptors:sortDescriptors];
    NSMutableArray *buddies = [[NSMutableArray alloc] init];

    for (Message *message in sortedMessages) {
        Buddy *buddy = message.sender;

        if([[buddies filteredArrayUsingPredicate:
                [NSPredicate predicateWithFormat:@"accountName like %@",
                buddy.jabberid]] count] == 0)
            [buddies addObject:buddy];
    }
    return buddies;
}

- (void)setUnreadMessagesAsReadForBuddyAcountName:(NSString *)accountName
{
    NSArray *currentBuddyMessages = 
        [self messagesForBuddyAccountName:accountName
            sortDescriptors:[NSArray array]];
    for (Message *message in currentBuddyMessages) {
        message.unread = NO;
    }
    [self saveToStorage];
}

- (void)addMessage:(Message *)message
{
    [self.storageMessages addObject:message];
    [self saveToStorage];
}

- (void)reloadStorage
{
    [self.storageMessages removeAllObjects];
    [self loadFromStorage];
}

#pragma mark -
#pragma mark MessageLogUserDefaultsStorage

- (void)loadFromStorage
{
    NSArray *storedMessages =
        [[NSUserDefaults standardUserDefaults] arrayForKey:kStorageKey];
    for (NSDictionary *entry in storedMessages) {
        NSString *messageStr = [entry objectForKey:kMessageKey];
        NSString *JIDStr = [entry objectForKey:kJIDKey];
        NSString *displayName = [entry objectForKey:kDisplayNameKey];
        NSData *photo = [entry objectForKey:kPhotoKey];
        BOOL received = [[entry objectForKey:kReceivedKey] boolValue];
        BOOL unread = [[entry objectForKey:kUnreadKey] boolValue];
        NSDate *date = [entry objectForKey:kDateKey];
        Buddy *buddy = [Buddy buddyWithDisplayName:displayName
            jabberid:JIDStr];

        if (photo != nil) {
            buddy.photo = photo;
        }
        
        /* To be fixed */
        Message *message = [Message messageWithSender:buddy
                                              message:messageStr messageId:nil
                                                 type:0 annotatedImage:nil
                                             received:received unread:unread];

        //buddy.lastMessage = message;

        message.date = date;
        [self.storageMessages addObject:message];
    }
}

- (void)saveToStorage
{
    NSMutableArray *messagesToStore = [[NSMutableArray alloc] init];
    
    for (Message *message in self.storageMessages)
    {
        @try {
            NSMutableDictionary *entry =
            [NSMutableDictionary dictionaryWithDictionary:@{
                                              kMessageKey: message.message,
                                                  kJIDKey: message.sender.jabberid,
                                          kDisplayNameKey: message.sender.displayName,
                                             kReceivedKey: [NSNumber numberWithBool:message.received],
                                               kUnreadKey: [NSNumber numberWithBool:message.unread],
                                                 kDateKey:message.date
             }];
            
            if (message.sender.photo != nil)
            {
                [entry setObject:message.sender.photo forKey:kPhotoKey];
            }
            
            if (entry != nil) {
                [messagesToStore addObject:entry];
            }

        }
        @catch (NSException *exception) {
            NSLog(@"exception : %@",exception);
        }
        @finally {
            
        }
        
    }
    [[NSUserDefaults standardUserDefaults] setObject:messagesToStore
        forKey:kStorageKey];
    //send a notifacation for update the chat history
    /*
    [[NSNotificationCenter defaultCenter]
        postNotificationName:kNewMessageNotification
        object:self];*/
}

#pragma mark -
#pragma mark <MessageLogStorageTesting>

- (void)setFixture:(NSArray *)fixture
{
    fixture = fixture;
    [[NSUserDefaults standardUserDefaults] setObject:fixture forKey:kStorageKey];
    [self reloadStorage];
}
@end
