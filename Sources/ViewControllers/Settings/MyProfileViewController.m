//
//  MyProfileViewController.m
//  Liri
//
//  Created by Varun Sankar on 25/08/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "MyProfileViewController.h"
#import "Account.h"
#import "Flurry.h"
#import "AddPhotoViewController.h"

@interface MyProfileViewController ()
{
//    NSString *signature;
}
@property (weak, nonatomic) IBOutlet UIImageView *userImgView;

@property (weak, nonatomic) IBOutlet UIView *fNameBgView;
@property (weak, nonatomic) IBOutlet UITextField *fNameTextField;

@property (weak, nonatomic) IBOutlet UIView *lNameBgView;
@property (weak, nonatomic) IBOutlet UITextField *lNameTextField;

@property (weak, nonatomic) IBOutlet UIView *jobTitleBgView;
@property (weak, nonatomic) IBOutlet UITextField *jobTitleTextField;

@property (weak, nonatomic) IBOutlet UIView *emailBgView;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;

@property (weak, nonatomic) IBOutlet UIView *mobileNoBgView;
@property (weak, nonatomic) IBOutlet UITextField *mobileNoTextField;

@property (weak, nonatomic) IBOutlet UIView *signatureBgView;
@property (weak, nonatomic) IBOutlet UIButton *signatureBtn;

@property (weak, nonatomic) IBOutlet UIView *contactsBgView;
@property (weak, nonatomic) IBOutlet UISwitch *companyContactSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *externalContactSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *allContactSwitch;

@property (weak, nonatomic) IBOutlet UIView *calendarBgView;
@property (weak, nonatomic) IBOutlet UIButton *calendarBtn;

@property (weak, nonatomic) IBOutlet UIButton *updatePinBtn;


- (IBAction)signatureBtnAction:(id)sender;
- (IBAction)calendarBtnAction:(id)sender;

@end

@implementation MyProfileViewController

@synthesize userImgView = _userImgView;

@synthesize fNameBgView = _fNameBgView, lNameBgView = _lNameBgView, jobTitleBgView = _jobTitleBgView, mobileNoBgView = _mobileNoBgView, signatureBgView = _signatureBgView, contactsBgView = _contactsBgView, calendarBgView = _calendarBgView;

@synthesize fNameTextField = _fNameTextField, lNameTextField = _lNameTextField, jobTitleTextField = _jobTitleTextField, emailLabel = _emailLabel, mobileNoTextField = _mobileNoTextField;

@synthesize  updatePinBtn = _updatePinBtn;

@synthesize companyContactSwitch = _companyContactSwitch, externalContactSwitch = _externalContactSwitch, allContactSwitch = _allContactSwitch;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - UIView Life Cycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lightBoxFinished:) name:kLightBoxFinishedNotification object:nil];
    
    [Flurry logEvent:@"My Profile Screen"];
    [self.userImgView setUserInteractionEnabled:YES];
    self.userImgView.layer.cornerRadius = self.userImgView.frame.size.width/2;
    self.userImgView.clipsToBounds = YES;
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
    [self.userImgView addGestureRecognizer:gesture];
    
    self.fNameBgView.layer.borderColor = DEFAULT_CGCOLOR;
    self.lNameBgView.layer.borderColor = DEFAULT_CGCOLOR;
    self.jobTitleBgView.layer.borderColor = DEFAULT_CGCOLOR;
    self.emailBgView.layer.borderColor = DEFAULT_CGCOLOR;
    self.mobileNoBgView.layer.borderColor = DEFAULT_CGCOLOR;
    self.signatureBgView.layer.borderColor = DEFAULT_CGCOLOR;
    self.contactsBgView.layer.borderColor = DEFAULT_CGCOLOR;
    self.calendarBgView.layer.borderColor = DEFAULT_CGCOLOR;
    self.updatePinBtn.layer.borderColor = DEFAULT_CGCOLOR;
    
    [self getUserProfile];
    
    [self.navigationItem setTitle:@"My Profile"];
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                    style:UIBarButtonItemStyleDone
                                                                   target:self
                                                                   action:@selector(didPressDone:)];
    self.navigationItem.rightBarButtonItem = rightButton;
    
//    signature = @"";
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : DEFAULT_UICOLOR}];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [UIView animateWithDuration:1.0 animations:^(void) {
        self.view.alpha = 1.0;
    }];
    Account *account = [Account sharedInstance];
    if (account.photo) {
        [self.userImgView setImage:account.photo];
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
    
    if ([segue.identifier isEqualToString:@"SignatureCtrlIdentifier"]) {
        
        SignatureViewController *signatureCtrl = segue.destinationViewController;
        signatureCtrl.signature = signature;
    }
}
*/

