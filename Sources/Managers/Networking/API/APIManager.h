#import <Foundation/Foundation.h>

@protocol APIClient;

@interface APIManager: NSObject

@property (atomic, strong, readonly) id<APIClient> client;

+ (APIManager *)sharedInstanceWithClientProtocol:(Protocol *)protocol;
@end

typedef void (^ClientSuccessBlock)(NSURLRequest *request,
    NSString *response);
typedef void (^ClientFailureBlock)(NSURLRequest *request,
    NSError *error);
typedef void (^ClientSuccessBlockJSON)(NSURLRequest *request,
                                   id responseJSON);
typedef void (^ClientFailureBlockJSON)(NSURLRequest *request,
                                   id responseJSON);

@protocol APIClient <NSObject>

@property (atomic, copy) ClientSuccessBlock success;
@property (atomic, copy) ClientFailureBlock failure;
@property (atomic, copy) ClientSuccessBlockJSON successJSON;
@property (atomic, copy) ClientFailureBlockJSON failureJSON;

- (void)postToURL:(NSURL *)url
       parameters:(NSDictionary *)parameters
       withMethod:(NSString *)method;

- (void)postToURL:(NSURL *)url
       parameters:(NSDictionary *)parameters
       withMethod:(NSString *)method
       servertoken:(NSString *)token;

- (void)postToURL:(NSURL *)url
       parameters:(NSDictionary *)parameters;

- (void)postToURLWithJSON:(NSURL *)url
        parameters:(NSDictionary *)parameters
        withMethod:(NSString *)method
        servertoken:(NSString *)token;

- (void)postToURLMultipartFormdata:(NSURL *)url
        parameters:(NSArray *)params
        servertoken:(NSString *)token;
@end

// Public interface to initiate the registration workflow

@protocol APIAccessClient <APIClient>

- (void)postEmail:(NSString *)email password:(NSNumber *)passwd jid:(NSString *)jid devicetoken:(NSString *)token;
- (void)postActivationCode:(NSString *)activationCode
                  forEmail:(NSString *)email forPassword:(NSNumber *)passwd;
- (void)postVerificationCode:(NSString *)verificationCode
                       forEmail:(NSString *)email;
- (void)requestVerificationCode:(NSString *)email;
- (void)addProfile:(NSString *)fname lastname:(NSString *)lname photo:(UIImage *)image jobtitle:(NSString *)job_title mobilenumber:(NSString *)mobile_number;
- (void)addContacts:(NSArray *)contactsArray;
- (void)deleteContacts:(NSString *)contactsArray;
- (void)getContacts;
- (void)getUpdatedContacts:(NSString *)dateOfPreviousApiCall;
- (void)getCompanyContacts;
- (void)getSalesforceContacts;
- (void)getGoogleContacts;
- (void)getZohoContacts;

- (void)createDiscussionWithID:(NSString *)uuid title:(NSString *)discTitle members:(NSArray *)memberList groups:(NSArray *)groupList is1on1:(NSString *)is1on1;
- (void)getDiscussion:(NSString *)discussionId;
- (void)getDiscussions;
- (void)getUpdatedDiscussions:(NSString *)timestamp;
- (void)updateDiscussionWithID:(NSString *)uuid title:(NSString *)discTitle members:(NSArray *)memberList groups:(NSArray *)groupList is1on1:(NSString *)is1on1;
- (void)deleteDiscussion:(NSString *)discussionId;
- (void)createGroupWithName:(NSString *)name members:(NSArray *)memberList;
- (void)updateGroupWithID:(NSString *)groupID name:(NSString *)name members:(NSArray *)memberList;
- (void)deleteGroupWithID:(NSString *)groupID;
- (void)getGroups;
- (void)getMessages:(NSString *)discussionId page:(int)pagenum;
- (void)getUnreadMessages:(NSString *)discussionId lastRead:(NSString *)messageId;

// Login
- (void)login:(NSString *)email andPassword:(NSNumber *)passwd;

// Productivity Category workflow
// Create
- (void)createSummaryWithDiscussionId:(NSString *)discussionId MessageId:(NSString *)messageId CategoryType:(int)categoryType andNotes:(NSString *)notes;
- (void)createSummaryWithDiscussionId:(NSString *)discussionId MessageId:(NSString *)messageId CategoryType:(int)categoryType MsgTimeStamp:(NSString *)messageTimeStamp andNotes:(NSString *)notes;
- (void)getSummaryPointWithDiscussionId:(NSString *)discussionId MessageId:(NSString *)messageId CategoryType:(int)categoryType;

- (void)createReminderWithDiscussionId:(NSString *)discussionId MessageId:(NSString *)messageId CategoryType:(int)categoryType andAttributes:(NSDictionary *)attributes;
- (void)createReminderWithDiscussionId:(NSString *)discussionId MessageId:(NSString *)messageId CategoryType:(int)categoryType MsgTimeStamp:(NSString *)messageTimeStamp andAttributes:(NSDictionary *)attributes;


- (void)createTaskWithDiscussionId:(NSString *)discussionId MessageId:(NSString *)messageId CategoryType:(int)categoryType andAttributes:(NSDictionary *)attributes;
- (void)createTaskWithDiscussionId:(NSString *)discussionId MessageId:(NSString *)messageId CategoryType:(int)categoryType MsgTimeStamp:(NSString *)messageTimeStamp andAttributes:(NSDictionary *)attributes;


