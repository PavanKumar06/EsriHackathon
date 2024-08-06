//
//  StreetView.swift
//  Chrononauts
//
//  Created by FredyCamas on 7/26/24.
//

import SwiftUI
import UIKit

struct ARViewContainer: UIViewControllerRepresentable {
    var panorama: Panorama
    
    func makeUIViewController(context: Context) -> ARStreetView {
        return ARStreetView(panorama: panorama)
    }
    
    func updateUIViewController(_ uiViewController: ARStreetView, context: Context) {}
}

struct BridgeStreetView: View {
    let panorama: Panorama
    
    var body: some View {
        ARViewContainer(panorama: panorama)
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    BridgeStreetView(
        panorama: Panorama(
            id: "sample_id",
            name: "esri1",
            panoImages: [
                PanoImages(name: "esricoffee", year: "2007", north_rotation: 0),
                PanoImages(name: "esricoffee", year: "2011", north_rotation: 0),
                PanoImages(name: "esricoffee", year: "2017", north_rotation: 0),
                PanoImages(name: "esricoffee", year: "2019", north_rotation: 0)
            ],
            latitude: 34.0,
            longitude: -117.0
        )
    )
}

