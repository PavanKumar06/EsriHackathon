//
//  InitialMapView.swift
//  ARTest
//
//  Created by Owen on 7/26/24.
//
// id: Item.ID(rawValue: "fae788aa91e54244b161b59725dcbb2a")!
import SwiftUI
import ArcGIS
import CoreLocation

struct MapNavigationView: View {
    // camera
    @State private var showPanoramicCamera = false
    @State private var capturedImage: UIImage?
    @State private var panoImageLocation: CLLocation?
    
    // album
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedImage: UIImage?
    @State private var imageCreationDate: Date?
    @State private var imageLocation: CLLocation?
    
    @StateObject private var panoramaViewModel = PanoramaViewModel()
    @StateObject private var locationManager = LocationManagerShared()
    // map
    @State private var graphicsOverlay = GraphicsOverlay()
    @State private var map: Map?
    @State private var tapScreenPoint: CGPoint?
    @State private var isShowingIdentifyResultAlert = false
    @State private var identifyResultMessage = "" {
        didSet { isShowingIdentifyResultAlert = identifyResultMessage.isEmpty }
    }
    
    @State private var error: Error?
    @State private var selectedPanorama: Panorama?
    @State private var selectedUserPhoto: UserPhoto?
    @State private var isNavigationActive: Bool = false
    
