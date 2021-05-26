//
//  AppIdFetcher.swift
//  RNDReactNativeDiceVideo
//
//  Created by Yaroslav Lvov on 02.12.2020.
//

import Foundation

class AppIdFetcher {
    static let shared = AppIdFetcher()
    private var appID: Int?
    
    func fetchAppId(completion: @escaping (Int?) -> Void) {
        if let appID = appID {
            completion(appID)
            return
        }
        
        guard let url = iTunesURLFromString() else {
            completion(nil)
            return
        }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 30)
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            self?.appID = self?.parseAppId(withData: data, response: response, error: error) ?? 0
            completion(self?.appID)
        }.resume()
    }
}

private extension AppIdFetcher {
    struct AppVersionModel: Decodable {
        let results: [Results]
        
        struct Results: Decodable {
            private enum CodingKeys: String, CodingKey {
                case appID = "trackId"
            }
            
            let appID: Int
        }
    }
    
    private func iTunesURLFromString() -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "itunes.apple.com"
        components.path = "/lookup"
        
        let items: [URLQueryItem] = [URLQueryItem(name: "bundleId", value: Bundle.main.bundleIdentifier)]
        components.queryItems = items
        return components.url
    }
    
    private func parseAppId(withData data: Data?, response: URLResponse?, error: Error?) -> Int? {
        if let _ = error { return nil }
        guard let data = data else { return nil }
        
        let model = try? JSONDecoder().decode(AppVersionModel.self, from: data)
        return model?.results.first?.appID
    }
}
