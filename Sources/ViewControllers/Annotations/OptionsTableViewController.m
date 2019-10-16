//
//  OptionsTableViewController.m
//  Liri
//
//  Created by Shankar Arunachalam on 7/5/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "OptionsTableViewController.h"
#import "AnnotationsViewController.h"
#import "APIClient.h"
#import "AppConstants.h"
#import "Account.h"
#import "Flurry.h"

@interface OptionsTableViewController ()

@property (strong, nonatomic) IBOutlet UITableView *optionTableView;
@end

@implementation OptionsTableViewController
@synthesize optionTableView = _optionTableView;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [Flurry logEvent:@"Annotation Options Screen"];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidLayoutSubviews
{
    if(IS_IPHONE_5) {
        //do stuff for 4 inch iPhone screen
    }
    else {
        [self.optionTableView setFrame:CGRectMake(self.optionTableView.frame.origin.x, self.optionTableView.frame.origin.y, self.optionTableView.frame.size.width, 357)];
        
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 8;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.row) {
        case 0:
            [self showAnnotationViewWithImage:nil];
            break;
        case 1:
            [self showFolderBrowserRoot:@"Box"];
            break;
        case 2:
            [self showFolderBrowserRoot:@"Dropbox"];
            break;
        case 3:
            [self showFolderBrowserRoot:@"Google"];
            break;
        case 4:
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kFavoritesRequestedNotification
             object:self userInfo:nil];
            break;
        case 5:
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kBrowserRequestedNotification
             object:self userInfo:nil];
            break;
        case 6:
            [self showCamera];
            break;
        case 7:
            [self showGallery];
            break;
        default:
            break;
    }
}

- (void) showCamera {
    UIImagePickerController *cameraPicker = [[UIImagePickerController alloc] init];
    cameraPicker.delegate = self;
    cameraPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:cameraPicker animated:YES completion:nil];
}

- (void) showGallery {
    UIImagePickerController *pickerController = [[UIImagePickerController alloc]
                                                 init];
    pickerController.delegate = self;
    [self presentViewController:pickerController animated:YES completion:nil];
}

- (void) showFolderBrowserRoot: (NSString *) externalSystem {
    Account *account = [Account sharedInstance];
    if((account.box_auth && [externalSystem isEqualToString:@"Box"])
       || (account.dropbox_auth && [externalSystem isEqualToString:@"Dropbox"])
       || (account.google_auth && [externalSystem isEqualToString:@"Google"])) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kAuthenticationCompletedNotification
         object:self userInfo:@{@"externalSystem": externalSystem}];
    } else {
        AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [delegate showActivityIndicator];
        
        // do create
        id<APIAccessClient> endpoint =
        (id<APIAccessClient>)[[APIManager
                                     sharedInstanceWithClientProtocol:
                                     @protocol(APIAccessClient)] client];
        
        endpoint.success = ^(NSURLRequest *request,
                             id response){
            [delegate hideActivityIndicator];
            
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kExternalAuthenticationSelectedNotification
             object:self userInfo:@{@"contentToLoad": response, @"externalSystem": externalSystem}];
        };
        endpoint.failure = ^(NSURLRequest *request,
                             id response){
            [delegate hideActivityIndicator];
            UIAlertView *failureAlert = [[UIAlertView alloc]
                                         initWithTitle:@""
                                         message:[response objectForKey:@"error"]
                                         delegate:self cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil];
            [failureAlert setTag:KFailureAlertTag];
            [failureAlert show];
            
            NSLog(@"error message %@ and json %@", [response objectForKey:@"error"], response);
        };
        [endpoint getClientAuth];
    }
}

- (void) showAnnotationViewWithImage: (UIImage *) image {
    if(image != nil) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kAnnotationOptionSelectedNotification
         object:self userInfo:@{@"pickedImage": image}];
    } else {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kAnnotationOptionSelectedNotification
         object:self userInfo:nil];
    }
}

-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [[picker presentingViewController] dismissViewControllerAnimated:YES completion:^() {
        UIImage* pickedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        [self showAnnotationViewWithImage:pickedImage];
    }];
}

#pragma mark UIImagePickerControllerDelegate

- (void) imagePickerController:(UIImagePickerController *)picker
         didFinishPickingImage:(UIImage *)image
                   editingInfo:(NSDictionary *)editingInfo
{
    //    self.imageView.image = image;
    [self dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}
/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: {
 forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

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
