//
//  AVDorisSourceMapper.swift
//  react-native-video
//
//  Created by Yaroslav Lvov on 27.05.2021.
//

import AVDoris

enum AVDorisSourceType {
    case ima(DAISource)
    case regular(PlayerItemSource)
    case unknown
}

class AVDorisSourceMapper {
    private let adTagParametersModifier = AdTagParametersModifier()
    
    func map(source: Source?, view: PlayerView?, completion: @escaping (AVDorisSourceType) -> Void) {
        guard let source = source else { return }
        
        var drmData: DorisDRMSource?
        if let drm = source.drm {
            drmData = DorisDRMSource(croToken: drm.croToken, licensingServerUrl: drm.licensingServerUrl)
        }
        
        if let ima = source.ima {
            adTagParametersModifier.prepareAdTagParameters(adTagParameters: ima.adTagParameters,
                                                           info: AdTagParametersModifierInfo(viewWidth: view?.bounds.width ?? 0,
                                                                                             viewHeight: view?.bounds.height ?? 0)) { newAdTagParameters in
                if let assetKey = ima.assetKey {
                    let liveDAISource = DAISource(assetKey: assetKey,
                                                  authToken: ima.authToken,
                                                  adTagParameters: newAdTagParameters,
                                                  adTagParametersValidFrom: ima.startDate,
                                                  adTagParametersValidUntil: ima.endDate)
                    
                    liveDAISource.drm = drmData
                    
                    completion(.ima(liveDAISource))
                } else if let contentSourceId = ima.contentSourceId, let videoId = ima.videoId {
                    let vodDAISource = DAISource(contentSourceId: contentSourceId,
                                                 videoId: videoId,
                                                 authToken: ima.authToken,
                                                 adTagParameters: newAdTagParameters,
                                                 adTagParametersValidFrom: ima.startDate,
                                                 adTagParametersValidUntil: ima.endDate)
                    
                    vodDAISource.drm = drmData
                    
                    completion(.ima(vodDAISource))
                } else {
                    completion(.unknown)
                }
            }
            
        } else {
            let source = PlayerItemSource(playerItem: .init(url: source.uri))
            source.drm = drmData
            completion(.regular(source))
        }
    }
}
