//
//  PlayerViewController.swift
//  react-native-video
//
//  Created by Yaroslav Lvov on 27.05.2021.
//

import AVDoris
import AVKit

class PlayerViewController {
    private var dorisUI: DorisUIModule?
    private let sourceMapper: AVDorisSourceMapper = AVDorisSourceMapper()
    private let muxDataMapper: AVDorisMuxDataMapper = AVDorisMuxDataMapper()
    private let translationsMapper: AVDorisTranslationsMapper = AVDorisTranslationsMapper()
    private let metadataMapper: AVDorisMetadataMapper = AVDorisMetadataMapper()
    private var adTagParametersModifier = AdTagParametersModifier()
    
    private var currentPlayingItemDuration: Double?
    private var currentPlayerState: DorisPlayerState = .initialization
    
    weak var view: PlayerView?
    
    //initial props
    var partialVideoInformation: PartialVideoInformation?
    var translations: Translations?
    var buttons: Buttons?
    var theme: Theme?
    var relatedVideos: RelatedVideos?
    var metadata: Metadata?
    var startAt: Double?
    
    //dynamic props
    var source: Source? { didSet { loadSource() } }
    var controls: Bool = false { didSet { controls ? dorisUI?.input?.enableUI() : dorisUI?.input?.disableUI() } }
    var isFavourite: Bool = false { didSet { dorisUI?.input?.setIsFavourite(isFavourite) } }
            
    func replaceAdTagParameters(parameters: AdTagParameters) {
        let extraInfo = AdTagParametersModifierInfo(viewWidth: view?.bounds.width ?? 0.0,
                                                    viewHeight: view?.bounds.height ?? 0.0)
        
        adTagParametersModifier.prepareAdTagParameters(adTagParameters: parameters.adTagParameters,
                                                       info: extraInfo) { [weak self] newAdTagParameters in
            guard let newAdTagParameters = newAdTagParameters else { return }
            self?.dorisUI?.input?.replaceAdTagParameters(adTagParameters: newAdTagParameters,
                                                         validFrom: parameters.startDate,
                                                         validUntil: parameters.endDate)
        }
    }
    
    func viewDidMoveToWindow() {
        setup()
        loadSource()
    }
    
    private func setup() {
        guard let theme = theme else { return }
        
        let player = AVPlayer()
        let dorisTranslations = translationsMapper.map(translations: translations)
        let dorisStyle = DorisUIStyle(colors: .init(primary: theme.colors.primary,
                                                    secondary: theme.colors.secondary),
                                      fonts: .init(primary: theme.fonts.primary,
                                                   secondary: theme.fonts.secondary))
        
        let dorisUI = DorisUIModuleFactory.createCustomUI(player: player,
                                                          style: dorisStyle,
                                                          translations: dorisTranslations,
                                                          output: self)
        
        view?.addSubview(dorisUI.view)
        dorisUI.fillSuperView()
        
        self.dorisUI = dorisUI
    }
    
    private func loadSource() {
        configureRelatedVideos()
        configureMux()
        configureUI()
        configurePlayback()
    }
    
    private func configureUI() {
        guard let dorisUI = dorisUI else { return }
        guard let buttons = buttons else { return }
        
        let dorisButtonsConfig = DorisUIButtonsConfiguration(watchlist: buttons.watchlist ?? false,
                                                             favourite: buttons.favourite,
                                                             epg: buttons.epg ?? false,
                                                             stats: buttons.stats)
        
        dorisUI.input?.setUIButtonsConfiguration(dorisButtonsConfig)
        if let metadata = metadata, let dorisUIMetadata = metadataMapper.map(metadata: metadata) {
            dorisUI.input?.setUIMetadataConfiguration(dorisUIMetadata)
        }
        dorisUI.input?.setIsFavourite(isFavourite)
        controls ? dorisUI.input?.enableUI() : dorisUI.input?.disableUI()
    }
    
