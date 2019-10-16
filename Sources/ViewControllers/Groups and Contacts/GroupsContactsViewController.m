//
//  GroupsContactsViewController.m
//  Liri
//
//  Created by Ramani Arunachalam on 6/13/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "GroupsContactsViewController.h"
#import "ImportTableViewController.h"
#import "Account.h"
#import "BuddyList.h"
#import "AppDelegate.h"
#import "NewDiscussionViewController.h"
#import "CreateGroupViewController.h"
#import "GroupViewController.h"
#import "ContactProfileViewController.h"
#import "S3Manager.h"
#import "Account.h"
#import "Group.h"
#import "CRNInitialsImageView.h"
#import "Flurry.h"
#import "AddressBook/ABPerson.h"

#define ALL_CONTACTS    0
#define DEVICE_CONTACTS 1
#define SALESFORCE_CONTACTS 2
#define ZOHO_CONTACTS 3
#define GOOGLE_CONTACTS 4
#define COMPANY_CONTACTS 5
#define SOURCE_TYPES 6

@interface GroupsContactsViewController ()
{
    NSMutableDictionary *contacts[SOURCE_TYPES];
    NSMutableArray *sectionTitles[SOURCE_TYPES];
    NSMutableArray *groups;
    BOOL contactsLoaded, filterPickerHidden;
    UIPickerView *filterPicker;
    NSArray *filters;
    NSInteger selectedFilterRow;
    NSInteger selectedSource;
    Group *newgroup, *updateGroup;
    
    NSMutableArray *searchResults;
    Buddy *selectedBuddy;
    BOOL selectedState;
    
    BOOL stopLoop, isCreateGroup, isEditGroup, startDiscUsingContact;
    int rowValue, sectionValue;
    
    NSInteger prevSelectedIndex, currentSelectedIndex;
    
    NSMutableArray *indexPaths;
    NSString *lastDateOfFetchContacts;
}
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedCtrl;
@property (weak, nonatomic) IBOutlet UICollectionView *groupsView;
@property (weak, nonatomic) IBOutlet UIButton *filterBtn;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *contactsTableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *initiateBtn;

@property (weak, nonatomic) IBOutlet UITableView *searchContactsTableView;

@property (weak, nonatomic) IBOutlet UIImageView *downArrowImgView;

@property (nonatomic, retain) UIBarButtonItem *oldButton;

@property (nonatomic, strong) NSIndexPath *selectedItemIndexPath;

@end

@implementation GroupsContactsViewController
@synthesize selectedGroups, selectedBuddies;
@synthesize filterBtn, searchBar, contactsTableView, groupsView;
@synthesize selectionMode, segmentedCtrl;

@synthesize searchContactsTableView = _searchContactsTableView;

@synthesize downArrowImgView = _downArrowImgView;

@synthesize oldButton = _oldButton;

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        
        // Do any additional setup after loading the view.
        self.navigationItem.hidesBackButton = YES;
        
        contactsTableView.userInteractionEnabled = YES;
        
        selectedBuddies = [[BuddyList alloc] init];
        
        filters = [NSArray arrayWithObjects:@"All Contacts", @"Device Contacts", @"Salesforce Contacts", @"Zoho Contacts", @"Google Contacts", @"Company Contacts", nil];
        
        for (int source = 0; source < SOURCE_TYPES; source++) {
            NSMutableArray *contactsArray[26];
            contacts[source] = [[NSMutableDictionary alloc] init];
            for (int i = 0; i < 26; i++) {
                contactsArray[i] = [[NSMutableArray alloc] initWithCapacity:1];
                NSString *key = [NSString stringWithFormat:@"%c", 'A'+i];
                [contacts[source] setObject:contactsArray[i] forKey:key];
            }
        }
        
        selectedFilterRow = ALL_CONTACTS;
        
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        
        filterPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, filterPicker.frame.origin.y+filterPicker.frame.size.height, screenWidth, 400)];
        filterPicker.transform = CGAffineTransformMakeScale(1.0, 1.25);
        filterPicker.showsSelectionIndicator = YES;
        filterPicker.delegate = self;
        filterPicker.dataSource = self;
        filterPicker.backgroundColor = [UIColor lightGrayColor];
        [filterPicker selectRow:selectedFilterRow inComponent:0 animated:NO];
        filterPickerHidden = YES;
        
        selectedSource = ALL_CONTACTS;
        [self getAllContacts];

        groups = [[NSMutableArray alloc] init];
        selectedGroups = [[NSMutableArray alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectContacts:) name:kSelectContactsNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [Flurry logEvent:@"Groups/Contacts Screen"];
    
    UITapGestureRecognizer *tableViewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tableTapped:)];
    [tableViewTap setNumberOfTapsRequired:1];
    tableViewTap.cancelsTouchesInView = false;
    [contactsTableView addGestureRecognizer:tableViewTap];
    
    UITapGestureRecognizer *collectionViewtap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tableTapped:)];
    [collectionViewtap setNumberOfTapsRequired:1];
    collectionViewtap.cancelsTouchesInView = false;
    [self.groupsView addGestureRecognizer:collectionViewtap];
    indexPaths = [NSMutableArray array];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backFromCreateGroup:) name:kBackFromCreateGroupNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backFromEditGroup:) name:kBackFromEditGroupNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteContactFromList:) name:kDeleteContactFromListNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteGroupFromList:) name:kDeleteGroupFromListNotification object:nil];

}

