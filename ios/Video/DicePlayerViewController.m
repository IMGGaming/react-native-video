//
//  DicePlayerViewController.m
//  RCTVideo
//
//  Created by Lukasz on 31/01/2019.
//  Copyright © 2019 Facebook. All rights reserved.
//

#import "DicePlayerViewController.h"

@interface DicePlayerViewController ()
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UISlider *seekBar;
@property (weak, nonatomic) IBOutlet UILabel *currentTime;
@property (weak, nonatomic) IBOutlet UILabel *totalTime;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *rewindButton;
@property (weak, nonatomic) IBOutlet UIButton *forwardButton;

@end

@implementation DicePlayerViewController

AVPlayerLayer* _playerLayer;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)setPlayer:(AVPlayer*)player {
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    _playerLayer.frame = self.view.bounds;
    _playerLayer.needsDisplayOnBoundsChange = YES;
//    UIView* newView = [[UIView alloc] initWithFrame:self.view.bounds];
//    [newView.layer addSublayer:_playerLayer];
//    newView.layer.needsDisplayOnBoundsChange = YES;
    [self.view.layer insertSublayer:_playerLayer atIndex:0];
//    [self.view.layer addSublayer:_playerLayer];
    self.view.layer.needsDisplayOnBoundsChange = YES;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Playback controll buttons

- (IBAction)didTapRewindButton:(UIButton *)sender {
    NSTimeInterval currentTime = CMTimeGetSeconds([_playerLayer.player currentTime]);
    NSTimeInterval newTime = currentTime - 15;
    if (newTime < 0) {
        newTime = 0;
    }
    
    CMTime seekToTime = CMTimeMake(newTime * 1000, 1000);
    
    AVPlayer *player = _playerLayer.player;
    
    [_playerLayer.player seekToTime:seekToTime completionHandler:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [player play];
        });
        
    }];
    
    
    
}

- (IBAction)didTapPlayPauseButton:(UIButton *)sender {
    if (!_playerLayer) {
        return;
    }
    if (_playerLayer.player.rate > 0) {
        [_playerLayer.player pause];
    } else {
        [_playerLayer.player play];
    }
        
}

- (IBAction)didTapForwardButton:(UIButton *)sender {
    
    NSTimeInterval mediaDuration = CMTimeGetSeconds(_playerLayer.player.currentItem.duration);
    NSTimeInterval currentTime = CMTimeGetSeconds([_playerLayer.player currentTime]);
    NSTimeInterval newTime = currentTime + 15;
    if (newTime > mediaDuration) {
        return;
    }
    
    CMTime seekToTime = CMTimeMake(newTime * 1000, 1000);
    
    [_playerLayer.player seekToTime:seekToTime completionHandler:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_playerLayer.player play];
        });
        
    }];
}

@end
