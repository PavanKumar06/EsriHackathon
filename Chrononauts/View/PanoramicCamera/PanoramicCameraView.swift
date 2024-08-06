//
//  PanoramicCameraView.swift
//  Chrononauts
//
//  Created by FredyCamas on 7/28/24.
//

import SwiftUI
import AVFoundation
import UIKit
import CoreLocation

struct PanoramicCameraView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedImage: UIImage?
    @Binding var imageCreationDate: Date?
    @Binding var imageLocation: CLLocation?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        context.coordinator.setupCaptureSession(in: viewController.view)
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate, CLLocationManagerDelegate {
        var parent: PanoramicCameraView
        var photoOutput: AVCapturePhotoOutput?
        var isCapturing = false
        var captureTimer: Timer?
        let captureInterval: TimeInterval = 1.0
        var audioPlayer: AVAudioPlayer?
        var clickSoundPlayer: AVAudioPlayer?
        var progressLayer: CAShapeLayer?
        var captureButton: UIButton?
        var retakeButton: UIButton?
        var usePhotosButton: UIButton?
        var images: [UIImage] = []
        var locationManager: CLLocationManager?
        var currentLocation: CLLocation?

        init(_ parent: PanoramicCameraView) {
            self.parent = parent
            super.init()

            if let soundURL = Bundle.main.url(forResource: "shutter", withExtension: "wav") {
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                    audioPlayer?.prepareToPlay()
                } catch {
                    print("Error loading sound effect: \(error)")
                }
            }

            if let clickSoundURL = Bundle.main.url(forResource: "click", withExtension: "wav") {
                do {
                    clickSoundPlayer = try AVAudioPlayer(contentsOf: clickSoundURL)
                    clickSoundPlayer?.prepareToPlay()
                } catch {
                    print("Error loading click sound effect: \(error)")
                }
            }

            setupLocationManager()
        }

        func setupLocationManager() {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
            locationManager?.requestWhenInUseAuthorization()
        }

        func startLocationUpdates() {
            locationManager?.startUpdatingLocation()
        }

        func stopLocationUpdates() {
            locationManager?.stopUpdatingLocation()
        }

        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            if let location = locations.last {
                currentLocation = location
                print("Current location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            }
        }

        @objc func startCapturing() {
            guard !isCapturing else { return }
            isCapturing = true
            captureImages()
            updateProgressIndicator(0)
            retakeButton?.isHidden = true
            usePhotosButton?.isHidden = true
            startLocationUpdates()
        }

        func captureImages() {
            guard isCapturing, let photoOutput = self.photoOutput else {
                print("Photo output is not set up correctly.")
                return
            }

            captureTimer = Timer.scheduledTimer(withTimeInterval: captureInterval, repeats: true) { _ in
                let photoSettings = AVCapturePhotoSettings()
                photoOutput.capturePhoto(with: photoSettings, delegate: self)
                self.audioPlayer?.play()
                print("Capture photo triggered.")
            }
        }

        func stopCapturing() {
            guard isCapturing else { return }
            isCapturing = false
            captureTimer?.invalidate()
            captureTimer = nil

            UIView.animate(withDuration: 0.3) {
                self.retakeButton?.isHidden = false
                self.usePhotosButton?.isHidden = false
            }

            updateProgressIndicator(1.0)
            stopLocationUpdates()
        }

        @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
            if gestureRecognizer.state == .began {
                clickSoundPlayer?.play()
                captureButton?.backgroundColor = .green
                startCapturing()
            } else if gestureRecognizer.state == .ended {
                captureButton?.backgroundColor = .white
                stopCapturing()
            }
        }

        @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
            capturePhoto()
        }

        @objc func capturePhoto() {
            startCapturing()
        }

        @objc func retakePhotos() {
            images.removeAll()
            startCapturing()
        }

        @objc func useCapturedPhotos() {
            stitchImages(images: images) { panoramicImage in
                if let panoramicImage = panoramicImage {
                    self.parent.selectedImage = panoramicImage
                    self.parent.imageCreationDate = Date()
                    self.parent.imageLocation = self.currentLocation
                    DispatchQueue.main.async {
                        self.parent.presentationMode.wrappedValue.dismiss()
                    }
                } else {
                    print("Failed to create panoramic image")
                }
            }
        }

        func updateProgressIndicator(_ progress: CGFloat) {
            DispatchQueue.main.async {
                self.progressLayer?.strokeEnd = progress
            }
        }

        func stitchImages(images: [UIImage], completion: @escaping (UIImage?) -> Void) {
            guard !images.isEmpty else {
                print("No images to stitch.")
                completion(nil)
                return
            }

            let imageSize = images[0].size
            for image in images {
                if image.size != imageSize {
                    print("Mismatch in image sizes. All images should have the same size.")
                    completion(nil)
                    return
                }
            }

            let totalWidth = imageSize.width * CGFloat(images.count)
            let imageHeight = imageSize.height

            UIGraphicsBeginImageContext(CGSize(width: totalWidth, height: imageHeight))

            guard let context = UIGraphicsGetCurrentContext() else {
                print("Failed to get graphics context.")
                UIGraphicsEndImageContext()
                completion(nil)
                return
            }

            for (index, image) in images.enumerated() {
                let xOffset = CGFloat(index) * imageSize.width
                context.draw(image.cgImage!, in: CGRect(x: xOffset, y: 0, width: imageSize.width, height: imageHeight))
            }

            let stitchedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            if let stitchedImage = stitchedImage {
                let targetWidth: CGFloat = 1000
                let scaleFactor = targetWidth / stitchedImage.size.width
                let targetSize = CGSize(width: targetWidth, height: stitchedImage.size.height * scaleFactor)

                UIGraphicsBeginImageContext(targetSize)
                stitchedImage.draw(in: CGRect(origin: .zero, size: targetSize))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()

                completion(resizedImage)
            } else {
                print("Failed to create stitched image.")
                completion(nil)
            }
        }

        func setupCaptureSession(in view: UIView) {
            let captureSession = AVCaptureSession()
            captureSession.sessionPreset = .photo

            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
                print("No video capture device found.")
                return
            }

            guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
                print("Cannot create video input.")
                return
            }

            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                print("Cannot add video input.")
                return
            }

            let photoOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
                self.photoOutput = photoOutput
            } else {
                print("Cannot add photo output.")
                return
            }

            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)

            setupCaptureButton(in: view)
            setupRetakeButton(in: view)
            setupUsePhotosButton(in: view)
            setupProgressIndicator(in: view)

            captureSession.startRunning()
        }

        func setupCaptureButton(in view: UIView) {
            let captureButton = UIButton(type: .custom)
            captureButton.backgroundColor = .white
            captureButton.layer.cornerRadius = 35
            captureButton.clipsToBounds = true

            captureButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(captureButton)

            NSLayoutConstraint.activate([
                captureButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
                captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                captureButton.widthAnchor.constraint(equalToConstant: 70),
                captureButton.heightAnchor.constraint(equalToConstant: 70)
            ])

            let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            longPressGestureRecognizer.minimumPressDuration = 0.1
            captureButton.addGestureRecognizer(longPressGestureRecognizer)

            self.captureButton = captureButton
        }

        func setupRetakeButton(in view: UIView) {
            let retakeButton = UIButton(type: .custom)
            retakeButton.backgroundColor = .red
            retakeButton.setTitle("Retake", for: .normal)
            retakeButton.layer.cornerRadius = 10
            retakeButton.clipsToBounds = true
            retakeButton.addTarget(self, action: #selector(retakePhotos), for: .touchUpInside)

            retakeButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(retakeButton)

            NSLayoutConstraint.activate([
                retakeButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
                retakeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                retakeButton.widthAnchor.constraint(equalToConstant: 100),
                retakeButton.heightAnchor.constraint(equalToConstant: 50)
            ])

            self.retakeButton = retakeButton
        }

        func setupUsePhotosButton(in view: UIView) {
            let usePhotosButton = UIButton(type: .custom)
            usePhotosButton.backgroundColor = .green
            usePhotosButton.setTitle("Use", for: .normal)
            usePhotosButton.layer.cornerRadius = 10
            usePhotosButton.clipsToBounds = true
            usePhotosButton.addTarget(self, action: #selector(useCapturedPhotos), for: .touchUpInside)

            usePhotosButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(usePhotosButton)

            NSLayoutConstraint.activate([
                usePhotosButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
                usePhotosButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                usePhotosButton.widthAnchor.constraint(equalToConstant: 100),
                usePhotosButton.heightAnchor.constraint(equalToConstant: 50)
            ])

            self.usePhotosButton = usePhotosButton
        }

        func setupProgressIndicator(in view: UIView) {
            let circularPath = UIBezierPath(arcCenter: CGPoint(x: 35, y: 35), radius: 35, startAngle: -(.pi / 2), endAngle: .pi * 1.5, clockwise: true)

            let progressLayer = CAShapeLayer()
            progressLayer.path = circularPath.cgPath
            progressLayer.strokeColor = UIColor.blue.cgColor
            progressLayer.lineWidth = 5
            progressLayer.strokeEnd = 0
            progressLayer.fillColor = UIColor.clear.cgColor

            captureButton?.layer.addSublayer(progressLayer)

            self.progressLayer = progressLayer
        }

        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            if let error = error {
                print("Error capturing photo: \(error)")
                return
            }

            guard let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) else {
                print("Error converting photo to UIImage.")
                return
            }

            images.append(image)

            if images.count >= 20 {
                stopCapturing()
            } else {
                let progress = CGFloat(images.count) / 20.0
                updateProgressIndicator(progress)
            }
        }
    }
}
