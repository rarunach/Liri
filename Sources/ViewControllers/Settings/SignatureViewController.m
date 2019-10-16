//
//  SignatureViewController.m
//  Liri
//
//  Created by Varun Sankar on 02/09/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "SignatureViewController.h"
#import "Flurry.h"
#import "Account.h"

@interface SignatureViewController ()

@property (weak, nonatomic) IBOutlet UITextView *signatureTxtView;
- (IBAction)cancelBtnAction:(id)sender;
- (IBAction)doneBtnAction:(id)sender;
@end

@implementation SignatureViewController

@synthesize signatureTxtView = _signatureTxtView;

//@synthesize signature = _signature;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - UIView LifeCycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [Flurry logEvent:@"Signature Screen"];
    self.signatureTxtView.layer.borderColor = DEFAULT_CGCOLOR;
    
    [self getSignature];
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

#pragma mark - Private Methods
- (void)getSignature
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        NSString *liriSignature;
        if ([responseJSON[@"message"] isEqualToString:@"success"]) {
            NSLog(@"%@", responseJSON[@"signature"]);
            
            liriSignature = responseJSON[@"signature"];
        } else {
            //default signature
            Account *account = [Account sharedInstance];
            
            liriSignature = [NSString stringWithFormat:@"Sent from Liri\n%@ %@", account.firstName, account.lastName];
        }
        [self.signatureTxtView setText:liriSignature];

        [delegate hideActivityIndicator];
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        
        [delegate hideActivityIndicator];
    };
    
    [endpoint getSignature];
}

- (void)updateSignature
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    // do create
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                         id responseJSON){
        
        [delegate hideActivityIndicator];

        [self dismissViewControllerAnimated:YES completion:nil];
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                         id responseJSON){
        
        [delegate hideActivityIndicator];
        
        NSLog(@"error message %@ and json %@", responseJSON[@"error"], responseJSON);
    };
    
    [endpoint updateSignature:self.signatureTxtView.text];
    
}

#pragma mark - IBAction Methods
- (IBAction)cancelBtnAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)doneBtnAction:(id)sender {
    [self updateSignature];
    
}
@end
