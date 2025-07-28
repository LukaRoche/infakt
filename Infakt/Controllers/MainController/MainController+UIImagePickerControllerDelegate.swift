//
//  MainController+UIImagePickerControllerDelegate.swift
//  Infakt
//
//  Created by Łukasz Stoiński on 28/07/2025.
//

import UIKit
import WebKit // Import the WebKit framework for WKWebView

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate (Image Selection Handling)
extension MainController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // Function to present UIImagePickerController
    func presentImagePicker(sourceType: UIImagePickerController.SourceType, completion: (([URL]?) -> Void)? = nil) {
        // Set the completion handler for file selection from WebView
        if let completion = completion {
            self.fileChooserCompletionHandler = { url in
                if let url = url {
                    completion([url])
                } else {
                    completion(nil)
                }
            }
        } else {
            self.fileChooserCompletionHandler = nil // Reset for direct JS call
        }
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        picker.allowsEditing = false // You can set to true if you want to allow image editing
        present(picker, animated: true, completion: nil)
    }

    // Method called after an image is selected
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil) // Dismiss the picker
        
        if let image = info[.originalImage] as? UIImage {
            // Resize the image before sending it to JavaScript (optional, but recommended for large images)
            let resizedImage = image.resized(toWidth: 800) // Change width as needed
            
            if let imageData = resizedImage?.jpegData(compressionQuality: 0.8) { // Compress to JPEG
                let base64String = imageData.base64EncodedString(options: .lineLength64Characters)
                
                // Send image data in Base64 format to JavaScript
                let js = "window.receiveCameraImage('\(base64String)');"
                webView.evaluateJavaScript(js) { (result, error) in
                    if let error = error {
                        print("Error sending image to JavaScript: \(error.localizedDescription)")
                    } else {
                        print("Image sent to JavaScript successfully.")
                    }
                }
                
                // If this was a call from input type="file", save the image temporarily and pass the URL
                if let handler = fileChooserCompletionHandler {
                    let tempDirectory = FileManager.default.temporaryDirectory
                    let fileName = UUID().uuidString + ".jpg"
                    let fileURL = tempDirectory.appendingPathComponent(fileName)
                    
                    do {
                        try imageData.write(to: fileURL)
                        handler(fileURL)
                    } catch {
                        print("Error writing temporary file: \(error)")
                        handler(nil)
                    }
                    fileChooserCompletionHandler = nil // Reset handler
                }
            }
        }
    }

    // Method called when image selection is cancelled
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        
        // If this was a call from input type="file", inform WebView about cancellation
        fileChooserCompletionHandler?(nil)
        fileChooserCompletionHandler = nil
    }
}
