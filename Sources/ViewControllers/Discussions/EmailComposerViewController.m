//
//  EmailComposerViewController.m
//  Liri
//
//  Created by Varun Sankar on 05/08/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "EmailComposerViewController.h"
#import "Account.h"
#import "Flurry.h"

@interface EmailComposerViewController ()
{
    NSMutableArray *searchArray, *emailArr;
}
@property (weak, nonatomic) IBOutlet UILabel *titleLbl;

@property (weak, nonatomic) IBOutlet UITextField *emailToField;
@property (weak, nonatomic) IBOutlet UITextField *emailSubjectField;
@property (weak, nonatomic) IBOutlet UIButton *filePathBtn;
@property (weak, nonatomic) IBOutlet UITextView *summaryTextView;
@property (weak, nonatomic) IBOutlet UITableView *contactTable;
@property (weak, nonatomic) IBOutlet UIButton *sendBtn;
@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;
@property (weak, nonatomic) IBOutlet UIImageView *lineImgView;
@property (weak, nonatomic) IBOutlet UIButton *inProgressBtn;

- (IBAction)backBtnAction:(id)sender;
- (IBAction)sendBtnAction:(id)sender;
- (IBAction)cancelBtnAction:(id)sender;

@end

@implementation EmailComposerViewController

@synthesize emailToField = _emailToField, emailSubjectField = _emailSubjectField;

@synthesize filePathBtn = _filePathBtn, sendBtn = _sendBtn, cancelBtn = _cancelBtn, inProgressBtn = _inProgressBtn;

@synthesize summaryTextView = _summaryTextView;

@synthesize contactTable = _contactTable;

@synthesize summaryContent = _summaryContent;

@synthesize attrArray = _attrArray;

@synthesize summaryTitle = _summaryTitle;

@synthesize titleLbl = _titleLbl;

@synthesize lineImgView = _lineImgView;


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
    [Flurry logEvent:@"Email Composer Screen"];
    
    [self.emailToField.layer setBorderColor:DEFAULT_CGCOLOR];
    
    [self.emailSubjectField.layer setBorderColor:DEFAULT_CGCOLOR];
    
    [self.filePathBtn.layer setBorderColor:DEFAULT_CGCOLOR];
    
    [self.summaryTextView.layer setBorderColor:DEFAULT_CGCOLOR];

    [self.summaryTextView setText:self.summaryContent];
    [self setAttributeString];
    
    self.contactTable.separatorInset = UIEdgeInsetsZero;
    self.contactTable.separatorColor = [UIColor lightGrayColor];
    [self.titleLbl setText:self.summaryTitle];
    [self emailContact];
    
    [self getSignature];
}

- (void)viewDidLayoutSubviews
{
    if(!IS_IPHONE_5) {
        //do stuff for 3.5 inch iPhone screen
        [self.summaryTextView setFrame:CGRectMake(self.summaryTextView.frame.origin.x, self.summaryTextView.frame.origin.y, self.summaryTextView.frame.size.width, 220)];
        
        [self.sendBtn setFrame:CGRectMake(self.sendBtn.frame.origin.x, 392, self.sendBtn.frame.size.width, self.sendBtn.frame.size.height)];
        
        [self.cancelBtn setFrame:CGRectMake(self.cancelBtn.frame.origin.x, 392, self.cancelBtn.frame.size.width, self.cancelBtn.frame.size.height)];
        
        [self.lineImgView setFrame:CGRectMake(self.lineImgView.frame.origin.x, 430, self.lineImgView.frame.size.width, self.lineImgView.frame.size.height)];
        
        [self.inProgressBtn setFrame:CGRectMake(self.inProgressBtn.frame.origin.x, 440, self.inProgressBtn.frame.size.width, self.inProgressBtn.frame.size.height)];
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
            [self.contactTable setFrame:CGRectMake(self.contactTable.frame.origin.x, self.contactTable.frame.origin.y, self.contactTable.frame.size.width, self.contactTable.frame.size.height - 86)];
        } else {
            [self.contactTable setFrame:CGRectMake(self.contactTable.frame.origin.x, self.contactTable.frame.origin.y, self.contactTable.frame.size.width, self.contactTable.frame.size.height - 42)];
        }
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private Methods
- (void)emailContact
{
    emailArr = [[NSMutableArray alloc]init];
    searchArray = [[NSMutableArray alloc]init];
    
    Account *account = [Account sharedInstance];
    for (Buddy *buddy in account.buddyList.allBuddies) {
        if (buddy.isUser) {
            NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:buddy.firstName, @"firstName", buddy.lastName, @"lastName", buddy.displayName, @"name", buddy.email, @"email", nil];
//            [emailArr addObject:dict];
            if (![emailArr containsObject:dict]) {
                [emailArr addObject:dict];
            }
        }
    }
}

