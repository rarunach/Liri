#import <Foundation/Foundation.h>

#import "AppConstants.h"
#import "Buddy.h"

#define MSG_TYPE_TEXT       1
#define MSG_TYPE_ANNOTATION 2

#define ANNOTATION_TAG @"liri-image"

@interface Message: NSObject

@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *messageId;
@property (nonatomic) NSInteger messageType;
@property (nonatomic, copy) NSString *annotatedImageUrl;
@property (nonatomic, copy) UIImage *annotatedImage;
@property (nonatomic, copy) NSString *discussionJID;
@property (nonatomic, retain) Buddy *sender;
@property (nonatomic, assign) BOOL received;
@property (nonatomic, assign) BOOL unread;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, retain) NSMutableArray *categoriesArray;

+ (Message *)incomingMessage:(NSString *)message withId:(NSString *)msgId from:(Buddy *)sender;
+ (Message *)outgoingMessage:(NSString *)message withId:(NSString *)msgId;
+ (Message *)outgoingTextMessage:(NSString *)message;
+ (Message *)outgoingAnnotationMessageWithName:(NSString *)imageKey image:(UIImage *)image;

+ (Message *)messageWithSender:(Buddy *)buddy
                       message:(NSString *)message
                     messageId:(NSString *)msgId
                          type:(NSInteger)msgType
                annotatedImage:(NSString *)image
                      received:(BOOL)received
                        unread:(BOOL)unread;

- (void)getAnnotatedImage;
- (void)setTimestamp:(NSString *)epochTime;

@end
