//
//  S3Manager.m
//  Liri
//
//  Created by Shankar Arunachalam on 7/17/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "S3Manager.h"
#import "AppConstants.h"

@implementation S3Manager
@synthesize appDelegate;
//@synthesize _s3Client, _putObjectRequest;

- (id)init
{
    self = [super init];
    if (self) {
         _s3Client = [[AmazonS3Client alloc]initWithAccessKey:S3_KEY withSecretKey:S3_SECRET];
    }
    return self;
}

-(UIImage *)downloadImage:(NSString *)imageKey {
    @try{
        S3GetObjectRequest *getObjectRequest = [[S3GetObjectRequest alloc]initWithKey:imageKey withBucket:S3_BUCKET];
        S3GetObjectResponse *response = [_s3Client getObject:getObjectRequest];
        
        if (response.error == nil)
        {
            if (response.body != nil)
            {
                UIImage *image = [UIImage imageWithData:response.body];
                return image;
            }
            else{
                NSLog(@"There was no value in the response body");
                return nil;
            }
        }
        else if (response.error != nil)
        {
            NSLog(@"S3 error for %@: %@", imageKey, response.error.description);
            return nil;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"S3 exception for %@: %@", imageKey, exception.description);
        return nil;
    }
}

-(BOOL)uploadImage:(NSData *)imageData withName:(NSString *)name {
    @try{
        appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate showActivityIndicator];
        _putObjectRequest = [[S3PutObjectRequest alloc]initWithKey:name inBucket:S3_BUCKET];
        _putObjectRequest.serverSideEncryption  = kS3ServerSideEnryptionAES256;
        _s3Client.endpoint = [AmazonEndpoints s3Endpoint:US_WEST_2];
        
        _putObjectRequest.contentType = @"image/jpeg";
        _putObjectRequest.data = [NSData dataWithData: imageData];
        _putObjectRequest.contentLength = [imageData length];
        
        //_putObjectRequest.delegate = self;
        S3PutObjectResponse *response = [_s3Client putObject:_putObjectRequest];
        [appDelegate hideActivityIndicator];
        if(response.error != nil)
        {
            NSLog(@"Error: %@", response.error);
            return NO;
        } else {
            return YES;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"There was an exception when connecting to s3: %@",exception.description);
        return NO;
    }
}

//- (void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
//{
//    [appDelegate hideActivityIndicator];
//    NSLog(@"response: %@", response.description);
//    if ([self.delegate respondsToSelector:@selector(uploadSuccessful)]) {
//        [self.delegate uploadSuccessful];
//    }
//}
//
//- (void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error
//{
//    [appDelegate hideActivityIndicator];
//    NSLog(@"Req failed: %@", error.description);
//    if ([self.delegate respondsToSelector:@selector(uploadFailed)]) {
//        [self.delegate uploadFailed];
//    }
//}

@end
