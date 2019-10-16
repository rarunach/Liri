//
//
//

#import <Foundation/Foundation.h>
#import "DataUtility.h"

extern NSString const *kRequestArrayFilePath;
extern NSString const *kMSRequestArrayFilePath;

extern NSString const *kname;
extern NSString const *kimage;

#define FS_ACC_TOKEN @"access_token"
#define FS_ACC_SECRET @"access_secret"

#define DEVICE_IS_IPHONE (UIUserInterfaceIdiomPhone == [DataUtility getCurrentUserInterfaceIdiom])
#define DEVICE_IS_IPAD (UIUserInterfaceIdiomPad == [DataUtility getCurrentUserInterfaceIdiom])


@interface Constants : NSObject {
    
}

@end