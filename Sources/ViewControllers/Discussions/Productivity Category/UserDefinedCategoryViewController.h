//
//  UserDefinedCategoryViewController.h
//  Liri
//
//  Created by Varun Sankar on 03/07/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Categories.h"
@protocol UserCategoryProtocol;

@interface UserDefinedCategoryViewController : UIViewController

@property (nonatomic, retain) NSString *userNotesTitle;
@property (nonatomic, retain) NSString *chatName;
@property (nonatomic, retain) NSString *chatMessage;

@property (nonatomic, retain) NSString *discussionId;
@property (nonatomic, retain) NSString *messageId;
@property (nonatomic, retain) UIImage *annotationImg;

@property (nonatomic) int categoryType;

@property (nonatomic) BOOL isEditMode;
@property (nonatomic, retain) Categories *userDefinedCategory;

@property (nonatomic,retain) id <UserCategoryProtocol> delegate;
@property (nonatomic, retain)NSString *messageTimeStamp;

@end

@protocol UserCategoryProtocol <NSObject>

- (void)userCategoryInstanceCreatedWithCategoryType:(int)categoryType categoryId:(int)categoryId categoryText:(NSString *)text andEditMode:(BOOL)edited;
@end