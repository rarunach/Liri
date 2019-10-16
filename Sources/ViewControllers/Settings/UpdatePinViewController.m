//
//  UpdatePinViewController.m
//  Liri
//
//  Created by Varun Sankar on 02/09/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "UpdatePinViewController.h"
#import "Account.h"
#import "Flurry.h"

@interface UpdatePinViewController ()

- (IBAction)backBtnAction:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *oldPinField;

@property (weak, nonatomic) IBOutlet UITextField *theNewPinField;

@property (weak, nonatomic) IBOutlet UITextField *confirmPinField;

- (IBAction)submitBtnAction:(id)sender;

@end

@implementation UpdatePinViewController

@synthesize oldPinField = _oldPinField, theNewPinField = _theNewPinField, confirmPinField = _confirmPinField;

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
    [Flurry logEvent:@"Update Pin Screen"];
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
#pragma mark - Private Method
- (void)updatePin
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
        
        NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        NSNumber *newpin = [f numberFromString:self.theNewPinField.text];

        Account *account = [Account sharedInstance];
        account.password = newpin;
        
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        [standardUserDefaults setObject:account.password forKey:@"USERPASS"];
        [standardUserDefaults synchronize];
        
        [delegate hideActivityIndicator];
        [self dismissViewControllerAnimated:YES completion:nil];

    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
        NSLog(@"error message %@ and json %@", responseJSON[@"error"], responseJSON);
    };
    
//    [endpoint updatePin:self.oldPinField.text andNewPin:self.theNewPinField.text];
}

#pragma mark - IBAction Methods
- (IBAction)backBtnAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)submitBtnAction:(id)sender {
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *newpin = [f numberFromString:self.theNewPinField.text];
    NSNumber *confirmPin = [f numberFromString:self.confirmPinField.text];
    
    if ([self.oldPinField.text isEqualToString:@""] || [self.theNewPinField.text isEqualToString:@""] || [self.confirmPinField.text isEqualToString:@""]) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"PIN values should not be empty"
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    } else if (![newpin isEqualToNumber:confirmPin]) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"PIN values don't match"
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        
    } else {
        [self updatePin];
    }
}
@end
