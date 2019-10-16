//
//  OwnershipDetailsViewController.m
//  Liri
//
//  Created by Shankar Arunachalam on 9/4/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "OwnershipDetailsViewController.h"
#import "SelectFieldsViewController.h"
#import "AppDelegate.h"
#import "APIClient.h"
#import "TaskDataLevel1.h"
#import "TaskDataLevel2.h"
#import "Flurry.h"

@interface OwnershipDetailsViewController ()
@property (weak, nonatomic) IBOutlet UIView *ownershipView;

@end

@implementation OwnershipDetailsViewController
@synthesize taskSource, taskSourceTitle, fields, fieldsTable, values, records;
@synthesize selectedLevel1Id, selectedLevel1Value, selectedLevel2Id , selectedLevel2Value, selectedLevel3Id, selectedLevel3Value;
@synthesize ownershipView = _ownershipView;

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
    [Flurry logEvent:@"Task Source Details Screen"];
    fields = [[NSMutableArray alloc] init];
    values = [[NSMutableArray alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fieldValueSelected:) name:kFieldValueSelectedNotification object:nil];
}

- (void)viewDidLayoutSubviews
{
    [self.ownershipView setCenter:self.view.center];
}

- (void) viewDidAppear:(BOOL)animated {
    taskSourceTitle.text = taskSource;
    if(fields.count == 0) {
        if([taskSource isEqualToString:@"Asana"]) {
            [fields addObject:@"Organization"];
            [fields addObject:@"Project"];
        } else if([taskSource isEqualToString:@"SalesforceTasks"]) {
            taskSourceTitle.text = @"Salesforce";
            [fields addObject:@"Related To"];
            [fields addObject:@"Value"];
        } else if([taskSource isEqualToString:@"Trello"]) {
            [fields addObject:@"Organization"];
            [fields addObject:@"Board"];
            [fields addObject:@"List"];
        }
        [self getData];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)getData {
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    // do create
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                         id response){
        [delegate hideActivityIndicator];
        if([taskSource isEqualToString:@"Asana"]) {
            [self processAsanaRecords:response];
        } else if([taskSource isEqualToString:@"Trello"]) {
            [self processTrelloRecords:response];
        }
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
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
    if([taskSource isEqualToString:@"Asana"]) {
        [endpoint getAsanaRecords];
    } else if([taskSource isEqualToString:@"SalesforceTasks"]) {
        [delegate hideActivityIndicator];
        records = [[NSMutableArray alloc] init];
        [records addObject:[self createSalesforceLevel1Record:@"0" withName:@"Account"]];
        [records addObject:[self createSalesforceLevel1Record:@"0" withName:@"Lead"]];
        [records addObject:[self createSalesforceLevel1Record:@"0" withName:@"Opportunity"]];
        [fieldsTable reloadData];
    } else if([taskSource isEqualToString:@"Trello"]) {
        [endpoint getTrelloRecords];
    }
}

- (TaskDataLevel1 *) createSalesforceLevel1Record:(NSString *)idnum withName:(NSString *)name {
    TaskDataLevel1 *record = [[TaskDataLevel1 alloc] init];
    record.level2Data = [[NSMutableArray alloc] init];
    record.idnum = idnum;
    record.name = name;
    record.source = taskSource;
    return record;
}

- (void) processAsanaRecords:(NSDictionary *) response {
    records = [TaskDataLevel1 parseTaskDataLevel1:[response objectForKey:@"workspaces"]
                                        andLevel2:[response objectForKey:@"projects"] forSource:@"Asana"];
    [fieldsTable reloadData];
}

- (void) processTrelloRecords:(NSDictionary *) response {
    records = [TaskDataLevel1 parseTaskDataLevel1:[response objectForKey:@"organizations"]
                                        andLevel2:[response objectForKey:@"boards"] forSource:@"Trello"];
    [fieldsTable reloadData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    if(fields == nil || fields.count == 0) {
        return 0;
    }
    if([taskSource isEqualToString:@"Trello"]) {
        return 3;
    } else {
        return 2;
    }
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"sourceFieldsCell"];
    if(fields.count > 0) {
        cell.textLabel.text = [fields objectAtIndex:indexPath.row];
        if([cell.textLabel.text isEqualToString:@"SalesforceTasks"]) {
            cell.textLabel.text = @"Salesforce";
        }
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        NSString *level1Id = [standardUserDefaults objectForKey:@"TASK_PREFERENCE_LEVEL1"];
        NSString *level2Id = [standardUserDefaults objectForKey:@"TASK_PREFERENCE_LEVEL2"];
        NSString *level3Id = [standardUserDefaults objectForKey:@"TASK_PREFERENCE_LEVEL3"];
        NSString *level3Name = [standardUserDefaults objectForKey:@"TASK_PREFERENCE_LEVEL3_NAME"];

        int level1Set = -1, level2Set = -1;
        if(indexPath.row == 0) {
            for(int i = 0; i < records.count; i++) {
                TaskDataLevel1 *record = [records objectAtIndex:i];
                if([record.idnum isEqualToString:level1Id]) {
                    cell.detailTextLabel.text = record.name;
                    selectedLevel1Id = level1Id;
                    selectedLevel1Value = record.name;
                    level1Set = i;
                    break;
                }
            }
            if(level1Set < 0) {
                if([taskSource isEqualToString:@"Trello"] && records.count == 1) {
                    TaskDataLevel1 *record = [records objectAtIndex:0];
                    cell.detailTextLabel.text = record.name;
                    selectedLevel1Id = record.idnum;
                    selectedLevel1Value = record.name;
                } else {
                    cell.detailTextLabel.text = @"Choose...";
                }
            }
        } else if(indexPath.row == 1) {
            for(int i = 0; i < records.count; i++) {
                TaskDataLevel1 *record = [records objectAtIndex:i];
                for(int j = 0; j < record.level2Data.count; j++) {
                    TaskDataLevel2 *level2Record = [record.level2Data objectAtIndex:j];
                    if([level2Record.idnum isEqualToString:level2Id]) {
                        cell.detailTextLabel.text = level2Record.name;
                        selectedLevel2Id = level2Id;
                        selectedLevel2Value = level2Record.name;
                        level2Set = j;
                        break;
                    }
                }
                if(level2Set >= 0) {
                    break;
                }
            }
            if(level2Set < 0) {
                cell.detailTextLabel.text = @"Choose...";
            }
        } else {
            if(level3Name != nil && ![level3Name isEqualToString:@""]) {
                cell.detailTextLabel.text = level3Name;
            } else {
                cell.detailTextLabel.text = @"Choose...";
            }
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSUInteger firstCellIndexCoords[2] = {0,0};
    NSIndexPath *firstCellIndex = [NSIndexPath indexPathWithIndexes:firstCellIndexCoords length:2];
    UITableViewCell *firstCell = [tableView cellForRowAtIndexPath:firstCellIndex];

    NSUInteger secondCellIndexCoords[2] = {0,1};
    NSIndexPath *secondCellIndex = [NSIndexPath indexPathWithIndexes:secondCellIndexCoords length:2];
    UITableViewCell *secondCell = [tableView cellForRowAtIndexPath:secondCellIndex];

    switch(indexPath.row) {
        case 0:
            [self launchSelectFieldsController:@"1" withValues:[self getLevel1Values]];
            break;
        case 1:
            if(![taskSource isEqualToString:@"Trello"] && [firstCell.detailTextLabel.text isEqualToString:@"Choose..."]) {
                UIAlertView *failureAlert = [[UIAlertView alloc]
                                             initWithTitle:@""
                                             message:[NSString stringWithFormat:@"Please select the %@ first", fields[0]]
                                             delegate:self cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil];
                [failureAlert show];
            } else {
                [self getLevel2Values];
            }
            break;
        case 2:
            if([secondCell.detailTextLabel.text isEqualToString:@"Choose..."]) {
                UIAlertView *failureAlert = [[UIAlertView alloc]
                                             initWithTitle:@""
                                             message:[NSString stringWithFormat:@"Please select the %@ first", fields[1]]
                                             delegate:self cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil];
                [failureAlert show];
            } else {
                [self getLevel3Values];
            }
            break;
        default:
            break;
    }
}

-(NSMutableArray *) getLevel1Values {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for(int i = 0; i < records.count; i++) {
        TaskDataLevel1 *record = [records objectAtIndex:i];
        NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObjectsAndKeys:record.name, @"name",
                                      record.idnum, @"id", nil];
        [result addObject:data];
    }
    return result;
}

-(void) getLevel2Values {
    if([taskSource isEqualToString:@"SalesforceTasks"]) {
        [self getSalesforceLevel2Values];
    } else {
        NSMutableArray *result = [[NSMutableArray alloc] init];
        for(int i = 0; i < records.count; i++) {
            TaskDataLevel1 *record = [records objectAtIndex:i];
            if([record.idnum isEqualToString:selectedLevel1Id]) {
                for(int j = 0; j < record.level2Data.count; j++) {
                    TaskDataLevel2 *level2record = [record.level2Data objectAtIndex:j];
                    NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObjectsAndKeys:level2record.name, @"name", level2record.idnum, @"id", nil];
                    [result addObject:data];
                }
                break;
            }
        }
        [self launchSelectFieldsController:@"2" withValues:result];
    }
}

- (void)launchSelectFieldsController:(NSString *)level withValues:(NSMutableArray *)valuesArray {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Tasks" bundle:nil];
    SelectFieldsViewController *selectFieldsController = [storyBoard instantiateViewControllerWithIdentifier:@"SelectFieldsViewController"];
    selectFieldsController.view.backgroundColor = [UIColor clearColor];
    
    selectFieldsController.taskSource = taskSource;
    selectFieldsController.values = valuesArray;
    selectFieldsController.valueLevel = level;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        
        self.modalPresentationStyle = UIModalPresentationCurrentContext;
        
    } else {
        
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        
        selectFieldsController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        
    }
    [self presentViewController:selectFieldsController animated:YES completion:nil];
}

