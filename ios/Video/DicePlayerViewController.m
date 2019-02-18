//
//  DicePlayerViewController.m
//  RCTVideo
//
//  Created by Lukasz on 31/01/2019.
//  Copyright © 2019 Facebook. All rights reserved.
//

#import "DicePlayerViewController.h"

static NSString *const player_statusKeyPath = @"status";
static NSString *const player_playbackLikelyToKeepUpKeyPath = @"playbackLikelyToKeepUp";
static NSString *const player_playbackBufferEmptyKeyPath = @"playbackBufferEmpty";
static NSString *const player_readyForDisplayKeyPath = @"readyForDisplay";
static NSString *const player_playbackRate = @"rate";
static NSString *const player_timedMetadata = @"timedMetadata";

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
AVPlayerItem* _playerItem;
BOOL _playerItemObserversSet;
BOOL _playbackStalled;

id _timeObserver;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _playerItemObserversSet = NO;
        _playbackStalled = NO;
    }
    return self;
}

-(void)setPlayer:(AVPlayer*)player playerItem:(AVPlayerItem*)playerItem {
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    _playerLayer.frame = self.view.bounds;
    _playerLayer.needsDisplayOnBoundsChange = YES;
    [self removePlayerItemObservers];
    _playerItem = playerItem;
//    UIView* newView = [[UIView alloc] initWithFrame:self.view.bounds];
//    [newView.layer addSublayer:_playerLayer];
//    newView.layer.needsDisplayOnBoundsChange = YES;
    [self.view.layer insertSublayer:_playerLayer atIndex:0];
//    [self.view.layer addSublayer:_playerLayer];
    self.view.layer.needsDisplayOnBoundsChange = YES;
    [self addPlayerItemObservers];
}

-(AVPlayerLayer*)getPlayerLayer {
    return _playerLayer;
}

- (void)addPlayerItemObservers
{
    [_playerItem addObserver:self forKeyPath:player_statusKeyPath options:0 context:nil];
    [_playerItem addObserver:self forKeyPath:player_playbackBufferEmptyKeyPath options:0 context:nil];
    [_playerItem addObserver:self forKeyPath:player_playbackLikelyToKeepUpKeyPath options:0 context:nil];
    [_playerItem addObserver:self forKeyPath:player_timedMetadata options:NSKeyValueObservingOptionNew context:nil];
    _playerItemObserversSet = YES;
}

/* Fixes https://github.com/brentvatne/react-native-video/issues/43
 * Crashes caused when trying to remove the observer when there is no
 * observer set */
