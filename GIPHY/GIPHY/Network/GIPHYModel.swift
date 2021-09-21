//
//  GIPHYModel.swift
//  GIPHY
//
//  Created by Cloud on 2021/09/20.
//

import Foundation

struct GIPHYData: Decodable {
    
    let items: [GIPHYItem]

    enum CodingKeys: String, CodingKey {
        case items = "data"
    }
}

struct GIPHYItem: Decodable {
    
    let image: GIPHYImage
    
    enum CodingKeys: String, CodingKey {
        case image = "images"
    }
}

struct GIPHYImage: Decodable {
    
    let info: GIPHYImageInformation
    
    enum CodingKeys: String, CodingKey {
        case info = "fixed_width_small_still"
    }
}

struct GIPHYImageInformation: Decodable {
    let width: String
    let height: String
    let url: String
}
