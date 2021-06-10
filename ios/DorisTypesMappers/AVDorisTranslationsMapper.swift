//
//  AVDorisTranslationsMapper.swift
//  react-native-video
//
//  Created by Yaroslav Lvov on 10.06.2021.
//

import AVDoris

class AVDorisTranslationsMapper {
    func map(translations: Translations?) -> DorisUITranslations? {
        guard let translations = translations else { return nil }
        
        let dorisTranslations = DorisUITranslations()
        dorisTranslations.playerStatsButton = translations.playerStatsButton
        dorisTranslations.playerPlayButton = translations.playerPlayButton
        dorisTranslations.playerPauseButton = translations.playerPauseButton
        dorisTranslations.playerAudioAndSubtitlesButton = translations.playerAudioAndSubtitlesButton
        dorisTranslations.live = translations.live
        dorisTranslations.favourite = translations.favourite
        dorisTranslations.watchlist = translations.watchlist
        dorisTranslations.moreVideos = translations.moreVideos
        dorisTranslations.captions = translations.captions
        dorisTranslations.rewind = translations.rewind
        dorisTranslations.fastForward = translations.fastForward
        dorisTranslations.audioTracks = translations.audioTracks
        dorisTranslations.info = translations.info
        dorisTranslations.adsCountdownAd = translations.adsCountdownAd
        dorisTranslations.adsCountdownOf = translations.adsCountdownOf
        
        return dorisTranslations
    }
}
