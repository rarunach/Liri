#import "AppConstants.h"
//#import "NSString+HTML.h"
#import "MessageLogManager.h"
#import "Message.h"
#import "Buddy.h"
#import "Account.h"
#import "S3Manager.h"

@implementation Buddy

#pragma mark -
#pragma mark Buddy

@synthesize displayName, firstName, lastName, email, jabberid, profile_pic, photo, isUser, storage, availabilityStatus;

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:displayName forKey:@"displayName"];
    [coder encodeObject:firstName forKey:@"firstName"];
    [coder encodeObject:lastName forKey:@"lastName"];
    [coder encodeObject:email forKey:@"email"];
    [coder encodeObject:jabberid forKey:@"jabberid"];
    [coder encodeObject:profile_pic forKey:@"profile_pic"];
    [coder encodeObject:photo forKey:@"photo"];
    [coder encodeBool:isUser forKey:@"isUser"];
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self != nil)
    {
        displayName = [coder decodeObjectForKey:@"displayName"];
        firstName = [coder decodeObjectForKey:@"firstName"];
        lastName = [coder decodeObjectForKey:@"lastName"];
        email = [coder decodeObjectForKey:@"email"];
        jabberid = [coder decodeObjectForKey:@"jabberid"];
        profile_pic = [coder decodeObjectForKey:@"profile_pic"];
        photo = [coder decodeObjectForKey:@"photo"];
        isUser = [coder decodeBoolForKey:@"isUser"];
    }
    return self;
}

+ (Buddy *)buddyWithDisplayName:(NSString *)name
                      jabberid:(NSString *)jid
{
    return [[self alloc] initWithDisplayName:name
                        jabberid:jid];
}

+ (Buddy *)buddyWithDisplayName:(NSString *)name
                       email:(NSString *)email
                        profile_pic:(NSString *)pic
                        isUser:(BOOL)userflag
{
    return [[self alloc] initWithDisplayName:name
                        email:email profile_pic:pic isUser:userflag];
}

+ (Buddy *)buddyWithDisplayName:(NSString *)name
                          email:(NSString *)email
                          photo:(UIImage *)pic
                         isUser:(BOOL)userflag
{
    return [[self alloc] initWithDisplayName:name
                            email:email photo:pic isUser:userflag];
}

- (id)initWithDisplayName:(NSString *)name
              jabberid:(NSString *)jid
{
    if ((self = [super init]) != nil) {
        displayName = name;
        NSArray *components = [name componentsSeparatedByString:@" "];
        firstName = components[0];
        lastName = components[1];
        jabberid = jid;
        // initialize the other variables to nil.
        profile_pic = nil;
        email = nil;
    }
    return self;
}

- (id)initWithDisplayName:(NSString *)name
                    email:(NSString *)emailId
                    profile_pic:(NSString *)pic
                   isUser:(BOOL)userflag
{
    if ((self = [super init]) != nil) {
        displayName = name;
        NSArray *components = [name componentsSeparatedByString:@" "];
        firstName = components[0];
        lastName = components[1];
        email = emailId;
        jabberid = [Account emailToJid:email];
        profile_pic = pic;
        isUser = userflag;
    }
    return self;
}

- (id)initWithDisplayName:(NSString *)name
                    email:(NSString *)emailId
                    photo:(UIImage *)pic
                   isUser:(BOOL)userflag
{
    if ((self = [super init]) != nil) {
        displayName = name;
        NSArray *components = [name componentsSeparatedByString:@" "];
        firstName = components[0];
        lastName = components[1];
        email = emailId;
        jabberid = [Account emailToJid:email];
        photo = pic;
        isUser = userflag;
    }
    return self;
}

- (id<MessageLogStorage>)storage;
{
    if (storage == nil){
        storage = [[MessageLogManager sharedInstance] storage];
    }
    return storage;
}

@end
