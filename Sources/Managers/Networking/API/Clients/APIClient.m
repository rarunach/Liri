#import "AppConstants.h"
#import "NSString+URLEncoding.h"
#import "APIClient.h"
#import "Account.h"

@implementation APIClient

- (id)init
{
    if ((self = [super init]) != nil) {
        account = [Account sharedInstance];
    }
    return self;
}

#pragma mark -
#pragma mark <APIAccessClient>

- (void)postEmail:(NSString *)email password:(NSNumber *)passwd jid:(NSString *)jidstr devicetoken:(NSString *)token
{
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:email, @"email", passwd, @"password", jidstr, @"jabberid", token, @"devicetoken", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_CREATE_USER)] parameters:params withMethod:@"POST" servertoken:nil];
}

- (void)requestVerificationCode:(NSString *)email
{
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:email, @"email", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_VERIFICATION_CODE)] parameters:params withMethod:@"GET" servertoken:nil];
}

- (void)postVerificationCode:(NSString *)verificationCode
                  forEmail:(NSString *)email
{
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:email, @"email", verificationCode, @"verification_code", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_VERIFICATION_CODE)] parameters:params withMethod:@"POST" servertoken:nil];
}

- (void)postActivationCode:(NSString *)activationCode
                  forEmail:(NSString *)email forPassword:(NSNumber *)passwd
{
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:email, @"email", passwd, @"password",activationCode, @"activation_code", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_ACTIVATE_USER)] parameters:params withMethod:@"POST" servertoken:nil];
}

- (void)addProfile:(NSString *)fname lastname:(NSString *)lname photo:(UIImage *)image jobtitle:(NSString *)job_title mobilenumber:(NSString *)mobile_number
{
    NSDictionary *dict1 = [[NSDictionary alloc] initWithObjectsAndKeys:@"first_name", @"paramname", fname, @"value", nil, @"mimetype", nil];
    NSDictionary *dict2 = [[NSDictionary alloc] initWithObjectsAndKeys:@"last_name", @"paramname", lname, @"value", nil, @"mimetype", nil];
    NSDictionary *dict3 = [[NSDictionary alloc] initWithObjectsAndKeys:@"job_title", @"paramname", job_title, @"value", nil, @"mimetype", nil];
    NSDictionary *dict4 = [[NSDictionary alloc] initWithObjectsAndKeys:@"mobile_number", @"paramname", mobile_number, @"value", nil, @"mimetype", nil];
    NSDictionary *dict5 = nil;
    
    if (image != nil) {
        NSData *imageData = UIImageJPEGRepresentation(image, 0.7);
        dict5 = [[NSDictionary alloc] initWithObjectsAndKeys:@"profile_pic", @"paramname", imageData, @"data", @"image/jpeg", @"mimetype", @"profile_pic.jpg", @"filename", nil];
    }
    NSArray *params = [NSArray arrayWithObjects:dict1, dict2, dict3, dict4, dict5, nil];
    [self postToURLMultipartFormdata:[NSURL URLWithString:ENDPOINT(API_PROFILE)] parameters:params
                         servertoken:account.serverToken];
}

- (void)addContacts:(NSArray *)contactsList
{    
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:@"contacts", @"type", contactsList, @"data", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_CONTACTS)] parameters:params withMethod:@"POST" servertoken:account.serverToken];
}
- (void)deleteContacts:(NSString *)contactsArray
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:contactsArray, @"contacts", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_CONTACTS)] parameters:params withMethod:@"DELETE" servertoken:account.serverToken];
}
- (void)getContacts
{
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_CONTACTS)] parameters:nil withMethod:@"GET" servertoken:account.serverToken];
}
- (void)getUpdatedContacts:(NSString *)dateOfPreviousApiCall
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:dateOfPreviousApiCall, @"date", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_UPDATED_CONTACTS)] parameters:params withMethod:@"GET" servertoken:account.serverToken];
}
- (void)getCompanyContacts
{    
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_GET_COMPANY_CONTACTS)] parameters:nil withMethod:@"GET" servertoken:account.serverToken];
}

