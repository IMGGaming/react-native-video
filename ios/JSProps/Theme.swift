//
//  Theme.swift
//  RNDReactNativeDiceVideo
//
//  Created by Yaroslav Lvov on 05.03.2021.
//

import Foundation

struct Theme: SuperCodable {
    let fonts: Fonts
    let colors: Colors
}

extension Theme {
    struct Fonts: SuperCodable {
        let secondary: String
        let primary: String
    }
    
    struct Colors: SuperCodable {
        let secondary: String
        let primary: String
    }
}
