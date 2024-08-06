//
//  UserPhotoARView.swift
//  Chrononauts
//
//  Created by FredyCamas on 7/27/24.
//

import Foundation

import SwiftUI
import UIKit

struct ARUserPhotoViewContainer: UIViewControllerRepresentable {
    var userPhoto: UserPhoto
    
    func makeUIViewController(context: Context) -> ARUserPhotoView {
        return ARUserPhotoView(userPhoto: userPhoto)
    }
    
    func updateUIViewController(_ uiViewController: ARUserPhotoView, context: Context) {}
}


struct UserPhotoARView: View {
    let userPhoto: UserPhoto
    
    var body: some View {
        ARUserPhotoViewContainer(userPhoto: userPhoto)
            .edgesIgnoringSafeArea(.all)
    }
}

