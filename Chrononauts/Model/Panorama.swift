//
//  Panorama.swift
//  Chrononauts
//
//  Created by FredyCamas on 7/26/24.
//

import Foundation

struct Panorama: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var panoImages:[PanoImages]
    var latitude: Double
    var longitude: Double
}

struct PanoImages: Codable, Equatable{
    var name:String
    var year:String
    var north_rotation:Int
}
