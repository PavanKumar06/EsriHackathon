//
//  CurrentLocation.swift
//  Chrononauts
//
//  Created by FredyCamas on 7/26/24.
//

import SwiftUI
import UIKit
import CoreLocation
import PhotosUI
import Combine

struct ImagePicker: UIViewControllerRepresentable {
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.selectedImage = uiImage
                
                // Extract metadata using PHAsset
                if let assetIdentifier = info[.referenceURL] as? URL {
                    let result = PHAsset.fetchAssets(withALAssetURLs: [assetIdentifier], options: nil)
                    if let asset = result.firstObject {
                        let creationDate = asset.creationDate
                        let location = asset.location
                        
                        parent.imageCreationDate = creationDate
                        parent.imageLocation = location
                    }
                }
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
    @Binding var selectedImage: UIImage?
    @Binding var imageCreationDate: Date?
    @Binding var imageLocation: CLLocation?
    @Environment(\.presentationMode) var presentationMode
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.image"]
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
