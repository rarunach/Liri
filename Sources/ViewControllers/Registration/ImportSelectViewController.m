//
//  ImportSelectViewController.m
//  Liri
//
//  Created by Ramani Arunachalam on 6/13/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "ImportSelectViewController.h"
#import "ImportTableViewController.h"
#import "Account.h"
#import "BuddyList.h"
#import "AppDelegate.h"
#import "NewDiscussionViewController.h"
#import "S3Manager.h"
#import "Account.h"
#import "AddressBook/ABAddressBook.h"
#import "AddressBook/ABPerson.h"
#import "AddressBook/ABMultiValue.h"
#import "AuthenticationsViewController.h"
#import "Flurry.h"

@interface ImportSelectViewController ()
{
    BOOL selectAll;
    NSMutableArray *searchResults;
    Buddy *selectedBuddy;
    BOOL selectedState;
    
    BOOL stopLoop;
    int rowValue, sectionValue;

}
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *contactsTableView;
@property (nonatomic) NSMutableDictionary *contacts;
@property (nonatomic) NSMutableArray *sectionTitles;
@property (nonatomic, retain) NSMutableArray *selectedContacts;
@property (weak, nonatomic) IBOutlet UIButton *importBtn;
@property (weak, nonatomic) IBOutlet UIButton *backBtn;
@property (weak, nonatomic) IBOutlet UIButton *selectAllBtn;
@property (weak, nonatomic) IBOutlet UITableView *searchContactsTableView;

@end

@implementation ImportSelectViewController

@synthesize searchBar, contactsTableView, searchContactsTableView;
@synthesize contacts, sectionTitles;
@synthesize selectedContacts, selectAllBtn;

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        
        // Do any additional setup after loading the view.
        //self.navigationItem.hidesBackButton = YES;
        
        //self.cancelBtn.hidden = YES;
        //self.nextBtn.hidden = YES;
        
        selectedContacts = [[NSMutableArray alloc] initWithCapacity:1];
        
        /*UISegmentedControl * seg1 = [[UISegmentedControl alloc]
                                     initWithItems:[NSArray arrayWithObjects:@"Groups", @"Contacts", nil]];
        seg1.selectedSegmentIndex = 1;
        self.navigationItem.titleView = seg1;
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cancelAction)];
        self.navigationItem.leftBarButtonItem = cancelButton;*/
        
        self.navigationItem.title = @"Select Contacts";
        UIBarButtonItem *importButton = [[UIBarButtonItem alloc] initWithTitle:@"Import" style:UIBarButtonItemStyleDone  target:self action:@selector(importAction)];
        self.navigationItem.rightBarButtonItem = importButton;
        
        NSMutableArray *contactsArray[26];
        contacts = [[NSMutableDictionary alloc] init];
        for (int i = 0; i < 26; i++) {
            contactsArray[i] = [[NSMutableArray alloc] initWithCapacity:1];
            NSString *key = [NSString stringWithFormat:@"%c", 'A'+i];
            [contacts setObject:contactsArray[i] forKey:key];
        }
        selectAll = NO;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [Flurry logEvent:@"Import Screen"];
    [contactsTableView setEditing:YES animated:YES];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tableTapped:)];
    [tap setNumberOfTapsRequired:1];
    tap.cancelsTouchesInView = false;
    [contactsTableView addGestureRecognizer:tap];
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
    }
}
- (void)tableTapped:(UIGestureRecognizer *)gesture
{
    [[self view] endEditing:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = NO;
    self.view.alpha = 1.0;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[self view] endEditing:YES];
}

#pragma mark - Private Methods
- (void) selectAllContacts
{
    if (selectAll) {
        for(NSString *key in sectionTitles)
        {
            for(NSDictionary *contact in contacts[key])
            {
                if (![selectedContacts containsObject:contact]) {
                    [selectedContacts addObject:contact];
                }
            }
        }
    } else {
        [selectedContacts removeAllObjects];
    }
}
- (IBAction)selectAllAction:(id)sender {
    if (!selectAll) {
        selectAll = YES;
        [selectAllBtn setTitle:@"Deselect All" forState:UIControlStateNormal];
    } else {
        selectAll = NO;
        [selectAllBtn setTitle:@"Select All" forState:UIControlStateNormal];
    }
    [self selectAllContacts];
    [contactsTableView reloadData];
}

