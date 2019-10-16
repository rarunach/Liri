//
//  S3Manager.h
//  Liri
//
//  Created by Shankar Arunachalam on 7/17/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSRuntime/AWSRuntime.h>
#import <AWSS3/AWSS3.h>
#import "AppDelegate.h"

@interface S3Manager : NSObject <AmazonServiceRequestDelegate>
{
    AmazonS3Client *_s3Client;
    S3PutObjectRequest *_putObjectRequest;
}

@property (nonatomic,retain) AppDelegate *appDelegate;
//@property (nonatomic) AmazonS3Client *_s3Client;
//@property (nonatomic) S3PutObjectRequest *_putObjectRequest;

- (id)init;
-(UIImage *)downloadImage:(NSString *)imageKey;
-(BOOL)uploadImage:(NSData *)imageData withName:(NSString *)name;

@end