- (void)getSalesforceLevel2Values {
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    // do create
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id response){
        [delegate hideActivityIndicator];
        [self launchSelectFieldsController:@"2" withValues:[self processSalesforceRecords:response]];
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
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
    [endpoint getSalesforceRecords:selectedLevel1Value];
}

- (void)getLevel3Values {
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showActivityIndicator];
    
    // do create
    id<APIAccessClient> endpoint =
    (id<APIAccessClient>)[[APIManager
                           sharedInstanceWithClientProtocol:
                           @protocol(APIAccessClient)] client];
    
    endpoint.successJSON = ^(NSURLRequest *request,
                             id response){
        [delegate hideActivityIndicator];
        [self launchSelectFieldsController:@"3" withValues:[self processTrelloLists:response]];
    };
    endpoint.failureJSON = ^(NSURLRequest *request,
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
    [endpoint getTrelloLists:selectedLevel2Id];
}

-(NSMutableArray *) processSalesforceRecords: (NSDictionary *)listResponse {
    NSMutableArray *lists = [[NSMutableArray alloc] init];
    NSMutableArray *responseRecords = [listResponse objectForKey:@"records"];
    for(int i = 0; i < responseRecords.count; i++) {
        NSDictionary *thisList = [responseRecords objectAtIndex:i];
        NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObjectsAndKeys:[thisList objectForKey:@"Name"], @"name", [thisList objectForKey:@"Id"], @"id", nil];
        [lists addObject:data];
    }
    return lists;
}