- (void)removePlayerItemObservers
{
    if (_playerItemObserversSet) {
        [_playerItem removeObserver:self forKeyPath:player_statusKeyPath];
        [_playerItem removeObserver:self forKeyPath:player_playbackBufferEmptyKeyPath];
        [_playerItem removeObserver:self forKeyPath:player_playbackLikelyToKeepUpKeyPath];
        [_playerItem removeObserver:self forKeyPath:player_timedMetadata];
        _playerItemObserversSet = NO;
    }
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

float _playbackRate;

- (IBAction)didChangeSeekBarValue:(UISlider*)sender {
    [self.currentTime setText:[self getTimeStringWith:sender.value]];
//    CMTime time = CMTimeMakeWithSeconds(sender.value, 1);
//    [self stopPlayingAndSeekSmoothlyToTime:time];
}

- (IBAction)timeSliderBeganTracking:(UISlider *)sender {
    _playbackRate = _playerLayer.player.rate;
    [_playerLayer.player pause];
    [self removePlayerTimeObserver];
}

- (IBAction)timeSliderEndedTrackingInside:(UISlider *)sender {
    CMTime time = CMTimeMakeWithSeconds(sender.value, 1);
    [self stopPlayingAndSeekSmoothlyToTime:time];
    [self addPlayerTimeObserver];
}

- (IBAction)timeSliderEndedTrackingOutside:(UISlider *)sender {
    CMTime time = CMTimeMakeWithSeconds(sender.value, 1);
    [self stopPlayingAndSeekSmoothlyToTime:time];
    [self addPlayerTimeObserver];
}





- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _playerItem) {
        // When timeMetadata is read the event onTimedMetadata is triggered
        if ([keyPath isEqualToString:player_timedMetadata]) {
            NSArray<AVMetadataItem *> *items = [change objectForKey:@"new"];
            if (items && ![items isEqual:[NSNull null]] && items.count > 0) {
                NSMutableArray *array = [NSMutableArray new];
                for (AVMetadataItem *item in items) {
                    NSString *value = (NSString *)item.value;
                    NSString *identifier = item.identifier;
                    
                    if (![value isEqual: [NSNull null]]) {
                        NSDictionary *dictionary = [[NSDictionary alloc] initWithObjects:@[value, identifier] forKeys:@[@"value", @"identifier"]];
                        
                        [array addObject:dictionary];
                    }
                }
                

            }
        }
        
        if ([keyPath isEqualToString:player_statusKeyPath]) {
            // Handle player item status change.
            if (_playerItem.status == AVPlayerItemStatusReadyToPlay) {
                float duration = CMTimeGetSeconds(_playerItem.asset.duration);
                float currentTime = CMTimeGetSeconds(_playerItem.currentTime);
                if (isnan(duration)) {
                    duration = 0.0;
                }
                
                if (isnan(currentTime)) {
                    currentTime = 0.0;
                }
                
                [self.seekBar setMaximumValue:duration];
                if (!isSeekInProgress) {
                    [self.seekBar setValue:currentTime];
                }
                [self addPlayerItemObservers];
                [self setDuration:duration];
                
                NSObject *width = @"undefined";
                NSObject *height = @"undefined";
                NSString *orientation = @"undefined";
                
                if ([_playerItem.asset tracksWithMediaType:AVMediaTypeVideo].count > 0) {
                    AVAssetTrack *videoTrack = [[_playerItem.asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
                    width = [NSNumber numberWithFloat:videoTrack.naturalSize.width];
                    height = [NSNumber numberWithFloat:videoTrack.naturalSize.height];
                    CGAffineTransform preferredTransform = [videoTrack preferredTransform];
                    
                    if ((videoTrack.naturalSize.width == preferredTransform.tx
                         && videoTrack.naturalSize.height == preferredTransform.ty)
                        || (preferredTransform.tx == 0 && preferredTransform.ty == 0))
                    {
                        orientation = @"landscape";
                    } else {
                        orientation = @"portrait";
                    }
                }
                
//                if (self.onVideoLoad && _videoLoadStarted) {
//                    self.onVideoLoad(@{@"duration": [NSNumber numberWithFloat:duration],
//                                       @"currentTime": [NSNumber numberWithFloat:CMTimeGetSeconds(_playerItem.currentTime)],
//                                       @"canPlayReverse": [NSNumber numberWithBool:_playerItem.canPlayReverse],
//                                       @"canPlayFastForward": [NSNumber numberWithBool:_playerItem.canPlayFastForward],
//                                       @"canPlaySlowForward": [NSNumber numberWithBool:_playerItem.canPlaySlowForward],
//                                       @"canPlaySlowReverse": [NSNumber numberWithBool:_playerItem.canPlaySlowReverse],
//                                       @"canStepBackward": [NSNumber numberWithBool:_playerItem.canStepBackward],
//                                       @"canStepForward": [NSNumber numberWithBool:_playerItem.canStepForward],
//                                       @"naturalSize": @{
//                                               @"width": width,
//                                               @"height": height,
//                                               @"orientation": orientation
//                                               },
//                                       @"audioTracks": [self getAudioTrackInfo],
//                                       @"textTracks": [self getTextTrackInfo],
//                                       @"target": self.reactTag});
//                }
//                _videoLoadStarted = NO;
                
                [self attachListeners];
                if (!_timeObserver) {
                    [self addPlayerTimeObserver];
                }
                
            } else if (_playerItem.status == AVPlayerItemStatusFailed) {
//                self.onVideoError(@{@"error": @{@"code": [NSNumber numberWithInteger: _playerItem.error.code],
//                                                @"domain": _playerItem.error.domain},
//                                    @"target": self.reactTag});
            }
        } else if ([keyPath isEqualToString:player_playbackBufferEmptyKeyPath]) {
//            _playerBufferEmpty = YES;
//            self.onVideoBuffer(@{@"isBuffering": @(YES), @"target": self.reactTag});
        } else if ([keyPath isEqualToString:player_playbackLikelyToKeepUpKeyPath]) {
            // Continue playing (or not if paused) after being paused due to hitting an unbuffered zone.
//            if ((!(_controls || _fullscreenPlayerPresented) || _playerBufferEmpty) && _playerItem.playbackLikelyToKeepUp) {
//                [self setPaused:_paused];
//            }
//            _playerBufferEmpty = NO;
//            self.onVideoBuffer(@{@"isBuffering": @(NO), @"target": self.reactTag});
        }
    } else if (object == _playerLayer) {
        if([keyPath isEqualToString:player_readyForDisplayKeyPath] && [change objectForKey:NSKeyValueChangeNewKey]) {
            if([change objectForKey:NSKeyValueChangeNewKey] ) {
//                self.onReadyForDisplay(@{@"target": self.reactTag});
            }
        }
    } else if (object == _playerLayer.player) {
        if([keyPath isEqualToString:player_playbackRate]) {
//            if(self.onPlaybackRateChange) {
//                self.onPlaybackRateChange(@{@"playbackRate": [NSNumber numberWithFloat:_player.rate],
//                                            @"target": self.reactTag});
//            }
            if(_playerLayer.player.rate > 0) {
//                [self startDiceBeaconCallsAfter:0];
            } else {
//                [_diceBeaconRequst cancel];
            }
            if(_playbackStalled && _playerLayer.player.rate > 0) {
//                if(self.onPlaybackResume) {
//                    self.onPlaybackResume(@{@"playbackRate": [NSNumber numberWithFloat:_player.rate],
//                                            @"target": self.reactTag});
//                }
                _playbackStalled = NO;
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


- (void)attachListeners
{
    // listen for end of file
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:[_playerLayer.player currentItem]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[_playerLayer.player currentItem]];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemPlaybackStalledNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackStalled:)
                                                 name:AVPlayerItemPlaybackStalledNotification
                                               object:nil];
}

- (void)playbackStalled:(NSNotification *)notification
{
//    if(self.onPlaybackStalled) {
//        self.onPlaybackStalled(@{@"target": self.reactTag});
//    }
    _playbackStalled = YES;
}

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
//    if(self.onVideoEnd) {
//        self.onVideoEnd(@{@"target": self.reactTag});
//    }
    
//    if (_repeat) {
//        AVPlayerItem *item = [notification object];
//        [item seekToTime:kCMTimeZero];
//        [self applyModifiers];
//    } else {
//        [self removePlayerTimeObserver];
//    }
}

-(void)setDuration:(float)duration {
    [self.totalTime setText: [self getTimeStringWith:duration]];
}

-(void)updateCurrentTime:(float)currentTime {
    [self.currentTime setText:[self getTimeStringWith:currentTime]];
    [self.seekBar setValue:currentTime];
}

-(NSString*)getTimeStringWith:(float)seconds {
    int hours = (int)(seconds / 3600);
    int minutes = (int)((seconds - hours*3600)/60);
    int secs = (int)(seconds - (hours*3600 + minutes*60));
    return [NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, secs];
}

-(void)addPlayerTimeObserver
{
    const Float64 progressUpdateIntervalMS = 0.25;
    // @see endScrubbing in AVPlayerDemoPlaybackViewController.m
    // of https://developer.apple.com/library/ios/samplecode/AVPlayerDemo/Introduction/Intro.html
    __weak DicePlayerViewController *weakSelf = self;
    _timeObserver = [_playerLayer.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(progressUpdateIntervalMS, NSEC_PER_SEC)
                                                          queue:NULL
                                                     usingBlock:^(CMTime time) { [weakSelf notifyProgressUpdate]; }
                     ];
}

- (void)notifyProgressUpdate {
    if (isSeekInProgress) {
        return;
    }
    float currentTime = CMTimeGetSeconds(_playerItem.currentTime);
    if (isnan(currentTime)) {
        currentTime = 0.0;
    }
    [self updateCurrentTime:currentTime];
}

/* Cancels the previously registered time observer. */
-(void)removePlayerTimeObserver
{
    if (_timeObserver)
    {
        [_playerLayer.player removeTimeObserver:_timeObserver];
        _timeObserver = nil;
    }
}

- (void)dealloc
{
    [self removePlayerItemObservers];
    [self removePlayerTimeObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _playerLayer.player = nil;
    _playerLayer = nil;
    
}

#pragma mark - Seekbar

CMTime chaseTime;
CMTime newChaseTime;
BOOL isSeekInProgress;

- (void)stopPlayingAndSeekSmoothlyToTime:(CMTime)newChaseTime
{
    [_playerLayer.player pause];
    
    if (CMTimeCompare(newChaseTime, chaseTime) != 0)
    {
        chaseTime = newChaseTime;
        
        if (!isSeekInProgress)
        {
            [self trySeekToChaseTime];
        }
    }
}




-(void) trySeekToChaseTime
{
    if (_playerItem.status == AVPlayerItemStatusUnknown)
    {
        // wait until item becomes ready (KVO player.currentItem.status)
    }
    else if (_playerItem.status == AVPlayerItemStatusReadyToPlay)
    {
        [self actuallySeekToTime];
    }
}


-(void) actuallySeekToTime
{
    isSeekInProgress = YES;
    CMTime seekTimeInProgress = chaseTime;
    [_playerLayer.player seekToTime:seekTimeInProgress toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        if (CMTimeCompare(seekTimeInProgress, chaseTime) == 0) {
            isSeekInProgress = NO;
            if (_playbackRate > 0) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [_playerLayer.player play];
                });
            }
        } else {
            [self trySeekToChaseTime];
        }
    }];
}

@end
