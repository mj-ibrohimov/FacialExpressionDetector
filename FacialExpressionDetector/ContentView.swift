//
//  ContentView.swift
//  FacialExpressionDetector
//
//  Created by Muhammadjon on 12/12/24.
//
import SwiftUI

struct ContentView: View {
    @State private var image: UIImage?
    @State private var detectedEmotion: String = ""
    @State private var isImagePickerPresented = false
    
    var body: some View {
        VStack {
            // Display the selected image
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .padding()
            } else {
                Text("Select an Image to Analyze")
                    .foregroundColor(.gray)
                    .padding()
            }
            
            // Display detected emotion
            Text("Detected Emotion: \(detectedEmotion)")
                .font(.title2)
                .foregroundColor(.blue)
                .padding()
            
            // Button to open ImagePicker
            Button(action: {
                isImagePickerPresented.toggle()
            }) {
                Text("Choose Photo")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(image: $image, detectedEmotion: $detectedEmotion)
        }
    }
}