- (void)getDeviceContacts
{
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        // callback can occur in background, address book must be accessed on thread it was created on
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                UIAlertView *alertView = [[UIAlertView alloc]
                                          initWithTitle:@""
                                          message:@"Error accessing Phone contacts."
                                          delegate:nil cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
                [alertView show];
            } else if (!granted) {
                UIAlertView *alertView = [[UIAlertView alloc]
                                          initWithTitle:@""
                                          message:@"Contacts access to Liri app is turned off in your device. You can enable contacts access to Liri app from Settings > Privacy > Contacts."
                                          delegate:nil cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
                [alertView show];
            } else {
                // access granted
                
                CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
                CFMutableArrayRef peopleMutable = CFArrayCreateMutableCopy(
                                                                           kCFAllocatorDefault,
                                                                           CFArrayGetCount(allPeople),
                                                                           allPeople
                                                                           );
                
                CFArraySortValues(
                                  peopleMutable,
                                  CFRangeMake(0, CFArrayGetCount(peopleMutable)),
                                  (CFComparatorFunction) ABPersonComparePeopleByName,
                                  kABPersonSortByFirstName
                                  );
                CFIndex nPeople = ABAddressBookGetPersonCount(addressBook);
                NSLog(@"nPeople: %ld", nPeople);
                for ( int i = 0; i < nPeople; i++ )
                {
                    ABRecordRef ref = CFArrayGetValueAtIndex(peopleMutable, i);
                    NSString *firstName = (__bridge NSString *)(ABRecordCopyValue(ref, kABPersonFirstNameProperty));
                    if (firstName == nil)
                        firstName = @"";
                    NSString *lastName = (__bridge NSString *)(ABRecordCopyValue(ref, kABPersonLastNameProperty));
                    if (lastName == nil)
                        lastName = @"";
                    ABMultiValueRef emailMultiValue = ABRecordCopyValue(ref, kABPersonEmailProperty);
                    NSArray *emailAddresses = (__bridge NSArray *)ABMultiValueCopyArrayOfAllValues(emailMultiValue);

                    for (NSString *email in emailAddresses) {
                        
                        NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:@"Device", @"source", firstName, @"first_name", lastName, @"last_name", email, @"email", nil];
                        //NSLog(@"dict: %@", dict);
                        
                        NSString *firstChar;
                        if ([firstName isEqualToString:@""])
                            firstChar = @"A";
                        else
                            firstChar = [firstName substringToIndex:1];
                        [contacts[firstChar] addObject:dict];
                    }

                }
                sectionTitles = [[NSMutableArray alloc] initWithCapacity:26];
                for (int i = 0; i < 26; i++)
                {
                    NSString *key = [NSString stringWithFormat:@"%c", 'A'+i];
                    if ([contacts[key] count])
                        [sectionTitles addObject:key];
                }
                [contactsTableView reloadData];
            }
        });
    });
    

}

