#import <Foundation/Foundation.h>

#import "XMPPFramework.h"
#import "Message.h"
#import "BuddyList.h"
#import "XMPPRoom.h"

#define NS_ERROR_CONNECTION_REFUSED 61

@interface XMPPManager: NSObject <XMPPStreamDelegate, XMPPRoomDelegate>

@property (nonatomic, assign) BOOL isXmppAuthenticated;
@property (nonatomic, assign) BOOL isNetworkReachable;


+ (XMPPManager *)sharedInstance;

- (void)registerOrLogin;
- (void)sendMessage:(Message *)messageObj;
- (BOOL)goOnline;
- (void)goOffline;
- (XMPPRoom *)createRoomWithJID:(NSString *)jidstr withSubject:(NSString *)roomSubject memberList:(BuddyList *)list;
- (XMPPRoom *)joinRoomWithJID:(NSString *)jidstr;
- (void)leaveRoom:(XMPPRoom *)xmppRoom;
- (void)updateRoomMembersForRoom:(XMPPRoom *)xmppRoom memberList:(NSMutableArray *)list;
- (void)sendMessageToRoom:(NSString *)jidstr message:(Message *)messageObj;
- (BOOL)changePassword:(NSString *)JIDStr password:(NSString *)thePassword;
- (NSString *)getChatDomain;
- (void)handleDisconnectTimer:(NSTimer*)timer;

@end
