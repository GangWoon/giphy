//
//  DocumentsManagerTest.swift
//  GIPHYTests
//
//  Created by Cloud on 2021/09/22.
//

import XCTest
@testable import GIPHY

class DocumentsManagerTest: XCTestCase {

    func testReadDocuments_noFile() {
        let fileName = "Test"
        let manager = DocumentFileManager(
            requestedURL: {
                FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            },
            fileName: fileName
        )
        manager.readDocuments()
        XCTAssertEqual(manager.items.isEmpty, true)
    }
    
    func testReadDocuments_file() {
        let fileName = "Test"
        let manager = DocumentFileManager(
            requestedURL: {
                FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            },
            fileName: fileName
        )
        let filePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        let dummy: [String: Bool] = ["Hi": true]
        let data = try! JSONEncoder().encode(dummy)
        try! String(data: data, encoding: .utf8)!.data(using: .utf8)?.write(to: filePath)
        FileManager.default.createFile(atPath: filePath.absoluteString, contents: nil)
        manager.readDocuments()
        XCTAssertEqual(manager.items, dummy)
    }
    
    func testUpdateFavorites() {
        let manager = DocumentFileManager(
            requestedURL: { fatalError("Should not be called") },
            fileName: ""
        )
        manager.updateFavorites("Hi", value: true)
        XCTAssertEqual(manager.items["Hi"], true)
    }
}
