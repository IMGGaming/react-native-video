#import <React/RCTConvert.h>
#import "RCTVideo.h"
#import <React/RCTBridgeModule.h>
#import <React/RCTEventDispatcher.h>
#import <React/UIView+React.h>
#include <MediaAccessibility/MediaAccessibility.h>
#include <AVFoundation/AVFoundation.h>
#include "DiceUtils.h"
#include "DiceBeaconRequest.h"
#include "DiceHTTPRequester.h"

#import <ReactVideoSubtitleSideloader_tvOS/ReactVideoSubtitleSideloader_tvOS-Swift.h>
#import <dice_shield_ios/dice_shield_ios-Swift.h>
@import MuxCoreTv;
@import MUXSDKStatsTv;
@import AVDoris;

static NSString *const playerVersion = @"react-native-video/3.3.1";

@implementation RCTVideo {
    NSNumber* _Nullable _startPlayingAt;

    ActionToken * _actionToken;
    DiceBeaconRequest * _diceBeaconRequst;
    BOOL _diceBeaconRequestOngoing;
    MUXSDKCustomerVideoData * _videoData;
    MUXSDKCustomerPlayerData * _playerData;
}

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher {
    if ((self = [super init])) {
        _diceBeaconRequestOngoing = NO;

        self.player = [IMAPlayer new];
        self.dorisUI = [DorisUIModuleFactory createNativeUIWithPlayer:self.player output:self];
        [self addSubview:self.dorisUI.view];
        [self.dorisUI fillSuperView];
    }
    
    return self;
}

#pragma mark - Prop setters

- (void)setResizeMode:(NSString*)mode {}
- (void)setPlayInBackground:(BOOL)playInBackground {}
- (void)setAllowsExternalPlayback:(BOOL)allowsExternalPlayback {}
- (void)setPlayWhenInactive:(BOOL)playWhenInactive {}
- (void)setIgnoreSilentSwitch:(NSString *)ignoreSilentSwitch {}
- (void)setRate:(float)rate {}
- (void)setMuted:(BOOL)muted {}
- (void)setVolume:(float)volume {}
- (void)setRepeat:(BOOL)repeat {}
- (void)setTextTracks:(NSArray*) textTracks {}
- (void)setFullscreen:(BOOL)fullscreen {}
- (void)setProgressUpdateInterval:(float)progressUpdateInterval {}
- (void)setPaused:(BOOL)paused {}


- (void)setSrc:(NSDictionary *)source {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) 0), dispatch_get_main_queue(), ^{
        // perform on next run loop, otherwise other passed react-props may not be set
        [self playerItemForSource:source withCallback:^(AVPlayerItem * playerItem) {
            id imaObject = [source objectForKey:@"ima"];
            
            if ([imaObject isKindOfClass:NSDictionary.class]) {
                [self setupPlaybackWithAds:imaObject playerItem:playerItem];
            } else {
                PlayerItemSource *source = [[PlayerItemSource alloc] initWithPlayerItem:playerItem];
                [self.dorisUI.input loadWithPlayerItemSource:source startPlayingAt:self->_startPlayingAt];
            }
            
            if (self.onVideoLoadStart) {
                id uri = [source objectForKey:@"uri"];
                id type = [source objectForKey:@"type"];
                self.onVideoLoadStart(@{@"src": @{
                                                  @"uri": uri ? uri : [NSNull null],
                                                  @"type": type ? type : [NSNull null],
                                                  @"isNetwork": [NSNumber numberWithBool:(bool)[source objectForKey:@"isNetwork"]]},
                                          @"target": self.reactTag
                                        });
            }
        }];
    });
}

- (void)setSeek:(NSDictionary *)info {
    NSNumber *seekTime = info[@"time"];
    _startPlayingAt = seekTime;
}


- (void)setControls:(BOOL)controls {
    if (controls) {
        [self.dorisUI.input showControls];
    } else {
        [self.dorisUI.input hideControls];
    }
}


- (void)setupPlaybackWithAds:(NSDictionary *)imaDict playerItem:(AVPlayerItem *)playerItem {
    NSString* __nullable assetKey = [imaDict objectForKey:@"assetKey"];
    NSString* __nullable contentSourceId = [imaDict objectForKey:@"contentSourceId"];
    NSString* __nullable videoId = [imaDict objectForKey:@"videoId"];
    NSString* __nullable authToken = [imaDict objectForKey:@"authToken"];
    
    IMASource* source = [[IMASource alloc] initWithAssetKey:assetKey contentSourceId:contentSourceId videoId:videoId authToken:authToken adTagParameters:nil];
    
    [self.dorisUI.input loadWithImaSource:source startPlayingAt:_startPlayingAt];
}




SubtitleResourceLoaderDelegate* _delegate;
dispatch_queue_t delegateQueue;

