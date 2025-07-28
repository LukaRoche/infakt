//
//  MainController+WKNavigationDelegate.swift
//  Infakt
//
//  Created by Łukasz Stoiński on 28/07/2025.
//

import UIKit
import WebKit

// MARK: - WKNavigationDelegate Methods
extension MainController: WKNavigationDelegate {
    // Method called when WebView starts loading a page
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("Started loading: \(webView.url?.absoluteString ?? "unknown URL")")
        // You can add an activity indicator here
    }

    // Method called when WebView finishes loading a page
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Finished loading: \(webView.url?.absoluteString ?? "unknown URL")")
        // You can hide the activity indicator here
        
        // Injecting JavaScript functions into the page after loading (example for camera)
        // This function will allow the web page to call the native camera
        let javascriptCameraFunction = """
            // Example JS function to open the camera
            function openNativeCamera() {
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.cameraHandler) {
                    window.webkit.messageHandlers.cameraHandler.postMessage('openCamera');
                } else {
                    console.log('Camera feature available only in the mobile app.');
                }
            }

            // Function to receive the image from the native app
            function receiveCameraImage(base64String) {
                console.log('Received camera image (start):', base64String.substring(0, 50) + '...');
                // Here you can display the image or send it to the server
            }
        """
        webView.evaluateJavaScript(javascriptCameraFunction) { (result, error) in
            if let error = error {
                print("Error injecting JavaScript for camera: \(error.localizedDescription)")
            } else {
                print("JavaScript for camera injected successfully.")
            }
        }
        
        // Injecting JavaScript functions into the page after loading (example for Face ID)
        // This function will allow the web page to call native Face ID
        let javascriptFaceIDFunction = """
            // Example JS function to trigger Face ID
            function loginWithFaceID() {
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.faceIDHandler) {
                    window.webkit.messageHandlers.faceIDHandler.postMessage('authenticate');
                } else {
                    console.log('Face ID available only in the mobile app.');
                }
            }

            // Function to receive the authentication result from the native app
            function handleFaceIDResult(success, errorMessage) {
                if (success) {
                    console.log('Face ID login successful!');
                    // Here you can perform user login on the web page
                    // For example, you can automatically click a login button
                    // or redirect the user
                } else {
                    console.log('Face ID login failed: ' + (errorMessage || 'Unknown error.'));
                    // Here you can display an error message on the web page
                }
            }
        """
        webView.evaluateJavaScript(javascriptFaceIDFunction) { (result, error) in
            if let error = error {
                print("Error injecting JavaScript for Face ID: \(error.localizedDescription)")
            } else {
                print("JavaScript for Face ID injected successfully.")
            }
        }
        
        // Injecting JavaScript functions into the page after loading (example for Push Notifications)
        let javascriptPushNotificationFunction = """
            // Function to receive push notification data from the native app
            function handlePushNotification(payload) {
                console.log('Received push notification in JS:', payload);
                // Here you can update the web page UI or perform other actions
                alert('Push Notification: ' + payload.aps.alert.body);
            }

            // Function to send the device token to JS (if available)
            function setDeviceToken(token) {
                console.log('Received device token in JS:', token);
                // You can save this token in localStorage or send it to your server
            }
        """
        webView.evaluateJavaScript(javascriptPushNotificationFunction) { (result, error) in
            if let error = error {
                print("Error injecting JavaScript for Push Notifications: \(error.localizedDescription)")
            } else {
                print("JavaScript for Push Notifications injected successfully.")
            }
        }
        
        // If device token is already available, send it to JS
        if let token = devicePushToken {
            self.webView.evaluateJavaScript("setDeviceToken('\(token)');")
        }

        // --- New logic: Require Face ID for login ---
        // Check if the current URL is the login page
        if webView.url?.host == "konto.infakt.pl" {
            print("Detected login page. Triggering Face ID authentication.")
            // Call the native biometric authentication function
            authenticateWithBiometrics()
            
        }
        // --- End of new logic ---
    }

    // Method called in case of an error during page loading
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("Loading error: \(error.localizedDescription)")
        // You can display an error message to the user here
    }

    // Method to decide whether WebView should allow navigation to a given URL
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            print("Attempting to navigate to: \(url.absoluteString)")
            
            // Example: Automatic redirection to front.infakt.pl after logging in on konto.infakt.pl
            // If the URL contains "front.infakt.pl", allow navigation
            if url.host == "front.infakt.pl" {
                decisionHandler(.allow)
                return
            }
            
            // If the URL is konto.infakt.pl, allow navigation
            if url.host == "konto.infakt.pl" {
                decisionHandler(.allow)
                return
            }
        }
        decisionHandler(.allow) // Default to allow navigation
    }
}
