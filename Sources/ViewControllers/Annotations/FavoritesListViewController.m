//
//  FavoritesListViewController.m
//  Liri
//
//  Created by Shankar Arunachalam on 9/3/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "FavoritesListViewController.h"
#import "AppDelegate.h"
#import "APIClient.h"
#import "BrowserController.h"
#import "Flurry.h"

@interface FavoritesListViewController ()
@property (weak, nonatomic) IBOutlet UIView *favoritesListView;

@end

@implementation FavoritesListViewController
@synthesize dataTable, data;
@synthesize favoritesListView = _favoritesListView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [Flurry logEvent:@"Favorites List Screen"];
    dataTable.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    if(IS_IPHONE_5) {
        //do stuff for 4 inch iPhone screen
    }
    else {
        [self.dataTable setFrame:CGRectMake(self.dataTable.frame.origin.x, self.dataTable.frame.origin.y, self.dataTable.frame.size.width, 396)];
    }
    [UIView animateWithDuration:0.3 animations:^(void) {
        self.view.alpha = 1.0;
    }];
    data = [[NSMutableArray alloc] init];
    [self getBookmarks];
}

- (void)viewDidLayoutSubviews
{
    if(IS_IPHONE_5) {
        //do stuff for 4 inch iPhone screen
    }
    else {
        [self.favoritesListView setFrame:CGRectMake(self.favoritesListView.frame.origin.x, self.favoritesListView.frame.origin.y, self.favoritesListView.frame.size.width, 440)];

    }
}

- (IBAction)backAction:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:^{
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kBrowsingCompletedNotification
         object:self userInfo:nil];
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    return [data count];
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"fileFolderCell"];
    UILabel *lblName = (UILabel *)[cell viewWithTag:100];
    NSDictionary *bookmark = data[indexPath.row];
    lblName.text = [bookmark objectForKey:@"name"];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView: (UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *bookmark = data[indexPath.row];
    
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    rootViewController.modalPresentationStyle = UIModalPresentationNone;

    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    BrowserController *browserController =
    [storyBoard instantiateViewControllerWithIdentifier:@"BrowserController"];
    browserController.path = [bookmark objectForKey:@"url"];
    browserController.isFromFavorites = true;
    
    [self presentViewController:browserController animated:YES completion:nil];

}

- (void) getBookmarks {
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
        if([responseJSON objectForKey:@"bookmarks"] != nil && [[responseJSON objectForKey:@"bookmarks"] objectForKey:@"data"] != nil) {
            NSDictionary *bookmarkData = [[responseJSON objectForKey:@"bookmarks"] objectForKey:@"data"];
            for (NSString* key in bookmarkData) {
                NSDictionary *bookmark = [bookmarkData objectForKey:key];
                [data addObject:bookmark];
            }
            [dataTable reloadData];
        }
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
        UIAlertView *failureAlert = [[UIAlertView alloc]
                                     initWithTitle:@""
                                     message:[responseJSON objectForKey:@"error"]
                                     delegate:self cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil];
        [failureAlert setTag:KFailureAlertTag];
        [failureAlert show];
        
        NSLog(@"error message %@ and json %@", [responseJSON objectForKey:@"error"], responseJSON);
    };
    [endpoint getBookmarks];
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
