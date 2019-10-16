//
//  FolderBrowserController.m
//  Liri
//
//  Created by Shankar Arunachalam on 7/29/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "FolderBrowserController.h"
#import "Account.h"
#import "DiscussionViewController.h"
#import "FileFolderMetadata.h"
#import "AppConstants.h"
#import "WebPreviewController.h"
#import "AnnotationOptionsViewController.h"
#import "Flurry.h"

@interface FolderBrowserController ()

@property (weak, nonatomic) IBOutlet UIView *folderBrowserView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewHeightConstraint;
@end

@implementation FolderBrowserController

@synthesize navTitle, externalSystem, searchBar, data, dataTable, cache, breadcrumbs, backCrumb, searchString;
@synthesize folderBrowserView = _folderBrowserView;

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
    [Flurry logEvent:@"Folder Browser Screen"];
    cache = [[NSMutableDictionary alloc] init];
    breadcrumbs = [[NSMutableArray alloc] init];
    backCrumb = -2;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenCaptured:) name:kScreenCapturedNotification object:nil];
}


- (void)adjustHeightOfTableview
{
    CGFloat height = self.dataTable.contentSize.height;
    CGFloat maxHeight = self.dataTable.superview.frame.size.height - self.dataTable.frame.origin.y;
    
    // if the height of the content is greater than the maxHeight of
    // total space on the screen, limit the height to the size of the
    // superview.
    
    if (height > maxHeight)
        height = maxHeight;
    
    // now set the height constraint accordingly
    
    [UIView animateWithDuration:0.25 animations:^{
        self.tableViewHeightConstraint.constant = height;
        [self.view needsUpdateConstraints];
    }];
}

- (void)viewDidLayoutSubviews
{
    if(!IS_IPHONE_5) {
        //do stuff for 3.5 inch iPhone screen
        [self.folderBrowserView setFrame:CGRectMake(self.folderBrowserView.frame.origin.x, self.folderBrowserView.frame.origin.y, self.folderBrowserView.frame.size.width, 440)];
        [self.dataTable reloadData];
        [self adjustHeightOfTableview];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    if(self.data == nil) {
        [self browseTo:@"" withBack:false andSource:externalSystem];
    }    
    if([externalSystem isEqualToString:@"Search results"]) {
        searchBar.text = searchString;
    }
}

- (IBAction)backAction:(id)sender
{
    [breadcrumbs pop];
    if(backCrumb >= 0) {
        NSString *previousPath = breadcrumbs[backCrumb];
        backCrumb--;
        [self browseTo:previousPath withBack:true andSource:externalSystem];
    } else {
        [self dismissViewControllerAnimated:NO completion:^{
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kBrowsingCompletedNotification
             object:self userInfo:@{@"externalSystem": self.externalSystem}];
        }];
    }
}