- (void)viewDidLayoutSubviews
{
    if(IS_IPHONE_5) {
        //do stuff for 4 inch iPhone screen
    }
    else {
        //do stuff for 3.5 inch iPhone screen
        [self.contactsTableView setFrame:CGRectMake(self.contactsTableView.frame.origin.x, self.contactsTableView.frame.origin.y, self.contactsTableView.frame.size.width, self.contactsTableView.frame.size.height - 88)];
        
        [self.searchContactsTableView setFrame:CGRectMake(self.searchContactsTableView.frame.origin.x, self.searchContactsTableView.frame.origin.y, self.searchContactsTableView.frame.size.width, self.searchContactsTableView.frame.size.height - 88)];
        
        [self.groupsView setFrame:CGRectMake(self.groupsView.frame.origin.x, self.groupsView.frame.origin.y, self.groupsView.frame.size.width, self.groupsView.frame.size.height - 88)];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [self getUpdatedAllContacts:lastDateOfFetchContacts];

    self.tabBarController.tabBar.hidden = NO;
    if (selectionMode) {
        [self startSelectionMode];
    } else {
        if (segmentedCtrl.selectedSegmentIndex == 0) {
            contactsTableView.hidden = YES;
            groupsView.hidden = NO;
        
            [groupsView reloadData];
            
            [filterPicker removeFromSuperview];
            filterPickerHidden = YES;
            
            [self.filterBtn setHidden:YES];
            [self.downArrowImgView setHidden:YES];
        } else {
            contactsTableView.hidden = NO;
            groupsView.hidden = YES;
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[self view] endEditing:YES];
}
- (void)willEnterForeground:(NSNotification *)notification
{
    if (self.navigationController.tabBarController.selectedIndex == 1) {
        [self getAllContacts];
    }
}

#pragma mark - Private Methods
- (void)dismissSearchTableView
{
    self.searchBar.text = @"";
    [self.searchContactsTableView setHidden:YES];
}

- (void)selectContacts:(NSNotification *)notification
{
    if (self.segmentedCtrl.selectedSegmentIndex == 1) {
        startDiscUsingContact = YES;
    } else {
        isCreateGroup = NO;
        isEditGroup = NO;
        
        contactsTableView.hidden = NO;
        groupsView.hidden = YES;
        [self.filterBtn setHidden:NO];
    }
    selectionMode = YES;
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)getAllContacts
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    Account *account = [Account sharedInstance];

    // Need to re-populate after any new contacts are added (done in getCompanyContacts) */
    for (int source = 0; source < SOURCE_TYPES; source++)
    {
        for (int i = 0; i < 26; i++)
        {
            NSString *key = [NSString stringWithFormat:@"%c", 'A'+i];
            [contacts[source][key] removeAllObjects];
        }
        [sectionTitles[source] removeAllObjects];
    }
    [contactsTableView reloadData];
    
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                                 sharedInstanceWithClientProtocol:
                                 @protocol(APIAccessClient)] client];

    endpoint.successJSON = ^(NSURLRequest *request,
                                         id responseJSON){
        
        lastDateOfFetchContacts = responseJSON[@"time"];
        NSArray *dictArray = (NSArray *)[responseJSON objectForKey:@"data"];
        
        for (int i = 0; i < [dictArray count]; i++)
        {
            NSString *sourcetype = [dictArray[i] objectForKey:@"source"];
            
            NSString *name;
            
            ABPersonCompositeNameFormat displayOrder = ABPersonGetCompositeNameFormatForRecord(NULL);
            
            if (displayOrder == kABPersonCompositeNameFormatFirstNameFirst) {
                name = [NSString stringWithFormat:@"%@ %@", [dictArray[i] objectForKey:@"first_name"],
                                [dictArray[i] objectForKey:@"last_name"]];
            } else {
                name = [NSString stringWithFormat:@"%@ %@", [dictArray[i] objectForKey:@"last_name"],
                                [dictArray[i] objectForKey:@"first_name"]];
            }
            
            NSString *email = [dictArray[i] objectForKey:@"email"];
            NSNumber *is_liri_user = [dictArray[i] objectForKey:@"is_liri_user"];
            NSString *profile_pic = [dictArray[i] objectForKey:@"profile_pic"];

            Buddy *buddy = [account.buddyList findBuddyForEmail:email];
            if (buddy == nil) {
                
                UIImage *buddyphoto = [account.s3Manager downloadImage:profile_pic];

                NSLog(@"Adding new buddy for %@!", email);
                buddy = [Buddy buddyWithDisplayName:name email:email photo:buddyphoto isUser:[is_liri_user boolValue]];
                [account.buddyList addBuddy:buddy];
            }
            
            
            buddy.displayName = name;
            buddy.firstName = [dictArray[i] objectForKey:@"first_name"];
            buddy.lastName = [dictArray[i] objectForKey:@"last_name"];
            buddy.availabilityStatus = [dictArray[i] objectForKey:@"status"];
            NSString *firstChar;// = [[name substringToIndex:1] capitalizedString];
            
            ABPersonSortOrdering sortOrder = ABPersonGetSortOrdering();
            if (sortOrder == kABPersonSortByFirstName) {
                // sort by firstName
//                if (![buddy.firstName isKindOfClass:[NSNull class]]) {
                if (![dictArray[i][@"first_name"] isEqualToString:@""]) {
                    firstChar = [[buddy.firstName substringToIndex:1] capitalizedString];
                }
            }
            else {
                // sort by lastName
//                if (![buddy.lastName isKindOfClass:[NSNull class]] ) {
                if (![dictArray[i][@"last_name"] isEqualToString:@""]) {
                    firstChar = [[buddy.lastName substringToIndex:1] capitalizedString];
                }
            }
            [contacts[ALL_CONTACTS][firstChar] addObject:buddy];
            
            if ([sourcetype isEqualToString:@"Device"])
            [contacts[DEVICE_CONTACTS][firstChar] addObject:buddy];
            else if ([sourcetype isEqualToString:@"Salesforce"])
            [contacts[SALESFORCE_CONTACTS][firstChar] addObject:buddy];
            else if ([sourcetype isEqualToString:@"Zoho"])
            [contacts[ZOHO_CONTACTS][firstChar] addObject:buddy];
            else if ([sourcetype isEqualToString:@"Google"])
            [contacts[GOOGLE_CONTACTS][firstChar] addObject:buddy];
            
        }
        
        [self getCompanyContacts];
        [delegate hideActivityIndicator];
        
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                                         id responseJSON){
        [delegate hideActivityIndicator];

    };

    [endpoint getContacts];
}