- (void)getSalesforceContacts
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:@"Contact", @"recordType", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_GET_SALESFORCE_CONTACTS)] parameters:params withMethod:@"GET" servertoken:account.serverToken];
}

- (void)getGoogleContacts
{
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_GET_GOOGLE_CONTACTS)] parameters:nil withMethod:@"GET" servertoken:account.serverToken];
}

- (void)getZohoContacts
{
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_GET_ZOHO_CONTACTS)] parameters:nil withMethod:@"GET" servertoken:account.serverToken];
}

- (void)createDiscussionWithID:(NSString *)uuid title:(NSString *)discTitle members:(NSArray *)memberList groups:(NSArray *)groupList is1on1:(NSString *)is1on1
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:uuid, @"discussion_id", discTitle, @"title", memberList, @"members", groupList, @"groups", is1on1, @"is1on1", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_DISCUSSIONS)] parameters:params withMethod:@"PUT" servertoken:account.serverToken];
}

- (void)getDiscussion:(NSString *)discussionId
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:discussionId, @"discussion_id", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_DISCUSSIONS_BY_ID)] parameters:params withMethod:@"GET" servertoken:account.serverToken];
}

- (void)updateDiscussionWithID:(NSString *)uuid title:(NSString *)discTitle members:(NSArray *)memberList groups:(NSArray *)groupList is1on1:(NSString *)is1on1
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:uuid, @"discussionId", discTitle, @"title", memberList, @"members", groupList, @"groups", is1on1, @"is1on1", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_UPDATE_DISCUSSION)] parameters:params withMethod:@"POST" servertoken:account.serverToken];
}

- (void)deleteDiscussion:(NSString *)discussionId
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:discussionId, @"discussion_id", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_DELETE_DISCUSSION)] parameters:params withMethod:@"DELETE" servertoken:account.serverToken];
}

- (void)createGroupWithName:(NSString *)name members:(NSArray *)memberList
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:name, @"name", memberList, @"members", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_GROUPS)] parameters:params withMethod:@"PUT" servertoken:account.serverToken];
}

- (void)updateGroupWithID:(NSString *)groupID name:(NSString *)name members:(NSArray *)memberList
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:groupID, @"id", name, @"name", memberList, @"members", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_GROUPS)] parameters:params withMethod:@"POST" servertoken:account.serverToken];
}

- (void)deleteGroupWithID:(NSString *)groupID
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:groupID, @"groups", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_GROUPS)] parameters:params withMethod:@"DELETE" servertoken:account.serverToken];
}
- (void)getGroups
{
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_GROUPS)] parameters:nil withMethod:@"GET" servertoken:account.serverToken];
}

- (void)getDiscussions
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:@"1", @"page", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_DISCUSSIONS)] parameters:params withMethod:@"GET" servertoken:account.serverToken];
}

- (void)getUpdatedDiscussions: (NSString *)timestamp
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:timestamp, @"date", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_UPDATED_DISCUSSIONS)] parameters:params withMethod:@"GET" servertoken:account.serverToken];
}

- (void)getMessages:(NSString *)discussionId page:(int)pagenum
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:discussionId, @"discussion_id", [NSString stringWithFormat:@"%d", pagenum], @"page", nil];
    
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_MESSAGES)] parameters:params withMethod:@"GET" servertoken:account.serverToken];
}

- (void)getUnreadMessages:(NSString *)discussionId lastRead:(NSString *)messageId
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:discussionId, @"discussion_id", messageId, @"message_id", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_UNREAD_MESSAGES)] parameters:params withMethod:@"GET" servertoken:account.serverToken];
}

