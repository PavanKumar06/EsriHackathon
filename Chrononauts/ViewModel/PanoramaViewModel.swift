//
//  ManagerViewModel.swift
//  Chrononauts
//
//  Created by FredyCamas on 7/26/24.
//

import Foundation
import Combine

class PanoramaViewModel: ObservableObject {
    @Published var panoramas: [Panorama] = []
    @Published var userPhotos: [UserPhoto] = []
    private let userPhotosFilename = "userPhotos.json"
    private let fileManager = FileManager.default
    
    init() {
        loadMockData()
        loadUserPhotos()
    }
    
//    {"id": "1", "name": "msla", "panoImages": [{"name": "msla2011", "year": "2011", "north_rotation": 0}, {"name": "msla2015", "year": "2015", "north_rotation": 0}, {"name": "msla2020", "year": "2020", "north_rotation": 0}], "latitude": 34.0578832, "longitude": -117.195714},
//    {"id": "2", "name": "esri", "panoImages": [{"name": "esri2007", "year": "2007", "north_rotation": 0}, {"name": "esri2011", "year": "2011", "north_rotation": 0}, {"name": "esri2016", "year": "2016", "north_rotation": 0},{"name": "esri2022", "year": "2022", "north_rotation": 0}], "latitude": 34.0568832, "longitude": -117.196714},
    private func loadMockData() {
        let json = """
        [
            {"id": "1", "name": "Truist Park", "panoImages": [{"name": "park2022", "year": "2022", "north_rotation": 141}, {"name": "park2021", "year": "2021", "north_rotation": 140}, {"name": "park2019", "year": "2019", "north_rotation": 320}, {"name": "park2018", "year": "2018", "north_rotation": 319}, {"name": "park2017", "year": "2017", "north_rotation": 139}, {"name": "park2016", "year": "2016", "north_rotation": 319}, {"name": "park2015", "year": "2015","north_rotation": 320}, {"name": "park2014", "year": "2014","north_rotation": 319},{"name": "park2013", "year": "2013","north_rotation": 141}, {"name": "park2012", "year": "2012","north_rotation": 141}, {"name": "park2011", "year": "2011","north_rotation": 140}, {"name": "park2008", "year": "2008","north_rotation": 318}], "latitude": 33.8889492, "longitude": -84.4672252},
            {"id": "2", "name": "Esri", "panoImages": [{"name": "esri2024", "year": "2024", "north_rotation": 8}, {"name": "esri2019", "year": "2019", "north_rotation": 1}, {"name": "esri2017", "year": "2017", "north_rotation": 181},{"name": "esri2015", "year": "2015", "north_rotation": 185}, {"name": "esri2011", "year": "2011", "north_rotation": 180}, {"name": "esri2007", "year": "2007", "north_rotation": 185}], "latitude": 34.0570921, "longitude": -117.1957212}
            
        ]
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        if let panorama = try? decoder.decode([Panorama].self, from: data) {
            self.panoramas = panorama
        }
    }
    
    func addUserPhoto(_ userPhoto: UserPhoto) {
        userPhotos.append(userPhoto)
        saveUserPhotos()
    }
    
    private func saveUserPhotos() {
        guard let url = getDocumentsDirectory()?.appendingPathComponent(userPhotosFilename) else { return }
        
        do {
            let data = try JSONEncoder().encode(userPhotos)
            try data.write(to: url)
        } catch {
            print("Failed to save user photos: \(error.localizedDescription)")
        }
    }
    
    private func loadUserPhotos() {
        guard let url = getDocumentsDirectory()?.appendingPathComponent(userPhotosFilename),
              fileManager.fileExists(atPath: url.path) else { return }
        
        do {
            let data = try Data(contentsOf: url)
            userPhotos = try JSONDecoder().decode([UserPhoto].self, from: data)
        } catch {
            print("Failed to load user photos: \(error.localizedDescription)")
        }
    }
    
    private func getDocumentsDirectory() -> URL? {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    }
}
