//
//  PlayerView.swift
//  RNDReactNativeDiceVideo
//
//  Created by Yaroslav Lvov on 05.03.2021.
//

import AVDoris
import AVKit

class PlayerView: UIView {
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
    @objc var playNextSource: NSDictionary?
    @objc var playlist: NSDictionary?
    
    //Props
    @objc var src: NSDictionary? { didSet { _source = try? Source(dict: src) } }
    @objc var partialVideoInformation: NSDictionary? { didSet { _partialVideoInformation = try? PartialVideoInformation(dict: partialVideoInformation) } }
    @objc var translations: NSDictionary? { didSet { _translations = try? Translations(dict: translations) } }
    @objc var buttons: NSDictionary? { didSet { _buttons = try? Buttons(dict: buttons) } }
    @objc var theme: NSDictionary? { didSet { _theme = try? Theme(dict: theme) } }
    @objc var selectedTextTrack: NSDictionary?
    @objc var selectedAudioTrack: NSDictionary?
    @objc var seek: NSDictionary?
    @objc var relatedVideos: NSDictionary?
    @objc var metadata: NSDictionary?
    
    @objc var annotations: NSArray?
    @objc var playNextSourceTimeoutMillis: NSNumber?
    @objc var resizeMode: NSString?
    @objc var textTracks: NSArray?
    @objc var ignoreSilentSwitch: NSString?
    @objc var volume: NSNumber?
    @objc var rate: NSNumber?
    @objc var currentTime: NSNumber?
    @objc var progressUpdateInterval: NSNumber?

    @objc var isFavourite: Bool = false { didSet { dorisUI?.input?.setIsFavourite(isFavourite) } }
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
    @objc var controls: Bool = false
    @objc var playInBackground: Bool = true
    @objc var playWhenInactive: Bool = true
    @objc var fullscreen: Bool = false
    @objc var `repeat`: Bool = false
    
    //Mapped
    var _source: Source?
    var _partialVideoInformation: PartialVideoInformation?
    var _translations: Translations?
    var _buttons: Buttons?
    var _theme: Theme?
        
    private var dorisUI: DorisUIModule?
    private var shouldRequestTrackingAuthorization = false
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        setup()
        loadSource()
    }
    
    private func setup() {
        guard let theme = _theme,
              let translationsDict = translations else { return }
        
        let player = AVPlayer()
        let dorisTranslations = DorisUITranslations.create(from: translationsDict)
        let dorisStyle = DorisUIStyle(colors: .init(primary: theme.colors.primary, secondary: theme.colors.secondary),
                                      fonts: .init(primary: theme.fonts.primary, secondary: theme.fonts.secondary))
        
        let dorisUI = DorisUIModuleFactory.createCustomUI(player: player,
                                                          style: dorisStyle,
                                                          translations: dorisTranslations,
                                                          output: self)
        
        addSubview(dorisUI.view)
        dorisUI.fillSuperView()

        self.dorisUI = dorisUI
    }
    
    private func loadSource() {
        guard let dorisUI = dorisUI else { return }
        guard let source = _source else { return }

        configureUI()
        
        if let ima = source.ima {
            AdTagParametersModifier.prepareAdTagParameters(adTagParameters: ima.adTagParameters,
                                                           info: AdTagParametersModifierInfo(viewWidth: bounds.width,
                                                                                             viewHeight: bounds.height)) { newAdTagParameters in
                let dorisIMASource = DAISource(assetKey: ima.assetKey,
                                               contentSourceId: ima.contentSourceId,
                                               videoId: ima.videoId,
                                               authToken: ima.authToken,
                                               adTagParameters: newAdTagParameters,
                                               adTagParametersValidFrom: ima.startDate,
                                               adTagParametersValidUntil: ima.endDate)
                
                dorisUI.input?.load(imaSource: dorisIMASource, startPlayingAt: nil)
            }
        } else {
            let playerItemSource = PlayerItemSource(playerItem: AVPlayerItem(url: source.uri))
            dorisUI.input?.load(playerItemSource: playerItemSource, startPlayingAt: nil)
        }
    }
    
    func configureUI() {
        guard let dorisUI = dorisUI else { return }
        guard let source = _source else { return }
        guard let buttons = _buttons else { return }
        
        let dorisButtonsConfig = DorisUIButtonsConfiguration(watchlist: buttons.watchlist ?? false,
                                                             favourite: buttons.favourite,
                                                             epg: buttons.epg ?? false,
                                                             stats: buttons.stats)
        
        let dorisUIConfig = DorisUIMetadataConfiguration(title: source.title,
                                                         infoDescription: nil,
                                                         type: source.type,
                                                         thumbnailUrl: "",
                                                         channelLogoUrl: nil)
        
        dorisUI.input?.setUIButtonsConfiguration(dorisButtonsConfig)
        dorisUI.input?.setUIMetadataConfiguration(dorisUIConfig)
        dorisUI.input?.setIsFavourite(isFavourite)
    }
}


extension PlayerView: DorisUIModuleOutputProtocol {
    func didTapBackButton() {
        onBackButton?(nil)
    }
    
    func didTapFavouriteButton() {
        onFavouriteButton?(nil)
    }
}
