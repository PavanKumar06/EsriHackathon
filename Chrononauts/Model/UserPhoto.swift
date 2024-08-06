//
//  User.swift
//  Chrononauts
//
//  Created by FredyCamas on 7/26/24.
//
import Foundation
import SwiftUI
import CoreLocation

struct UserPhoto: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    var imageData: Data?
    var imageLocation: CLLocation?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, imageData, latitude, longitude
    }
    
    init(id: String = UUID().uuidString, title: String, description: String, imageData: Data? = nil, imageLocation: CLLocation? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.imageData = imageData
        self.imageLocation = imageLocation
    }
    
    mutating func set(_ image: UIImage, with location: CLLocation?) {
        self.imageData = image.jpegData(compressionQuality: 1.0)
        self.imageLocation = location
    }
    
    // Encoding custom CLLocation to latitude and longitude
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(imageData, forKey: .imageData)
        
        if let location = imageLocation {
            try container.encode(location.coordinate.latitude, forKey: .latitude)
            try container.encode(location.coordinate.longitude, forKey: .longitude)
        }
    }
    
    // Decoding custom CLLocation from latitude and longitude
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        imageData = try container.decode(Data?.self, forKey: .imageData)
        
        if let latitude = try container.decodeIfPresent(Double.self, forKey: .latitude),
           let longitude = try container.decodeIfPresent(Double.self, forKey: .longitude) {
            imageLocation = CLLocation(latitude: latitude, longitude: longitude)
        } else {
            imageLocation = nil
        }
    }
}
