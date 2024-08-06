//
//  UserAerialView.swift
//  Chrononauts
//
//  Created by FredyCamas on 7/27/24.
//

import ARKit
import Combine
import CoreLocation
import SwiftUI

class ARUserPhotoView: UIViewController, ARSCNViewDelegate, CLLocationManagerDelegate, ARSessionDelegate {
    var sceneView: ARSCNView!
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var userPhoto: UserPhoto // Single UserPhoto instance
    
    init(userPhoto: UserPhoto) {
        self.userPhoto = userPhoto
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
        addFunFacts()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cleanupARResources()
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
    
    func setupARScene() {
        sceneView = ARSCNView(frame: self.view.frame)
        self.view.addSubview(sceneView)
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.scene = SCNScene()
        
        // Display the user photo
        displayUserPhoto()
    }
    
    func displayUserPhoto() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let imageData = self.userPhoto.imageData,
                  let originalImage = UIImage(data: imageData),
                  let mirroredImage = self.mirrorImage(originalImage) else { return }

            DispatchQueue.main.async {
                let sphere = SCNTube(innerRadius: 199, outerRadius: 200, height: 300)
                let sphereMaterial = SCNMaterial()
                sphereMaterial.diffuse.contents = mirroredImage
                sphereMaterial.isDoubleSided = true
                sphere.materials = [sphereMaterial]

                let sphereNode = SCNNode(geometry: sphere)
                sphereNode.position = SCNVector3(0, 0, 0)
                sphereNode.name = "userPhoto"
                self.sceneView.scene.rootNode.addChildNode(sphereNode)
            }
        }
    }
    
    func startLocationServices() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.startUpdatingLocation()
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
