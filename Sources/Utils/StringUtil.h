//
//
//

#import <Foundation/Foundation.h>

#define kDomainURL @""

struct StringSize {
    int numberOfLine;
    float height;
    float width;
};
typedef struct StringSize StringSize;


@interface StringUtil : NSObject {
    
}


+ (NSString *)removeHTMLTagsFromString:(NSString *)string;
+ (NSString *)serializeString:(NSString *)inputString;
+ (StringSize)getStringSize:(NSString *)string 
                    ofWidth:(float)width 
                    andFont:(UIFont *)font;

+ (BOOL)isValidObject:(id)object;
+ (BOOL)isValidString:(NSString *)inputString;

+ (NSString *)filterPhoneNumber:(NSString *)originalString;

+(NSString *)getTranslationFor:(NSString *)_text;

+(NSString *)getUniqueFilenameFor:(NSURL *)url ;
+ (UIImage*)resizeImageToMaxSize:(CGFloat)max forImage:(UIImage *)inOriginalImage;
+(UIImage*)imageWithImage: (UIImage*) sourceImage scaledToWidth: (float) i_width;
@end