- (void)getContactsForSource:(NSString *)source
{
    NSLog(@"source: %@", source);
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                                 sharedInstanceWithClientProtocol:
                                 @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        NSLog(@"responseJSON: %@", responseJSON);
        NSDictionary *dict = (NSDictionary *)responseJSON;
        NSArray *contactsArr = [dict objectForKey:@"records"];
        NSLog(@"contacts count: %ld", [contactsArr count]);
        for (NSDictionary *contact in contactsArr)
        {
            NSString *name = [contact objectForKey:@"Name"];
            
            if(name == [NSNull null] || name == nil)
                continue;
            NSArray *components = [name componentsSeparatedByString:@" "];
            NSString *firstname = components[0];
            NSString *email = [contact objectForKey:@"Email"];
            if ([firstname isEqualToString:@""] || email == [NSNull null] || [email isEqualToString:@""])
                continue;
            NSString *lastname = @"";
            if (components.count == 2)
                lastname = components[1];
            NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:source, @"source", firstname, @"first_name", lastname, @"last_name", [contact objectForKey:@"Email"], @"email", nil];
            NSString *firstChar;

            firstChar = [[firstname substringToIndex:1] uppercaseString];
            [contacts[firstChar] addObject:dict];
        }

        sectionTitles = [[NSMutableArray alloc] initWithCapacity:26];
        for (int i = 0; i < 26; i++)
        {
            NSString *key = [NSString stringWithFormat:@"%c", 'A'+i];
            if ([contacts[key] count])
                [sectionTitles addObject:key];
        }
        [contactsTableView reloadData];
        
        if ([dict objectForKey:@"moreContacts"]) {
            /*UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Only 250 contacts have been fetched. To fetch all your contacts, please upgrade to Paid version."
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            [alertView show];*/
        }
        [delegate hideActivityIndicator];

    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Contacts couldn't be fetched."
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        [delegate hideActivityIndicator];

    };
    
    if ([source isEqualToString:@"Salesforce"]) {
        [endpoint getSalesforceContacts];
    } else if ([source isEqualToString:@"Google"]) {
        [endpoint getGoogleContacts];
    } else if ([source isEqualToString:@"Zoho"]) {
        [endpoint getZohoContacts];
    }
}

- (void)uploadContacts
{
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                                 sharedInstanceWithClientProtocol:
                                 @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                                         id responseJSON){
        
        //Account *account = [Account sharedInstance];
        //account.deviceContactsImported = YES;
        
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Selected contacts have been imported."
                                  delegate:self cancelButtonTitle:@"Ok"
                                  otherButtonTitles:nil];
        [alertView show];
        
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                                         id responseJSON){
        
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Unable to import contacts."
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    };
    
    [endpoint addContacts:selectedContacts];

}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex)
    {
        AppDelegate *appdelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

        if (!appdelegate.tabBarController) {
            // first time import
            UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Tabs" bundle:nil];
            appdelegate.tabBarController = [storyBoard instantiateInitialViewController];
            appdelegate.tabBarController.selectedIndex = CONTACTS_TAB_INDEX;
            [self.view.window setRootViewController:appdelegate.tabBarController];
        } else {
            [self.view.window setRootViewController:appdelegate.tabBarController];
            
            /*
//            UINavigationController *navCtlr = (UINavigationController *)appdelegate.tabBarController.selectedViewController;
            UINavigationController *navCtlr = appdelegate.tabBarController.viewControllers[1];
            appdelegate.tabBarController.selectedIndex = CONTACTS_TAB_INDEX;
//            GroupsContactsViewController *groupsCtlr = (GroupsContactsViewController *)navCtlr.topViewController;
            GroupsContactsViewController *groupsCtlr = (GroupsContactsViewController *)navCtlr.childViewControllers[0];
            [groupsCtlr getAllContacts];
            */
            
            UINavigationController *navCtlr = appdelegate.tabBarController.viewControllers[1];
            appdelegate.tabBarController.selectedIndex = CONTACTS_TAB_INDEX;
            if (navCtlr.childViewControllers.count > 1) {
                NSMutableArray *navigationArray = [[NSMutableArray alloc] initWithArray: navCtlr.viewControllers];
                
                [navigationArray removeObjectAtIndex:1];  // You can pass your index here
                navCtlr.viewControllers = navigationArray;
            }
            GroupsContactsViewController *groupsCtlr = (GroupsContactsViewController *)navCtlr.childViewControllers[0];
            [groupsCtlr getAllContacts];
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UITableView
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.searchContactsTableView) {
        return 1;
    }
    return [sectionTitles count];
}

