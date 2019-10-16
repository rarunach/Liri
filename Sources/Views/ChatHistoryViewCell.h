#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ChatHistoryViewCell: UITableViewCell

@property (nonatomic, strong) NSNumber *unreadMessages;
@property (nonatomic, strong) NSDate *lastDate;

+ (CGFloat)getCellHeight;


@end
