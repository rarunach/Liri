//
//  FileFolderMetadata.h
//  Liri
//
//  Created by Shankar Arunachalam on 7/31/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileFolderMetadata : NSObject

@property (nonatomic, retain) NSString *source;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSNumber *size;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *fileType;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSString *token;
@property (nonatomic, retain) NSString *id;
@property (nonatomic, retain) NSDate *lastModifiedTime;

+(NSMutableArray *) getFileFolderMetadata: (NSArray *) responseJSON forCloudSearch:(BOOL)isCloudSearch;

@end
