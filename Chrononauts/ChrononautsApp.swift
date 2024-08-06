//
//  ChrononautsApp.swift
//  Chrononauts
//
//  Created by FredyCamas on 7/26/24.
//

import SwiftUI

@main
struct ChrononautsApp: App {
    @StateObject var viewModel = PanoramaViewModel()
    
    var body: some Scene {
        WindowGroup {
            MapNavigationView()
                .environmentObject(viewModel)
        }
    }
}