-(NSMutableArray *) processTrelloLists: (NSMutableArray *)listResponse {
    NSMutableArray *lists = [[NSMutableArray alloc] init];
    for(int i = 0; i < listResponse.count; i++) {
        NSDictionary *thisList = [listResponse objectAtIndex:i];
        NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObjectsAndKeys:[thisList objectForKey:@"name"], @"name", [thisList objectForKey:@"id"], @"id", nil];
        [lists addObject:data];
    }
    return lists;
}

- (void)fieldValueSelected:(NSNotification*)aNotification {
    NSDictionary* info = [aNotification userInfo];
    NSString *selectedName = [info objectForKey:@"selectedName"];
    NSString *selectedId = [info objectForKey:@"selectedId"];
    NSString *valueLevel = [info objectForKey:@"valueLevel"];
    if([valueLevel isEqualToString:@"1"]) {
        NSUInteger firstCellIndexCoords[2] = {0,0};
        NSIndexPath *firstCellIndex = [NSIndexPath indexPathWithIndexes:firstCellIndexCoords length:2];
        UITableViewCell *firstCell = [fieldsTable cellForRowAtIndexPath:firstCellIndex];
        firstCell.detailTextLabel.text = selectedName;
        selectedLevel1Value = selectedName;
        selectedLevel1Id = selectedId;
    } else if([valueLevel isEqualToString:@"2"]) {
        NSUInteger secondCellIndexCoords[2] = {0,1};
        NSIndexPath *secondCellIndex = [NSIndexPath indexPathWithIndexes:secondCellIndexCoords length:2];
        UITableViewCell *secondCell = [fieldsTable cellForRowAtIndexPath:secondCellIndex];
        secondCell.detailTextLabel.text = selectedName;
        selectedLevel2Value = selectedName;
        selectedLevel2Id = selectedId;
    } else if([valueLevel isEqualToString:@"3"]) {
        NSUInteger thirdCellIndexCoords[2] = {0,2};
        NSIndexPath *thirdCellIndex = [NSIndexPath indexPathWithIndexes:thirdCellIndexCoords length:2];
        UITableViewCell *thirdCell = [fieldsTable cellForRowAtIndexPath:thirdCellIndex];
        thirdCell.detailTextLabel.text = selectedName;
        selectedLevel3Value = selectedName;
        selectedLevel3Id = selectedId;
    }
}

