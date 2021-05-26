//
//  Source.swift
//  RNDReactNativeDiceVideo
//
//  Created by Yaroslav Lvov on 05.03.2021.
//

import Foundation

struct Source: SuperCodable {
    let id: String?
    let ima: Ima?
    let uri: URL
    let drm: Drm?
    let progressUpdateInterval: Int?
    let type: String
    let title: String?
    let live: Bool?
    let partialVideoInformation: PartialVideoInformation?
    let isAudioOnly: Bool?
    let config: Config
    let titleInfo: TitleInfo?
    let imageUri: URL?
}


extension Source {
    struct Ima: SuperCodable {
        let videoId: String?
        let adTagParameters: [String: String]?
        let endDate: Date?
        let startDate: Date?
        let assetKey: String?
        let contentSourceId: String?
        let authToken: String?
    }
    
    struct Drm: SuperCodable {
        let contentUrl: URL
        let drmScheme: String
        let id: String
    }
    
    struct PartialVideoInformation: SuperCodable {
        let title: String
        let imageUri: URL
    }
    
    struct Config: SuperCodable {
        let muxData: MuxData
        let beacon: Beacon?
    }
    
    struct TitleInfo: SuperCodable {
        let external: Bool
        let title: String
        let description: String
    }
}


extension Source.Config {
    struct Beacon: SuperCodable {
        let authUrl: URL
        let url: URL
    }
    
    struct MuxData: SuperCodable {
        let envKey: String
        let videoTitle: String
        let viewerUserId: String
        let videoId: String
        let playerName: String
        let videoStreamType: String
        let subPropertyId: String
        let videoIsLive: Bool
    }
}
