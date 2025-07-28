//
//  MainController.swift
//  Infakt
//
//  Created by Łukasz Stoiński on 22/07/2025.
//

import UIKit
import WebKit // Import the WebKit framework for WKWebView
import AVFoundation // Import AVFoundation for camera interaction
import LocalAuthentication // Import LocalAuthentication for Face ID/Touch ID

class MainController: UIViewController {

    var webView: WKWebView! // Declaration of the WKWebView variable
    
    // Variable to store the completion handler for file selection from WebView
    var fileChooserCompletionHandler: ((URL?) -> Void)?
    
    // Variable to store the device push token
    var devicePushToken: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        setupWebView() // Configure and add WebView to the view
        loadInitialURL() // Load the initial URL
    }

    // Function to configure WKWebView
    private func setupWebView() {
        // Configuration settings for WKWebView
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true // Allows JavaScript to open windows automatically

        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        
        // Add a user content controller to the configuration
        let userContentController = WKUserContentController()
        // Add message handlers for Swift <-> JavaScript communication
        userContentController.add(self, name: "cameraHandler") // Handler for the camera
        userContentController.add(self, name: "faceIDHandler") // Handler for Face ID
        userContentController.add(self, name: "pushNotificationHandler") // New handler for push notifications
        configuration.userContentController = userContentController
        
        // Initialize WKWebView with the configuration
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self // Set the navigation delegate
        webView.uiDelegate = self // Set the UI delegate (for handling JS alerts, etc.)
        
        // Add WebView as a subview to the main view controller's view
        view.addSubview(webView)
        
        // Set constraints for WebView to fill the entire screen
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), // Pin to the top safe area
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor), // Pin to the left edge
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor), // Pin to the right edge
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor) // Pin to the bottom safe area
        ])
    }

    // Function to load the initial URL
    private func loadInitialURL() {
        if let url = URL(string: "https://konto.infakt.pl") { // Authorization app URL
            let request = URLRequest(url: url)
            webView.load(request) // Load the request into WebView
        }
    }

    
    // Method to handle the device token received from AppDelegate
    func handleDeviceToken(_ token: String) {
        self.devicePushToken = token
        print("ViewController received Device Token: \(token)")
        // Once the token is received, if WebView is already loaded, send it to JavaScript
        if webView.url != nil {
            webView.evaluateJavaScript("setDeviceToken('\(token)');") { (result, error) in
                if let error = error {
                    print("Error sending device token to JS: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Method to pass push notification data to JavaScript
    func handlePushNotification(userInfo: [AnyHashable: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: userInfo, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                // Escape JSON string for JavaScript safely
                let escapedJsonString = jsonString.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "'", with: "\\'").replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "\r", with: "\\r")
                let js = "window.handlePushNotification(\(escapedJsonString));"
                webView.evaluateJavaScript(js) { (result, error) in
                    if let error = error {
                        print("Error sending push notification to JavaScript: \(error.localizedDescription)")
                    } else {
                        print("Push notification sent to JavaScript successfully.")
                    }
                }
            }
        } catch {
            print("Error serializing notification data: \(error.localizedDescription)")
        }
    }
}

// MARK: - Face ID / Touch ID Authentication
extension MainController {
     func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?

        // Check if biometric authentication is possible
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Log in with Face ID / Touch ID to access the application."

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        // Authentication successful
                        print("Biometric authentication successful.")
                        self?.webView.evaluateJavaScript("window.handleFaceIDResult(true);") { (result, error) in
                            if let error = error {
                                print("Error sending Face ID result to JS: \(error.localizedDescription)")
                            }
                        }
                    } else {
                        // Authentication failed
                        let errorMessage = authenticationError?.localizedDescription ?? "Unknown biometric authentication error."
                        print("Biometric authentication failed: \(errorMessage)")
                        self?.webView.evaluateJavaScript("window.handleFaceIDResult(false, '\(errorMessage)');") { (result, error) in
                            if let error = error {
                                print("Error sending Face ID result to JS: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        } else {
            // Biometric authentication is not available
            let errorMessage = error?.localizedDescription ?? "Biometric authentication is not available on this device or is not configured."
            print("Biometric authentication unavailable: \(errorMessage)")
            self.webView.evaluateJavaScript("window.handleFaceIDResult(false, '\(errorMessage)');") { (result, error) in
                if let error = error {
                    print("Error sending Face ID result to JS: \(error.localizedDescription)")
                }
            }
        }
    }
}