- (void)createMeetingWithDiscussionId:(NSString *)discussionId MessageId:(NSString *)messageId CategoryType:(int)categoryType andAttributes:(NSDictionary *)attributes;
- (void)createMeetingWithDiscussionId:(NSString *)discussionId MessageId:(NSString *)messageId CategoryType:(int)categoryType MsgTimeStamp:(NSString *)messageTimeStamp andAttributes:(NSDictionary *)attributes;



- (void)createUserDefinedCategoryWithName:(NSString *)name andColor:(NSString *)color;
- (void)createUserDefinedCategoryInstanceWithDiscussionId:(NSString *)discussionId MessageId:(NSString *)messageId CategoryType:(int)categoryType andNotes:(NSString *)notes;
- (void)createUserDefinedCategoryInstanceWithDiscussionId:(NSString *)discussionId MessageId:(NSString *)messageId CategoryType:(int)categoryType MsgTimeStamp:(NSString *)messageTimeStamp andNotes:(NSString *)notes;

// Delete
- (void)deleteCategoryWithDiscussionId:(NSString *)discussionId MessageId:(NSString *)messageId CategoryType:(int)categoryType;

//Get Category Task
- (void)getCategoryTask:(NSString *)categoryId;

//Get Category Meeting
- (void)getCategoryMeeting:(NSString *)categoryId;

// Get maximum no of user defined category
- (void)getMaximumUDCValue;

// Get maximum no of user defined category
- (void)getUDCData;

// Update UDC
- (void)updateUserDefinedCategoryWithName:(NSString *)name andId:(int)udcId;

// Discussion Notification Methods
- (void)setCategoryAcceptanceWithOwner:(NSString *)owner MessageId:(NSString *)messageId DiscussionId:(NSString *)discussionId CategoryType:(int)categoryType andIsAccepted:(BOOL)isAccept;

// Get Discussion Summary
- (void)getDiscussionSummaryByDiscussionId:(NSString *)discussionId;

// send Discussion Summary using e-mail
- (void)sendEmail:(NSString *)from to:(NSString *)to subject:(NSString *)subject body:(NSString *)body attachments:(NSString *)attachments;


//external auths
- (void) getClientAuth;
- (void) saveZohoAuth:(NSString *)data;

//search and browse
- (void) cloudSearch:(NSString *)query;
- (void) boxSearch:(NSString *)query;
- (void) dropboxSearch:(NSString *)query;
- (void) gdriveSearch:(NSString *)query;
- (void)browse:(NSString *)externalSystem withRoot:(NSString *)root andType:(NSString *)type;

//fetching files
- (void) fetchDownloadUrlFromGoogle: (NSString *)accessToken withFile:(NSString *)id;

// Activity History
- (void)getCategoriesCount;
- (void)getUserReminders;
- (void)getUserMeetingInvites;
- (void)getUserTasks;

//bookmarks
- (void)createBookmark:(NSString *)url withName:(NSString *)name;
- (void)getBookmarks;

//Tasks
- (void)getSalesforceRecords:(NSString *)recordType;
- (void)getTrelloRecords;
- (void)getTrelloLists:(NSString *)boardId;
- (void)getAsanaRecords;
- (void)saveTrelloTask:(NSString *)name withListId:(NSString *)listId andDescription:(NSString *)desc
                andDue:(NSString *)due;
- (void)joinTrelloTask:(NSString *)id;
- (void)saveAsanaTask:(NSString *)name withWorkspaceId:(NSString *)workspaceId andProjectId:(NSString *)projectId andDescription:(NSString *)desc andDue:(NSString *)due;
- (void)saveAsanaSubtask:(NSString *)id withName:(NSString *)name andDescription:(NSString *)desc andDue:(NSString *)due;
- (void)saveSalesforceTask:(NSString *)name withAccountId:(NSString *)accountId andDescription:(NSString *)desc andDue:(NSString *)due;
- (void)saveTaskPreferences:(NSString *)source withLevel1:(NSString *)level1 andLevel2:(NSString *)level2;

- (void)setCategoryProgressStatusWithOwner:(NSString *)owner MessageId:(NSString *)messageId DiscussionId:(NSString *)discussionId CategoryType:(int)categoryType andProgressStatus:(NSString *)progressStatus;

- (void)editUserProfile:(NSString *)fname lastname:(NSString *)lname photo:(UIImage *)image jobtitle:(NSString *)job_title mobilenumber:(NSString *)mobile_number companyContactStatus:(NSString *)companyContactStatus externalContactsStatus:(NSString *)externalContactsStatus allContactsStatus:(NSString *)allContactsStatus;

- (void)getUserProfile:(NSString *)email;
- (void)getUserProfileForJID:(NSString *)jid;
- (void)getFullProfile;

- (void)setUserAvailability:(NSDictionary *)params;
- (void)getUserAvailability;

- (void)updatePin:(NSString *)newPin;

- (void)deleteUserSourceUsingType:(NSString *)type;

- (void)updateSignature:(NSString *)signature;

- (void)getSignature;

@end
