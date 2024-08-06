//
//  ARViewController.swift
//  Chrononauts
//
//  Created by FredyCamas on 7/26/24.
//

import SwiftUI
import ARKit
import Combine
import CoreLocation

class ARStreetView: UIViewController, ARSCNViewDelegate, CLLocationManagerDelegate, ARSessionDelegate {
    var sceneView: ARSCNView!
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var currentHeading: CLHeading?
    var panorama: Panorama // Single panorama instance
    var images: [PanoImages] {
        return panorama.panoImages
    }
    var currentImageIndex:Int = 0
    
    init(panorama: Panorama) {
        self.panorama = panorama
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupARScene()
        startLocationServices()
        configureARSession()
        addHorizontalPicker()
        addMapIconButton()
        
        if panorama.name == "Esri"{
            addFunFacts()
        }
        
        self.replaceBuildingWithPhoto(identifier: images.first)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cleanupARResources()
    }
    func cleanupARResources() {
        // Pause the AR session
        sceneView.session.pause()
        
        // Remove all nodes
        sceneView.scene.rootNode.childNodes.forEach { $0.removeFromParentNode() }
        
        // Stop location updates
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        
        // Clear the delegate to avoid potential memory leaks
        sceneView.delegate = nil
        sceneView.session.delegate = nil
        locationManager.delegate = nil
    }


    func addMapIconButton() {
        let mapIconButton = UIButton(type: .system)
        mapIconButton.setImage(UIImage(systemName: "map.circle.fill"), for: .normal)
        mapIconButton.tintColor = .systemBlue
        mapIconButton.addTarget(self, action: #selector(showAerialView), for: .touchUpInside)
        
        // Ensuring the icon scales appropriately within the button
        mapIconButton.imageView?.contentMode = .scaleAspectFit
        mapIconButton.imageEdgeInsets = UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30)
        
        // Add the button to the view hierarchy
        self.view.addSubview(mapIconButton)
        
        // Disable autoresizing mask translation to use Auto Layout
        mapIconButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Set up constraints
        NSLayoutConstraint.activate([
            mapIconButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            mapIconButton.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: 50),
            
            // Set button size
            mapIconButton.widthAnchor.constraint(equalToConstant: 150),
            mapIconButton.heightAnchor.constraint(equalToConstant: 150)
        ])
        
        print("Map icon button added")
    }

        
    @objc func showAerialView() {
        print("Map icon button pressed")
        let aerialView = AerialView(panorama: panorama, currentIndex: self.currentImageIndex)
        let hostingController = UIHostingController(rootView: aerialView)
        
        // Check if self.navigationController is not nil
        if let navigationController = self.navigationController {
            navigationController.pushViewController(hostingController, animated: true)
            print("AerialView pushed onto navigation stack")
        } else {
            print("No navigation controller found")
        }
    }

    
    func setupARScene() {
        sceneView = ARSCNView(frame: self.view.frame)
        self.view.addSubview(sceneView)
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.scene = SCNScene()
    }
    
    //this will add fun facts on top screen
    
    func addFunFacts() {
        let funFacts = UIHostingController(rootView: FanFactsView())
        self.addChild(funFacts)
        funFacts.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(funFacts.view)
        
        NSLayoutConstraint.activate([
            funFacts.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            funFacts.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            funFacts.view.topAnchor.constraint(equalTo: self.view.topAnchor), // Changed from bottomAnchor to topAnchor
            funFacts.view.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    func addHorizontalPicker() {
        let horizontalPicker = UIHostingController(rootView: HorizontalPickerView(images: images, onImageSelected: { index in
            self.currentImageIndex = index!
            self.replaceBuildingWithPhoto(identifier: self.images[index!])
        }))
        
        self.addChild(horizontalPicker)
        horizontalPicker.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(horizontalPicker.view)
        
        NSLayoutConstraint.activate([
            horizontalPicker.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            horizontalPicker.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            horizontalPicker.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            horizontalPicker.view.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        horizontalPicker.didMove(toParent: self)
    }


    func startLocationServices() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        } else {
            print("Location services not authorized")
        }
    }
    
    func configureARSession() {
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("ARKit is not available on this device.")
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        
        sceneView.session.run(configuration)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
    }
    func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
        //guard let heading = heading else { return }
        currentHeading = heading
    }
    
    func removePanoramicImageNode() {
        if let existingNode = sceneView.scene.rootNode.childNode(withName: "panoramicImage", recursively: true) {
            existingNode.removeFromParentNode()
        }
    }
    
    func replaceBuildingWithPhoto(identifier: PanoImages?) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let identifier = identifier, let originalImage = UIImage(named: identifier.name) {
                guard let mirroredImage = self.mirrorImage(originalImage) else { return }

                DispatchQueue.main.async { [self] in
                    // Remove all existing panoramic image nodes
                    self.removePanoramicImageNode()
                    sceneView.scene = SCNScene()
                    //sceneView.scene.
                    
                    // Add the new panoramic image node
                    let sphere = SCNSphere(radius: 10)
                    let sphereMaterial = SCNMaterial()
                    sphereMaterial.diffuse.contents = mirroredImage
                    sphereMaterial.isDoubleSided = true
                    sphere.materials = [sphereMaterial]
                    
                    let sphereNode = SCNNode(geometry: sphere)
                    sphereNode.position = SCNVector3(0, 0, 0)
                    
//                    var offsetAngle = currentHeading!.trueHeading - 180
//                    var offsetRad = Float(offsetAngle) * Float.pi/180
//                    
//                    print(currentHeading!.trueHeading)
//                    print(offsetAngle)
//                    print(offsetRad)
//                    

                    var north_rotation = (Float(identifier.north_rotation) + Float(currentHeading!.trueHeading))  * Float.pi/180
                    //sphereNode.rotation = SCNVector4(0,1,0, offsetRad)
                    sphereNode.rotation = SCNVector4(0,1,0, north_rotation)
                    //}
                
                    //sphereNode.rotation = SCNVector4(0,0,1, 45)
                    sphereNode.name = "panoramicImage"
                    self.sceneView.scene.rootNode.addChildNode(sphereNode)
                }
            } else {
                DispatchQueue.main.async {
                    // No image selected; remove all panoramic image nodes and show the AR camera
                    self.removePanoramicImageNode()
                }
            }
        }
    }
    
  
    
    func mirrorImage(_ image: UIImage) -> UIImage? {
        UIGraphicsBeginImageContext(image.size)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        context.translateBy(x: image.size.width, y: image.size.height)
        context.scaleBy(x: -1.0, y: -1.0)

        context.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        let mirroredImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return mirroredImage
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        print("AR session failed with error: \(error.localizedDescription)")
        sceneView.session.run(sceneView.session.configuration!, options: [.resetTracking, .removeExistingAnchors])
    }
}

