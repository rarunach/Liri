//
//  FileFolderMetadata.m
//  Liri
//
//  Created by Shankar Arunachalam on 7/31/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "FileFolderMetadata.h"

@implementation FileFolderMetadata

+(NSMutableArray *) getFileFolderMetadata: (NSArray *) responseJSON forCloudSearch:(BOOL)isCloudSearch {
    NSMutableArray *fileResults = [[NSMutableArray alloc]init];
    NSMutableArray *folderResults = [[NSMutableArray alloc]init];
    for(int i = 0; i < responseJSON.count; i++) {
        if(!isCloudSearch) {
            FileFolderMetadata *data = [FileFolderMetadata parseMetadata:responseJSON[i]];
            if([data.type isEqualToString:@"folder"]) {
                [folderResults addObject:data];
            } else {
                [fileResults addObject:data];
            }
        } else {
            for(NSDictionary *result in responseJSON[i]) {
                FileFolderMetadata *data = [FileFolderMetadata parseMetadata:result];
                if([data.type isEqualToString:@"folder"]) {
                    [folderResults addObject:data];
                } else {
                    [fileResults addObject:data];
                }
            }
        }
    }
    NSMutableArray *sortedFolders;
    sortedFolders = [[folderResults sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSString *first = [(FileFolderMetadata*)a name];
        NSString *second = [(FileFolderMetadata*)b name];
        return [first compare:second options:NSCaseInsensitiveSearch];
    }] mutableCopy];
    NSMutableArray *sortedFiles;
    sortedFiles = [[fileResults sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSString *first = [(FileFolderMetadata*)a name];
        NSString *second = [(FileFolderMetadata*)b name];
        return [first compare:second options:NSCaseInsensitiveSearch];
    }] mutableCopy];
    [sortedFolders addObjectsFromArray:sortedFiles];
    return sortedFolders;
}

+(FileFolderMetadata *) parseMetadata: (NSDictionary *)result {
    FileFolderMetadata *metadata = [[FileFolderMetadata alloc] init];
    metadata.source = [result objectForKey:@"source"];
    metadata.name = [result objectForKey:@"name"];
    metadata.size = [result objectForKey:@"size"];
    metadata.type = [result objectForKey:@"type"];
    metadata.id = [result objectForKey:@"id"];
    
    NSString *lastModified = [result objectForKey:@"last_modified_time"];
    NSDateFormatter *dateFormat1 = [[NSDateFormatter alloc] init];
    [dateFormat1 setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"]; //box
    NSDateFormatter *dateFormat2 = [[NSDateFormatter alloc] init];
    [dateFormat2 setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"]; //google
    NSDateFormatter *dateFormat3 = [[NSDateFormatter alloc] init];
    [dateFormat3 setDateFormat:@"EEE, d MMM yyyy HH:mm:ss ZZZZZ"]; //dropbox
    metadata.lastModifiedTime = [dateFormat1 dateFromString:lastModified];
    if(metadata.lastModifiedTime == nil) {
        metadata.lastModifiedTime = [dateFormat2 dateFromString:lastModified];
        if(metadata.lastModifiedTime == nil) {
            metadata.lastModifiedTime = [dateFormat3 dateFromString:lastModified];
        }
    }
    
    metadata.fileType = [result objectForKey:@"filetype"];
    metadata.url = [result objectForKey:@"url"];
    metadata.token = [result objectForKey:@"token"];
    return metadata;
}
@end
