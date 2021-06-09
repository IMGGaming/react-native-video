//
//  RCTVideoManager.swift
//  RNDReactNativeDiceVideo
//
//  Created by Lukasz on 24/10/2019.
//  Copyright © 2019 Endeavor Streaming. All rights reserved.
//

import Foundation

@objc(RCTVideoManager)
class RCTVideoManager: RCTViewManager {
    override func view() -> UIView! {
        let controller = PlayerViewController()
        let view = PlayerView(controller: controller)
        controller.view = view
        return view
    }
    
    //MARK: Differs (ios only)
    @objc public func seekToNow(_ node: NSNumber) {
        DispatchQueue.main.async {
            let component = self.bridge.uiManager.view(forReactTag: node) as? PlayerView
            component?.seekToNow()
        }
    }
    
    //MARK: Differs (ios only)
    @objc public func seekToTimestamp(_ node: NSNumber, isoDate: String) {
        DispatchQueue.main.async {
            let component = self.bridge.uiManager.view(forReactTag: node) as? PlayerView
            component?.seekToTimestamp(isoDate: isoDate)
        }
    }
    
    @objc public func seekToPosition(_ node: NSNumber, position: Double) {
        DispatchQueue.main.async {
            let component = self.bridge.uiManager.view(forReactTag: node) as? PlayerView
            component?.seekToPosition(position: position)
        }
    }
    
    @objc public func replaceAdTagParameters(_ node: NSNumber, payload: NSDictionary) {
        DispatchQueue.main.async {
            let component = self.bridge.uiManager.view(forReactTag: node) as? PlayerView
            component?.replaceAdTagParameters(payload: payload)
        }
    }
    
    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
}
