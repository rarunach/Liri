#import "Message.h"
#import "Account.h"
#import "S3Manager.h"

@implementation Message

#pragma mark -
#pragma mark Message

@synthesize message, messageId, messageType;
@synthesize sender, date, annotatedImage, categoriesArray;

+ (Message *)incomingMessage:(NSString *)message withId:(NSString *)msgId from:(Buddy *)sender
{
    NSArray *components = [message componentsSeparatedByString:@":"];
    if (components.count == 2) {
        NSString *tag = components[0];
        NSString *url = components[1];
        if ([tag isEqualToString:ANNOTATION_TAG]) {
            
            return [[self alloc] initWithSender:sender message:message messageId:msgId type:MSG_TYPE_ANNOTATION annotatedImageUrl:url received:YES unread:YES];
        }
    }
    return [[self alloc] initWithSender:sender message:message messageId:msgId type:MSG_TYPE_TEXT annotatedImageUrl:nil received:YES unread:YES];
}

+ (Message *)outgoingMessage:(NSString *)message withId:(NSString *)msgId
{
    Account *account = [Account sharedInstance];
    NSArray *components = [message componentsSeparatedByString:@":"];
    if (components.count == 2) {
        NSString *tag = components[0];
        NSString *url = components[1];
        if ([tag isEqualToString:ANNOTATION_TAG]) {
            
            return [[self alloc] initWithSender:[account getMyBuddy] message:message messageId:msgId type:MSG_TYPE_ANNOTATION annotatedImageUrl:url received:NO unread:YES];
        }
    }
    return [[self alloc] initWithSender:[account getMyBuddy] message:message messageId:msgId
                                   type:MSG_TYPE_TEXT annotatedImageUrl:nil received:NO unread:YES];
}

+ (Message *)outgoingTextMessage:(NSString *)message
{
    Account *account = [Account sharedInstance];
    return [[self alloc] initWithSender:[account getMyBuddy] message:message messageId:[[NSUUID UUID] UUIDString]
                          type:MSG_TYPE_TEXT annotatedImageUrl:nil received:NO unread:YES];
}

+ (Message *)outgoingAnnotationMessageWithName:(NSString *)imageUrl image:(UIImage *)image
{
    Account *account = [Account sharedInstance];
    NSString *message = [NSString stringWithFormat:@"%@:%@", ANNOTATION_TAG, imageUrl];
    Message *messageObj = [[self alloc] initWithSender:[account getMyBuddy] message:message messageId:[[NSUUID UUID] UUIDString] type:MSG_TYPE_ANNOTATION annotatedImageUrl:imageUrl received:NO unread:YES];
    messageObj.annotatedImage = image;
    return messageObj;
}

+ (Message *)messageWithSender:(Buddy *)buddy
                        message:(NSString *)message
                    messageId:(NSString *)msgId
                          type:(NSInteger)msgType
                annotatedImageUrl:(NSString *)imageUrl
                       received:(BOOL)received
                       unread:(BOOL)unread
{
    return [[self alloc] initWithSender:buddy message:message messageId:msgId
                                   type:msgType annotatedImageUrl:imageUrl
                               received:received unread:unread];
}

- (id)initWithSender:(Buddy *)theSender
            message:(NSString *)theMessage
          messageId:(NSString *)msgId
                type:(NSInteger)msgType
       annotatedImageUrl:(NSString *)imageUrl
           received:(BOOL)beenReceived
             unread:(BOOL)beenUnread
{
    if ((self = [super init]) != nil) {
        self.sender = theSender;
        self.message = theMessage;
        self.messageId = msgId;
        self.messageType = msgType;
        self.annotatedImageUrl = imageUrl;
        self.received = beenReceived;
        self.unread = beenUnread;
        self.date = [NSDate date];
        self.categoriesArray = [[NSMutableArray alloc]init];
    }
    return self;
}

- (void)getAnnotatedImage
{
    if (self.messageType == MSG_TYPE_TEXT)
        return;
    if (!self.annotatedImage) {
        Account *account = [Account sharedInstance];
        self.annotatedImage = [account.s3Manager downloadImage:self.annotatedImageUrl];
    }
}

- (void)setTimestamp:(NSString *)epochTime
{
    NSTimeInterval seconds = [epochTime doubleValue]/1000;
    
    self.date = [[NSDate alloc] initWithTimeIntervalSince1970:seconds];
}

@end