- (void)getCompanyContacts
{
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                                 sharedInstanceWithClientProtocol:
                                 @protocol(APIAccessClient)] client];
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];

    Account *account = [Account sharedInstance];
    endpoint.successJSON = ^(NSURLRequest *request,
                                         id responseJSON){
        
        NSArray *dictArray = (NSArray *)responseJSON;
        for (int i = 0; i < [dictArray count]; i++)
        {
            NSString *name;
            
            ABPersonCompositeNameFormat displayOrder = ABPersonGetCompositeNameFormatForRecord(NULL);
            
            if (displayOrder == kABPersonCompositeNameFormatFirstNameFirst) {
                name = [NSString stringWithFormat:@"%@ %@", [dictArray[i] objectForKey:@"first_name"],
                        [dictArray[i] objectForKey:@"last_name"]];
            } else {
                name = [NSString stringWithFormat:@"%@ %@", [dictArray[i] objectForKey:@"last_name"],
                        [dictArray[i] objectForKey:@"first_name"]];
            }
            NSString *email = [dictArray[i] objectForKey:@"email"];
            NSString *profile_pic = [dictArray[i] objectForKey:@"profile_pic"];
            
            Buddy *buddy = [account.buddyList findBuddyForEmail:email];
            if (buddy == nil) {
                
                UIImage *buddyphoto = [account.s3Manager downloadImage:profile_pic];

                NSLog(@"Adding new buddy for %@!", email);
                buddy = [Buddy buddyWithDisplayName:name email:email photo:buddyphoto isUser:YES];
                [account.buddyList addBuddy:buddy];
            }
            buddy.displayName = name;
            buddy.firstName = [dictArray[i] objectForKey:@"first_name"];
            buddy.lastName = [dictArray[i] objectForKey:@"last_name"];
            buddy.availabilityStatus = [dictArray[i] objectForKey:@"status"];
            NSString *firstChar = [[name substringToIndex:1] capitalizedString];
            ABPersonSortOrdering sortOrder = ABPersonGetSortOrdering();
            if (sortOrder == kABPersonSortByFirstName) {
                // sort by firstName
                if (nil == buddy.firstName || [buddy.firstName isEqual:[NSNull null]]) {
                    
                } else {
                    firstChar = [[buddy.firstName substringToIndex:1] capitalizedString];
                }
            }
            else {
                // sort by lastName
                if (nil == buddy.lastName || [buddy.lastName isEqual:[NSNull null]]) {
                    
                } else {
                    firstChar = [[buddy.lastName substringToIndex:1] capitalizedString];
                }
            }
            BOOL isContactExist = NO;
            for (int i = 0; i < 26; i++)
            {
                NSString *key = [NSString stringWithFormat:@"%c", 'A'+i];
                if ([contacts[ALL_CONTACTS][key] containsObject:buddy]) {
                    isContactExist = YES;
                }
            }
            if (!isContactExist) {
                [contacts[ALL_CONTACTS][firstChar] addObject:buddy];
            }
            
            [contacts[COMPANY_CONTACTS][firstChar] addObject:buddy];
        }
        
        for (int source = 0; source < SOURCE_TYPES; source++) {
            sectionTitles[source] = [[NSMutableArray alloc] initWithCapacity:0];
            for (int i = 0; i < 26; i++)
            {
                NSString *key = [NSString stringWithFormat:@"%c", 'A'+i];
                if ([contacts[source][key] count])
                [sectionTitles[source] addObject:key];
            }
        }

        [contactsTableView reloadData];
        [self getGroups];

        // Also store an entry for myself
        BOOL isMyBuddyExist = NO;
        for (Buddy *myBuddy in account.buddyList.allBuddies) {
            if ([myBuddy.email isEqualToString:[account getMyBuddy].email]) {
                isMyBuddyExist = YES;
                break;
            }
        }
        if (!isMyBuddyExist) {
            [account.buddyList addBuddy:[account getMyBuddy]];
        }
        [account.buddyList saveBuddiesToUserDefaults];
        
        [delegate hideActivityIndicator];

    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                                         id responseJSON){
        [delegate hideActivityIndicator];
    };

    [endpoint getCompanyContacts];
}

- (void)getUpdatedAllContacts:(NSString *)dateOfPreviousApiCall
{
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        lastDateOfFetchContacts = responseJSON[@"time"];
        [self updateContactsWithServerData:responseJSON[@"data"]];
        
        [delegate hideActivityIndicator];
        
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
    };
    NSArray *dateArray = [lastDateOfFetchContacts componentsSeparatedByString:@"+"];
    if (dateArray.count == 2) {
        lastDateOfFetchContacts = dateArray[0];
    }
    [endpoint getUpdatedContacts:lastDateOfFetchContacts];
}
- (void)filterContactsBySource:(NSInteger)source
{
    selectedSource = source;
    //if (contactsLoaded) {
        AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [delegate showActivityIndicator];
        [contactsTableView reloadData];
        [delegate hideActivityIndicator];
    //}
}

- (void)tableTapped:(UIGestureRecognizer *)gesture
{
    [[self view] endEditing:YES];
}

- (void)setImageForBuddy:(Buddy *)buddy imageView:(UIImageView *)imgview imageBorder:(BOOL)border
{
    if (buddy.photo) {
        imgview.image = buddy.photo;
        if (border) {
            imgview.layer.borderWidth = 1;
        }
    } else {
        if (border) {
            imgview.layer.borderWidth = 2;
        }
        
        CRNInitialsImageView *crnImageView = [[CRNInitialsImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        crnImageView.initialsBackgroundColor = [UIColor whiteColor];
        crnImageView.initialsTextColor = DEFAULT_UICOLOR;
        crnImageView.initialsFont = [UIFont boldSystemFontOfSize:18];
        crnImageView.useCircle = FALSE;
        crnImageView.firstName = buddy.firstName;
        crnImageView.lastName = buddy.lastName;
        crnImageView.email = buddy.email;
        [crnImageView drawImage];
        imgview.image = crnImageView.image;
    }
}

- (void)backFromCreateGroup:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    if ([info[@"group"] isEqualToString:@"create"]) {
        
        isCreateGroup = YES;
        
        isEditGroup = NO;
        
        startDiscUsingContact = NO;
        
        contactsTableView.hidden = NO;
        
        groupsView.hidden = YES;
        
        [self.filterBtn setHidden:NO];
        
        [self.downArrowImgView setHidden:NO];
        
        [self startSelectionMode];
        
    } else if ([info[@"group"] isEqualToString:@"cancel"]) {
        
    }
}

- (void)backFromEditGroup:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    if ([info[@"group"] isEqualToString:@"edit"]) {
        
        isEditGroup = YES;
        
        isCreateGroup = NO;
        
        startDiscUsingContact = NO;
    }
}

- (void)deleteContactFromList:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    Buddy *deleteBuddy = info[@"deleteBuddy"];
    /*
    for (int contactType = 0; contactType < SOURCE_TYPES; contactType++) {
        if (nil != sectionTitles[contactType]) {
            [sectionTitles[contactType] removeObject:deleteBuddy];
        }
    }
    */
    BOOL breakLoop = NO;
    for (int sourceType = 0; sourceType < SOURCE_TYPES; sourceType++) {
        
        for(int i = 0; i < sectionTitles[sourceType].count; i++)
        {
            NSString *key = sectionTitles[sourceType][i];
            for(int j = 0; j < [contacts[sourceType][key] count]; j++)
            {
                Buddy *userBuddy = contacts[sourceType][key][j];
                if (userBuddy == deleteBuddy) {
                    [contacts[sourceType][key] removeObject:deleteBuddy];
                    if ([contacts[sourceType][key] count] == 0) {
                        [sectionTitles[sourceType] removeObject:key];
                    }
                    breakLoop = YES;
                    break;
                }
            }
            if (breakLoop) {
                breakLoop = NO;
                break;
            }
        }
    }
    Account *account = [Account sharedInstance];
    [account.buddyList removeBuddy:deleteBuddy];
    [account.buddyList saveBuddiesToUserDefaults];
    
    [contactsTableView reloadData];
}
- (void)deleteGroupFromList:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    Group *deleteGroup = info[@"deleteGroup"];
    [groups removeObject:deleteGroup];
    [groupsView reloadData];
}

