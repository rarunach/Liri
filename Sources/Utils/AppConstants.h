#define IS_IPHONE_5  ([[UIScreen mainScreen] bounds].size.height == 568)?TRUE:FALSE

#define DISCUSSIONS_TAB_INDEX       0
#define CONTACTS_TAB_INDEX          1
#define TODO_TAB_INDEX              2
#define SETTINGS_TAB_INDEX          3

// Notifications
#define kReceivedRemoteNotification @"ReceivedRemoteNotification"
#define kMessageReceivedNotification @"MessageReceivedNotification"
#define kXMPPAuthenticatedNotification @"XMPPAuthenticatedNotification"
#define kXMPPDisconnectedNotification @"XMPPDisconnectedNotification"
#define kRoomReadyNotification @"RoomReadyNotification"
#define kRoomJoinedNotification @"RoomJoinedNotification"
#define kDiscussionInviteReceivedNotification @"DiscussionInviteReceivedNotification"
#define kDiscussionReadyNotification @"DiscussionReadyNotification"
#define kStartNewDiscussionNotification @"StartNewDiscussionNotification"
#define kStartNew1On1DiscussionNotification @"StartNew1On1DiscussionNotification"
#define kSelectContactsNotification @"SelectContactsNotification"
#define kOccupantJoinedNotification @"OccupantJoinedNotification"
#define kOccupantLeftNotification @"OccupantLeftNotification"
#define kNewAnnotationNotification @"NewAnnotationNotification"
#define kAnnotationOptionSelectedNotification @"AnnotationOptionSelectedNotification"
#define kExternalAuthenticationSelectedNotification @"ExternalAuthenticationSelectedNotification"
#define kAuthenticationCompletedNotification @"AuthenticationCompletedNotification"
#define kAuthenticationFailedNotification @"AuthenticationFailedNotification"
#define kBrowsingCompletedNotification @"BrowsingCompletedNotification"
#define kScreenCapturedNotification @"ScreenCapturedNotification"
#define kBrowserRequestedNotification @"BrowserRequestedNotification"
#define kAnnotationStageCompletedNotification @"AnnotationStageCompletedNotification"
#define kEditingCompletedNotification @"EditingCompletedNotification"
#define kTextViewMovedUpNotification @"TextViewMovedUpNotification"
#define kFontSelectedNotification @"FontSelectedNotification"
#define kAttributesChangingNotification @"AttributesChangingNotification"
#define kSelectionChangesCompletedNotification @"SelectionChangesCompletedNotification"
#define kFavoritesRequestedNotification @"FavoritesRequestedNotification"
#define kDefaultCalendarSetNotification @"DefaultCalendarSetNotification"
#define kTaskAuthenticationCompletedNotification @"TaskAuthenticationCompletedNotification"
#define kTaskAuthenticationFailedNotification @"TaskAuthenticationFailedNotification"
#define kFieldValueSelectedNotification @"FieldValueSelectedNotification"
#define kAuthenticationCompletedNotificationFromSetting @"AuthenticationCompletedNotificationFromSetting"
#define kAuthenticationFailedNotificationFromSetting @"AuthenticationFailedNotificationFromSetting"
#define kTaskSourceSelectedNotification @"TaskSourceSelectedNotification"
#define kTaskSelectionCompletedNotification @"TaskSelectionCompletedNotification"
#define kLightBoxFinishedAtDiscussionNotification @"LightBoxFinishedAtDiscussionNotification"
#define kLightBoxFinishedNotification @"LightBoxFinishedNotification"
#define kBackFromCreateGroupNotification @"BackFromCreateGroupNotification"
#define kBackFromEditGroupNotification @"BackFromEditGroupNotification"
#define kDeleteContactFromListNotification @"DeleteContactFromListNotification"
#define kDeleteGroupFromListNotification @"DeleteGroupFromListNotification"
#define kStatusBarChangeNotification @"StatusBarChangeNotification"
#define kUnknownBuddyAddedNotification @"UnknownBuddyAddedNotification"