// Login
- (void)login:(NSString *)email andPassword:(NSNumber *)passwd
{
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:email, @"email", passwd, @"password", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_LOGIN)] parameters:params withMethod:@"POST" servertoken:nil];
}

// Productivity Category
// Create
- (void)createSummaryWithDiscussionId:(NSString *)discussionId MessageId:(NSString *)messageId CategoryType:(int)categoryType andNotes:(NSString *)notes
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:discussionId, @"discussionid", messageId, @"messageid", [NSNumber numberWithInt:categoryType], @"categorytype", notes, @"notes", nil];
    
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_SUMMARY_POINT)] parameters:params withMethod:@"PUT" servertoken:account.serverToken];
}
- (void)createSummaryWithDiscussionId:(NSString *)discussionId MessageId:(NSString *)messageId CategoryType:(int)categoryType MsgTimeStamp:(NSString *)messageTimeStamp andNotes:(NSString *)notes;
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:discussionId, @"discussionid", messageId, @"messageid", [NSNumber numberWithInt:categoryType], @"categorytype", notes, @"notes",messageTimeStamp, @"messagetimestamp", nil];
    
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_SUMMARY_POINT)] parameters:params withMethod:@"PUT" servertoken:account.serverToken];
}
- (void)getSummaryPointWithDiscussionId:(NSString *)discussionId MessageId:(NSString *)messageId CategoryType:(int)categoryType
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:discussionId, @"discussionid", messageId, @"messageid", [NSNumber numberWithInt:categoryType], @"categorytype", nil];
    
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_SUMMARY_POINT)] parameters:params withMethod:@"GET" servertoken:account.serverToken];
}

- (void)createReminderWithDiscussionId:(NSString *)discussionId MessageId:(NSString *)messageId CategoryType:(int)categoryType andAttributes:(NSDictionary *)attributes
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:discussionId, @"discussionid", messageId, @"messageid", [NSNumber numberWithInt:categoryType], @"categorytype", attributes, @"attributes", nil];
    
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_REMINDER)] parameters:params withMethod:@"PUT" servertoken:account.serverToken];
}

- (void)createReminderWithDiscussionId:(NSString *)discussionId MessageId:(NSString *)messageId CategoryType:(int)categoryType MsgTimeStamp:(NSString *)messageTimeStamp andAttributes:(NSDictionary *)attributes
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:discussionId, @"discussionid", messageId, @"messageid", [NSNumber numberWithInt:categoryType], @"categorytype", attributes, @"attributes",messageTimeStamp, @"messagetimestamp", nil];
    
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_REMINDER)] parameters:params withMethod:@"PUT" servertoken:account.serverToken];
    
}
- (void)createTaskWithDiscussionId:(NSString *)discussionId MessageId:(NSString *)messageId CategoryType:(int)categoryType andAttributes:(NSDictionary *)attributes
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:discussionId, @"discussionid", messageId, @"messageid", [NSNumber numberWithInt:categoryType], @"categorytype", attributes, @"attributes", nil];
    
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_TASK)] parameters:params withMethod:@"PUT" servertoken:account.serverToken];
}

- (void)createTaskWithDiscussionId:(NSString *)discussionId MessageId:(NSString *)messageId CategoryType:(int)categoryType MsgTimeStamp:(NSString *)messageTimeStamp andAttributes:(NSDictionary *)attributes
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:discussionId, @"discussionid", messageId, @"messageid", [NSNumber numberWithInt:categoryType], @"categorytype", attributes, @"attributes", messageTimeStamp, @"messagetimestamp", nil];
    
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_TASK)] parameters:params withMethod:@"PUT" servertoken:account.serverToken];
}

- (void)createMeetingWithDiscussionId:(NSString *)discussionId MessageId:(NSString *)messageId CategoryType:(int)categoryType andAttributes:(NSDictionary *)attributes
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:discussionId, @"discussionid", messageId, @"messageid", [NSNumber numberWithInt:categoryType], @"categorytype", attributes, @"attributes", nil];
    
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_INVITE)] parameters:params withMethod:@"PUT" servertoken:account.serverToken];
}

