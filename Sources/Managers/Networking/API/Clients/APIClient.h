#import <Foundation/Foundation.h>

#import "BaseJSONClient.h"
#import "Account.h"

// avoids warnings
@protocol APIClient;

@interface APIClient: BaseJSONClient <APIAccessClient>
{
    Account *account;
}
@end