- (NSString *)tableView:(UITableView *)sender titleForHeaderInSection:(NSInteger)sectionIndex
{
    if (sender == self.searchContactsTableView) {
        return @"";
    }
    return sectionTitles[sectionIndex];
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
    return [contacts[sectionTitles[sectionIndex]] count];
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (tableView == self.searchContactsTableView) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"searchContactsCell"];
        if (cell == nil) {
            
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"searchContactsCell"];
        }
        NSDictionary *contact = searchResults[indexPath.row];
        NSString *first = [contact objectForKey:@"first_name"];
        NSString *last = [contact objectForKey:@"last_name"];

        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", first, last];
        cell.detailTextLabel.text = [contact objectForKey:@"email"];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"contactsCell"];
        UILabel *nameLbl = (UILabel *)[cell viewWithTag:100];
        UILabel *emailLbl = (UILabel *)[cell viewWithTag:200];
        NSDictionary *dict;
        
        NSString *key = sectionTitles[indexPath.section];
        dict = [contacts[key] objectAtIndex:indexPath.row];
        NSString *name = [NSString stringWithFormat:@"%@ %@", [dict objectForKey:@"first_name"], [dict objectForKey:@"last_name"]];
        [nameLbl setText:name];
        [emailLbl setText:[dict objectForKey:@"email"]];
        
        if (selectAll) {
            [contactsTableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
//            [selectedContacts addObject:dict];
        } else {
//            [selectedContacts removeObject:dict];
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
    return [sectionTitles indexOfObject:title];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchContactsTableView) {
        selectedBuddy = searchResults[indexPath.row];
        [self.searchContactsTableView setHidden: YES];
        [self.searchBar setText:@""];
        [self.searchBar resignFirstResponder];
        
        sectionValue = 0;
        
        stopLoop = NO;
        for(NSString *key in sectionTitles)
        {
            rowValue = 0;
            for(Buddy *userBuddy in contacts[key])
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
        [contactsTableView scrollToRowAtIndexPath:indexPath
                                 atScrollPosition:UITableViewScrollPositionTop
                                         animated:YES];
    } else {
        NSDictionary *dict;
      
        NSString *key = sectionTitles[indexPath.section];
        dict = [contacts[key] objectAtIndex:indexPath.row];
        [selectedContacts addObject:dict];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchContactsTableView) {
        
    } else {
        NSDictionary *dict;
        
        NSString *key = sectionTitles[indexPath.section];
        dict = [contacts[key] objectAtIndex:indexPath.row];
        [selectedContacts removeObject:dict];
    }
}

- (IBAction)backAction:(id)sender {
    [selectedContacts removeAllObjects];
    [self.navigationController popViewControllerAnimated:YES];
}

//- (IBAction)importAction:(id)sender {
- (void)importAction {
    //self.tabBarController.tabBar.hidden = NO;
    //[UIView animateWithDuration:0.5 animations:^(void) {
    //    self.view.alpha = 0.5;
    //}];
    
    if (selectedContacts.count == 0) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Please select the contacts to import.."
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }

    // call upload contacts API
    [self uploadContacts];
}

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

- (void)searchAutocompleteEntriesWithSubstring:(NSString *)substring
{
    
    if (![substring hasSuffix:@"\n"] && ![substring isEqualToString:@""]) {
        
        [searchResults removeAllObjects];
        for(NSString *key in sectionTitles)
        {
            for(NSDictionary *contact in contacts[key])
            {
                NSString *first = [contact objectForKey:@"first_name"];
                NSString *last = [contact objectForKey:@"last_name"];
                NSString *name = [NSString stringWithFormat:@"%@ %@", first, last];
                if (nil != first && nil != last && nil != name && first != [NSNull null] && last != [NSNull null] && name != [NSNull null]) {
                    NSRange firstNameRange = [first rangeOfString:substring options:NSCaseInsensitiveSearch];
                    NSRange lastNameRange = [last rangeOfString:substring options:NSCaseInsensitiveSearch];
                    NSRange nameRange = [name rangeOfString:substring options:NSCaseInsensitiveSearch];
                    if (firstNameRange.location == 0 || lastNameRange.location == 0 || nameRange.location == 0)
                    {
                        [searchResults addObject:contact];
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
