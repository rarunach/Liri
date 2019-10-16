//
//  SelectFieldsViewController.m
//  Liri
//
//  Created by Shankar Arunachalam on 9/9/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "SelectFieldsViewController.h"
#import "Flurry.h"

@interface SelectFieldsViewController ()

@property (weak, nonatomic) IBOutlet UIView *selectFieldView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewHeightConstraint;
@end

@implementation SelectFieldsViewController
@synthesize taskSource, taskSourceTitle, values, valuesTable, valueLevel;
@synthesize selectFieldView = _selectFieldView;
@synthesize tableViewHeightConstraint = _tableViewHeightConstraint;

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
    [Flurry logEvent:@"Task Source Fields Selection Screen"];
    taskSourceTitle.text = taskSource;
}

- (void)viewDidLayoutSubviews
{
    if(!IS_IPHONE_5) {
        //do stuff for 3.5 inch iPhone screen
        [self.selectFieldView setFrame:CGRectMake(self.selectFieldView.frame.origin.x, self.selectFieldView.frame.origin.y, self.selectFieldView.frame.size.width, 440)];
        [self.valuesTable reloadData];
        [self adjustHeightOfTableview];
    }
}

- (void)adjustHeightOfTableview
{
    CGFloat height = self.valuesTable.contentSize.height;
    CGFloat maxHeight = self.valuesTable.superview.frame.size.height - self.valuesTable.frame.origin.y;
    
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    return values.count;
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"sourceFieldsCell"];
    NSMutableDictionary *data = [values objectAtIndex:indexPath.row];
    cell.textLabel.text = [data objectForKey:@"name"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSMutableDictionary *data = [values objectAtIndex:indexPath.row];
    [self dismissViewControllerAnimated:NO completion:^{
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kFieldValueSelectedNotification
         object:self userInfo:@{@"selectedName": [data objectForKey:@"name"],
                                @"selectedId": [data objectForKey:@"id"],
                                @"valueLevel": valueLevel}];
    }];
}

- (IBAction)didPressCancelButton:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
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