    private func configureMux() {
        guard let avDorisMuxData = muxDataMapper.map(muxData: source?.config.muxData) else { return }
        dorisUI?.input?.configureMux(playerData: avDorisMuxData.playerData,
                                     videoData: avDorisMuxData.videoData)
    }
    
    private func configurePlayback() {
        sourceMapper.map(source: source, view: view) { [weak self] avDorisSource in
            guard let self = self else { return }
            
            switch avDorisSource {
            case .ima(let source):
                self.dorisUI?.input?.load(imaSource: source,
                                          startPlayingAt: self.startAt as NSNumber?)
            case .regular(let source):
                self.dorisUI?.input?.load(playerItemSource: source,
                                          startPlayingAt: self.startAt as NSNumber?)
            case .unknown:
                return
            }
        }
    }
    
    private func configureRelatedVideos() {
        guard let relatedVideos = relatedVideos else { return }
        
        let relatedVideosToShow = relatedVideos.items
            .dropFirst(relatedVideos.headIndex + 1)
            .prefix(3)
            .map { DorisRelatedVideo(id: $0.id,
                                     thumbnailUrl: $0.thumbnailUrl,
                                     title: $0.title,
                                     type: StreamType(rawValue: $0.type) ?? .unknown) }
        
        dorisUI?.input?.setRelatedVideos(relatedVideosToShow)
    }
}


extension PlayerViewController: DorisUIModuleOutputProtocol {
    func onPlayerEvent(_ event: DorisPlayerEvent) {
        switch event {
        
        case .stateChanged(state: let state):
            onPlayerStateChanged(state)
        case .finishedPlaying(endTime: _):
            view?.onVideoEnd?(nil)
        case .currentTimeChanged(time: let time):
            if time > 0 {
                view?.onVideoProgress?(["currentTime": time])
            }
            
            if let duration = currentPlayingItemDuration {
                let isAboutToEnd = time >= duration - 10
                view?.onVideoAboutToEnd?(["isAboutToEnd": isAboutToEnd]);
            }
        case .itemDurationChanged(duration: let duration):
            currentPlayingItemDuration = duration
        default: break
        }
    }
    
    func onAdvertisementEvent(_ event: AdvertisementEvent) {
        switch event {
        case .REQUIRE_AD_TAG_PARAMETERS(let data):
            view?.onRequireAdParameters?(["date": data.date.timeIntervalSince1970,
                                          "isBlocking": data.isBlocking])
        default: break
        }
    }
    
    func onViewEvent(_ event: DorisViewEvent) {
        switch event {
        case .favouritesButtonTap:
            view?.onFavouriteButton?(nil)
        case .statsButtonTap:
            view?.onStatsIconClick?(nil)
        case .scheduleButtonTap:
            view?.onEpgIconClick?(nil)
        case .relatedVideoSelected(id: let id, type: let type):
            view?.onRelatedVideoClicked?(["id": id, "type": type.rawValue])
        case .moreRelatedVideosTap:
            view?.onRelatedVideosIconClicked?(nil)
        case .backButtonTap:
            view?.onBackButton?(nil)
        default: break
        }
    }
    
    func onError(_ error: Error) {
        view?.onVideoError?(nil)
    }
    
    func onPlayerStateChanged(_ state: DorisPlayerState) {
        if currentPlayerState == .buffering {
            view?.onVideoBuffer?(["isBuffering": false])
        }
        
        currentPlayerState = state
        
        switch state {
        case .failed:
            view?.onVideoError?(nil)
        case .loaded:
            view?.onVideoLoad?(nil)
        case .loading,
             .buffering,
             .waitingForNetwork:
            view?.onVideoBuffer?(["isBuffering": true])
        case .paused,
             .stopped:
            view?.onPlaybackRateChange?(["playbackRate": 0.0])
        case .playing:
            view?.onPlaybackRateChange?(["playbackRate": 1.0])
        default: break
        }
    }
}
