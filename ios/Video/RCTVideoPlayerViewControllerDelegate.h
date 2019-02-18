#import <Foundation/Foundation.h>
#import "AVKit/AVKit.h"

@protocol RCTVideoPlayerViewControllerDelegate <NSObject>
- (void)videoPlayerViewControllerWillDismiss:(UIViewController *)playerViewController;
- (void)videoPlayerViewControllerDidDismiss:(UIViewController *)playerViewController;
@end