    init() {
        ArcGISEnvironment.apiKey = APIKey("AAPTxy8BH1VEsoebNVZXo8HurHZ1MzVOs8E8fZ2W2I-6tpKGT07I4Jx-83LYrpPSRrhhsNZqPRMKZ1FWNBFyLPJnz90W0tkfMM4abnDWZHZLJiZdmuHq16FR0XaD82cMgZ0ZjwX3EASTFJd5wCBO3Dcw8UjERntMT6_Hg7egEQQvFeNZDpq4xB3KrqIta3BWpnfANSh-BA7Xyj1p1ZNWFjSxbSaZDW5izfg5vmwVNpgA-DP6t0PqcyDFJ1YPC0xHd8YzAT1_tfSbJgDX")
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if let map = map {
                    MapViewReader { mapViewProxy in
                        MapView(map: map, graphicsOverlays: [graphicsOverlay])
                            .onSingleTapGesture { screenPoint, _ in
                                tapScreenPoint = screenPoint
                            }
                            .task(id: tapScreenPoint) {
                                guard let tapScreenPoint else { return }
                                await handleTap(screenPoint: tapScreenPoint, mapViewProxy: mapViewProxy)
                            }
                            .alert(
                                "Identify Result",
                                isPresented: $isShowingIdentifyResultAlert,
                                actions: {},
                                message: { Text(identifyResultMessage) }
                            )
                            .onAppear {
                                updateGraphicsOverlay()
                            }
                            .onChange(of: panoramaViewModel.panoramas) { _ in
                                updateGraphicsOverlay()
                            }
                            .onChange(of: panoramaViewModel.userPhotos) { _ in
                                updateGraphicsOverlay()
                            }
                            .overlay(
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        VStack {
                                            
                                            Button(action: {
                                                showPanoramicCamera = true
                                            }) {
                                                Image(systemName:"camera.circle.fill")
                                                    .resizable()
                                                    .foregroundColor(.blue)
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 50, height: 50) // Adjust the size as needed
                                            }.sheet(isPresented: $showPanoramicCamera) {
                                                PanoramicCameraView(selectedImage: $selectedImage, imageCreationDate: $imageCreationDate, imageLocation: $imageLocation)
                                            }
                                            
                                            
                                            Button(action: {
                                                showingImagePicker = true
                                            }) {
                                                Image(systemName:"person.2.crop.square.stack.fill")
                                                    .resizable()
                                                    .foregroundColor(.blue)
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 50, height: 50) // Adjust the size as needed
                                            }
                                            .sheet(isPresented: $showingImagePicker) {
                                                ImagePicker(selectedImage: $selectedImage, imageCreationDate: $imageCreationDate, imageLocation: $imageLocation)
                                            }
                                            
                                            Button(action: {
                                                Task {
                                                    await goToCurrentLocation(mapViewProxy: mapViewProxy)
                                                }
                                            }) {
                                                Image(systemName: "location.circle.fill")
                                                    .resizable()
                                                    .frame(width: 40, height: 40)
                                                    .foregroundColor(.blue)
                                            }
                                        }.padding(.bottom, 50)
                                            .padding()
                                        
                                    }
                                }
                            )
                    }
                } else {
                    ProgressView("Loading map...")
                        .onAppear {
                            setupMap()
                        }
                }
            }.background(
                Group {
                    if let selectedPanorama = selectedPanorama {
                        NavigationLink(
                            destination: BridgeStreetView(panorama: selectedPanorama),
                            isActive: $isNavigationActive
                        ) {
                            EmptyView()
                        }
                        .hidden()
                    }
                    
                    if let selectedUserPhoto = selectedUserPhoto {
                        NavigationLink(
                            destination: UserPhotoARView(userPhoto: selectedUserPhoto),
                            isActive: $isNavigationActive
                        ) {
                            EmptyView()
                        }
                        .hidden()
                    }
                }
            ).onChange(of: selectedImage) { newImage in
                if let newImage = newImage {
                    var userPhoto = UserPhoto(
                        title: "Photo",
                        description: "Description"
                    )
                    userPhoto.set(newImage, with: imageLocation)
                    panoramaViewModel.addUserPhoto(userPhoto)
                    clearSelections()
                }
            }
            
        }
    }
    
    private func saveCapturedImage(image: UIImage, creationDate: Date?, location: CLLocation?) {
        var userPhoto = UserPhoto(
            title: "Captured Image",
            description: "Panoramic image captured on \(creationDate?.description ?? "unknown date")",
            imageData: image.jpegData(compressionQuality: 1.0),
            imageLocation: location
        )
        panoramaViewModel.addUserPhoto(userPhoto)
        clearSelections()
    }
    
    
    private func setupMap() {
        map = Map(basemapStyle: .arcGISCommunity)
        if let location = locationManager.lastLocation {
            let point = Point(
                x: location.coordinate.longitude,
                y: location.coordinate.latitude,
                spatialReference: .wgs84
            )
            map?.initialViewpoint = Viewpoint(center: point, scale: 4e4)
        } else {
            // Fallback to a default location if current location is not available
            let point = Point(
                x: -117.1957212,
                y: 34.0570921,
                spatialReference: .wgs84
            )
            map?.initialViewpoint = Viewpoint(center: point, scale: 4e4)
        }
    }
    
    @MainActor
    private func handleTap(screenPoint: CGPoint, mapViewProxy: MapViewProxy) async {
        do {
            let identifyResult = try await mapViewProxy.identify(
                on: graphicsOverlay,
                screenPoint: screenPoint,
                tolerance: 12
            )
            
            if identifyResult.graphics.isNotEmpty {
                let graphic = identifyResult.graphics.first
                let id = graphic?.attributes["id"] as! String
                identifyResultMessage = "Tapped on a panorama image, id: \(id), Jumping to Panorama View..."
                
                if let panorama = panoramaViewModel.panoramas.first(where: { $0.id == id }) {
                    selectedPanorama = panorama
                    isNavigationActive = true // Trigger the navigation
                    selectedUserPhoto = nil // Clear the other selection
                } else if let userPhoto = panoramaViewModel.userPhotos.first(where: { $0.id == id }) {
                    selectedUserPhoto = userPhoto
                    isNavigationActive = true // Trigger the navigation
                    selectedPanorama = nil // Clear the other selection
                }
            }
        } catch {
            self.error = error
        }
        
        self.tapScreenPoint = nil
    }
    
    @MainActor
    private func goToCurrentLocation(mapViewProxy: MapViewProxy) async {
        if let location = locationManager.lastLocation {
            do {
                let point = Point(
                    x: location.coordinate.longitude,
                    y: location.coordinate.latitude,
                    spatialReference: .wgs84
                )
                try await mapViewProxy.setViewpoint(Viewpoint(center: point, scale: 4e4))
            } catch {
                print("Error moving to current location: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateGraphicsOverlay() {
        let graphics = panoramaViewModel.panoramas.map { pano in
            makePictureMarkerSymbolFromImage(x: pano.longitude, y: pano.latitude, id: pano.id, iconName: "panorama_icon")
        }
        graphicsOverlay.addGraphics(graphics)
        
        let userGraphics = panoramaViewModel.userPhotos.map { user in
            makePictureMarkerSymbolFromImage(x: user.imageLocation?.coordinate.longitude ?? -117.195686, y: user.imageLocation?.coordinate.latitude ?? 34.058955, id: user.id, iconName: "panorama_user_icon")
        }
        graphicsOverlay.addGraphics(userGraphics)
    }
    
    private func makePictureMarkerSymbolFromImage(x: Double, y: Double, id: String, iconName: String) -> Graphic {
        let pinSymbol = PictureMarkerSymbol(image: resizeImage(image: UIImage(named: iconName)!, newWidth: 150))
        let pinPoint = Point(x: x, y: y, spatialReference: .wgs84)
        let attr = ["id": id]
        let pinGraphic = Graphic(geometry: pinPoint, attributes: attr, symbol: pinSymbol)
        return pinGraphic
    }
    
    private func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    private func clearSelections() {
        selectedImage = nil
        imageCreationDate = nil
        imageLocation = nil
        
    }
}

private extension Collection {
    var isNotEmpty: Bool {
        !self.isEmpty
    }
}

#Preview {
    MapNavigationView()
}


