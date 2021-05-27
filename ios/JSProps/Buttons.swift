//
//  Buttons.swift
//  RNDReactNativeDiceVideo
//
//  Created by Yaroslav Lvov on 05.03.2021.
//

import Foundation

//MARK: Differs
struct Buttons: SuperCodable {
    let watchlist: Bool?//tvOS
    let epg: Bool?//tvOS
    let fullscreen: Bool?
    let stats: Bool//tvOS/ios
    let favourite: Bool//tvOS/ios
    let zoom: Bool?//ios
    let back: Bool?//ios
    let settings: Bool?//ios
    let info: Bool?//tvos/ios
}
