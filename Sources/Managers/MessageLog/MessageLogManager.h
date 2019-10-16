#import <Foundation/Foundation.h>

#import "Message.h"
#import "Buddy.h"

@protocol MessageLogStorage <NSObject>

- (NSArray *)messages;
- (NSArray *)messagesForBuddy:(Buddy *)buddy;
- (NSArray *)messagesForBuddy:(Buddy *)buddy
               sortDescriptors:(NSArray *)sortDescriptors;
- (NSArray *)messagesForBuddyAccountName:(NSString *)accountName
               sortDescriptors:(NSArray *)sortDescriptors;
- (NSArray *)messagesWithSortDescriptors:(NSArray *)sortDescriptors;
- (NSInteger)countUnreadMessagesForBuddy:(Buddy *)buddy;
- (NSInteger)countUnreadMessages;
- (NSArray *)buddiesByMessagesWithSortDescriptors:(NSArray *)sortDescriptors;
- (void)setUnreadMessagesAsReadForBuddyAcountName:(NSString *)accountName;
- (void)addMessage:(Message *)message;
- (void)reloadStorage;
- (void)setFixture:(NSArray *)fixture;
@end

@interface MessageLogManager: NSObject

@property (nonatomic, readonly) id<MessageLogStorage> storage;

+ (MessageLogManager *)sharedInstance;
@end
