#import <Foundation/Foundation.h>

#import "Account.h"

@protocol AccountStorage;

@interface AccountManager: NSObject

@property (nonatomic, readonly) id<AccountStorage> storage;

+ (AccountManager *)sharedInstance;
+ (void)replaceInstance:(AccountManager *)instance;
+ (id<AccountStorage>)storage;
+ (void)setStorage:(id<AccountStorage>)storage;
@end

@protocol AccountStorage <NSObject>

- (Account *)getAccount;
- (void)saveAccount:(Account *)account;
- (void)clearStorage;
@end
