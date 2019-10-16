#import "AccountUserDefaultsStorage.h"

static NSString *const kStorageKey = @"AccountSingletonStorage";
static NSString *const kEmailKey = @"email";
static NSString *const kPasswordKey = @"password";
static NSString *const kChatPinKey = @"chatPin";
static NSString *const kFirstNameKey = @"firstName";
static NSString *const kLastNameKey = @"lastName";
static NSString *const kPhotoKey = @"photo";

@interface AccountUserDefaultsStorage()

- (Account *)loadFromStorage;
- (void)saveToStorage:(Account *)account;
@end

@implementation AccountUserDefaultsStorage

#pragma mark -
#pragma mark <AccountStorage>

- (Account *)getAccount
{
    return [self loadFromStorage];
}

- (void)saveAccount:(Account *)account
{
    return [self saveToStorage:account];
}

- (void)clearStorage
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kStorageKey];
}

#pragma mark -
#pragma mark AccountUserDefaultsStorage

- (Account *)loadFromStorage
{
    NSDictionary *storedAccount =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:kStorageKey];

    if (storedAccount == nil)
        return nil;

    NSString *email = storedAccount[kEmailKey];
    NSNumber *password = storedAccount[kPasswordKey];
    NSNumber *chatPin = storedAccount[kChatPinKey];
    NSString *firstName = storedAccount[kFirstNameKey];
    NSString *lastName = storedAccount[kLastNameKey];
    NSData *photo = storedAccount[kPhotoKey];

    Account *account = [Account sharedInstance];

    account.email = email;
    account.password = password;
    account.chatPin = chatPin;
    account.firstName = firstName;
    account.lastName = lastName;
    //account.photo = photo;

    return account;
}

- (void)saveToStorage:(Account *)account
{
    NSMutableDictionary *entry = [NSMutableDictionary dictionary];
    [entry setValue:account.email forKey:kEmailKey];
    if (account.password != nil) {
        [entry setValue:account.password forKey:kPasswordKey];
    }
    if (account.chatPin != nil) {
        [entry setValue:account.chatPin forKey:kChatPinKey];
    }
    if (account.firstName != nil) {
        [entry setValue:account.firstName forKey:kFirstNameKey];
    }
    if (account.lastName != nil) {
        [entry setValue:account.lastName forKey:kLastNameKey];
    }
    if (account.photo != nil) {
        [entry setValue:account.photo forKey:kPhotoKey];
    }
    [[NSUserDefaults standardUserDefaults] setObject:entry forKey:kStorageKey];
}
@end
