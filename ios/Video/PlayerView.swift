//
//  RNPlayerView.swift
//  RNDReactNativeDiceVideo
//
//  Created by Yaroslav Lvov on 05.03.2021.
//

import AVDoris
import AVKit

class PlayerView: UIView {
    private var controller: PlayerViewController
    
    //Events
    @objc var onBackButton: RCTBubblingEventBlock?
    @objc var onFavouriteButton: RCTBubblingEventBlock?
    @objc var onVideoLoadStart: RCTBubblingEventBlock?
    @objc var onVideoLoad: RCTBubblingEventBlock?
    @objc var onVideoBuffer: RCTBubblingEventBlock?
    @objc var onVideoError: RCTBubblingEventBlock?
    @objc var onVideoProgress: RCTBubblingEventBlock?
    @objc var onVideoSeek: RCTBubblingEventBlock?
    @objc var onVideoEnd: RCTBubblingEventBlock?
    @objc var onTimedMetadata: RCTBubblingEventBlock?
    @objc var onVideoAudioBecomingNoisy: RCTBubblingEventBlock?
    @objc var onVideoFullscreenPlayerWillPresent: RCTBubblingEventBlock?
    @objc var onVideoFullscreenPlayerDidPresent: RCTBubblingEventBlock?
    @objc var onVideoFullscreenPlayerWillDismiss: RCTBubblingEventBlock?
    @objc var onVideoFullscreenPlayerDidDismiss: RCTBubblingEventBlock?
    @objc var onReadyForDisplay: RCTBubblingEventBlock?
    @objc var onPlaybackStalled: RCTBubblingEventBlock?
    @objc var onPlaybackResume: RCTBubblingEventBlock?
    @objc var onPlaybackRateChange: RCTBubblingEventBlock?
    @objc var onRequireAdParameters: RCTBubblingEventBlock?
    @objc var onVideoAboutToEnd: RCTBubblingEventBlock?
    @objc var onFavouriteButtonClick: RCTBubblingEventBlock?
    @objc var onRelatedVideoClicked: RCTBubblingEventBlock?
    @objc var onRelatedVideosIconClicked: RCTBubblingEventBlock?
    @objc var onStatsIconClick: RCTBubblingEventBlock?
    @objc var onEpgIconClick: RCTBubblingEventBlock?
    
    //Props
    @objc var src: NSDictionary? { didSet { controller.source = try? Source(dict: src) } }
    @objc var partialVideoInformation: NSDictionary? { didSet { controller.partialVideoInformation = try? PartialVideoInformation(dict: partialVideoInformation) } }
    @objc var translations: NSDictionary? { didSet { controller.translations = translations } }
    @objc var buttons: NSDictionary? { didSet { controller.buttons = try? Buttons(dict: buttons) } }
    @objc var theme: NSDictionary? { didSet { controller.theme = try? Theme(dict: theme) } }
    @objc var selectedTextTrack: NSDictionary?
    @objc var selectedAudioTrack: NSDictionary?
    @objc var seek: NSDictionary?
    @objc var relatedVideos: NSDictionary? { didSet { controller.relatedVideos = try? RelatedVideos(dict: relatedVideos) } }
    @objc var metadata: NSDictionary?  { didSet { controller.metadata = DorisUIMetadataConfiguration.create(from: metadata ?? [:]) } }
    @objc var playNextSource: NSDictionary?
    @objc var playlist: NSDictionary?
    @objc var annotations: NSArray?
    @objc var playNextSourceTimeoutMillis: NSNumber?
    @objc var resizeMode: NSString?
    @objc var textTracks: NSArray?
    @objc var ignoreSilentSwitch: NSString?
    @objc var volume: NSNumber?
    @objc var rate: NSNumber?
    @objc var currentTime: NSNumber?
    @objc var progressUpdateInterval: NSNumber?

    @objc var isFavourite: Bool = false { didSet { controller.isFavourite = isFavourite } }
    @objc var isFullScreen: Bool = false
    @objc var allowAirplay: Bool = false
    @objc var isAnnotationsOn: Bool = false
    @objc var isStatsOpen: Bool = false
    @objc var isJSOverlayShown: Bool = false
    @objc var isPaused: Bool = false
    @objc var canMinimise: Bool = false
    @objc var allowsExternalPlayback: Bool = false
    @objc var paused: Bool = false
    @objc var muted: Bool = false
    @objc var controls: Bool = false { didSet { controller.controls = controls } }
    @objc var playInBackground: Bool = true
    @objc var playWhenInactive: Bool = true
    @objc var fullscreen: Bool = false
    @objc var `repeat`: Bool = false
    
    init(controller: PlayerViewController) {
        self.controller = controller
        super.init(frame: .zero)                
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        controller.didMoveToWindow()
    }
}
    