- (void)playerItemForSource:(NSDictionary *)source withCallback:(void(^)(AVPlayerItem *))handler {
    bool isNetwork = [RCTConvert BOOL:[source objectForKey:@"isNetwork"]];
    bool isAsset = [RCTConvert BOOL:[source objectForKey:@"isAsset"]];
    NSString *uri = [source objectForKey:@"uri"];
    NSString *type = [source objectForKey:@"type"];
    
    NSURL *url = isNetwork || isAsset
    ? [NSURL URLWithString:uri]
    : [[NSURL alloc] initFileURLWithPath:[[NSBundle mainBundle] pathForResource:uri ofType:type]];
    NSMutableDictionary *assetOptions = [[NSMutableDictionary alloc] init];
        
    [self setupMuxDataFromSource:source];
    
    if (isNetwork) {
        [self setupBeaconFromSource:source];
    }
    
    id drmObject = [source objectForKey:@"drm"];
    if (drmObject) {
        ActionToken* ac = nil;
        if ([drmObject isKindOfClass:NSDictionary.class]) {
            NSDictionary* drmDictionary = drmObject;
            ac = [[ActionToken alloc] initWithDict:drmDictionary contentUrl:uri];
        } else if ([drmObject isKindOfClass:NSString.class]) {
            NSString* drmString = drmObject;
            ac = [ActionToken createFrom: drmString contentUrl:uri];
        }
        if (ac) {
            _actionToken = ac;
            AVURLAsset* asset = [ac urlAsset];
            handler([AVPlayerItem playerItemWithAsset:asset]);
            
            return;
        } else {
            NSLog(@"Failed to created action token for playback.");
        }
    } else {
        // we can try subtitles if it's not a DRM file
        id subtitleObjects = [source objectForKey:@"subtitles"];
        if ([subtitleObjects isKindOfClass:NSArray.class]) {
            NSArray* subs = subtitleObjects;
            NSArray* subtitleTracks = [SubtitleResourceLoaderDelegate createSubtitleTracksFromArray:subs];
            SubtitleResourceLoaderDelegate* delegate = [[SubtitleResourceLoaderDelegate alloc] initWithM3u8URL:url subtitles:subtitleTracks];
            _delegate = delegate;
            url = delegate.redirectURL;
            if (!delegateQueue) {
                delegateQueue = dispatch_queue_create("SubtitleResourceLoaderDelegate", 0);
            }
            AVURLAsset* asset = [AVURLAsset URLAssetWithURL:url options:nil];
            [asset.resourceLoader setDelegate:delegate queue:delegateQueue];
            handler([AVPlayerItem playerItemWithAsset:asset]);
            
            return;
        }
    }
    
    if (isNetwork) {
        NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
        [assetOptions setObject:cookies forKey:AVURLAssetHTTPCookiesKey];
        
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:assetOptions];
        handler([AVPlayerItem playerItemWithAsset:asset]);
        
        return;
    }
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[[NSURL alloc] initFileURLWithPath:[[NSBundle mainBundle] pathForResource:uri ofType:type]] options:nil];
    handler([AVPlayerItem playerItemWithAsset:asset]);
}






#pragma mark - DorisExternalOutputProtocol

- (void)didRequestAdTagParametersFor:(NSTimeInterval)timeInterval {
    if(self.onRequireAdParameters) {
        NSNumber* _timeIntervalSince1970 = [[NSNumber alloc] initWithDouble:timeInterval];
        self.onRequireAdParameters(@{@"date": _timeIntervalSince1970});
    }
}

- (void)didGetPlaybackError {
    if(self.onVideoError) {
        self.onVideoError(@{@"target": self.reactTag});
    }
}

- (void)didChangeCurrentPlaybackTimeWithCurrentTime:(double)currentTime {
    if( currentTime >= 0 && self.onVideoProgress) {
        self.onVideoProgress(@{@"currentTime": [NSNumber numberWithDouble:currentTime]});
    }
}

- (void)didFinishPlayingWithEndTime:(double)endTime {
    if(self.onVideoEnd) {
        self.onVideoEnd(@{@"target": self.reactTag});
    }
}

- (void)didLoadVideo {
    if(self.onVideoLoad) {
        self.onVideoLoad(@{@"target": self.reactTag});
    }
}

- (void)didResumePlayback:(BOOL)isPlaying {
    if (isPlaying) {
        self.onPlaybackRateChange(@{@"playbackRate": [NSNumber numberWithFloat:1.0],
                                    @"target": self.reactTag});
        [self startDiceBeaconCallsAfter:0];
    } else {
        self.onPlaybackRateChange(@{@"playbackRate": [NSNumber numberWithFloat:0.0],
                                    @"target": self.reactTag});
        [_diceBeaconRequst cancel];
    }
}

