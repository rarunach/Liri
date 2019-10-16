#import "AccountUserDefaultsStorage.h"
#import "AccountManager.h"

static __strong AccountManager *kSharedInstance = nil;
static __strong id<AccountStorage> kSharedStorage = nil;

@interface AccountManager()

+ (Class)accountStorageClass;
@end

@implementation AccountManager

#pragma mark -
#pragma mark NSObject

- (id)init
{
    if ((self = [super init]) != nil)
        // Load the account from the start
        [self.storage getAccount];
    return self;
}

#pragma mark -
#pragma mark Singleton methods

+ (AccountManager *)sharedInstance
{
    @synchronized(self) {
        if (kSharedInstance == nil)
            kSharedInstance = [[super allocWithZone:nil] init];
    }
    return kSharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (kSharedInstance == nil) {
            kSharedInstance = [super allocWithZone:zone];
            return kSharedInstance;
        }
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

#pragma mark -
#pragma mark AccountManager

@synthesize storage;

+ (void)replaceInstance:(AccountManager *)instance
{
    kSharedInstance = nil;
}

+ (id<AccountStorage>)storage
{
    @synchronized (self) {
        if (kSharedStorage == nil)
            kSharedStorage = [[[self accountStorageClass] alloc] init];
    }
    return kSharedStorage;
}

+ (void)setStorage:(id<AccountStorage>)storage
{
    kSharedStorage = storage;
}

+ (Class)accountStorageClass
{
    return [AccountUserDefaultsStorage class];
}

- (id<AccountStorage>)storage
{
    @synchronized (self) {
        if (storage == nil) {
            storage = [[self class] storage];
        }
    }
    return storage;
}
@end