- (void)createMeetingWithDiscussionId:(NSString *)discussionId MessageId:(NSString *)messageId CategoryType:(int)categoryType MsgTimeStamp:(NSString *)messageTimeStamp andAttributes:(NSDictionary *)attributes
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:discussionId, @"discussionid", messageId, @"messageid", [NSNumber numberWithInt:categoryType], @"categorytype", attributes, @"attributes",messageTimeStamp, @"messagetimestamp", nil];
    
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_INVITE)] parameters:params withMethod:@"PUT" servertoken:account.serverToken];
}

- (void)createUserDefinedCategoryWithName:(NSString *)name andColor:(NSString *)color
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:name, @"name", color, @"colour", nil];
    
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_UDC)] parameters:params withMethod:@"PUT" servertoken:account.serverToken];
}

- (void)createUserDefinedCategoryInstanceWithDiscussionId:(NSString *)discussionId MessageId:(NSString *)messageId CategoryType:(int)categoryType andNotes:(NSString *)notes
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:discussionId, @"discussionid", messageId, @"messageid", [NSNumber numberWithInt:categoryType], @"categorytype", notes, @"notes", nil];
    
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_UDCINSTANT)] parameters:params withMethod:@"PUT" servertoken:account.serverToken];
}

- (void)createUserDefinedCategoryInstanceWithDiscussionId:(NSString *)discussionId MessageId:(NSString *)messageId CategoryType:(int)categoryType MsgTimeStamp:(NSString *)messageTimeStamp andNotes:(NSString *)notes
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:discussionId, @"discussionid", messageId, @"messageid", [NSNumber numberWithInt:categoryType], @"categorytype", notes, @"notes",messageTimeStamp, @"messagetimestamp", nil];
    
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_UDCINSTANT)] parameters:params withMethod:@"PUT" servertoken:account.serverToken];
}

// Delete
- (void)deleteCategoryWithDiscussionId:(NSString *)discussionId MessageId:(NSString *)messageId CategoryType:(int)categoryType
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:discussionId, @"discussionid", messageId, @"messageid", [NSNumber numberWithInt:categoryType], @"categorytype", nil];
    
    NSDictionary *jsonDict;
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params
                                                       options:0 // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        jsonDict = [[NSDictionary alloc] initWithObjectsAndKeys:jsonString, @"json", nil];
    }
    if (categoryType == 1) {
        [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_SUMMARY_POINT)] parameters:jsonDict withMethod:@"DELETE" servertoken:account.serverToken];
    } else if (categoryType == 2) {
        [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_REMINDER)] parameters:jsonDict withMethod:@"DELETE" servertoken:account.serverToken];
    } else if (categoryType == 3) {
        [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_TASK)] parameters:jsonDict withMethod:@"DELETE" servertoken:account.serverToken];
    } else if (categoryType == 4) {
        [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_INVITE)] parameters:jsonDict withMethod:@"DELETE" servertoken:account.serverToken];
    } else {
        [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_UDCINSTANT)] parameters:jsonDict withMethod:@"DELETE" servertoken:account.serverToken];
    }
}

//Get Category Task
- (void)getCategoryTask:(NSString *)categoryId
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:categoryId, @"category_id", nil];
    
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_TASK)] parameters:params withMethod:@"GET" servertoken:account.serverToken];
}

//Get Category Meeting
- (void)getCategoryMeeting:(NSString *)categoryId
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:categoryId, @"category_id", nil];
    
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_INVITE)] parameters:params withMethod:@"GET" servertoken:account.serverToken];
}

// Get maximum no of user defined category
- (void)getMaximumUDCValue
{
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_GET_MAX_UDC)] parameters:nil withMethod:@"GET" servertoken:account.serverToken];
}