- (void)didStartBuffering {
    if (self.onVideoBuffer) {
        self.onVideoBuffer(@{@"isBuffering": @(YES), @"target": self.reactTag});
    }
}

- (void)didFinishBuffering {
    if (self.onVideoBuffer) {
        self.onVideoBuffer(@{@"isBuffering": @(NO), @"target": self.reactTag});
    }
}



#pragma mark - Lifecycle
- (void)dealloc
{
    if (_playerData || _videoData) {
        [MUXSDKStats destroyPlayer:@"dicePlayer"];
        _playerData = nil;
        _videoData = nil;
    }
    
    [_diceBeaconRequst cancel];
    _diceBeaconRequst = nil;
}










#pragma mark - DICE Beacon

- (void)startDiceBeaconCallsAfter:(long)seconds {
    [self startDiceBeaconCallsAfter:seconds ongoing:NO];
}

- (void)startDiceBeaconCallsAfter:(long)seconds ongoing:(BOOL)ongoing {
    if (_diceBeaconRequst == nil) {
        return;
    }
    if (_diceBeaconRequestOngoing && !ongoing) {
        DICELog(@"startDiceBeaconCallsAfter ONGOING request. INGNORING.");
        return;
    }
    _diceBeaconRequestOngoing = YES;
    DICELog(@"startDiceBeaconCallsAfter %ld", seconds);
    __weak RCTVideo *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // in case there is ongoing request
        [_diceBeaconRequst cancel];
        [_diceBeaconRequst makeRequestWithCompletionHandler:^(DiceBeaconResponse *response, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf handleBeaconResponse:response error:error];
            });
        }];
    });
}

-(void)handleBeaconResponse:(DiceBeaconResponse *)response error:(NSError *)error {
    DICELog(@"handleBeaconResponse error=%@", error);
    if (self.player.timeControlStatus == AVPlayerTimeControlStatusPaused) {
        // video is not playing back, so no point
        DICELog(@"handleBeaconResponse player is paused. STOP beacons.");
        _diceBeaconRequestOngoing = NO;
        return;
    }
    
    if (error != nil) {
        DICELog(@"handleBeaconResponse error on call. STOP beacons.");
        // raise an error and stop playback
        NSNumber *code = [[NSNumber alloc] initWithInt:-1];
        self.onVideoError(@{@"error": @{@"code": code,
                                        @"domain": @"DiceBeacon",
                                        @"messages": @[@"Failed to make beacon request", error.localizedDescription]
        },
                            @"rawError": RCTJSErrorFromNSError(error),
                            @"target": self.reactTag});
        _diceBeaconRequestOngoing = NO;
        return;
    }
    
    if (response == nil || !response.OK) {
        // raise an error and stop playback
        NSNumber *code = [[NSNumber alloc] initWithInt:-2];
        NSString *rawResponse = @"";
        NSArray<NSString *> *errorMessages = @[];
        if (response != nil) {
            if (response.rawResponse != nil && response.rawResponse.length > 0) {
                rawResponse = [NSString stringWithUTF8String:[response.rawResponse bytes]];
            }
            if (rawResponse == nil) {
                rawResponse = @"";
            }
            if (response.errorMessages != nil) {
                errorMessages = response.errorMessages;
            }
        }
        self.onVideoError(@{@"error": @{@"code": code,
                                        @"domain": @"DiceBeacon",
                                        @"messages": errorMessages
        },
                            @"rawResponse": rawResponse,
                            @"target": self.reactTag});
        [self setPaused:YES];
        _diceBeaconRequestOngoing = NO;
        return;
    }
    [self startDiceBeaconCallsAfter:response.frequency ongoing:YES];
}

- (void)setupBeaconFromSource:(NSDictionary *)source {
    id configObject = [source objectForKey:@"config"];
    id beaconObject = nil;
    if (configObject != nil && [configObject isKindOfClass:NSDictionary.class]) {
        beaconObject = [((NSDictionary *)configObject) objectForKey:@"beacon"];
    }
    
    if (beaconObject != nil) {
        if ([beaconObject isKindOfClass:NSString.class]) {
            NSString * beaconString = beaconObject;
            NSError *error = nil;
            beaconObject = [NSJSONSerialization JSONObjectWithData:[beaconString dataUsingEncoding:kCFStringEncodingUTF8]  options:0 error:&error];
            if (error != nil) {
                DICELog(@"Failed to create JSON object from provided beacon: %@", beaconString);
            }
        }
        if ([beaconObject isKindOfClass:NSDictionary.class]) {
            NSDictionary *beacon = beaconObject;
            NSString* url = [beacon objectForKey:@"url"];
            NSDictionary<NSString *, NSString *> *headers = [beacon objectForKey:@"headers"];
            NSDictionary* body = [beacon objectForKey:@"body"];
            _diceBeaconRequst = [DiceBeaconRequest requestWithURLString:url headers:headers body:body];
            [self startDiceBeaconCallsAfter:0];
        } else {
            DICELog(@"Failed to read dictionary object provided beacon: %@", beaconObject);
        }
    }
}







