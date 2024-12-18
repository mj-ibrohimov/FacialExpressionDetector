//
//  CameraViewController.swift
//  FacialExpressionDetector
//
//  Created by Muhammadjon on 12/12/24.
//

import UIKit
import AVFoundation
import Vision

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var currentDevice: AVCaptureDevice!
    private var currentDeviceInput: AVCaptureDeviceInput!
    private var photoOutput: AVCapturePhotoOutput!

    private var currentCameraPosition: AVCaptureDevice.Position = .back

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera(position: .back) // Start with the back camera
    }

    // Setup camera with front or back position
    private func setupCamera(position: AVCaptureDevice.Position) {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        // Replacing deprecated devices(for:) with DiscoverySession
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                                mediaType: .video,
                                                                position: position)
        
        guard let device = discoverySession.devices.first else {
            print("No camera found")
            return
        }

        currentDevice = device

        do {
            let input = try AVCaptureDeviceInput(device: currentDevice)

            if let currentDeviceInput = currentDeviceInput {
                captureSession.removeInput(currentDeviceInput)
            }

            captureSession.addInput(input)
            currentDeviceInput = input

            photoOutput = AVCapturePhotoOutput()
            captureSession.addOutput(photoOutput)

            setupPreviewLayer()
            captureSession.startRunning()
        } catch {
            print("Error setting up camera: \(error)")
        }
    }

    // Setup the preview layer
    private func setupPreviewLayer() {
        if previewLayer != nil {
            previewLayer.removeFromSuperlayer()
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
    }

    // Toggle camera between front and back
    func toggleCamera() {
        let newPosition: AVCaptureDevice.Position = (currentCameraPosition == .back) ? .front : .back
        currentCameraPosition = newPosition
        setupCamera(position: newPosition)
    }

    // Capture photo and analyze facial expression
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // Delegate method for capturing photo
    func capture(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { return }

        analyzeFacialExpression(on: image)
    }

    // Analyze facial expression on the captured photo
    private func analyzeFacialExpression(on image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let faceDetectionRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
            guard let results = request.results as? [VNFaceObservation], error == nil else { return }
            DispatchQueue.main.async {
                self?.handleFaceObservations(results)
            }
        }

        do {
            try requestHandler.perform([faceDetectionRequest])
        } catch {
            print("Failed to perform request: \(error)")
        }
    }

    // Handle face observations and draw the bounding box
    private func handleFaceObservations(_ observations: [VNFaceObservation]) {
        for face in observations {
            let boundingBox = face.boundingBox
            let faceRect = CGRect(
                x: boundingBox.origin.x * view.bounds.width,
                y: (1 - boundingBox.origin.y - boundingBox.height) * view.bounds.height,
                width: boundingBox.width * view.bounds.width,
                height: boundingBox.height * view.bounds.height
            )
            drawFaceRectangle(at: faceRect)
            analyzeFacialExpression(for: face, in: faceRect)
        }
    }

    // Draw face rectangle on the screen
    private func drawFaceRectangle(at rect: CGRect) {
        view.layer.sublayers?.removeAll(where: { $0.name == "faceRect" })
        
        let faceLayer = CALayer()
        faceLayer.name = "faceRect"
        faceLayer.frame = rect
        faceLayer.borderColor = UIColor.red.cgColor
        faceLayer.borderWidth = 2
        view.layer.addSublayer(faceLayer)
    }

    // Analyze facial expression (e.g., smile)
    private func analyzeFacialExpression(for face: VNFaceObservation, in faceRect: CGRect) {
        guard let landmarks = face.landmarks,
              let outerLips = landmarks.outerLips else { return }

        let points = outerLips.normalizedPoints

        guard points.count >= 4 else { return }
        let leftMouthCorner = points.first!
        let rightMouthCorner = points.last!
        let upperLipMid = points[points.count / 2 - 1]
        let lowerLipMid = points[points.count / 2 + 1]

        func convertPoint(_ point: CGPoint) -> CGPoint {
            return CGPoint(
                x: point.x * view.bounds.width,
                y: (1 - point.y) * view.bounds.height
            )
        }

        let leftCorner = convertPoint(leftMouthCorner)
        let rightCorner = convertPoint(rightMouthCorner)
        let upperMid = convertPoint(upperLipMid)
        let lowerMid = convertPoint(lowerLipMid)

        let mouthWidth = hypot(rightCorner.x - leftCorner.x, rightCorner.y - leftCorner.y)
        let mouthHeight = abs(lowerMid.y - upperMid.y)

        let smileRatio = mouthHeight / mouthWidth
        let smilePercentage = min(Int(smileRatio * 200), 100)

        showExpressionOverlay(text: "Smile: \(smilePercentage)%", at: faceRect)
    }

    // Show the expression percentage on screen
    private func showExpressionOverlay(text: String, at rect: CGRect) {
        let labelLayer = CATextLayer()
        labelLayer.name = "expressionOverlay"
        labelLayer.string = text
        labelLayer.foregroundColor = UIColor.white.cgColor
        labelLayer.fontSize = 14
        labelLayer.alignmentMode = .center
        labelLayer.frame = CGRect(x: rect.origin.x, y: rect.origin.y - 20, width: rect.width, height: 20)
        view.layer.addSublayer(labelLayer)
    }
}