// Get user defined category Data
- (void)getUDCData
{
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_UDC)] parameters:nil withMethod:@"GET" servertoken:account.serverToken];
}

// Update UDC
- (void)updateUserDefinedCategoryWithName:(NSString *)name andId:(int)udcId
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:name, @"name", [NSNumber numberWithInt:udcId], @"id", nil];
    
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_UDC)] parameters:params withMethod:@"POST" servertoken:account.serverToken];
}

// Discussion Notification Methods
- (void)setCategoryAcceptanceWithOwner:(NSString *)owner MessageId:(NSString *)messageId DiscussionId:(NSString *)discussionId CategoryType:(int)categoryType andIsAccepted:(BOOL)isAccept
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:owner, @"owner", discussionId, @"discussionid", messageId, @"messageid", [NSNumber numberWithInt:categoryType], @"categorytype", [NSNumber numberWithBool:isAccept], @"isaccepted", nil];
    
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_CATEGORY_ACCEPTANCE)] parameters:params withMethod:@"POST" servertoken:account.serverToken];
}

// Get Discussion Summary
- (void)getDiscussionSummaryByDiscussionId:(NSString *)discussionId
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:discussionId, @"discussionid", nil];
    
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_DISCUSSION_CATEGORIES)] parameters:params withMethod:@"GET" servertoken:account.serverToken];
}

// send Discussion Summary using e-mail
- (void)sendEmail:(NSString *)from to:(NSString *)to subject:(NSString *)subject body:(NSString *)body attachments:(NSString *)attachments
{
    NSDictionary *dict1 = [[NSDictionary alloc] initWithObjectsAndKeys:@"from", @"paramname", from, @"value", nil, @"mimetype", nil];
    NSDictionary *dict2 = [[NSDictionary alloc] initWithObjectsAndKeys:@"to", @"paramname", to, @"value", nil, @"mimetype", nil];
    NSDictionary *dict3 = [[NSDictionary alloc] initWithObjectsAndKeys:@"subject", @"paramname", subject, @"value", nil, @"mimetype", nil];
    NSDictionary *dict4 = [[NSDictionary alloc] initWithObjectsAndKeys:@"body", @"paramname", body, @"value", nil, @"mimetype", nil];
//    NSDictionary *dict5 = [[NSDictionary alloc] initWithObjectsAndKeys:@"attachments", @"paramname", attachments, @"value", nil, @"mimetype", nil];
    //    if (image != nil) {
    //        NSData *imageData = UIImageJPEGRepresentation(image, 0.3);
    //        dict5 = [[NSDictionary alloc] initWithObjectsAndKeys:@"profile_pic", @"paramname", imageData, @"data", @"image/jpeg", @"mimetype", @"profile_pic.jpg", @"filename", nil];
    //    }
    NSArray *params = [NSArray arrayWithObjects:dict1, dict2, dict3, dict4, nil];
    [self postToURLMultipartFormdata:[NSURL URLWithString:ENDPOINT(API_SEND_MAIL)] parameters:params
                         servertoken:account.serverToken];
}

- (void)getClientAuth
{
    [self postToURL:[NSURL URLWithString:ENDPOINT(API_GET_CLIENT_AUTH)] parameters:nil withMethod:@"POST" servertoken:account.serverToken];
}

- (void)saveZohoAuth:(NSString *)data
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:data, @"data", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_SAVE_ZOHO_AUTH)] parameters:params withMethod:@"POST" servertoken:account.serverToken];
}

- (void)cloudSearch:(NSString *)query
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:query, @"query", nil];
   [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_CLOUD_SEARCH)] parameters:params withMethod:@"GET" servertoken:account.serverToken];
}

- (void)boxSearch:(NSString *)query
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:query, @"query", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_BOX_SEARCH)] parameters:params withMethod:@"GET" servertoken:account.serverToken];
}