#pragma mark - Private Methods
- (void)getUserProfile
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    Account *account = [Account sharedInstance];

    // do create
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id responseJSON){
        
        [delegate hideActivityIndicator];
        
        NSDictionary *jsonDict = responseJSON[@"details"];

        account.firstName = jsonDict[@"firstName"];
        account.lastName = jsonDict[@"lastName"];
        
        account.photo = [account.s3Manager downloadImage:jsonDict[@"profilePic"]];
        if(account.photo != nil) {
            [self.userImgView setImage:account.photo];
        }
        
        [self.fNameTextField setText:account.firstName];
        [self.lNameTextField setText:account.lastName];
        [self.jobTitleTextField setText:jsonDict[@"jobTitle"]];
        [self.emailLabel setText:account.email];
        [self.mobileNoTextField setText:jsonDict[@"mobileNumber"]];
        /*
        signature = jsonDict[@"userSignature"];
        
        if (signature.length == 0) {
            signature = @"Sent From Liri";
        }
        */
        self.companyContactSwitch.on = [jsonDict[@"companyContactsStatus"] boolValue];
        
        self.externalContactSwitch.on = [jsonDict[@"externalContactsStatus"] boolValue];
        
        self.allContactSwitch.on = [jsonDict[@"allContactsStatus"] boolValue];
        
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        [delegate hideActivityIndicator];
        NSLog(@"error message %@ and json %@", responseJSON[@"error"], responseJSON);
    };
    
    [endpoint getFullProfile];
}

- (void)imageTapped:(UIGestureRecognizer *)gesture
{
    [UIView animateWithDuration:0.5 animations:^(void) {
        self.view.alpha = 0.5;
    }];
    
    
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    
    AddPhotoViewController *photoCtlr = [storyBoard instantiateViewControllerWithIdentifier:@"AddPhotoViewController"];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        
        UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
        
        rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
        
    } else {

        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        
        photoCtlr.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        
    }
    photoCtlr.view.backgroundColor = [UIColor clearColor];
    [self presentViewController:photoCtlr animated:YES completion:nil];
    
}

- (BOOL)userProfileValidation
{
    if ([self.fNameTextField.text isEqualToString:@""]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Please provide a First Name." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];
        return NO;
    } else if ([self.lNameTextField.text isEqualToString:@""]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Please provide a Last Name." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];
        return NO;
    }
    return YES;
}

- (void) lightBoxFinished:(NSNotification*)aNotification {
    
    NSDictionary *info = [aNotification userInfo];
    
    if ([info[@"className"] isEqualToString:@"AddPhotoViewController"]) {
        [UIView animateWithDuration:0.3 animations:^(void) {
            
            self.view.alpha = 1.0;
            
        }];
        Account *account = [Account sharedInstance];
        if (account.photo) {
            [self.userImgView setImage:account.photo];
        }
    }
    
}

#pragma mark - IBAction Methods


#pragma mark - Bar Button Action Method
- (void)didPressDone:(id)sender {
    
    [self.view endEditing:YES];
    
    if ([self userProfileValidation]) {
        AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [delegate showActivityIndicator];
        
        // do create
        id<APIAccessClient> endpoint =
        (id<APIAccessClient>)[[APIManager
                               sharedInstanceWithClientProtocol:
                               @protocol(APIAccessClient)] client];
        
        endpoint.success = ^(NSURLRequest *request,
                             id responseJSON){
            
            [delegate hideActivityIndicator];
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:@"Success"
                                      message:@"User profile has been successfully updated."
                                      delegate:self cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
            [alertView show];
            
        };
        endpoint.failure = ^(NSURLRequest *request,
                             id responseJSON){
            [delegate hideActivityIndicator];
            NSLog(@"error message %@ and json %@", responseJSON[@"error"], responseJSON);
        };
        NSString *companyContact = @"false";
        NSString *externalContact = @"false";
        NSString *allContacts = @"false";
        
        if (self.companyContactSwitch.isOn) {
            companyContact = @"true";
        }
        if (self.externalContactSwitch.isOn) {
            externalContact = @"true";
        }
        if (self.allContactSwitch.isOn) {
            allContacts = @"true";
        }
        
        [endpoint editUserProfile:self.fNameTextField.text lastname:self.lNameTextField.text photo:self.userImgView.image jobtitle:self.jobTitleTextField.text mobilenumber:self.mobileNoTextField.text companyContactStatus:companyContact externalContactsStatus:externalContact allContactsStatus:allContacts];
    }
}

#pragma mark - UITextField Delegate Methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.fNameTextField) {
        [self.lNameTextField becomeFirstResponder];
    } else if (textField == self.lNameTextField) {
        [self.jobTitleTextField becomeFirstResponder];
    } else if (textField == self.jobTitleTextField) {
        [self.mobileNoTextField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    return YES;
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[self view] endEditing:YES];
}

- (IBAction)signatureBtnAction:(id)sender {
}

- (IBAction)calendarBtnAction:(id)sender {
}

@end