- (IBAction)didPressDoneButton:(id)sender {
    if(([taskSource isEqualToString:@"Trello"] && selectedLevel3Id != nil && ![selectedLevel3Id isEqualToString:@""]) ||
       ([taskSource isEqualToString:@"Asana"] && selectedLevel1Id != nil && ![selectedLevel1Id isEqualToString:@""]) ||
       ([taskSource isEqualToString:@"SalesforceTasks"] &&
        selectedLevel1Id != nil && ![selectedLevel1Id isEqualToString:@""]&&
        selectedLevel2Id != nil && ![selectedLevel2Id isEqualToString:@""]))
    {
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        if([taskSource isEqualToString:@"SalesforceTasks"]) {
            [standardUserDefaults setObject:@"Salesforce" forKey:@"TASK_PREFERENCE_SOURCE"];
        } else {
            [standardUserDefaults setObject:taskSource forKey:@"TASK_PREFERENCE_SOURCE"];
        }
        if(selectedLevel1Id != nil && ![selectedLevel1Id isEqualToString:@""]) {
            [standardUserDefaults setObject:selectedLevel1Id forKey:@"TASK_PREFERENCE_LEVEL1"];
        }
        if(selectedLevel2Id != nil && ![selectedLevel2Id isEqualToString:@""]) {
            [standardUserDefaults setObject:selectedLevel2Id forKey:@"TASK_PREFERENCE_LEVEL2"];
        }
        if(selectedLevel3Id != nil && ![selectedLevel3Id isEqualToString:@""]) {
            [standardUserDefaults setObject:selectedLevel3Id forKey:@"TASK_PREFERENCE_LEVEL3"];
            [standardUserDefaults setObject:selectedLevel3Value forKey:@"TASK_PREFERENCE_LEVEL3_NAME"];
        }
        [standardUserDefaults synchronize];

        AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [delegate showActivityIndicator];
        
        // do create
        id<APIAccessClient> endpoint =
        (id<APIAccessClient>)[[APIManager
                               sharedInstanceWithClientProtocol:
                               @protocol(APIAccessClient)] client];
        
        endpoint.successJSON = ^(NSURLRequest *request,
                                 id response){
            [delegate hideActivityIndicator];
            [self dismissViewControllerAnimated:NO completion:^{
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:kTaskSourceSelectedNotification
                 object:self userInfo:nil];
            }];
        };
        endpoint.failureJSON = ^(NSURLRequest *request,
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
        [endpoint saveTaskPreferences:taskSource withLevel1:selectedLevel1Id andLevel2:selectedLevel2Id];
    } else {
        NSString *errorMessage;
        if([taskSource isEqualToString:@"Trello"]) {
            errorMessage = @"Please choose a Board and a List";
        } else if ([taskSource isEqualToString:@"Asana"]) {
            errorMessage = @"Please choose an Organization";
        } else if ([taskSource isEqualToString:@"SalesforceTasks"]) {
            errorMessage = @"Please choose a Related Entity and a Value";
        }
        UIAlertView *failureAlert = [[UIAlertView alloc]
                                     initWithTitle:@""
                                     message:errorMessage
                                     delegate:self cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil];
        [failureAlert show];
    }
}

- (IBAction)didPressCancelButton:(id)sender {
    [self dismissSelf];
}

- (void) dismissSelf {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        [self dismissViewControllerAnimated:NO completion:nil];
    } else {
        [self dismissViewControllerAnimated:NO completion:^{
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kLightBoxFinishedNotification
             object:self userInfo:@{@"className" : NSStringFromClass([self class])}];
        }];
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