- (void)dropboxSearch:(NSString *)query
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:query, @"query", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_DROPBOX_SEARCH)] parameters:params withMethod:@"GET" servertoken:account.serverToken];
}

- (void)gdriveSearch:(NSString *)query
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:query, @"query", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_GDRIVE_SEARCH)] parameters:params withMethod:@"GET" servertoken:account.serverToken];
}


- (void)browse:(NSString *)externalSystem withRoot:(NSString *)root andType:(NSString *)type
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:root, @"file_id", type, @"file_type", nil];
    
    NSDictionary *jsonDict;
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params
                                                       options:0
                                                         error:&error];
    
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        jsonDict = [[NSDictionary alloc] initWithObjectsAndKeys:jsonString, @"json", nil];
    }
    NSURL *url = nil;
    if([externalSystem isEqualToString:@"Box"]) {
        url = [NSURL URLWithString:ENDPOINT(API_BOX_BROWSE)];
    } else if([externalSystem isEqualToString:@"Dropbox"]) {
        url = [NSURL URLWithString:ENDPOINT(API_DROPBOX_BROWSE)];
    } else if([externalSystem isEqualToString:@"Google"]) {
        url = [NSURL URLWithString:ENDPOINT(API_GOOGLE_BROWSE)];
    }
    [self postToURLWithJSON:url parameters:jsonDict withMethod:@"GET" servertoken:account.serverToken];
}

- (void) fetchDownloadUrlFromGoogle: (NSString *)accessToken withFile:(NSString *)id {
    NSString *url = [NSString stringWithFormat:@"%@%@", GOOGLE_FILES_BASE_URL, id];
    [self postToURLWithJSON:[NSURL URLWithString:url] parameters:nil withMethod:@"GET" servertoken:accessToken];
}


// Activity History
- (void)getCategoriesCount
{
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_GET_CATEGORIES_COUNT)] parameters:nil withMethod:@"GET" servertoken:account.serverToken];
}

- (void)getUserReminders
{
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_GET_USER_REMINDER)] parameters:nil withMethod:@"GET" servertoken:account.serverToken];
}

- (void)getUserMeetingInvites
{
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_GET_USER_MEETING_INVITE)] parameters:nil withMethod:@"GET" servertoken:account.serverToken];
}

- (void)getUserTasks
{
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_GET_USER_TASK)] parameters:nil withMethod:@"GET" servertoken:account.serverToken];
}

- (void)setCategoryProgressStatusWithOwner:(NSString *)owner MessageId:(NSString *)messageId DiscussionId:(NSString *)discussionId CategoryType:(int)categoryType andProgressStatus:(NSString *)progressStatus
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:owner, @"owner", discussionId, @"discussionid", messageId, @"messageid", [NSNumber numberWithInt:categoryType], @"categorytype", progressStatus, @"progressstatus", nil];
    
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_CATEGORY_PROGRESS_STATUS)] parameters:params withMethod:@"POST" servertoken:account.serverToken];
}

- (void)editUserProfile:(NSString *)fname lastname:(NSString *)lname photo:(UIImage *)image jobtitle:(NSString *)job_title mobilenumber:(NSString *)mobile_number companyContactStatus:(NSString *)companyContactStatus externalContactsStatus:(NSString *)externalContactsStatus allContactsStatus:(NSString *)allContactsStatus