- (void)selectGroup:(NSIndexPath *)index
{
    UICollectionViewCell *cell = [groupsView cellForItemAtIndexPath:index];
    UIButton *selectBtn = (UIButton *)[cell viewWithTag:700];
    [selectBtn setBackgroundColor:DEFAULT_UICOLOR];
    if (![selectedGroups containsObject:groups[index.row-1]]) {
        [selectedGroups addObject:groups[index.row-1]];
    }
    [indexPaths addObject:index];
}

- (void)deselectGroup:(NSIndexPath *)index
{
    UICollectionViewCell *cell = [groupsView cellForItemAtIndexPath:index];
    UIButton *selectBtn = (UIButton *)[cell viewWithTag:700];
    [selectBtn setBackgroundColor:nil];
    if ([selectedGroups containsObject:groups[index.row-1]]) {
        [selectedGroups removeObject:groups[index.row-1]];
    }
    [indexPaths removeObject:index];
}

- (BOOL)isFreeUserForContacts:(NSInteger)selection
{
    if (selection == 2) {
        BOOL salesforce = [[[NSUserDefaults standardUserDefaults] objectForKey:SALESFORCE_CONFIG] boolValue];
        if (!salesforce) {
            return NO;
        }
    } else if (selection == 3) {
        BOOL zoho = [[[NSUserDefaults standardUserDefaults] objectForKey:ZOHO_CONFIG] boolValue];
        if (!zoho) {
            return NO;
        }
    }
    return YES;
}
- (void)getLastDateOfFetchContacts
{
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss"];
    
    [dateFormatter setTimeZone:[NSTimeZone defaultTimeZone]];
    
    lastDateOfFetchContacts = [dateFormatter stringFromDate:date];
    
}

- (void)updateContactsWithServerData:(NSArray *)dictArray
{
    if (dictArray.count > 0) {
        for (NSDictionary *dictionary in dictArray) {
            
            BOOL isExistingContact = NO;
            
            for(int i = 0; i < sectionTitles[0].count; i++)//for(NSString *key in sectionTitles[0])
            {
                NSString *key = sectionTitles[0][i];
                BOOL breakLoop = NO;
                
                for(int j = 0; j < [contacts[0][key] count]; j++)//for(Buddy *userBuddy in contacts[0][key])
                {
                    Buddy *userBuddy = contacts[0][key][j];
                    if ([dictionary[@"email"] isEqualToString:userBuddy.email]) {
                        
                        breakLoop = YES;
                        isExistingContact = YES;
                        
                        NSString *sourcetype = dictionary[@"source"];
                        
                        if ([sourcetype isEqualToString:@"Device"]){
                            [contacts[DEVICE_CONTACTS][key] removeObject:userBuddy];
                            if ([contacts[DEVICE_CONTACTS][key] count] == 0) {
                                [sectionTitles[DEVICE_CONTACTS] removeObject:key];
                            }
                        } else if ([sourcetype isEqualToString:@"Salesforce"]) {
                            [contacts[SALESFORCE_CONTACTS][key] removeObject:userBuddy];
                            if ([contacts[SALESFORCE_CONTACTS][key] count] == 0) {
                                [sectionTitles[SALESFORCE_CONTACTS] removeObject:key];
                            }
                        } else if ([sourcetype isEqualToString:@"Zoho"]) {
                            [contacts[ZOHO_CONTACTS][key] removeObject:userBuddy];
                            if ([contacts[ZOHO_CONTACTS][key] count] == 0) {
                                [sectionTitles[ZOHO_CONTACTS] removeObject:key];
                            }
                        } else if ([sourcetype isEqualToString:@"Google"]) {
                            [contacts[GOOGLE_CONTACTS][key] removeObject:userBuddy];
                            if ([contacts[GOOGLE_CONTACTS][key] count] == 0) {
                                [sectionTitles[GOOGLE_CONTACTS] removeObject:key];
                            }
                        } else if (nil == sourcetype) {//} else if ([sourcetype isEqualToString:@""]) { //Source not come for company
                            [contacts[COMPANY_CONTACTS][key] removeObject:userBuddy];
                            if ([contacts[COMPANY_CONTACTS][key] count] == 0) {
                                [sectionTitles[COMPANY_CONTACTS] removeObject:key];
                            }
                        }
                        // All Contacts
                        [contacts[0][key] removeObject:userBuddy];
                        if ([contacts[0][key] count] == 0) {
                            [sectionTitles[0] removeObject:key];
                        }
                        
                        Account *account = [Account sharedInstance];
                        for (int i = 0; i < account.buddyList.allBuddies.count; i++) { // Remove buddy from buddylist
                            Buddy *buddy = account.buddyList.allBuddies[i];
                            if ([buddy.email isEqualToString:dictionary[@"email"]]) {
                                [account.buddyList.allBuddies removeObject:buddy];
                                break;
                            }
                        }
                        
                        [self insertBuddy:dictionary]; // Insert buddy for updation
                        
                        break;
                    }
                }
                if (breakLoop) {
                    break;
                }
            }
            if(!isExistingContact) {
                [self insertBuddy:dictionary]; // Insert buddy for updation
            }
        }
        
        for (int source = 0; source < SOURCE_TYPES; source++) {//Need to re-populate after any new contacts are added or updated
            [sectionTitles[source] removeAllObjects];
            sectionTitles[source] = [[NSMutableArray alloc] initWithCapacity:0];
            for (int i = 0; i < 26; i++)
            {
                NSString *key = [NSString stringWithFormat:@"%c", 'A'+i];
                if ([contacts[source][key] count])
                    [sectionTitles[source] addObject:key];
            }
        }
        [contactsTableView reloadData];
        Account *account = [Account sharedInstance];
        // save the updated contact info to user defaults.
        [account.buddyList saveBuddiesToUserDefaults];
    }
}

