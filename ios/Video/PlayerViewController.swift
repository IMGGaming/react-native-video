//
//  PlayerViewController.swift
//  react-native-video
//
//  Created by Yaroslav Lvov on 27.05.2021.
//

import AVDoris
import AVKit

class PlayerViewController {
    weak var view: PlayerView?
    
    var source: Source? { didSet { loadSource() } }
    var controls: Bool = false { didSet { controls ? dorisUI?.input?.enableUI() : dorisUI?.input?.disableUI() } }
    var isFavourite: Bool = false { didSet { dorisUI?.input?.setIsFavourite(isFavourite) } }
    
    var partialVideoInformation: PartialVideoInformation?
    var translations: NSDictionary?
    var buttons: Buttons?
    var theme: Theme?
    var relatedVideos: RelatedVideos?
    var metadata: DorisUIMetadataConfiguration?
    var startAt: Double?
    
    private var dorisUI: DorisUIModule?
    private let sourceMapper: AVDorisSourceMapper = AVDorisSourceMapper()
    private let muxDataMapper: AVDorisMuxDataMapper = AVDorisMuxDataMapper()
    private var currentPlayingItemDuration: Double?
    private var adTagParametersModifier = AdTagParametersModifier()
    
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
    
    func didMoveToWindow() {
        setup()
        loadSource()
    }
    
    private func setup() {
        guard let theme = theme,
              let translationsDict = translations else { return }
        
        let player = AVPlayer()
        let dorisTranslations = DorisUITranslations.create(from: translationsDict)
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
        if let metadata = metadata {
            dorisUI.input?.setUIMetadataConfiguration(metadata)
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
            case .ima(let source): self.dorisUI?.input?.load(imaSource: source, startPlayingAt: self.startAt as NSNumber?)
            case .regular(let source): self.dorisUI?.input?.load(playerItemSource: source, startPlayingAt: self.startAt as NSNumber?)
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
    func didTapBackButton() {
        view?.onBackButton?(nil)
    }
    
    func didTapFavouriteButton() {
        view?.onFavouriteButton?(nil)
    }
    
    func didRequestAdTagParameters(for timeInterval: TimeInterval, isBlocking: Bool) {
        view?.onRequireAdParameters?(["date": timeInterval,
                                "isBlocking": isBlocking])
    }
    
    func didGetPlaybackError() {
        view?.onVideoError?(nil)
    }
    
    func didChangeCurrentPlaybackTime(currentTime: Double) {
        if currentTime > 0 {
            view?.onVideoProgress?(["currentTime": currentTime])
        }
        
        if let duration = currentPlayingItemDuration {
            view?.onVideoAboutToEnd?(["isAboutToEnd": currentTime >= duration - 10 ? true : false]);
        }
    }
    
    func didFinishPlaying(endTime: Double) {
        view?.onVideoEnd?(nil)
    }
    
    func didLoadVideo() {
        view?.onVideoLoad?(nil)
    }
    
    func didResumePlayback(_ isPlaying: Bool) {
        view?.onPlaybackRateChange?(["playbackRate": isPlaying ? 1.0 : 0.0])
    }
    
    func didStartBuffering() {
        view?.onVideoBuffer?(["isBuffering": true])
    }
    
    func didFinishBuffering() {
        view?.onVideoBuffer?(["isBuffering": false])
    }
    
    func didChangeItemDuration(_ duration: Double) {
        currentPlayingItemDuration = duration
    }
    
    func didTapMoreRelatedVideosButton() {
        view?.onRelatedVideosIconClicked?(nil)
    }
    
    func didSelectRelatedVideo(identifier: NSNumber, type: String) {
        view?.onRelatedVideoClicked?(["id": identifier, "type": type])
    }
    
    func didTapStatsButton() {
        view?.onStatsIconClick?(nil)
    }
    
    func didTapScheduleButton() {
        view?.onEpgIconClick?(nil)
    }
}
