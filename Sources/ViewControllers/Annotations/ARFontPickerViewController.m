//
//  ARFontPickerViewController.m
//
//  Created by Alexander Repty on 15.03.10.
// 
//  Copyright (c) 2010, Alexander Repty
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//  
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//  Neither the name of Alexander Repty nor the names of his contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.

#import "ARFontPickerViewController.h"
#import "AnnotationsViewController.h"
#import "Flurry.h"

NSString *const kARFontPickerViewControllerCellIdentifier = @"ARFontPickerViewControllerCellIdentifier";

@interface ARFontPickerViewController (PrivateMethods)

- (NSString *)_fontFamilyForRow:(NSInteger)row;

@end

@implementation ARFontPickerViewController

@synthesize delegate = _delegate;
@synthesize fonts;

- (void)viewWillAppear:(BOOL)animated
{
    self.view.alpha = 1.0;
    [Flurry logEvent:@"Font Picker Screen"];
    fonts = [[[UIFont familyNames] sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSString *first = (NSString*)a;
        NSString *second = (NSString*)b;
        return [first compare:second options:NSCaseInsensitiveSearch];
    }] mutableCopy];
    UITableView *tableView = (UITableView *)[self.view viewWithTag:100];
    if (IS_IPHONE_5) {
        
    } else {
        [tableView setFrame:CGRectMake(tableView.frame.origin.x, tableView.frame.origin.y, tableView.frame.size.width, 416)];
    }
}

#pragma mark -
#pragma mark UITableViewController methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[UIFont familyNames] count];
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//	return [self _fontFamilyForSection:section];
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kARFontPickerViewControllerCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kARFontPickerViewControllerCellIdentifier];
    }
    
    NSString *familyName = [self _fontFamilyForRow:indexPath.row];
	UIFont *font = [UIFont fontWithName:familyName size:[UIFont smallSystemFontSize]];
	
	cell.textLabel.text = familyName;
	cell.textLabel.font = font;
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSString *familyName = [self _fontFamilyForRow:indexPath.row];
    [standardUserDefaults setObject:familyName forKey:@"SELECTED_FONT"];
    [standardUserDefaults synchronize];
    
    AnnotationsViewController *mainController = (AnnotationsViewController *)self.presentingViewController;
    
    [self dismissViewControllerAnimated:YES completion:^{
        [mainController updateSelectedFont:familyName];
    }];
}

- (IBAction)backAction:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark -
#pragma mark Private methods

- (NSString *)_fontFamilyForRow:(NSInteger)row {
	@try {
		return [fonts objectAtIndex:row];
	}
	@catch (NSException * e) {
		// ignore
	}
	return nil;
}

@end

