#import "NSObject+ConformingClasses.h"
#import "APIManager.h"

static APIManager *kSharedInstance = nil;

@interface APIManager()

@property (atomic, strong) id<APIClient> client;

- (id)initWithClientProtocol:(Protocol *)protocol;
@end

@implementation APIManager

#pragma mark -
#pragma mark Singleton methods

+ (APIManager *)sharedInstanceWithClientProtocol:(Protocol *)protocol;
{
    @synchronized (self) {
        if (kSharedInstance == nil)
            kSharedInstance =
                [[super allocWithZone:nil] initWithClientProtocol:protocol];
    }
    return kSharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized (self) {
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
#pragma mark APIManager

@synthesize client;

- (id)initWithClientProtocol:(Protocol *)protocol
{
    if ((self = [super init]) != nil) {
        NSSet *clientClasses =
            [NSObject setWithClassesConformingToProtocol:protocol];

        // Any object from the set, even if the set is nil
        self.client = [[[clientClasses anyObject] alloc] init];
    }
    return self;
}
@end
