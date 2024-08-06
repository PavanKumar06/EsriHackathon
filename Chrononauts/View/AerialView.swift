//
//  AerialView.swift
//  ARTest
//
//  Created by Owen on 7/26/24.
//

import SwiftUI
import ArcGIS

struct AerialView: View {
    var panorama: Panorama
    var currentIndex: Int
    
    
    //@State private var nearestIndex: Int
//    init(panorama: Panorama){
//        self.lat = panorama.latitude
//        self.long = panorama.longitude
//    }
    @State var Layers: Array<ArcGISMapImageLayer> = Array<ArcGISMapImageLayer>()
    @State var long: Double?
    @State var lat: Double?
    @State static var itemIDs = [
                                 ["0580885df74341d5b91aa431c69950ca", "2023", "Raster"],
                                 ["https://maps.sbcounty.gov/arcgis/rest/services/Y2022_pua_cache/MapServer", "2022", "URL"],
                                 ["https://maps.sbcounty.gov/arcgis/rest/services/Y2021_pua_cache/MapServer", "2021", "URL"],
                                 ["https://maps.sbcounty.gov/arcgis/rest/services/Y2020_pua_cache/MapServer", "2020", "URL"],
                                 ["https://maps.sbcounty.gov/arcgis/rest/services/Y2019_StatePlane/MapServer", "2019", "URL"],
                                 ["https://maps.sbcounty.gov/arcgis/rest/services/Y2018_pua_cache/MapServer", "2018", "URL"],
                                 ["https://maps.sbcounty.gov/arcgis/rest/services/Y2017_pua_cache/MapServer", "2017", "URL"],
                                 ["https://maps.sbcounty.gov/arcgis/rest/services/Y2016_pua_cache/MapServer", "2016", "URL"],
                                 ["https://maps.sbcounty.gov/arcgis/rest/services/Y2015_pua_cache/MapServer", "2015", "URL"],
                                 ["https://maps.sbcounty.gov/arcgis/rest/services/Y2014_pua_cache/MapServer", "2014", "URL"],
                                 ["https://maps.sbcounty.gov/arcgis/rest/services/Y2013_pua_cache/MapServer", "2013", "URL"],
                                 ["https://maps.sbcounty.gov/arcgis/rest/services/Y2012_pua_cache/MapServer", "2012", "URL"],
                                 ["https://maps.sbcounty.gov/arcgis/rest/services/Y2011_pua_cache/MapServer", "2011", "URL"],
                                 //["https://maps.sbcounty.gov/arcgis/rest/services/Y2010_pua_cache/MapServer", "2010", "URL"],
                                 
    ]
    
    @State private var map: Map = {
        let map = Map()
        return map
    }()
    var body: some View {
        VStack{
            MapView(map: map).task {
                map.initialViewpoint = Viewpoint(center:Point(x: self.panorama.longitude,
                                                              y: self.panorama.latitude,
                                                              spatialReference: .wgs84),
                                                 scale: 1000)
                let portal = Portal(url: URL(string: "https://sbcounty.maps.arcgis.com")!, connection:.anonymous)
                let nearestIndex = getNearestIndex()
                for idx in 0 ..< AerialView.itemIDs.count{
                    let portal_item = PortalItem(
                        portal: portal,
                        id: PortalItem.ID(AerialView.itemIDs[idx][0])!
                    )
                    if AerialView.itemIDs[idx][2] == "Raster" {
                        let layer = RasterLayer(item: portal_item)
                        try? await layer.load()
                        if nearestIndex != idx{
                            layer.isVisible = false
                        }
                        map.addOperationalLayer(layer)
                    }else if AerialView.itemIDs[idx][2] == "MapService"{
                        let layer = ArcGISMapImageLayer(item: portal_item)
                        try? await layer.load()
                        if nearestIndex != idx{
                            layer.isVisible = false
                        }
                        map.addOperationalLayer(layer)
                    }else
                    {
                        let layer = ArcGISMapImageLayer(url: URL(string: AerialView.itemIDs[idx][0])!)
                        try? await layer.load()
                        if nearestIndex != idx{
                            layer.isVisible = false
                        }
                        try? await layer.load()
                        map.addOperationalLayer(layer)
                    }
                }
                try? await map.load()
            }
            ScrollView(.horizontal, showsIndicators: false)
            {
                let nearestIndex = getNearestIndex()
                ExtractedView(map: map, intial_index: nearestIndex)
            }
        }
    }
    private func getNearestIndex() -> Int
    {
        let arYear = Int(self.panorama.panoImages[self.currentIndex].year)!
        var minDiff = Int.max
        var targetYearIndex = 0
        for i in 0..<AerialView.itemIDs.count {
            let year = Int(AerialView.itemIDs[i][1])!
            if abs(year - arYear) < minDiff {
                targetYearIndex = i
                minDiff = abs(year - arYear)
            }
        }
        return targetYearIndex
    }
  
}

#Preview {
    AerialView(panorama: PanoramaViewModel().panoramas[0], currentIndex: 2)
}

struct ExtractedView: View {
    @State private var bgColors: [Color]
    @State private var intial_index: Int
    init(map: Map, intial_index: Int) {
        print("Loading aerial map from year: " + AerialView.itemIDs[intial_index][1])
        // Initialize bgColor with an array of default colors
        _bgColors = State(initialValue: Array(repeating: Color(red: 0.8, green: 0.8, blue: 0.8), count: AerialView.itemIDs.count))
        
        self.map = map
        self.intial_index = intial_index
        
    }
    
    var map:Map
    var body: some View {
        HStack{
            ForEach(AerialView.itemIDs.indices, id: \.self) { idx in
                Button(action: {
                    showLayer(index: idx)
                })
                {
                    Text(AerialView.itemIDs[idx][1])
                        .padding()
                        .background(bgColors[idx])
                        .cornerRadius(5)
                        .foregroundColor(.black)
                    
                }
            }
        }.task {
            bgColors[self.intial_index] = .blue
        }
    }
    private func showLayer(index: Int)
    {
        for i in 0..<map.operationalLayers.count {
            if i == index{
                bgColors[index] = .blue
                map.operationalLayers[i].isVisible = true
            }else{
                bgColors[i] = Color(red: 0.8, green: 0.8, blue: 0.8)
                map.operationalLayers[i].isVisible = false
            }
        }
        
    }
}