- (void)insertBuddy:(NSDictionary *)dictionary
{
    NSString *sourcetype = dictionary[@"source"];
    
    NSString *name;
    
    ABPersonCompositeNameFormat displayOrder = ABPersonGetCompositeNameFormatForRecord(NULL);
    
    if (displayOrder == kABPersonCompositeNameFormatFirstNameFirst) {
        name = [NSString stringWithFormat:@"%@ %@", dictionary[@"first_name"],
                dictionary[@"last_name"]];
    } else {
        name = [NSString stringWithFormat:@"%@ %@", dictionary[@"last_name"],
                dictionary[@"first_name"]];
    }
    
    NSString *email = dictionary[@"email"];
    NSNumber *is_liri_user = dictionary[@"is_liri_user"];
    NSString *profile_pic = dictionary[@"profile_pic"];
    
    Account *account = [Account sharedInstance];
    UIImage *buddyphoto = [account.s3Manager downloadImage:profile_pic];
    
    NSLog(@"Adding new buddy for %@!", email);
    Buddy *buddy = [Buddy buddyWithDisplayName:name email:email photo:buddyphoto isUser:[is_liri_user boolValue]];
    [account.buddyList addBuddy:buddy];
    
    
    buddy.displayName = name;
    buddy.firstName = dictionary[@"first_name"];
    buddy.lastName = dictionary[@"last_name"];
    buddy.availabilityStatus = dictionary[@"status"];
    NSString *firstChar;// = [[name substringToIndex:1] capitalizedString];
    
    ABPersonSortOrdering sortOrder = ABPersonGetSortOrdering();
    if (sortOrder == kABPersonSortByFirstName) {
        // sort by firstName
        if (![dictionary[@"first_name"] isEqualToString:@""]) {
            firstChar = [[buddy.firstName substringToIndex:1] capitalizedString];
        }
    }
    else {
        // sort by lastName
        if (![dictionary[@"last_name"] isEqualToString:@""]) {
            firstChar = [[buddy.lastName substringToIndex:1] capitalizedString];
        }
    }
    [contacts[ALL_CONTACTS][firstChar] addObject:buddy];
    
    if ([sourcetype isEqualToString:@"Device"])
        [contacts[DEVICE_CONTACTS][firstChar] addObject:buddy];
    else if ([sourcetype isEqualToString:@"Salesforce"])
        [contacts[SALESFORCE_CONTACTS][firstChar] addObject:buddy];
    else if ([sourcetype isEqualToString:@"Zoho"])
        [contacts[ZOHO_CONTACTS][firstChar] addObject:buddy];
    else if ([sourcetype isEqualToString:@"Google"])
        [contacts[GOOGLE_CONTACTS][firstChar] addObject:buddy];
    else if (nil == sourcetype)//else if ([sourcetype isEqualToString:@""])//Source not come for company
        [contacts[COMPANY_CONTACTS][firstChar] addObject:buddy];
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Contacts
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.searchContactsTableView) {
        return 1;
    }
    return [sectionTitles[selectedSource] count];
}

- (NSString *)tableView:(UITableView *)sender titleForHeaderInSection:(NSInteger)sectionIndex
{
    
    if (sender == self.searchContactsTableView) {
        return nil;
    }
    return sectionTitles[selectedSource][sectionIndex];
}

- (CGFloat)tableView:(UITableView *)sender heightForHeaderInSection:(NSInteger)section
{
    if (sender == self.searchContactsTableView) {
        return 0;
    }
    return 20;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    if (tableView == self.searchContactsTableView) {
        return searchResults.count;
    }
    NSString *key = sectionTitles[selectedSource][sectionIndex];
    return [contacts[selectedSource][key] count];
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (tableView == self.searchContactsTableView) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"searchContactsCell"];
        
        if (segmentedCtrl.selectedSegmentIndex == 0 && [contactsTableView isHidden]) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"searchContactsCell"];
            Group *searchedGroup = searchResults[indexPath.row];
            
            cell.textLabel.text = searchedGroup.name;

        } else {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"searchContactsCell"];
            Buddy *buddy = searchResults[indexPath.row];
            
            cell.textLabel.text = buddy.displayName;
            
            cell.detailTextLabel.text = buddy.email;
        }
        
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"contactsCell"];
        UILabel *lblName = (UILabel *)[cell viewWithTag:100];
        Buddy *buddy;
        
        NSString *key = sectionTitles[selectedSource][indexPath.section];
        buddy = [contacts[selectedSource][key] objectAtIndex:indexPath.row];
        [lblName setText:buddy.displayName];
        
        UIImageView *photoView = (UIImageView *)[cell viewWithTag:200];
        photoView.contentMode = UIViewContentModeScaleAspectFit;
        [self setImageForBuddy:buddy imageView:photoView imageBorder:YES];

        photoView.layer.cornerRadius = 20;
        photoView.clipsToBounds = YES;
        //photoView.layer.borderWidth = 2;
        photoView.layer.borderColor = DEFAULT_CGCOLOR;
        
        UIImageView *imgView = (UIImageView *)[cell viewWithTag:300];
        UIButton *inviteBtn = (UIButton *)[cell viewWithTag:400];
        UILabel *statusLabel = (UILabel *)[cell viewWithTag:500];

        if (!buddy.isUser) {
            imgView.image = [UIImage imageNamed:@"Invite-to-Connect-Icon.png"];
            inviteBtn.hidden = NO;
            statusLabel.hidden = YES;
        } else {
            if ([buddy.availabilityStatus isEqualToString:@"Available"]) {
                imgView.image = [UIImage imageNamed:@"Status-Available-Icon.png"];
                [statusLabel setText:@"Available"];
            } else if ([buddy.availabilityStatus isEqualToString:@"Away"]) {
                imgView.image = [UIImage imageNamed:@"Status-Away-Icon.png"];
                [statusLabel setText:@"Away"];
            } else if ([buddy.availabilityStatus isEqualToString:@"Busy"]) {
                imgView.image = [UIImage imageNamed:@"Status-Busy-Icon.png"];
                [statusLabel setText:@"Busy"];
            } else {
                imgView.image = [UIImage imageNamed:@"Status-Available-Icon.png"];
                [statusLabel setText:@"Available"];
            }
            inviteBtn.hidden = YES;
            statusLabel.hidden = NO;
        }
    }

    return cell;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (tableView == self.searchContactsTableView) {
        return nil;
    }
    return [NSArray arrayWithObjects:@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"Y", @"Z", nil];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    if (tableView == self.searchContactsTableView) {
        return 0;
    }
    return [sectionTitles[selectedSource] indexOfObject:title];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchContactsTableView) {
        [self.searchContactsTableView setHidden: YES];
        [self.searchBar setText:@""];
        [self.searchBar resignFirstResponder];
        
        sectionValue = 0;
        
        if (self.segmentedCtrl.selectedSegmentIndex == 0 && [contactsTableView isHidden]) {
            
            Group *selectedGroup = searchResults[indexPath.row];
            
            rowValue = 0;
            
            for (Group *searchGroup in groups) {
                if ([selectedGroup isEqual:searchGroup]) {
                    break;
                }
                rowValue++;
            }
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowValue inSection:sectionValue];
            
            
            if (selectionMode) {
                indexPath = [NSIndexPath indexPathForRow:indexPath.row+1 inSection:indexPath.section];
                UICollectionViewCell *cell = [groupsView cellForItemAtIndexPath:indexPath];
                UIButton *selectBtn = (UIButton *)[cell viewWithTag:700];
                [selectBtn setBackgroundColor:DEFAULT_UICOLOR];
                [selectedGroups addObject:selectedGroup];
            } else {
                UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"GroupsContacts" bundle:nil];
                GroupViewController *groupCtlr = [storyBoard instantiateViewControllerWithIdentifier:@"GroupViewController"];
                [groupCtlr initWithGroup:[groups objectAtIndex:indexPath.row] new:NO];
                updateGroup = groups[indexPath.row];
                [self.navigationController pushViewController:groupCtlr animated:YES];
            }
        } else {
            selectedBuddy = searchResults[indexPath.row];

            stopLoop = NO;
            
            for(NSString *key in sectionTitles[selectedSource])
            {
                rowValue = 0;
                for(Buddy *userBuddy in contacts[selectedSource][key])
                {
                    if([userBuddy isEqual:selectedBuddy])
                    {
                        stopLoop = YES;
                        break;
                    }
                    rowValue++;
                }
                if(stopLoop) {
                    break;
                }
                sectionValue++;
            }
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowValue inSection:sectionValue];
            
            if (selectionMode) {
                [contactsTableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
                [selectedBuddies addBuddy:selectedBuddy];
            } else {

                UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"GroupsContacts" bundle:nil];
                ContactProfileViewController *profCtlr = (ContactProfileViewController *)[storyBoard instantiateViewControllerWithIdentifier:@"ContactProfileViewController"];
                [profCtlr initWithBuddy:selectedBuddy];
                [self.navigationController pushViewController:profCtlr animated:YES];
            }
        }
        
        
    } else {
        
        Buddy *buddy;
        
        NSString *key = sectionTitles[selectedSource][indexPath.section];
        buddy = [contacts[selectedSource][key] objectAtIndex:indexPath.row];
        
        if (selectionMode) {
            [selectedBuddies addBuddy:buddy];
        } else {
            if ([tableView isEditing]) {
                [selectedBuddies addBuddy:buddy];
            } else {
                [tableView deselectRowAtIndexPath:indexPath animated:NO];
                
                UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"GroupsContacts" bundle:nil];
                ContactProfileViewController *profCtlr = (ContactProfileViewController *)[storyBoard instantiateViewControllerWithIdentifier:@"ContactProfileViewController"];
                [profCtlr initWithBuddy:buddy];
                [self.navigationController pushViewController:profCtlr animated:YES];
            }
            
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchContactsTableView) {
        
    } else {
        Buddy *buddy;
      
        NSString *key = sectionTitles[selectedSource][indexPath.section];
        buddy = [contacts[selectedSource][key] objectAtIndex:indexPath.row];
        [selectedBuddies removeBuddy:buddy];
    }
}