- (void)searchAutocompleteEntriesWithSubstring:(NSString *)substring
{
    
    [searchArray removeAllObjects];
    
    for(NSDictionary *curDict in emailArr)
    {
        NSString *first = [curDict objectForKey:@"firstName"];
        NSString *last = [curDict objectForKey:@"lastName"];
        NSString *name = curDict[@"name"];
        if ((first == [NSNull null]) || (last == [NSNull null]) || (name == [NSNull null])) continue;
        
        NSRange firstNameRange = [[curDict objectForKey:@"firstName"] rangeOfString:substring options:NSCaseInsensitiveSearch];
        NSRange lastNameRange = [[curDict objectForKey:@"lastName"] rangeOfString:substring options:NSCaseInsensitiveSearch];
        NSRange nameRange = [name rangeOfString:substring options:NSCaseInsensitiveSearch];
        if (firstNameRange.location == 0 || lastNameRange.location == 0 || nameRange.location == 0)
        {
            [searchArray addObject:curDict];
        }
    }
    
    if ([searchArray count] > 0) {
        self.contactTable.hidden = NO;
    } else {
        self.contactTable.hidden = YES;
    }
    
    [self.contactTable reloadData];
}

- (void)setAttributeString
{
    NSMutableAttributedString * attrString = [[NSMutableAttributedString alloc] initWithString:self.summaryTextView.text];
    NSRange foundRangeFull = [self.summaryTextView.text rangeOfString:[attrString string]];
    [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithName:FONT_HELVETICA_NEUE size:FONT_SIZE] range:foundRangeFull];
    
    [attrString beginEditing];
    
    for (int i = 0; i < self.attrArray.count; i++) {
        NSRange foundRange = [self.summaryTextView.text rangeOfString:[NSString stringWithFormat:@"%@", self.attrArray[i]]];
        [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithName:FONT_HELVETICA_NEUE_BOLD size:FONT_SIZE] range:foundRange];
    }
    
    [attrString endEditing];
    [self.summaryTextView setAttributedText:attrString];
}

- (void)alertViewWithTitle:(NSString *)title message:(NSString *)msg okButton:(NSString *)ok cancelButton:(NSString *)cancel andTag:(int)tag
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:title
                          message:msg
                          delegate:self cancelButtonTitle:ok
                          otherButtonTitles:cancel, nil];
    alert.tag = tag;
    [alert show];
}
- (BOOL)contactFieldValidation
{
    
    NSMutableArray *validateEmailArray =  (NSMutableArray *)[self.emailToField.text componentsSeparatedByString:@","];
    
    BOOL isValid = YES;
    
    for (int i = 0; i < [validateEmailArray count]; i++) {
        
        // Not Last Object
        if (i != [validateEmailArray count] - 1) {
            if ([[validateEmailArray objectAtIndex:i] isEqualToString:@""] || ![Account verifyEmail:[validateEmailArray objectAtIndex:i]]) {
                isValid = NO;
                break;
            }
        }
        else {// Last Object may have empty if ',' appears
            if (![[validateEmailArray objectAtIndex:i] isEqualToString:@""]) {
                if(![Account verifyEmail:[validateEmailArray objectAtIndex:i]]){
                    isValid = NO;
                    break;
                }
            } else {
                break;
            }
        }
    }
    return isValid;
}