// Alerts constants
#define kEmailIDCheckMessage @"Is this email id correct?"
#define kEmailInvalidAlertTitle @""
#define kEmailInvalidAlertMessage @"Email id is invalid."
#define kNameInvalidAlertTitle @""
#define kNameInvalidAlertMessage @"First and Last name are required."
#define kCodeInvalidAlertMessage @"Incorrect activation code, please try again."
#define kCodeExceededAlertMessage @"Exceeded the activation attempts. A new activation code has been sent to you."
#define kConnectionErrorMessage \
@"Unable to contact server, check your internet connection and try again"
#define kEmailControllerRequesFailureKey @"errorMsg"

// XMPP backend conf

#define kChatPort 5222

// User defaults preferences
#define kUsernamePreference @"username_preference"
#define kPasswordPreference @"password_preference"

// Backend conf
#ifdef DEBUG
#define kChatServerName @"54.85.35.204"
#define kHostDomain @"54.85.35.204"
#define kHostDomain2 @"54.85.35.204"
#define BACKEND_HOST_NAME @"ec2-54-191-47-167.us-west-2.compute.amazonaws.com"
#define BACKEND_BASE_URL @"https://" BACKEND_HOST_NAME @":3001/"
#define BACKEND_BASE_PORT @"3001"
#else
#define kChatServerName @"chat.vyaza.com"
#define kHostDomain @"chat.vyaza.com"
#define kHostDomain2 @"chat2.vyaza.com"
#define BACKEND_HOST_NAME @"api.vyaza.com"
#define BACKEND_BASE_URL @"https://" BACKEND_HOST_NAME @"/"
#define BACKEND_BASE_PORT @"443"
#endif

// Flurry conf
#ifdef DEBUG
#define FLURRY_KEY @"QZ5MGZR4SQJZ53J9Z29T"
#else
#define FLURRY_KEY @"MSZBS93PWM8PZ87BNFXP"
#endif

#define DEFAULT_PARAMETER_METHOD @"POST"
#define PUT_PARAMETER_METHOD @"PUT"

// Endpoint-construction helper
#define ENDPOINT(url) BACKEND_BASE_URL url
#define ENDPOINT_FROM_STRING(url) \
[BACKEND_BASE_URL stringByAppendingString:url]
// Helper for forming URL calls
#define URL(...) [NSURL URLWithString:[NSString stringWithFormat:__VA_ARGS__]]
#define URL_WITHOUT_PARAMETERS(...) [NSURL URLWithString:__VA_ARGS__]

#define API_CREATE_USER @"users/create"
#define API_ACTIVATE_USER @"user/activate"
#define API_VERIFICATION_CODE @"user/verify"
#define API_GET_COMPANY_CONTACTS @"company/contacts"
#define API_GET_SALESFORCE_CONTACTS @"salesforce/records"
#define API_GET_GOOGLE_CONTACTS @"google/contacts"
#define API_GET_ZOHO_CONTACTS @"zoho/contacts"
#define API_PROFILE @"user/profile"
#define API_CONTACTS @"user/contacts"
#define API_UPDATED_CONTACTS @"user/contacts/updated"
#define API_DISCUSSIONS @"user/discussions"
#define API_UPDATED_DISCUSSIONS @"user/discussions/updated"
#define API_DISCUSSIONS_BY_ID @"discussions/by_id"
#define API_DISCUSSION_CATEGORIES @"discussion/categories"
#define API_DELETE_DISCUSSION @"discussions"
#define API_UPDATE_DISCUSSION @"discussions"
#define API_GROUPS @"groups"
#define API_GROUPS_BY_OWNER @"groups/by_owner"

#define API_MESSAGES @"messages"
#define API_UNREAD_MESSAGES @"messages/unread"
#define API_CLOUD_SEARCH @"cloud/search"
#define API_BOX_SEARCH @"box/search"
#define API_DROPBOX_SEARCH @"dropbox/search"
#define API_GDRIVE_SEARCH @"gdrive/search"
#define API_BOX_BROWSE @"box/browse"
#define API_DROPBOX_BROWSE @"dropbox/browse"
#define API_GOOGLE_BROWSE @"gdrive/browse"