- (IBAction)filterAction:(id)sender {

    if (filterPickerHidden) {
        [self.view addSubview:filterPicker];
        filterPickerHidden = NO;
    } else {
        [filterPicker removeFromSuperview];
        filterPickerHidden = YES;
    }
}

#pragma mark -
#pragma mark PickerView DataSource

- (NSInteger)numberOfComponentsInPickerView:
(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
    return filters.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    return filters[row];
} 

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 30;
}

#pragma mark -
#pragma mark PickerView Delegate
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row
      inComponent:(NSInteger)component
{
    prevSelectedIndex = currentSelectedIndex;
    currentSelectedIndex = row;
    
    [filterPicker removeFromSuperview];
    filterPickerHidden = YES;
    
    if (![self isFreeUserForContacts:row]) {
        [pickerView selectRow:prevSelectedIndex inComponent:0 animated:NO];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:FREE_USER_CONFIG_MSG delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    } else {
        selectedFilterRow = row;
        [filterBtn setTitle:filters[row] forState:UIControlStateNormal];
        
        [self filterContactsBySource:selectedFilterRow];
    }
    
}

- (void)startSelectionMode
{
    selectionMode = YES;

    if (isEditGroup) {
        contactsTableView.hidden = NO;
        groupsView.hidden = YES;
        [self.filterBtn setHidden:NO];
    } else {
        [selectedGroups removeAllObjects];
        [groupsView reloadData];
    }
    
    if (groupsView.isHidden) {
        self.segmentedCtrl.selectedSegmentIndex = 1;
    }
    [selectedBuddies.allBuddies removeAllObjects];
    [contactsTableView setEditing:YES animated:YES];
    
    UIBarButtonItem *item = self.navigationItem.rightBarButtonItem;
    item.image = nil;
    item.title = @"Next";
    item.action = @selector(nextAction:);
    
    item = self.navigationItem.leftBarButtonItem;
    item.image = nil;
    item.title = @"Cancel";
    item.action = @selector(cancelAction:);
}

- (void)endSelectionMode
{
    selectionMode = NO;
    
    [groupsView reloadData];
    [contactsTableView setEditing:NO animated:YES];
    
    UIBarButtonItem *item = self.navigationItem.rightBarButtonItem;
    item.image = [UIImage imageNamed:@"Initiate-Conversation-Icon.png"];
    item.title = @"";
    item.action = @selector(initiateAction:);
    
    item = self.navigationItem.leftBarButtonItem;
    item.image = [UIImage imageNamed:@"Add-Icon.png"];
    item.title = @"";
    item.action = @selector(addAction:);
}


- (IBAction)initiateAction:(id)sender {
    
    [self startSelectionMode];
}
        
- (IBAction)nextAction:(id)sender {

    if (isCreateGroup || isEditGroup) {
        startDiscUsingContact = NO;
    } else {
        startDiscUsingContact = YES;
    }
    NSString *msg = nil;
    
    if (segmentedCtrl.selectedSegmentIndex == 0) {
        if (selectedGroups.count == 0) {
            msg = @"Please select the groups to start the discussion.";
        }
    } else {
        if (selectedBuddies.allBuddies.count == 0) {
            if (isEditGroup) {
                msg = @"Please select the participants to add to the group.";
            } else if (startDiscUsingContact) {
                msg = @"Please select the participants to start the discussion.";
            } else if (isCreateGroup) {
                msg = @"Please select the participants to create the group.";
            }
        }
    }
    if (msg != nil) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:msg
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    [self endSelectionMode];
    
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"GroupsContacts" bundle:nil];
    if (segmentedCtrl.selectedSegmentIndex == 0) {
        //create discussion with groups
        NewDiscussionViewController *newdiscCtlr = [storyBoard instantiateViewControllerWithIdentifier:@"NewDiscussionViewController"];
        [newdiscCtlr initWithGroups:selectedGroups];
        [self presentViewController:newdiscCtlr animated:NO completion:nil];
        
    } else {
        if (isEditGroup) {
            //Edit groups
            for (Buddy *buddy in selectedBuddies.allBuddies) {
                
                if (![updateGroup.memberlist.allBuddies containsObject:buddy]) {
                    
                    [updateGroup addMember:buddy];
                }
            }
            [groupsView reloadData];
            
            GroupViewController *groupCtlr = [storyBoard instantiateViewControllerWithIdentifier:@"GroupViewController"];
            
            [groupCtlr initWithUpdateGroup:updateGroup];
            
            [self.navigationController pushViewController:groupCtlr animated:YES];
            
            [self.segmentedCtrl setSelectedSegmentIndex:0];
            
        } else if (startDiscUsingContact) {
            //create discussion with contacts
            NewDiscussionViewController *newdiscCtlr = [storyBoard instantiateViewControllerWithIdentifier:@"NewDiscussionViewController"];
            
            [newdiscCtlr initWithBuddyList:selectedBuddies];
            
            [self presentViewController:newdiscCtlr animated:NO completion:nil];
            
        } else if (isCreateGroup){
            //Create Group
            for (Buddy *buddy in selectedBuddies.allBuddies) {
                [newgroup addMember:buddy];
            }
            [groups addObject:newgroup];
            
            [groupsView reloadData];
            
            GroupViewController *groupCtlr = [storyBoard instantiateViewControllerWithIdentifier:@"GroupViewController"];
            
            [groupCtlr initWithGroup:newgroup new:YES];
            
            [self.navigationController pushViewController:groupCtlr animated:YES];
            
            [self.segmentedCtrl setSelectedSegmentIndex:0];
        }
    }
}

