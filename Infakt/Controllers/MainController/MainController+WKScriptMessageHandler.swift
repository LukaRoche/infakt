//
//  MainController+WKScriptMessageHandler.swift
//  Infakt
//
//  Created by Łukasz Stoiński on 28/07/2025.
//

import UIKit
import WebKit // Import the WebKit framework for WKWebView
import AVFoundation // Import AVFoundation for camera interaction

// MARK: - WKScriptMessageHandler (JavaScript -> Swift Communication)
extension MainController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // Check if the message is from our 'cameraHandler'
        if message.name == "cameraHandler" {
            // Check if the message is 'openCamera'
            if let messageBody = message.body as? String, messageBody == "openCamera" {
                // Present the source selection (camera/gallery)
                let alertController = UIAlertController(title: "Choose Photo Source", message: nil, preferredStyle: .actionSheet)

                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    alertController.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
                        self.presentImagePicker(sourceType: .camera)
                    }))
                }

                if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                    alertController.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
                        self.presentImagePicker(sourceType: .photoLibrary)
                    }))
                }

                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                present(alertController, animated: true, completion: nil)
            }
        } else if message.name == "faceIDHandler" { // Handle messages from faceIDHandler
            if let messageBody = message.body as? String, messageBody == "authenticate" {
                authenticateWithBiometrics()
            }
        } else if message.name == "pushNotificationHandler" { // Handle messages from pushNotificationHandler
            // This handler can be used to send a test notification from JS to the native app
            // or to confirm that JS has received the device token.
            if let messageBody = message.body as? String {
                print("Message from JS to pushNotificationHandler: \(messageBody)")
                // For example, if JS sends 'getDeviceToken', you can return it
                if messageBody == "getDeviceToken" {
                    if let token = devicePushToken {
                        webView.evaluateJavaScript("setDeviceToken('\(token)');")
                    } else {
                        webView.evaluateJavaScript("setDeviceToken(null);")
                    }
                }
            }
        }
    }
}
