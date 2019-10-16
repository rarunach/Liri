#import <Foundation/Foundation.h>

@protocol MessageLogStorage;
@class Message;

@interface Buddy: NSObject

@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *jabberid; //Jid in xmpp
@property (nonatomic, copy) NSString *profile_pic;
@property (nonatomic, copy) UIImage *photo;
@property (nonatomic) BOOL isUser;
@property (nonatomic, weak) id<MessageLogStorage> storage;
@property (nonatomic, copy) NSString *availabilityStatus;

+ (Buddy *)buddyWithDisplayName:(NSString *)name
                      jabberid:(NSString *)jid;
+ (Buddy *)buddyWithDisplayName:(NSString *)name
                       email:(NSString *)email
                        profile_pic:(NSString *)pic
                         isUser:(BOOL)userflag;
+ (Buddy *)buddyWithDisplayName:(NSString *)name
                          email:(NSString *)email
                          photo:(UIImage *)pic
                         isUser:(BOOL)userflag;

- (id)initWithDisplayName:(NSString *)name
              jabberid:(NSString *)jid;

- (id)initWithDisplayName:(NSString *)name
                 email:(NSString *)email
                profile_pic:(NSString *)pic
                   isUser:(BOOL)userflag;
- (id)initWithDisplayName:(NSString *)name
                    email:(NSString *)email
                    photo:(UIImage *)pic
                   isUser:(BOOL)userflag;
@end