- (IBAction)addAction:(id)sender {
    if (!selectionMode) {
        
        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Import" bundle:nil];
        UIViewController *viewController = [storyBoard instantiateInitialViewController];
        [self.view.window setRootViewController:viewController];
        self.tabBarController.tabBar.hidden = YES;
    } else {
        [self endSelectionMode];
    }
}

- (void)cancelAction:(id)sender {
    if (isEditGroup || isCreateGroup) {
        self.segmentedCtrl.selectedSegmentIndex = 0;
        [self segmentedCtrlAction:self];
    }
    isEditGroup = NO;
    startDiscUsingContact = NO;
    isCreateGroup = NO;
    
    [self endSelectionMode];
}

- (IBAction)inviteAction:(id)sender {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailComposer =
            [[MFMailComposeViewController alloc] init];
        
        UIButton *inviteBtn = (UIButton *)sender;
        UITableViewCell *cell;
        
        if([inviteBtn.superview.superview isKindOfClass:[UITableViewCell class]]) {
            cell = (UITableViewCell *) inviteBtn.superview.superview;
        } else {
            cell = (UITableViewCell *) inviteBtn.superview.superview.superview;
        }
        NSIndexPath *indexPath = [contactsTableView indexPathForCell:cell];
        NSString *key = sectionTitles[selectedSource][indexPath.section];
        Buddy *buddy = [contacts[selectedSource][key] objectAtIndex:indexPath.row];

        [mailComposer setToRecipients:[NSArray arrayWithObjects:buddy.email, nil]];
        [mailComposer setSubject:@"Let's connect on Liri app"];
        
        NSArray *components = [buddy.displayName componentsSeparatedByString:@" "];
        
        NSString *message = [NSString stringWithFormat:@"Hi %@,<br/><br/>&nbsp&nbsp&nbsp&nbspHope you are doing well. I found this cool new business collaboration app called Liri. The app has interesting features like the ability to search across multiple cloud sources, and add annotation to documents. You should download their app from their website - <a href='http://www.liriapp.com'>www.liriapp.com</a> and send me a message from the app. <br/>", components[0]];

        [mailComposer setMessageBody:message
                              isHTML:YES];
        mailComposer.mailComposeDelegate = self;
        [self presentViewController:mailComposer animated:YES completion:nil];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Unable to send invite, please add your company email account to Mail app."
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

#pragma mark MFMailComposeViewControllerDelegate

-(void)mailComposeController:(MFMailComposeViewController *)controller
         didFinishWithResult:(MFMailComposeResult)result
                       error:(NSError *)error{
    [self dismissViewControllerAnimated:YES completion:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Groups
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)getGroups
{
    [groups removeAllObjects];

    Account *account = [Account sharedInstance];
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        for (NSDictionary *dict in [responseJSON objectForKey:@"groups"]) {
            Group *group = [Group groupWithName:[dict objectForKey:@"name"]];
            NSString *owneremail = [dict objectForKey:@"owner"];
            Buddy *ownerBuddy = [account.buddyList findBuddyForEmail:owneremail];
            if (nil != ownerBuddy) {
                group.owner = ownerBuddy;
            } else {
                ownerBuddy = [[Buddy alloc] init];
                ownerBuddy.email = dict[@"owner"];
                ownerBuddy.displayName = dict[@"owner"];
                ownerBuddy.firstName = @"";
                ownerBuddy.lastName = @"";
                group.owner = ownerBuddy;
            }
            group.groupID = [dict objectForKey:@"id"];
            NSArray *members = [dict objectForKey:@"members"];
            for (NSString *email in members) {
                if (![email isEqualToString:ownerBuddy.email]) {
                    
                    Buddy *buddy = [account.buddyList findBuddyForEmail:email];
                    
                    if (nil != buddy) {
                        [group addMember:buddy];
                    } else {
                        buddy = [[Buddy alloc] init];
                        buddy.email = email;
                        buddy.displayName = email;
                        buddy.firstName = @"";
                        buddy.lastName = @"";
                        [group addMember:buddy];
                    }
                }
            }
            [groups addObject:group];
        }
        [groupsView reloadData];

        [delegate hideActivityIndicator];
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        /*UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Unable to get list of groups"
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];*/
        [delegate hideActivityIndicator];
    };
    [endpoint getGroups];
}

- (IBAction)segmentedCtrlAction:(id)sender {
    
    if(isEditGroup || isCreateGroup) {
        [self endSelectionMode];
    }
    if (segmentedCtrl.selectedSegmentIndex == 0) {
        
        [filterPicker removeFromSuperview];
        filterPickerHidden = YES;
        
        contactsTableView.hidden = YES;
        groupsView.hidden = NO;
        [self.filterBtn setHidden:YES];
        
        [self.downArrowImgView setHidden:YES];
        
    } else {
        contactsTableView.hidden = NO;
        groupsView.hidden = YES;
        [self.filterBtn setHidden:NO];
        
        [self.downArrowImgView setHidden:NO];
    }
    [self dismissSearchTableView];
}

#pragma mark -
#pragma mark UICollectionViewDataSource

-(NSInteger)numberOfSectionsInCollectionView:
(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section
{
    return ([groups count]+1);
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *groupsCell;
    
    if (indexPath.row == 0) {
        groupsCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CreateGroupCell"
                            forIndexPath:indexPath];
        UIImageView *imageView = (UIImageView *)[groupsCell viewWithTag:100];
        imageView.image = [UIImage imageNamed:@"Add-Group-Icon.png"];
    } else {
        groupsCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ShowGroupCell"
                            forIndexPath:indexPath];
        
        Group *group = [groups objectAtIndex:indexPath.row-1];
        UILabel *label = (UILabel *)[groupsCell viewWithTag:500];
        label.text = group.name;
        
        //square border
        /*UIImageView *imgview = (UIImageView *)[groupsCell viewWithTag:600];
        imgview.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        imgview.layer.borderWidth = 1;*/
        
        UIButton *selectBtn = (UIButton *)[groupsCell viewWithTag:700];
//        [selectBtn setBackgroundColor:nil];
        
        
        if (selectionMode) {
            [selectBtn addTarget:self action:@selector(groupSelectAction:event:) forControlEvents:UIControlEventTouchUpInside];

            selectBtn.layer.borderColor = DEFAULT_CGCOLOR;
            selectBtn.layer.borderWidth = 2;
            selectBtn.layer.cornerRadius = 8;
            selectBtn.layer.masksToBounds = YES;
            selectBtn.hidden = NO;
            
            if ([indexPaths containsObject:indexPath]) {
                selectBtn.backgroundColor = DEFAULT_UICOLOR;
            } else {
                selectBtn.backgroundColor = nil;
            }
        } else {
            selectBtn.hidden = YES;
            [selectBtn setBackgroundColor:nil];
            [indexPaths removeAllObjects];
        }
        int count = 0;
        
        for (int i = 1; i <= 4; i++) {
            UIImageView *imgview = (UIImageView *)[groupsCell viewWithTag:i*100];
            imgview.hidden = YES;
        }
        {
            count++;
            UIImageView *imgview = (UIImageView *)[groupsCell viewWithTag:count*100];
            imgview.hidden = NO;
            if (group.owner.photo) {
                [imgview setImage:group.owner.photo];
            } else {
                [self setImageForBuddy:group.owner imageView:imgview imageBorder:NO];
            }
        }
        for (Buddy *buddy in group.memberlist.allBuddies) {
         //if (buddy.photo) {
            {
                if(![buddy.email isEqualToString:group.owner.email]) {
                    count++;
                    UIImageView *imgview = (UIImageView *)[groupsCell viewWithTag:count*100];
                    imgview.hidden = NO;
                    if (buddy.photo) {
                        [imgview setImage:buddy.photo];
                    } else {
                        [self setImageForBuddy:buddy imageView:imgview imageBorder:NO];
                    }
                }
            }
            if (count == 4) break;
        }
    }
    
    return groupsCell;
}

