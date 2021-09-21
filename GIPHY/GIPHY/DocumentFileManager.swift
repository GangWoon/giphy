//
//  DocumentFileManager.swift
//  GIPHY
//
//  Created by Cloud on 2021/09/21.
//

import Foundation
import UIKit

class DocumentFileManager {
    
    private let manager: FileManager
    private static let fileName: String = "favorites.json"
    private var path: URL {
        let urlPath = manager.urls(
            for: .documentDirectory,
               in: .userDomainMask
        ).first?.appendingPathComponent(DocumentFileManager.fileName)
        return urlPath!
    }
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    var items: Set<StoredItem> = []
    static let standard = DocumentFileManager(manager: .default)
    
    init(manager: FileManager) {
        self.manager = manager
        self.decoder = .init()
        self.encoder = .init()
        readFromDocuments()
    }
    
    
    func readFavorites(with key: String) -> Bool {
        let item = items
            .filter { $0.url == key }
            .map(\.isFavorites)
        
        return item.first ?? false
    }
    
    func writeFavorites(with key: String, value: Bool) {
        let item = StoredItem(url: key, isFavorites: value)
        items.insert(item)
    }
    
    func readFromDocuments() {
        do {
            let data = try Data(contentsOf: path)
            let items = try decoder.decode(Set<StoredItem>.self, from: data)
            self.items = items
        } catch {
            manager.createFile(atPath: path.absoluteString, contents: nil, attributes: nil)
        }
    }
    
    func writeForDocuments() {
        do {
            let data = try encoder.encode(items)
            let json = String(data: data, encoding: .utf8)!.data(using: .utf8)
            try json?.write(to: path)
        } catch {
        }
    }
    
    private func makeEmptyFile() {
        let empty: [StoredItem] = []
        let data = try? encoder.encode(empty)
        try? data?.write(to: path)
    }
}

struct StoredItem: Codable, Hashable {
    static var empty = Self(
        url: "",
        isFavorites: false
    )
    var url: String
    var isFavorites: Bool = false
}