- (void)screenCaptured:(NSNotification*)aNotification
{
    [self dismissViewControllerAnimated:NO completion:^{
        NSDictionary* info = [aNotification userInfo];
        if(info != nil) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kAnnotationOptionSelectedNotification
             object:self userInfo:@{@"pickedImage": [info objectForKey:@"capturedImage"]}];
        } else {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kAnnotationOptionSelectedNotification
             object:self userInfo:nil];
        }
    }];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)thisSearchBar {
    NSLog(@"User searched for %@", thisSearchBar.text);
    [thisSearchBar resignFirstResponder];
    searchString = thisSearchBar.text;
    [self doSearch:thisSearchBar.text];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)thisSearchBar {
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) thisSearchBar {
    NSLog(@"User canceled search");
    [thisSearchBar resignFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    UIImageView *lblImage = (UIImageView *)[cell viewWithTag:101];
    UILabel *lblDate = (UILabel *)[cell viewWithTag:102];
    lblName.text = [data[indexPath.row] name];
    lblDate.text = [self relativeDateStringForDate:[data[indexPath.row] lastModifiedTime]];
    FileFolderMetadata *metadata = (FileFolderMetadata *)data[indexPath.row];

    if([externalSystem isEqualToString:@"Search results"]) {
        if([metadata.source isEqualToString:@"Google"]) {
            lblImage.image = [UIImage imageNamed:@"Google-Drive-icon.png"];
        } else if([metadata.source isEqualToString:@"Dropbox"]) {
            lblImage.image = [UIImage imageNamed:@"Dropbox-icon.png"];
        } else if([metadata.source isEqualToString:@"Box"]) {
            lblImage.image = [UIImage imageNamed:@"Box-Icon.png"];
        }
    } else if([metadata.type isEqualToString:@"folder"]) {
        lblImage.image = [UIImage imageNamed:@"Folder-Icon@2x.png"];
    } else {
        lblImage.image = [UIImage imageNamed:@"File-Icon@2x.png"];
    }
    
    if([metadata.type isEqualToString:@"folder"]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (NSString *)relativeDateStringForDate:(NSDate *)date
{
    if(date == nil) {
        return @"";
    }
    NSCalendarUnit units = NSDayCalendarUnit | NSWeekOfYearCalendarUnit |
    NSMonthCalendarUnit | NSYearCalendarUnit;
    
    // if `date` is before "now" (i.e. in the past) then the components will be positive
    NSDateComponents *components = [[NSCalendar currentCalendar] components:units
                                                                   fromDate:date
                                                                     toDate:[NSDate date]
                                                                    options:0];
    if (components.year > 0) {
        return [NSString stringWithFormat:@"%ld %@ ago", (long)components.year,
                (long)components.year > 1 ? @"years" : @"year"];
    } else if (components.month > 0) {
        return [NSString stringWithFormat:@"%ld %@ ago", (long)components.month,
                (long)components.month > 1 ? @"months" : @"month"];
    } else if (components.weekOfYear > 0) {
        return [NSString stringWithFormat:@"%ld %@ ago", (long)components.weekOfYear,
                (long)components.weekOfYear > 1 ? @"weeks" : @"week"];
    } else if (components.day > 0) {
        if (components.day > 1) {
            return [NSString stringWithFormat:@"%ld %@ ago", (long)components.day,
                    (long)components.day > 1 ? @"days" : @"day"];
        } else {
            return @"Yesterday";
        }
    } else {
        return @"Today";
    }
}

- (void)tableView: (UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FileFolderMetadata *metadata = (FileFolderMetadata *)data[indexPath.row];
    if([metadata.type isEqualToString:@"folder"]) {
        [self browseTo:metadata.id withBack:false andSource:metadata.source];
    } else {
        [self fetchAndShowContents:metadata];
    }
}

- (void) adjustCrumbs:(NSString *)path_id withBack:(BOOL)isBack {
    if(!isBack) {
        [breadcrumbs push:path_id];
        backCrumb++;
    }
}

- (void) browseTo: (NSString *)path_id withBack:(BOOL)isBack andSource:(NSString *)source {
    NSMutableArray *cachedData = [cache objectForKey:path_id];
    if(cachedData != nil) {
        [self adjustCrumbs:path_id withBack:isBack];
        self.data = cachedData;
        
        [self.dataTable reloadData];
        if(!IS_IPHONE_5) {
            [self adjustHeightOfTableview];
        }
        return;
    }
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                                 sharedInstanceWithClientProtocol:
                                 @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
        self.data = [FileFolderMetadata getFileFolderMetadata:responseJSON forCloudSearch:false];
        [self adjustCrumbs:path_id withBack:isBack];
        [cache setObject:self.data forKey:path_id];
        [self.dataTable reloadData];
        if(!IS_IPHONE_5) {
            [self adjustHeightOfTableview];
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
    [endpoint browse:source withRoot:path_id andType:@"folder"];
}

- (void) fetchAndShowContents: (FileFolderMetadata *)metadata {
    if([metadata.source isEqualToString:@"Box"]) {
        NSString *url = [NSString stringWithFormat:@"%@%@/content", BOX_FILES_BASE_URL, metadata.id];
        [self fetchFile:url withToken:metadata.token andName:metadata.name];
    } else if([metadata.source isEqualToString:@"Dropbox"]) {
        NSString *url = [NSString stringWithFormat:@"%@%@", DROPBOX_FILES_BASE_URL, metadata.id];
        [self fetchFile:url withToken:metadata.token andName:metadata.name];
    } else if([metadata.source isEqualToString:@"Google"]) {
        [self fetchDownloadUrlFromGoogle:metadata.token withFile:metadata.id andName:metadata.name];
    }
}

- (void) doSearch:(NSString *)query {
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                                 sharedInstanceWithClientProtocol:
                                 @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
        
        self.data = [FileFolderMetadata getFileFolderMetadata:responseJSON
                                               forCloudSearch:[externalSystem isEqualToString:@"Search results"] ? true: false];
        [self.dataTable reloadData];
        if(!IS_IPHONE_5) {
            [self adjustHeightOfTableview];
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
    if([externalSystem isEqualToString:@"Box"]) {
        [endpoint boxSearch:query];
    } else if([externalSystem isEqualToString:@"Dropbox"]) {
        [endpoint dropboxSearch:query];
    } else if([externalSystem isEqualToString:@"Google"]) {
        [endpoint gdriveSearch:query];
    } else if([externalSystem isEqualToString:@"Search results"]) {
        [endpoint cloudSearch:query];
    }
}

- (void) fetchFile: (NSString *)url
         withToken:(NSString *)accessToken
         andName:(NSString *)name
{
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    WebPreviewController *webPreviewController = [storyBoard instantiateViewControllerWithIdentifier:@"WebPreviewController"];
    webPreviewController.path = url;
    webPreviewController.token = accessToken;
    webPreviewController.name = name;
    webPreviewController.source = externalSystem;
    [self presentViewController:webPreviewController animated:YES completion:nil];
}

- (void) fetchDownloadUrlFromGoogle: (NSString *)accessToken withFile:(NSString *)file_id andName:(NSString *)name {
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                                 sharedInstanceWithClientProtocol:
                                 @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
        NSString *downloadUrl = [responseJSON objectForKey:@"downloadUrl"];
        NSString *embedLink = [[responseJSON objectForKey:@"exportLinks"] objectForKey:@"application/pdf"];
        if(downloadUrl != nil && ![downloadUrl isEqualToString:@""]) {
            [self fetchFile:[responseJSON objectForKey:@"downloadUrl"] withToken:accessToken andName:name];
        } else if(embedLink != nil && ![embedLink isEqualToString:@""]) {
            [self fetchFile:[[responseJSON objectForKey:@"exportLinks"] objectForKey:@"application/pdf"] withToken:accessToken andName:name];
        } else {
            UIAlertView *failureAlert = [[UIAlertView alloc]
                                         initWithTitle:@""
                                         message:@"File could not be fetched. Please try again or check the source for any issues."
                                         delegate:self cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil];
            [failureAlert setTag:KFailureAlertTag];
            [failureAlert show];
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
    [endpoint fetchDownloadUrlFromGoogle:accessToken withFile:file_id];
}

@end
