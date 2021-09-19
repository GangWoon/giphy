//
//  NetworkManager.swift
//  GIPHY
//
//  Created by Cloud on 2021/09/19.
//

import UIKit
import Combine

struct NetworkManager {
    
    // MARK: - Properties
    private let urlSession: URLSession
    private let decoder: JSONDecoder
    
    // MARK: - Lifecycle
    init(
        urlSession: URLSession,
        decoder: JSONDecoder
    ) {
        self.urlSession = urlSession
        self.decoder = decoder
    }
    
    // MARK: - Methods
    func fectItems(query: String) -> AnyPublisher<[URL], Never> {
        guard let url = makeURL(query) else {
            return Just([])
                .eraseToAnyPublisher()
        }
        
        return urlSession.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: GIPHYData.self, decoder: decoder)
            .map(\.urls)
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }
    
    private func makeURL(_ query: String) -> URL? {
        let baseURL: String = "http://api.giphy.com/v1/gifs/search"
        let key = "q"
        var components = URLComponents(string: baseURL)
        components?.queryItems = QueryItems.allCases.map { $0.item }
        components?.queryItems?.append(URLQueryItem(name: key, value: query))
        
        return (components?.url)
    }
}

// MARK: - NetworkManager + Extension
extension NetworkManager {
    private enum QueryItems: String, CaseIterable {
        
        case api_key
        case limit
        
        private var privateKey: String {
            return "TAe8SiGc5beuLWNZP2BmhAyoCPzNhewX"
        }
        private var fetchCount: String {
            return "16"
        }
        
        var item: URLQueryItem {
            let item: URLQueryItem
            switch self {
            case .api_key:
                item = URLQueryItem(name: rawValue, value: privateKey)
            case .limit:
                item = URLQueryItem(name: rawValue, value: fetchCount)
            }
            
            return item
        }
    }
}

// MARK: - GIPHYData + Extension
private extension GIPHYData {
    var urls: [URL] {
        items.compactMap { $0.url }
    }
}

// MARK: - GIPHYItem + Extension
private extension GIPHYItem {
    var url: URL? {
        URL(string: image.info.url)
    }
}
