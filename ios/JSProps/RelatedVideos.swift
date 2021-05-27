//
//  RelatedVideos.swift
//  react-native-video
//
//  Created by Yaroslav Lvov on 27.05.2021.
//

import Foundation

struct RelatedVideo: Codable {
    let id: Int
    let type: String
    let thumbnailUrl: String
    let title: String
}

struct RelatedVideos: SuperCodable {
    let headIndex: Int
    let items: [RelatedVideo]
}
