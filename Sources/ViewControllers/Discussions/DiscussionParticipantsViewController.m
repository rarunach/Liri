//
//  DiscussionMemberViewController.m
//  Liri
//
//  Created by Varun Sankar on 17/11/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "DiscussionParticipantsViewController.h"
#import "Account.h"

@interface DiscussionParticipantsViewController ()
{
    NSMutableArray *discussionMembers, *groupMembers, *finalMemberList;
    NSMutableArray *myContacts;
    NSArray *searchResults;
    NSArray *groupList;
    NSString *discussionTitle;
}
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@end

@implementation DiscussionParticipantsViewController
@synthesize discussionId = _discussionId;
@synthesize searchBar = _searchBar;
@synthesize discussion;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self getDiscussionDetails:self.discussionId];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private Methods
- (void)getDiscussionDetails:(NSString *)discussionId
 {
     AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
     [delegate showActivityIndicator];
     
     id<APIAccessClient> endpoint =
     (id<APIAccessClient>)[[APIManager
                            sharedInstanceWithClientProtocol:
                            @protocol(APIAccessClient)] client];
     
     endpoint.successJSON = ^(NSURLRequest *request,
                              id responseJSON){
         NSDictionary *responseDict = (NSDictionary *)responseJSON;
         
         NSDictionary *infoDict = [responseDict objectForKey:@"discussion_info"];
         
         Account *account = [Account sharedInstance];
         if (![infoDict[@"owner"] isEqualToString:account.mybuddy.email]) {
             self.navigationItem.rightBarButtonItem = nil;
             [self.searchBar setHidden:YES];
         }
         
         discussionTitle = infoDict[@"title"];
         groupList = infoDict[@"groups"];
         
         NSMutableArray *allMembers = [[NSMutableArray alloc] init];
         
         for (NSString *email in infoDict[@"allmembers"]) {
             Buddy *buddy = [account.buddyList findBuddyForEmail:email];
             if (buddy != nil) {
                 [allMembers addObject:buddy];
             } else {
                 [allMembers addObject:email];
             }
         }
         
         discussionMembers = [[NSMutableArray alloc] init];
         
         for (NSString *email in infoDict[@"members"]) {
             Buddy *buddy = [account.buddyList findBuddyForEmail:email];
             if (buddy != nil) {
                 [discussionMembers addObject:buddy];
             } else {
                 [discussionMembers addObject:email];
             }
         }
         
         NSMutableSet* set1 = [NSMutableSet setWithArray:allMembers];
         NSMutableSet* set2 = [NSMutableSet setWithArray:discussionMembers];
         [set1 minusSet:set2];
         
         groupMembers = (NSMutableArray *)[set1 allObjects];
         
         [self getAllContacts];
         [self.tableView reloadData];
         
         [delegate hideActivityIndicator];
     };
     endpoint.failureJSON = ^(NSURLRequest *request,
                              id responseJSON){
         [delegate hideActivityIndicator];
     };
     
     [endpoint getDiscussion:discussionId];
 }

- (void)updateDiscussion
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        
        [delegate hideActivityIndicator];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success" message:responseJSON[@"message"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        alertView.tag = 2;
        [alertView show];
        
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Failure" message:responseJSON[@"error"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        alertView.tag = 2;
        [alertView show];
    };
    
    [endpoint updateDiscussionWithID:self.discussionId title:discussionTitle members:finalMemberList groups:groupList is1on1:@"false"];
}

- (void)getAllContacts
{
    Account *account = [Account sharedInstance];
    myContacts = [account.buddyList.allBuddies mutableCopy];
    
    for (Buddy *buddy in discussionMembers) {
        if ([myContacts containsObject:buddy]) {
            [myContacts removeObject:buddy];
        }
    }
    
    for (Buddy *myBuddy in myContacts) {
        if ([myBuddy.email isEqualToString:account.mybuddy.email]) {
            [myContacts removeObject:myBuddy];
            break;
        }
    }
    
}
#pragma mark - IBAction Methods
- (IBAction)doneAction:(id)sender {
    NSMutableArray *allEmails = [NSMutableArray array];
    finalMemberList = [NSMutableArray array];
    for (Buddy *buddy in groupMembers) {
        if (![buddy isKindOfClass:[NSString class]]) {
            [allEmails addObject:buddy.email];
        } else {
            [allEmails addObject:buddy];
        }
    }

    for (Buddy *buddy in discussionMembers) {
        if (![buddy isKindOfClass:[NSString class]]) {
            [finalMemberList addObject:buddy.email];
        } else {
            [finalMemberList addObject:buddy];
        }
    }

    [allEmails addObjectsFromArray:finalMemberList];
    
    [self updateToXmpp:allEmails];
    [self updateDiscussion];
    /*
    if (discussionMembers.count == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"You have deleted all members in the discussion. Do you want to continue?" delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"Continue", nil];
        alertView.tag = 1;
        [alertView show];
    } else {
        
    }*/
}

-(void)updateToXmpp:(NSMutableArray *)allEmails {
    [discussion updateDiscussionMembers:allEmails];
}

#pragma mark - UIAlertView Delegate Methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1 && buttonIndex == 1) {
        [self updateDiscussion];
    } else if (alertView.tag == 2) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}
#pragma mark - UITableView DataSource Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return 1;
    }
    return 2;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return searchResults.count;
    } else {
        if (sectionIndex == 0) {
            return discussionMembers.count;
        } else {
            return groupMembers.count;
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return @"My Contacts";
    } else {
        if(section == 0) {
            if (discussionMembers.count == 0) {
                return @"";
            }
            return @"Participants";
        } else {
            if (groupMembers.count == 0 ) {
                return @"";
            }
            return @"Participants from groups";
        }
    }
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    static NSString *memberTableIdentifier = @"membersTableCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:memberTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:memberTableIdentifier];
    }
    Buddy *buddy;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        buddy = [searchResults objectAtIndex:indexPath.row];
        cell.textLabel.text = buddy.displayName;
        cell.detailTextLabel.text = buddy.email;
    } else {
        if (indexPath.section == 0) {
            buddy = discussionMembers[indexPath.row];
            if (![buddy isKindOfClass:[NSString class]]) {
                cell.textLabel.text = buddy.displayName;
                cell.detailTextLabel.text = buddy.email;
            } else {
                cell.textLabel.text = discussionMembers[indexPath.row];
            }
        } else {
            buddy = groupMembers[indexPath.row];
            if (![buddy isKindOfClass:[NSString class]]) {
                cell.textLabel.text = buddy.displayName;
                cell.detailTextLabel.text = buddy.email;
            } else {
                cell.textLabel.text = groupMembers[indexPath.row];
            }
        }
    }
    return cell;
}

#pragma mark - UITableView Delegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        Buddy *selectedBuddy = searchResults[indexPath.row];
//        [discussionMembers insertObject:selectedBuddy atIndex:0];
        [discussionMembers addObject:selectedBuddy];
        [self.searchDisplayController setActive:NO animated:YES];
        [self.tableView reloadData];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return NO;
    } else {
        if (indexPath.section == 0) {
            if (!self.searchBar.isHidden) {
                return YES;
            }
        }
    }*/
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [discussionMembers removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - UISearchDisplayController Delegate Methods
-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                      objectAtIndex:[self.searchDisplayController.searchBar
                                                     selectedScopeButtonIndex]]];
    
    return YES;
}


- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"displayName contains[c] %@", searchText];
    searchResults = [myContacts filteredArrayUsingPredicate:resultPredicate];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
