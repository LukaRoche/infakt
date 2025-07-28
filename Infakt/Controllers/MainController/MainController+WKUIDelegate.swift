//
//  MainController+WKUIDelegate.swift
//  Infakt
//
//  Created by Łukasz Stoiński on 28/07/2025.
//

import UIKit
import WebKit // Import the WebKit framework for WKWebView

// MARK: - WKUIDelegate Methods (Handling JavaScript alerts and file selection)
extension MainController: WKUIDelegate {
    // Handle JavaScript alerts (e.g., alert(), confirm(), prompt())
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            completionHandler()
        }))
        present(alertController, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            completionHandler(false)
        }))
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            completionHandler(true)
        }))
        present(alertController, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = defaultText
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            completionHandler(nil)
        }))
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            completionHandler(alertController.textFields?.first?.text)
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    // Handle file selection from input type="file" in WebView for iOS 17.0 and earlier
    func webView(_ webView: WKWebView, runOpenPanelWith completionHandler: @escaping ([URL]?) -> Void) {
        let alertController = UIAlertController(title: "Choose Source", message: nil, preferredStyle: .actionSheet)

        // "Take Photo" option
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alertController.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { _ in
                self.presentImagePicker(sourceType: .camera, completion: completionHandler)
            }))
        }

        // "Choose from Gallery" option
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alertController.addAction(UIAlertAction(title: "Choose from Gallery", style: .default, handler: { _ in
                self.presentImagePicker(sourceType: .photoLibrary, completion: completionHandler)
            }))
        }

        // "Cancel" option
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            completionHandler(nil) // Cancel selection
        }))

        // Present the action sheet
        present(alertController, animated: true, completion: nil)
    }
}