{
    NSDictionary *dict1 = [[NSDictionary alloc] initWithObjectsAndKeys:@"first_name", @"paramname", fname, @"value", nil, @"mimetype", nil];
    NSDictionary *dict2 = [[NSDictionary alloc] initWithObjectsAndKeys:@"last_name", @"paramname", lname, @"value", nil, @"mimetype", nil];
    NSDictionary *dict3 = [[NSDictionary alloc] initWithObjectsAndKeys:@"job_title", @"paramname", job_title, @"value", nil, @"mimetype", nil];
    NSDictionary *dict4 = [[NSDictionary alloc] initWithObjectsAndKeys:@"mobile_number", @"paramname", mobile_number, @"value", nil, @"mimetype", nil];
    NSDictionary *dict5 = [[NSDictionary alloc] initWithObjectsAndKeys:@"company_contacts_status", @"paramname", companyContactStatus, @"value", nil, @"mimetype", nil];
    NSDictionary *dict6 = [[NSDictionary alloc] initWithObjectsAndKeys:@"external_contacts_status", @"paramname", externalContactsStatus, @"value", nil, @"mimetype", nil];
    NSDictionary *dict7 = [[NSDictionary alloc] initWithObjectsAndKeys:@"all_contacts_status", @"paramname", allContactsStatus, @"value", nil, @"mimetype", nil];

    NSDictionary *dict8 = nil;
    
    if (image != nil) {
        NSData *imageData = UIImageJPEGRepresentation(image, 0.7);
        dict8 = [[NSDictionary alloc] initWithObjectsAndKeys:@"profile_pic", @"paramname", imageData, @"data", @"image/jpeg", @"mimetype", @"profile_pic.jpg", @"filename", nil];
    }

    NSArray *params = [NSArray arrayWithObjects:dict1, dict2, dict3, dict4, dict5, dict6, dict7, dict8, nil];
    [self postToURLMultipartFormdata:[NSURL URLWithString:ENDPOINT(API_EDIT_FULL_PROFILE)] parameters:params
                         servertoken:account.serverToken];
}

- (void)getFullProfile
{
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_GET_FULL_PROFILE)] parameters:nil withMethod:@"GET" servertoken:account.serverToken];
}

- (void)getUserProfile:(NSString *)email
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:email, @"email", nil];

    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_GET_USER_PROFILE)] parameters:params withMethod:@"GET" servertoken:account.serverToken];
}

- (void)getUserProfileForJID:(NSString *)jid
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:jid, @"jid", nil];
    
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_GET_USER_PROFILE_FOR_JID)] parameters:params withMethod:@"GET" servertoken:account.serverToken];
}

- (void)setUserAvailability:(NSDictionary *)params
{
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_USER_AVAILABILITY)] parameters:params withMethod:@"POST" servertoken:account.serverToken];
}

- (void)getUserAvailability
{
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_USER_AVAILABILITY)] parameters:nil withMethod:@"GET" servertoken:account.serverToken];
}

- (void)updatePin:(NSString *)newPin
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:newPin, @"new_PIN", nil];
    
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_USER_PIN_RESET)] parameters:params withMethod:@"POST" servertoken:account.serverToken];
}

- (void)deleteUserSourceUsingType:(NSString *)type
{
    if ([type isEqualToString:@"Box"]) {
        [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_BOX_SOURCE)] parameters:nil withMethod:@"DELETE" servertoken:account.serverToken];
    } else if ([type isEqualToString:@"Dropbox"]) {
        [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_DROPBOX_SOURCE)] parameters:nil withMethod:@"DELETE" servertoken:account.serverToken];
    } else if ([type isEqualToString:@"Google Drive"] || [type isEqualToString:@"Google Mail"]) {
        [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_GOOGLE_SOURCE)] parameters:nil withMethod:@"DELETE" servertoken:account.serverToken];
    } else if ([type isEqualToString:@"Salesforce"]) {
        [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_SALESFORCE_SOURCE)] parameters:nil withMethod:@"DELETE" servertoken:account.serverToken];
    } else if ([type isEqualToString:@"Zoho"]) {
        [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_ZOHO_SOURCE)] parameters:nil withMethod:@"DELETE" servertoken:account.serverToken];
    } else if ([type isEqualToString:@"Asana"]) {
        [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_ASANA_SOURCE)] parameters:nil withMethod:@"DELETE" servertoken:account.serverToken];
    } else if ([type isEqualToString:@"Trello"]) {
        [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_TRELLO_SOURCE)] parameters:nil withMethod:@"DELETE" servertoken:account.serverToken];

    }
}