- (void)sendDiscussionSummaryByEmail
{
    id<APIAccessClient> discussionsEndpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    discussionsEndpoint.success = ^(NSURLRequest *request,
                                    id responseJSON){
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"Email sent successfully"
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        [delegate hideActivityIndicator];
        [self dismissViewControllerAnimated:YES completion:nil];
    };
    discussionsEndpoint.failure = ^(NSURLRequest *request,
                                    id responseJSON){
        
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"An error occurred while sending email."
                                  delegate:nil cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        [delegate hideActivityIndicator];
        [self dismissViewControllerAnimated:YES completion:nil];
    };
    
    Account *account = [Account sharedInstance];
    
    NSString *content = self.summaryTextView.text;
    content = [content stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];
    for (NSString *string in self.attrArray) {
        if ([content rangeOfString:string].location != NSNotFound) {
            NSLog(@"string contains bla!");
            content = [content stringByReplacingOccurrencesOfString:string withString:[NSString stringWithFormat:@"<b>%@</b>",string]];
        }
    }
    
    [discussionsEndpoint sendEmail:account.email to:self.emailToField.text subject:self.emailSubjectField.text body:content attachments:@""];
}

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
            
            liriSignature = responseJSON[@"signature"];
        } else {
            //default signature
            Account *account = [Account sharedInstance];
            
            liriSignature = [NSString stringWithFormat:@"\nSent from Liri\n%@ %@", account.firstName, account.lastName];
        }
        self.summaryTextView.text = [self.summaryTextView.text stringByAppendingString:liriSignature];
        
        [self setAttributeString];
        [delegate hideActivityIndicator];
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
                             id responseJSON){
        
        [delegate hideActivityIndicator];
    };
    
    [endpoint getSignature];
}

#pragma mark - UITextField Delegate Methods
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.emailToField) {
        
        if ([string isEqualToString:@" "] && self.contactTable.hidden) {
            return NO;
        }
        
        NSString * searchStr = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSArray *myArray = [searchStr componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
        if ([myArray count] == 1)
        {
            [self searchAutocompleteEntriesWithSubstring:searchStr];
        } else {
            [self searchAutocompleteEntriesWithSubstring:[myArray lastObject]];
        }
    }else {
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        return (newLength > KMaxUserCategoryLength) ? NO : YES;
    }
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField == self.emailSubjectField) {
        [self.contactTable setHidden:YES];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField;
{
    [textField resignFirstResponder];
    [self.contactTable setHidden:YES];
    
    return YES;
}

#pragma mark - UITableView DataSource Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    return [searchArray count];
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"ContactCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    //5.1 you do not need this if you have set SettingsCell as identifier in the storyboard (else you can remove the comments on this code)
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    cell.textLabel.text = [[searchArray objectAtIndex:indexPath.row] objectForKey:@"name"];
    [cell.textLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:15.0]];
    
    cell.detailTextLabel.text = [[searchArray objectAtIndex:indexPath.row] objectForKey:@"email"];
    [cell.detailTextLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:15.0]];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

#pragma mark - UITableView Delegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *emailAddedArr = (NSMutableArray *)[self.emailToField.text componentsSeparatedByString:@","];
    
    
    NSString *emailStr = @"";
    
    if ([emailAddedArr count] == 1)
    {
        self.emailToField.text = [NSString stringWithFormat:@"%@,",[[searchArray objectAtIndex:indexPath.row] objectForKey:@"email"]];
    }
    else
    {
        [emailAddedArr removeLastObject];
        [emailAddedArr addObject:[[searchArray objectAtIndex:indexPath.row] objectForKey:@"email"]];
        for (NSString *email in emailAddedArr)
        {
            emailStr = [emailStr stringByAppendingString:[NSString stringWithFormat:@"%@,",email]];
        }
        self.emailToField.text = emailStr;
    }
    self.contactTable.hidden = YES;
}

#pragma mark - IBAction Methods
- (IBAction)backBtnAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)sendBtnAction:(id)sender
{
    
    if ([self.emailToField.text isEqualToString:@""]) {
        [self alertViewWithTitle:@"Alert" message:@"Cannot send message without recipient list" okButton:@"Ok" cancelButton:nil andTag:0];
        return;
    } else if (![self contactFieldValidation]) {
        [self alertViewWithTitle:@"Alert" message:@"Invalid recipient email address. Please change or remove the email address." okButton:@"Ok" cancelButton:nil andTag:0];
        return;
    } else if ([self.emailSubjectField.text isEqualToString:@""]) {
        [self alertViewWithTitle:@"Alert" message:@"Subject line is blank, Send it anyway?" okButton:@"Ok" cancelButton:@"Cancel" andTag:KInsertAlertTag];
    } else {
        [self sendDiscussionSummaryByEmail];
    }
}

- (IBAction)cancelBtnAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIAlertView Delegate Method
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0 && alertView.tag == KInsertAlertTag) {
        [self sendDiscussionSummaryByEmail];
    }
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
