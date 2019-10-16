#import "AFJSONRequestOperation.h"

#import "DDLog.h"
#import "DDTTYLogger.h"

#import "NSString+URLEncoding.h"
#import "AppConstants.h"
#import "BaseJSONClient.h"

static NSString *const kKeyValuePair = @"%@=%@";
static NSString *const kPairDelimiter = @"&";

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_WARN;
#endif

@implementation BaseJSONClient

#pragma mark -
#pragma mark NSObject

- (id)init
{
    if ((self = [super init]) != nil) {
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
        // Configure logging framework
        //[DDLog addLogger:[DDTTYLogger sharedInstance]];
    }
    return self;
}

#pragma mark -
#pragma mark <APIClient>

@synthesize success;
@synthesize failure;
@synthesize successJSON;
@synthesize failureJSON;

- (void)postToURL:(NSURL *)url
       parameters:(NSDictionary *)parameters;
{
    [self postToURL:url parameters:parameters
         withMethod:DEFAULT_PARAMETER_METHOD];
}

- (void)postToURL:(NSURL *)url
       parameters:(NSDictionary *)parameters
       withMethod:(NSString *)method
{
    NSMutableArray *queryArray = [NSMutableArray array];

    for (NSString *key in [parameters allKeys]) {
        NSString *pair =
            [NSString stringWithFormat:kKeyValuePair, key,
            [parameters[key] URLEncodedString]];

        [queryArray addObject:pair];
    }

    NSString *query = [queryArray componentsJoinedByString:kPairDelimiter];
    NSData *queryData = [query dataUsingEncoding:NSUTF8StringEncoding];
    NSString *postLength =
        [NSString stringWithFormat:@"%d", [queryData length]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    [request setHTTPMethod:method];
    [request setHTTPBody:queryData];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded"
        forHTTPHeaderField:@"Current-Type"];
    [self sendRequest:request success:self.success failure:self.failure];
}

- (void)postToURL:(NSURL *)url
       parameters:(NSDictionary *)parameters
       withMethod:(NSString *)method
       servertoken:(NSString *)token
{
    NSMutableArray *queryArray = [NSMutableArray array];
    
    for (NSString *key in [parameters allKeys]) {
        NSString *pair =
        [NSString stringWithFormat:kKeyValuePair, key,
         [parameters[key] URLEncodedString]];
        
        [queryArray addObject:pair];
    }
    
    NSString *query = [queryArray componentsJoinedByString:kPairDelimiter];
    NSData *queryData = [query dataUsingEncoding:NSUTF8StringEncoding];
    NSString *postLength =
    [NSString stringWithFormat:@"%d", [queryData length]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    [request setHTTPMethod:method];
    [request setHTTPBody:queryData];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded"
   forHTTPHeaderField:@"Current-Type"];
    
    if (token) {
        NSString *bearer = @"Bearer ";
        [request setValue:[bearer stringByAppendingString:token] forHTTPHeaderField:@"Authorization"];
    }

    [self sendRequest:request success:self.success failure:self.failure];
}

- (void)postToURLMultipartFormdata:(NSURL *)url
                        parameters:(NSArray *)params
                       servertoken:(NSString *)token
{
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:@"" parameters:nil constructingBodyWithBlock:^(id <AFMultipartFormData>formData) {
        
        for (int i = 0; i < params.count; i++) {
            
            if (params[i][@"mimetype"] != nil) {
                [formData appendPartWithFileData:params[i][@"data"]
                                    name:params[i][@"paramname"]
                                fileName:params[i][@"filename"] mimeType:params[i][@"mimetype"]];
            } else {
                [formData appendPartWithFormData:[params[i][@"value"] dataUsingEncoding:NSUTF8StringEncoding]
                                    name:params[i][@"paramname"]];
            }
        
        }
    }];
    
    if (token) {
        NSString *bearer = @"Bearer ";
        [request setValue:[bearer stringByAppendingString:token] forHTTPHeaderField:@"Authorization"];
    }
    [self sendRequest:request success:self.success failure:self.failure];
}

- (void)postToURLWithJSON:(NSURL *)url
               parameters:(NSDictionary *)params
               withMethod:(NSString *)method
               servertoken:(NSString *)token
{
    NSLog(@"postToURLWithJSON:%@, %@", [url relativePath], params);
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    httpClient.parameterEncoding = AFJSONParameterEncoding;
    NSMutableURLRequest *request = [httpClient requestWithMethod:method path:@"" parameters:params];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    if (token) {
        NSString *bearer = @"Bearer ";
        [request setValue:[bearer stringByAppendingString:token] forHTTPHeaderField:@"Authorization"];
    }
    [self sendRequestJSON:request success:self.successJSON
                               failure:self.failureJSON];
}

- (void)sendRequest:(NSURLRequest *)request
                      success:(ClientSuccessBlock)successBlock
                      failure:(ClientFailureBlock)failureBlock
{
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            //DDLogVerbose(@"%@: %@ - Output:\n%@", THIS_FILE, THIS_METHOD, responseObject);
            NSString *stringResponse = [[NSString alloc] initWithData:responseObject
                                                         encoding:NSUTF8StringEncoding];
        if (successBlock != NULL)
            successBlock(request, stringResponse);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogVerbose(@"%@: %@ \nNSError:\n%@", THIS_FILE,
                     THIS_METHOD, error);
            if (failureBlock != NULL)
            failureBlock(request, error);
        }];
    
        [operation start];
}

- (void)sendRequestJSON:(NSURLRequest *)request
            success:(ClientSuccessBlockJSON)successBlock
            failure:(ClientFailureBlockJSON)failureBlock
{
        AFJSONRequestOperation *operation = [AFJSONRequestOperation
                                             JSONRequestOperationWithRequest:request
                            success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
        {
            //NSLog(@"ResponseJSON:\n%@", JSON);
            if (successBlock != NULL)
                successBlock(request, JSON);
        }
        failure:^(NSURLRequest *request, NSHTTPURLResponse *response,
            NSError *error, id JSON)
        {
            NSLog(@"Failure ResponseJSON:\n%@", JSON);
            if (failureBlock != NULL)
                failureBlock(request, JSON);
        }];
        [operation start];
}
@end
