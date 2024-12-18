//
//  ImagePicker.swift
//  FacialExpressionDetector
//
//  Created by Muhammadjon on 12/12/24.
//

import SwiftUI
import Mentalist

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var detectedEmotion: String
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary // Change to .camera to open camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
                print("Image successfully selected.")
                detectEmotion(image: uiImage) // Call to detect emotion
            } else {
                print("Error: No image was selected.")
            }
            picker.dismiss(animated: true)
        }
        
        func detectEmotion(image: UIImage) {
            print("Starting emotion detection...")
            
            // Convert UIImage to SwiftUI.Image
            let swiftUIImage = Image(uiImage: image)
            
            do {
                // Use Mentalist to analyze the image
                let analysisResults = try Mentalist.analyze(image: swiftUIImage)
                if let firstAnalysis = analysisResults.first {
                    parent.detectedEmotion = firstAnalysis.dominantEmotion.rawValue
                    print("Detected Emotion: \(parent.detectedEmotion)")
                } else {
                    parent.detectedEmotion = "No face detected"
                    print("No face detected in the image.")
                }
            } catch {
                parent.detectedEmotion = "Error analyzing image: \(error.localizedDescription)"
                print("Error analyzing image: \(error)")
            }
        }
    }
}
