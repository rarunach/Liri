//
//  SummayPointViewController.h
//  Liri
//
//  Created by Varun Sankar on 03/07/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Categories.h"

@protocol SummaryPointProtocol;

@interface SummaryPointViewController : UIViewController<UITextViewDelegate>

@property (nonatomic, retain)NSString *chatName;
@property (nonatomic, retain)NSString *chatMessage;

@property (nonatomic, retain)NSString *discussionId;
@property (nonatomic, retain)NSString *messageId;

@property (nonatomic, retain)UIImage *annotationImg;

@property (nonatomic) BOOL isEditMode;
@property (nonatomic, retain) Categories *summaryPoint;

@property (nonatomic,retain) id <SummaryPointProtocol> delegate;
@property (nonatomic, retain)NSString *messageTimeStamp;

@end

@protocol SummaryPointProtocol <NSObject>

- (void)summaryPointCreatedWithCategoryType:(int)categoryType categoryId:(int)categoryId categoryText:(NSString *)text andEditMode:(BOOL)edited;
@end