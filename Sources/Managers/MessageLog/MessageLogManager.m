#import "Storage/MessageLogUserDefaultsStorage.h"
#import "MessageLogManager.h"

static MessageLogManager *sharedManager = nil;

@interface MessageLogManager(Private)

@property (nonatomic, strong) id<MessageLogStorage> storage;
@end

@implementation MessageLogManager

#pragma mark -
#pragma mark Singleton methods

+ (MessageLogManager *)sharedInstance
{
    @synchronized (self) {
        if (sharedManager == nil)
            sharedManager = [[self alloc] init];
    }
    return sharedManager;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized (self) {
        if (sharedManager == nil)
            sharedManager = [super allocWithZone:zone];
            return sharedManager;
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

#pragma mark -
#pragma mark MessageLogManager

@synthesize storage;

- (id<MessageLogStorage>)storage
{
    @synchronized (self) {
        if (storage == nil) {
            storage = [[MessageLogUserDefaultsStorage alloc] init];
        }
    }
    return storage;
}
@end