#pragma mark - Mux Data
- (NSString * _Nullable)stringFromDict:(NSDictionary *)dict forKey:(id _Nonnull)key {
    id obj = [dict objectForKey:key];
    if (obj != nil && [obj isKindOfClass:NSString.class]) {
        return obj;
    }
    return nil;
}

- (void)setupMuxDataFromSource:(NSDictionary *)source {
    id configObject = [source objectForKey:@"config"];
    id muxData = nil;
    if (configObject != nil && [configObject isKindOfClass:NSDictionary.class]) {
        muxData = [((NSDictionary *)configObject) objectForKey:@"muxData"];
    }
    
    if (muxData != nil) {
        if ([muxData isKindOfClass:NSString.class]) {
            NSString * muxDataString = muxData;
            NSError *error = nil;
            muxData = [NSJSONSerialization JSONObjectWithData:[muxDataString dataUsingEncoding:kCFStringEncodingUTF8]  options:0 error:&error];
            if (error != nil) {
                DICELog(@"Failed to create JSON object from provided playbackData: %@", muxDataString);
            }
        }
        if ([muxData isKindOfClass:NSDictionary.class]) {
            NSDictionary *muxDict = muxData;
            
            NSString* envKey = [muxDict objectForKey:@"envKey"];
            if (envKey == nil) {
                DICELog(@"envKey is not present. Mux will not be available.");
                return;
            }
            
            NSString *value = nil;
            // Video metadata (cleared with videoChangeForPlayer:withVideoData:)
            BOOL isReplace = NO;
            if (_videoData != nil) {
                isReplace = YES;
            } else {
                // Environment and player data that persists until the player is destroyed
                _playerData = [[MUXSDKCustomerPlayerData alloc] initWithEnvironmentKey:envKey];
                // ...insert player metadata
                value = [self stringFromDict:muxDict forKey:@"viewerUserId"];
                [_playerData setViewerUserId:value];
                
                [_playerData setPlayerVersion:playerVersion];
                
                [_playerData setPlayerName:@"react-native-video/dice"];
                
                value = [self stringFromDict:muxDict forKey:@"subPropertyId"];
                [_playerData setSubPropertyId:value];
                
                value = [self stringFromDict:muxDict forKey:@"experimentName"];
                [_playerData setExperimentName:value];
            }
            
            _videoData = [MUXSDKCustomerVideoData new];
            
            // ...insert video metadata
            value = [self stringFromDict:muxDict forKey:@"videoTitle"];
            [_videoData setVideoTitle:value];
            
            value = [self stringFromDict:muxDict forKey:@"videoId"];
            [_videoData setVideoId:value];
            
            value = [self stringFromDict:muxDict forKey:@"videoSeries"];
            [_videoData setVideoSeries:value];
            
            value = [self stringFromDict:muxDict forKey:@"videoCdn"];
            [_videoData setVideoCdn:value];
            
            id videoIsLive = [muxDict objectForKey:@"videoIsLive"];
            if (videoIsLive != nil && [videoIsLive isKindOfClass:NSNumber.class]) {
                NSNumber* num = videoIsLive;
                [_videoData setVideoIsLive:num];
            } else {
                [_videoData setVideoIsLive:nil];
            }
            
            id videoDuration = [muxDict objectForKey:@"videoDuration"];
            if (videoDuration != nil && [videoDuration isKindOfClass:NSNumber.class]) {
                [_videoData setVideoDuration:((NSNumber*)videoDuration)];
            } else {
                [_videoData setVideoDuration:nil];
            }
            
            value = [self stringFromDict:muxDict forKey:@"videoStreamType"];
            [_videoData setVideoStreamType:value];
            
            
            if (isReplace) {
                [MUXSDKStats videoChangeForPlayer:@"dicePlayer" withVideoData:_videoData];
            } else {
                [self setupMux];
            }
        } else {
            DICELog(@"Failed to read dictionary object provided playbackData: %@", muxData);
        }
    }
}

- (void)setupMux {
    if (_playerData == nil || _videoData == nil) {
        return;
    }
    
    if (self.dorisUI.playerLayer != nil) {
        [MUXSDKStats monitorAVPlayerLayer:self.dorisUI.playerLayer withPlayerName:@"dicePlayer" playerData:_playerData videoData:_videoData];
    } else if (self.dorisUI.playerViewController != nil) {
        [MUXSDKStats monitorAVPlayerViewController:self.dorisUI.playerViewController withPlayerName:@"dicePlayer" playerData:_playerData videoData:_videoData];
    }
}

@end

