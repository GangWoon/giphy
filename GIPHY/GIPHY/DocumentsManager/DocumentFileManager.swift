//
//  DocumentFileManager.swift
//  GIPHY
//
//  Created by Cloud on 2021/09/21.
//

import Foundation
import UIKit

final class DocumentFileManager {
    
    // MARK: - Properties
    private var filePath: URL {
        return requsetedURL().appendingPathComponent(fileName)
    }
    private(set) var items: [String: Bool] = [String: Bool]()
    private let manager: FileManager = .default
    private let decoder: JSONDecoder = JSONDecoder()
    private let encoder: JSONEncoder = JSONEncoder()
    
    var fileName: String
    var requsetedURL: () -> URL
    
    // MARK: - Lifecycle
    init(
        requestedURL: @escaping () -> URL,
        fileName: String = "favorites.json"
    ) {
        self.requsetedURL = requestedURL
        self.fileName = fileName
    }
    
    // MARK: - Methods
    func readDocuments() {
        guard let data = try? Data(contentsOf: filePath) else {
            manager.createFile(atPath: filePath.absoluteString, contents: nil)
            return
        }
        let items = try? decoder.decode([String: Bool].self, from: data)
        self.items = items ?? [: ]
    }
    
    func updateDocuments() {
        guard let data = try? encoder.encode(items) else { return }
        let json = String(data: data, encoding: .utf8)?.data(using: .utf8)
        try? json?.write(to: filePath)
    }
    
    func readFavorites(_ key: String) -> Bool {
        return items[key] ?? false
    }
    
    func updateFavorites(_ key: String, value: Bool) {
        DispatchQueue.global().async { [weak self] in
            self?.items[key] = value
        }
    }
}
