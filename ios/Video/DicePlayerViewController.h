//
//  DicePlayerViewController.h
//  RCTVideo
//
//  Created by Lukasz on 31/01/2019.
//  Copyright © 2019 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DicePlayerViewController : UIViewController

-(AVPlayerLayer*)getPlayerLayer;
-(void)setPlayer:(AVPlayer*)player playerItem:(AVPlayerItem*)playerItem;

@end

NS_ASSUME_NONNULL_END