#define API_LOGIN @"users/login"
#define API_GET_MAX_UDC @"client_configuration"

// Productivity Category
#define API_SUMMARY_POINT @"category/summary"
#define API_REMINDER @"category/reminder"
#define API_TASK @"category/task"
#define API_INVITE @"category/invite"
#define API_UDC @"category/UDC"
#define API_UDCINSTANT @"category/UDCInstance"
#define API_CATEGORY_ACCEPTANCE "category/member_acceptance"

#define API_SEND_MAIL @"sendMail"

#define API_GET_CLIENT_AUTH @"client_auth"
#define API_SAVE_ZOHO_AUTH @"zoho/auth/save"

#define DEFAULT_UICOLOR [UIColor colorWithRed:(CGFloat)51/255 green:(CGFloat)204/255 blue:(CGFloat)51/255 alpha:1]
#define DEFAULT_CGCOLOR [DEFAULT_UICOLOR CGColor]

#define kMaxContacts 500
#define KMaxUserSelectCategory 6
#define KMaxUserCategoryLength 50
#define KMaxSummaryPointDescriptionLength 4000
#define KSuccessAlertTag 200
#define KFailureAlertTag 111
#define KInsertAlertTag 101
#define KDeleteAlertTag 201
#define KWarningAlertTag 300
#define KLocalResourceAccessFailureTag 311

#define FONT_SIZE 15
#define FONT_HELVETICA_NEUE_BOLD @"HelveticaNeue-Bold"
#define FONT_HELVETICA_NEUE @"HelveticaNeue"

// circle colors
#define CAT_IMG_1 @"Action-Categories-Green-Icon@2x"
#define CAT_IMG_2 @"Action-Categories-Orange-Icon@2x"
#define CAT_IMG_3 @"Action-Categories-Purple-Icon@2x"
#define CAT_IMG_4 @"Action-Categories-Blue-Icon@2x"
#define CAT_IMG_5 @"Action-Categories-Turquoise-Icon@2x"
#define CAT_IMG_6 @"Action-Categories-Red-Icon@2x"
#define CAT_IMG_7 @"Action-Categories-Pink-Icon@2x"
#define CAT_IMG_8 @"Action-Categories-Lavender-Icon@2x"
#define CAT_IMG_9 @"Action-Categories-Yellow-Icon@2x"
#define CAT_IMG_10 @"Action-Categories-Gray-Icon@2x"
#define CAT_IMG_11 @"Action-Categories-Coral-Icon@2x"
#define CAT_IMG_12 @"Action-Categories-Dark-Brown-Icon@2x"
#define CAT_IMG_13 @"Action-Categories-Light-Blue-Icon@2x"
#define CAT_IMG_14 @"Action-Categories-Light-Dirty-Green-Icon@2x"
#define CAT_IMG_15 @"Action-Categories-Black-Icon@2x"
#define CAT_IMG_16 @"Action-Categories-Chocolate-Brown-Icon@2x"
#define CAT_IMG_17 @"Action-Categories-Dark-Green-Icon@2x"
#define CAT_IMG_18 @"Action-Categories-Dark-Purple-Icon@2x"
#define CAT_IMG_19 @"Action-Categories-Light-Yellow-Icon@2x"
#define CAT_IMG_20 @"Action-Categories-Orange-Red-Icon@2x"
#define CAT_IMG_21 @"Action-Categories-Royal-Blue-Icon@2x"
#define CAT_IMG_22 @"Action-Categories-Dark-Red-Icon@2x"
#define CAT_IMG_23 @"Action-Categories-Steel-Blue-Icon@2x"
#define CAT_IMG_24 @"Action-Categories-Crimson-Icon@2x"
#define CAT_IMG_25 @"Action-Categories-Dirty-Yellow-Icon@2x"
//#define CAT_IMG_11 @"Action-Categories-White-Icon@2x"