//bookmarks
- (void)createBookmark:(NSString *)url withName:(NSString *)name {
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:name, @"name", url, @"url", nil];
    
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_BOOKMARK)] parameters:params withMethod:@"PUT" servertoken:account.serverToken];
}

- (void)getBookmarks {
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_BOOKMARK)] parameters:nil withMethod:@"GET" servertoken:account.serverToken];
}

//Tasks
- (void)getSalesforceRecords:(NSString *)recordType
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:recordType, @"recordType", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_GET_SALESFORCE_RECORDS)] parameters:params withMethod:@"GET" servertoken:account.serverToken];
}

- (void)getTrelloRecords
{
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_GET_TRELLO_RECORDS)] parameters:nil withMethod:@"GET" servertoken:account.serverToken];
}

- (void)getTrelloLists:(NSString *)boardId {
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:boardId, @"board_id", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_GET_TRELLO_LISTS)] parameters:params withMethod:@"GET" servertoken:account.serverToken];
}

- (void)getAsanaRecords
{
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_GET_ASANA_RECORDS)] parameters:nil withMethod:@"GET" servertoken:account.serverToken];
}

- (void)saveTrelloTask:(NSString *)name withListId:(NSString *)listId andDescription:(NSString *)desc
                andDue:(NSString *)due {
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:name, @"name", listId, @"list_id", desc, @"desc", due, @"due", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_SAVE_TRELLO_TASK)] parameters:params withMethod:@"PUT" servertoken:account.serverToken];
}

- (void)joinTrelloTask:(NSString *)id {
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:id, @"card_id", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_JOIN_TRELLO_TASK)] parameters:params withMethod:@"PUT" servertoken:account.serverToken];
}

- (void)saveAsanaTask:(NSString *)name withWorkspaceId:(NSString *)workspaceId andProjectId:(NSString *)projectId andDescription:(NSString *)desc andDue:(NSString *)due {
    if(projectId == nil) {
        projectId = @"";
    }
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:name, @"name", workspaceId, @"workspace_id", projectId, @"project_id", desc, @"notes", due, @"due", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_SAVE_ASANA_TASK)] parameters:params withMethod:@"PUT" servertoken:account.serverToken];
}

- (void)saveAsanaSubtask:(NSString *)id withName:(NSString *)name andDescription:(NSString *)desc andDue:(NSString *)due {
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"Subtask: %@", name], @"name", id, @"parent_id", desc, @"notes", due, @"due", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_SAVE_ASANA_SUBTASK)] parameters:params withMethod:@"PUT" servertoken:account.serverToken];
}

- (void)saveSalesforceTask:(NSString *)name withAccountId:(NSString *)accountId andDescription:(NSString *)desc andDue:(NSString *)due {
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:name, @"subject", accountId, @"account_id", desc, @"desc", due, @"due", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_SAVE_SALESFORCE_TASK)] parameters:params withMethod:@"PUT" servertoken:account.serverToken];
}

- (void)saveTaskPreferences:(NSString *)source withLevel1:(NSString *)level1 andLevel2:(NSString *)level2 {
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:source, @"task_source", level1, @"task_level1", level2, @"task_level2", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_SAVE_TASK_PREFERENCE)] parameters:params withMethod:@"PUT" servertoken:account.serverToken];
}

- (void)updateSignature:(NSString *)signature
{
    NSDictionary *params =[[NSDictionary alloc] initWithObjectsAndKeys:signature, @"signature", nil];
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_UPDATE_USER_SIGNATURE)] parameters:params withMethod:@"PUT" servertoken:account.serverToken];
}

- (void)getSignature
{
    [self postToURLWithJSON:[NSURL URLWithString:ENDPOINT(API_UPDATE_USER_SIGNATURE)] parameters:nil withMethod:@"GET" servertoken:account.serverToken];
}

@end
