//
//  ChooseCategoryViewController.m
//  Liri
//
//  Created by Varun Sankar on 14/08/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "ChooseCategoryViewController.h"
#import "UserCategories.h"
#import "Flurry.h"

@interface ChooseCategoryViewController ()
{
    NSMutableArray *categoryArray, *selectedItems, *backUpArray;
    
}
- (IBAction)cancelBtnAction:(id)sender;
- (IBAction)doneBtnAction:(id)sender;

@property (weak, nonatomic) IBOutlet UITableView *chooseCategoryTable;
@property (weak, nonatomic) IBOutlet UIView *chooseCategoryView;
@end

@implementation ChooseCategoryViewController

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
    [Flurry logEvent:@"Choose Category Screen"];
    self.chooseCategoryTable.allowsMultipleSelection = YES;
    selectedItems = [[NSMutableArray alloc] init];
    categoryArray = [[UserCategories sharedManager] categoryArray];
    
    [self makeViewAlignment];
    [self selectAllRows];
}
- (void)viewWillAppear:(BOOL)animated
{
    backUpArray = [[NSMutableArray alloc] initWithArray:selectedItems];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private Methods

- (void)makeViewAlignment
{
    CGFloat categoryViewHeight, categoryTableHeight;
    if (IS_IPHONE_5) {
        categoryViewHeight = 440;
        categoryTableHeight = 390;
    } else {
        categoryViewHeight = 352;
        categoryTableHeight = 302;
    }
    CGRect frame = self.chooseCategoryView.frame;
    frame.size.height = MIN((categoryArray.count * 44) + 50, categoryViewHeight);
    frame.origin.y = (self.view.frame.size.height - frame.size.height) / 2;
    self.chooseCategoryView.frame = frame;
    
    frame = self.chooseCategoryTable.frame;
    frame.size.height = MIN((categoryArray.count * 44), categoryTableHeight);
    self.chooseCategoryTable.frame = frame;
}

- (void)selectAllRows
{
    [selectedItems removeAllObjects];
    for (int i = 0; i < [self.chooseCategoryTable numberOfSections]; i++) {
        for (int j = 0; j < [self.chooseCategoryTable numberOfRowsInSection:i]; j++) {
            
            NSUInteger ints[2] = {i,j};
            NSIndexPath *index = [NSIndexPath indexPathWithIndexes:ints length:2];
            [self.chooseCategoryTable selectRowAtIndexPath:index animated:NO scrollPosition:UITableViewScrollPositionNone];
            
            UITableViewCell *cell = [self.chooseCategoryTable cellForRowAtIndexPath:index];
            UIButton *firstButton = (UIButton *)[cell viewWithTag:100];
            [firstButton setBackgroundColor:DEFAULT_UICOLOR];
            [selectedItems addObject:index];
        }
    }
}

#pragma mark - UIButton Actions
- (void)categoryCheckAction:(id)sender event:(id)event
{
    NSSet *touches = [event allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.chooseCategoryTable];
	NSIndexPath *indexPath = [self.chooseCategoryTable indexPathForRowAtPoint: currentTouchPosition];    
    UITableViewCell *cell = [self.chooseCategoryTable cellForRowAtIndexPath:indexPath];
    
    UIButton *checkBoxBtn = (UIButton *)[cell viewWithTag:100];
    
    if (![checkBoxBtn backgroundColor]) {
        
        if (indexPath.row == 0) {
            [selectedItems removeAllObjects];
            for (int i = 0; i < [self.chooseCategoryTable numberOfSections]; i++) {
                for (int j = 0; j < [self.chooseCategoryTable numberOfRowsInSection:i]; j++) {
                    
                        NSUInteger ints[2] = {i,j};
                        NSIndexPath *index = [NSIndexPath indexPathWithIndexes:ints length:2];
                        [self.chooseCategoryTable selectRowAtIndexPath:index animated:NO scrollPosition:UITableViewScrollPositionNone];
                        
                        UITableViewCell *cell = [self.chooseCategoryTable cellForRowAtIndexPath:index];
                        UIButton *selectAll = (UIButton *)[cell viewWithTag:100];
                        [selectAll setBackgroundColor:DEFAULT_UICOLOR];
                        [selectedItems addObject:index];
                    }
            }
        } else {
            [self.chooseCategoryTable selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            [checkBoxBtn setBackgroundColor:DEFAULT_UICOLOR];
            [selectedItems addObject:indexPath];
            
            if([[self.chooseCategoryTable indexPathsForSelectedRows] count] == [categoryArray count]-1) {
                NSUInteger ints[2] = {0,0};
                NSIndexPath *index = [NSIndexPath indexPathWithIndexes:ints length:2];
                [self.chooseCategoryTable selectRowAtIndexPath:index animated:NO scrollPosition:UITableViewScrollPositionNone];
                
                UITableViewCell *cell = [self.chooseCategoryTable cellForRowAtIndexPath:index];
                UIButton *firstButton = (UIButton *)[cell viewWithTag:100];
                [firstButton setBackgroundColor:DEFAULT_UICOLOR];
                [selectedItems addObject:index];
            }
        }
        
        
    } else {
        [self.chooseCategoryTable deselectRowAtIndexPath:indexPath animated:NO];
        [checkBoxBtn setBackgroundColor:nil];
        [selectedItems removeObject:indexPath];
        
        if (indexPath.row == 0) {
            NSArray *array = [self.chooseCategoryTable indexPathsForSelectedRows];
            for (NSIndexPath *index in array) {
                [self.chooseCategoryTable deselectRowAtIndexPath:index animated:NO];
                UITableViewCell *cell = [self.chooseCategoryTable cellForRowAtIndexPath:index];
                UIButton *deSelectAll = (UIButton *)[cell viewWithTag:100];
                [deSelectAll setBackgroundColor:nil];
                [selectedItems removeAllObjects];
            }
        } else {
            NSUInteger ints[2] = {0,0};
            NSIndexPath *index = [NSIndexPath indexPathWithIndexes:ints length:2];
            [self.chooseCategoryTable deselectRowAtIndexPath:index animated:NO];
            
            UITableViewCell *cell = [self.chooseCategoryTable cellForRowAtIndexPath:index];
            UIButton *firstButton = (UIButton *)[cell viewWithTag:100];
            [firstButton setBackgroundColor:nil];
            [selectedItems removeObject:index];
        }
    }
    
}

#pragma mark - UITableView Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    return [categoryArray count];
}
- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"myCategoriesCell"];
    if (cell != nil) {
    
        UIButton *categoryButton = (UIButton *)[cell viewWithTag:100];
        [categoryButton addTarget:self action:@selector(categoryCheckAction:event:) forControlEvents:UIControlEventTouchUpInside];
        [categoryButton.layer setBorderColor:DEFAULT_CGCOLOR];
        [categoryButton.layer setBorderWidth:2.0f];
    
        if ([selectedItems containsObject:indexPath]) {
            categoryButton.backgroundColor = DEFAULT_UICOLOR;
        } else {
            categoryButton.backgroundColor = nil;
        }
    
        UIImageView *categoryImageView = (UIImageView *)[cell viewWithTag:200];
        if (indexPath.row == 0) {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_25]];
        } else if (indexPath.row == 1) {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_1]];
        } else if (indexPath.row == 2) {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_2]];
        } else if (indexPath.row == 3) {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_3]];
        } else if (indexPath.row == 4) {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_4]];
        } else if (indexPath.row == 5) {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_5]];
        } else if (indexPath.row == 6) {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_6]];
        } else if (indexPath.row == 7) {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_7]];
        } else if (indexPath.row == 8) {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_8]];
        } else if (indexPath.row == 9) {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_9]];
        } else if (indexPath.row == 10) {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_10]];
        } else if (indexPath.row == 11) {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_11]];
        } else if (indexPath.row == 12) {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_12]];
        } else if (indexPath.row == 13) {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_13]];
        } else if (indexPath.row == 14) {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_14]];
        } else if (indexPath.row == 15) {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_15]];
        } else if (indexPath.row == 16) {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_16]];
        } else if (indexPath.row == 17) {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_17]];
        } else if (indexPath.row == 18) {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_18]];
        } else if (indexPath.row == 19) {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_19]];
        } else if (indexPath.row == 20) {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_20]];
        } else if (indexPath.row == 21) {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_21]];
        } else if (indexPath.row == 22) {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_22]];
        } else if (indexPath.row == 23) {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_23]];
        } else if (indexPath.row == 24) {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_24]];
        } else {
            [categoryImageView setImage:[UIImage imageNamed:CAT_IMG_25]];
        }
        
        UILabel *categoryLabel = (UILabel *)[cell viewWithTag:300];
        if (indexPath.row == 0) {
            [categoryLabel setText:@"All Categories"];
        } else if(indexPath.row < 5) {
            [categoryLabel setText:categoryArray[indexPath.row - 1][@"sysCategory"]];
        } else {
            [categoryLabel setText:categoryArray[indexPath.row - 1][@"userDefinedCategory"]];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        [selectedItems removeAllObjects];
        for (int i = 0; i < [tableView numberOfSections]; i++) {
            for (int j = 0; j < [tableView numberOfRowsInSection:i]; j++) {
                
                    NSUInteger ints[2] = {i,j};
                    NSIndexPath *index = [NSIndexPath indexPathWithIndexes:ints length:2];
                    [tableView selectRowAtIndexPath:index animated:NO scrollPosition:UITableViewScrollPositionNone];
                    
                    UITableViewCell *cell = [tableView cellForRowAtIndexPath:index];
                    UIButton *firstButton = (UIButton *)[cell viewWithTag:100];
                    [firstButton setBackgroundColor:DEFAULT_UICOLOR];
                    [selectedItems addObject:index];
            }
        }
    } else {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UIButton *checkBoxBtn = (UIButton *)[cell viewWithTag:100];
        [checkBoxBtn setBackgroundColor:DEFAULT_UICOLOR];
        [selectedItems addObject:indexPath];
        
        if([[tableView indexPathsForSelectedRows] count] == [categoryArray count]-1) {
            NSUInteger ints[2] = {0,0};
            NSIndexPath *index = [NSIndexPath indexPathWithIndexes:ints length:2];
            [tableView selectRowAtIndexPath:index animated:NO scrollPosition:UITableViewScrollPositionNone];
            
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:index];
            UIButton *firstButton = (UIButton *)[cell viewWithTag:100];
            [firstButton setBackgroundColor:DEFAULT_UICOLOR];
            [selectedItems addObject:index];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger ints[2] = {0,0};
    NSIndexPath *index = [NSIndexPath indexPathWithIndexes:ints length:2];
    [tableView deselectRowAtIndexPath:index animated:NO];
    
    UITableViewCell *firstCell = [tableView cellForRowAtIndexPath:index];
    UIButton *firstBoxBtn = (UIButton *)[firstCell viewWithTag:100];
    [firstBoxBtn setBackgroundColor:nil];
    [selectedItems removeObject:index];
    
    if (indexPath.row == 0) {
        NSArray *array = [tableView indexPathsForSelectedRows];
        for (NSIndexPath *index in array) {
            [tableView deselectRowAtIndexPath:index animated:NO];
            
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:index];
            UIButton *checkBoxBtn = (UIButton *)[cell viewWithTag:100];
            [checkBoxBtn setBackgroundColor:nil];
            [selectedItems removeObject:index];
        }
    } else {
        
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UIButton *checkBoxBtn = (UIButton *)[cell viewWithTag:100];
        [checkBoxBtn setBackgroundColor:nil];
        [selectedItems removeObject:indexPath];
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


- (IBAction)cancelBtnAction:(id)sender {
    [selectedItems removeAllObjects];
    
    NSArray *array = [self.chooseCategoryTable indexPathsForSelectedRows];
    for (NSIndexPath *index in array) {
        [self.chooseCategoryTable deselectRowAtIndexPath:index animated:NO];
        UITableViewCell *cell = [self.chooseCategoryTable cellForRowAtIndexPath:index];
        UIButton *deSelectAll = (UIButton *)[cell viewWithTag:100];
        [deSelectAll setBackgroundColor:nil];
    }
    
    for (NSIndexPath *index in backUpArray) {
        [self.chooseCategoryTable selectRowAtIndexPath:index animated:NO scrollPosition:UITableViewScrollPositionNone];
        UITableViewCell *cell = [self.chooseCategoryTable cellForRowAtIndexPath:index];
        UIButton *firstButton = (UIButton *)[cell viewWithTag:100];
        [firstButton setBackgroundColor:DEFAULT_UICOLOR];
        [selectedItems addObject:index];
    }
    
    [self dismissSelf];
}
- (IBAction)doneBtnAction:(id)sender {
    [self.delegate returnSelectedIndexPaths:selectedItems];
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

@end