//Annotation text box
#define TEXTBOX_MIN_LEFT 10
#define TEXTBOX_MAX_RIGHT 300
#define TEXTBOX_MAX_RIGHT_4S 300
#define TEXTBOX_MIN_TOP 10
#define TEXTBOX_MAX_BOTTOM 400
#define TEXTBOX_MAX_BOTTOM_4S 310
#define TEXTBOX_MAX_WIDTH 290
#define TEXTBOX_MIN_HEIGHT 30
#define DONE_BUTTON_WIDTH 60
#define BUTTONS_HEIGHT 20
#define TEXTBOX_INNER_PADDING 5
#define TEXTBOX_INNER_DOUBLE_PADDING 10

typedef enum {
    NotJustified    = 0,
    LeftJustified   = 1,
    CenterJustified = 2,
    RightJustified  = 3,
} TextJustification;

// external systems
#ifdef DEBUG
#define S3_BUCKET @"vyazadev"
#define S3_KEY @"AKIAJYL4AEQD6SQPVJLQ"
#define S3_SECRET @"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"
#else
#define S3_BUCKET @"vyazaprod"
#define S3_KEY @"AKIAIIWTIZLQTNY6IRFQ"
#define S3_SECRET @"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"
#endif

#define BOX_FILES_BASE_URL @"https://api.box.com/2.0/files/"
#define GOOGLE_FILES_BASE_URL @"https://www.googleapis.com/drive/v2/files/"
#define DROPBOX_FILES_BASE_URL @"https://api-content.dropbox.com/1/files/auto"

// Activity History
#define API_GET_CATEGORIES_COUNT @"categories/outstanding/count"

#define API_GET_USER_REMINDER @"user/reminders"
#define API_GET_USER_MEETING_INVITE @"user/invites"
#define API_GET_USER_TASK @"user/tasks"

#define API_CATEGORY_PROGRESS_STATUS @"category/member_progress_status"
#define API_EDIT_FULL_PROFILE @"user/fullprofile"
#define API_GET_FULL_PROFILE @"user/fullprofile"

#define API_GET_USER_PROFILE @"user/profile"
#define API_GET_USER_PROFILE_FOR_JID @"user/profile/for_jid"


#define API_USER_AVAILABILITY @"user/availability"

#define API_USER_PIN_RESET @"user/PIN/reset"

#define API_BOX_SOURCE @"box/auth"
#define API_DROPBOX_SOURCE @"dropbox/auth"
#define API_GOOGLE_SOURCE @"google/auth"
#define API_SALESFORCE_SOURCE @"salesforce/auth"
#define API_ZOHO_SOURCE @"zoho/auth"
#define API_ASANA_SOURCE @"asana/auth"
#define API_TRELLO_SOURCE @"trello/auth"
//Bookmarks
#define API_BOOKMARK @"bookmark"

//Tasks
#define API_GET_SALESFORCE_RECORDS @"salesforce/records"
#define API_GET_ASANA_RECORDS @"asana/records"
#define API_GET_TRELLO_RECORDS @"trello/records"
#define API_GET_TRELLO_LISTS @"trello/board/lists"
#define API_SAVE_TRELLO_TASK @"trello/card"
#define API_JOIN_TRELLO_TASK @"trello/card/join"
#define API_SAVE_ASANA_TASK @"asana/task"
#define API_SAVE_ASANA_SUBTASK @"asana/subtask"
#define API_SAVE_SALESFORCE_TASK @"salesforce/task"
#define API_SAVE_TASK_PREFERENCE @"user/preference/task"


#define API_UPDATE_USER_SIGNATURE @"user/signature"
#define API_GET_SIGNATURE @"user/signature"
#define ASANA_CONFIG @"asana"
#define SALESFORCE_CONFIG @"salesforce"
#define TRELLO_CONFIG @"trello"
#define ZOHO_CONFIG @"zoho"
#define CATEGORIES_CONFIG @"custom_categories_count"
#define FREE_USER_CONFIG_MSG @"This feature is available only in Liri paid plan. Please visit our website www.liriapp.com or contact us at 1-844-LIRIAPP to upgrade to Liri paid plan."
#define isNSNull(value) [value isKindOfClass:[NSNull class]]