- (void)groupSelectAction:(id)sender event:(id)event
{
    NSSet *touches = [event allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:groupsView];
	NSIndexPath *indexPath = [groupsView indexPathForItemAtPoint:currentTouchPosition];
    if (indexPath != nil) {
        UIButton *selectBtn = (UIButton *)sender;
        if (![selectBtn backgroundColor]) {
            [self selectGroup:indexPath];
        } else {
            [self deselectGroup:indexPath];
        }
    }
}

#pragma mark -
#pragma mark UICollectionViewDelegate

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        // create a group
        isEditGroup = NO;
        newgroup = [[Group alloc] init];
        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"GroupsContacts" bundle:nil];
        CreateGroupViewController *groupsCtlr = [storyBoard instantiateViewControllerWithIdentifier:@"CreateGroupViewController"];
        [groupsCtlr initWithGroup:newgroup];
        updateGroup = newgroup;
        [self presentViewController:groupsCtlr animated:NO completion:nil];
    } else {
        if (selectionMode) {
            UICollectionViewCell *cell = [groupsView cellForItemAtIndexPath:indexPath];
            UIButton *selectBtn = (UIButton *)[cell viewWithTag:700];
            if (![selectBtn backgroundColor]) {
                [self selectGroup:indexPath];
            } else {
                [self deselectGroup:indexPath];
            }
        } else {
            UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"GroupsContacts" bundle:nil];
            GroupViewController *groupCtlr = [storyBoard instantiateViewControllerWithIdentifier:@"GroupViewController"];
            [groupCtlr initWithGroup:[groups objectAtIndex:indexPath.row-1] new:NO];
            updateGroup = groups[indexPath.row - 1];
            [self.navigationController pushViewController:groupCtlr animated:YES];
        }
    }
}

#pragma mark - UISearchBar Delegate Methods
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    searchResults = [NSMutableArray array];
    return YES;
}
- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    return YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    self.searchContactsTableView.hidden = NO;
    
    NSString * searchStr = [self.searchBar.text stringByReplacingCharactersInRange:range withString:text];
    [self searchAutocompleteEntriesWithSubstring:searchStr];
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchText length] == 0) {
        [self performSelector:@selector(hideKeyboardWithSearchBar:) withObject:self.searchBar afterDelay:0];
    }
}

- (void)hideKeyboardWithSearchBar:(UISearchBar *)searchBar
{
    [self.searchContactsTableView setHidden: YES];

}


- (void)searchAutocompleteEntriesWithSubstring:(NSString *)substring
{
    
    if (![substring hasSuffix:@"\n"] && ![substring isEqualToString:@""]) {
        
        [searchResults removeAllObjects];
        
        if (self.segmentedCtrl.selectedSegmentIndex == 0 && [contactsTableView isHidden]) {
            for (Group *searchGroup in groups) {
                
                NSString *groupName = searchGroup.name;
                
                if (nil != groupName) {
                    
                    NSRange groupNameRange = [groupName rangeOfString:substring options:NSCaseInsensitiveSearch];
            
                    if (groupNameRange.location == 0) {
                        [searchResults addObject:searchGroup];
                    }
                }
            }
        } else {
            for(NSString *key in sectionTitles[selectedSource])
            {
                for(Buddy *userBuddy in contacts[selectedSource][key])
                {
                    NSString *first = userBuddy.firstName;
                    NSString *last = userBuddy.lastName;
                    
                    NSString *name = userBuddy.displayName;
                    
                    if (!isNSNull(first) && !isNSNull(last) && !isNSNull(name)) {
                        NSRange firstNameRange = [first rangeOfString:substring options:NSCaseInsensitiveSearch];
                        
                        NSRange lastNameRange = [last rangeOfString:substring options:NSCaseInsensitiveSearch];
                        
                        NSRange nameRange = [name rangeOfString:substring options:NSCaseInsensitiveSearch];
                        
                        if (firstNameRange.location == 0 || lastNameRange.location == 0 || nameRange.location == 0)
                        {
                            if (nil != first && nil != last && nil != name) {
                                [searchResults addObject:userBuddy];
                            }
                            
                        }
                    }
                }
            }
        }
        [self.searchContactsTableView reloadData];
    }
    if ([substring isEqualToString:@""]) {
        self.searchBar.text = @"";
        self.searchContactsTableView.hidden = YES;
        [self.view endEditing:YES];
    } else if ([substring hasSuffix:@"\n"]) {
        [self.view endEditing:YES];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
