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
import UserNotifications // Import UserNotifications for push notification handling

// Extension for UIImage to resize images
extension UIImage {
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

class MainController: UIViewController, WKNavigationDelegate {

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
        
        // Set the UNUserNotificationCenter delegate to self (for handling notifications)
        // This is important so the ViewController can receive notifications when the app is active
        UNUserNotificationCenter.current().delegate = self
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

    // MARK: - WKNavigationDelegate Methods

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
                // const img = document.createElement('img');
                // img.src = 'data:image/jpeg;base64,' + base64String;
                // document.body.appendChild(img);
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
                } else {
                    console.log('Face ID login failed: ' + (errorMessage || 'Unknown error.'));
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
        
        // Check if the URL is front.infakt.pl and optionally hide the navigation bar
        // if webView.url?.host == "front.infakt.pl" {
        //     self.navigationController?.setNavigationBarHidden(true, animated: true)
        // } else {
        //     self.navigationController?.setNavigationBarHidden(false, animated: true)
        // }
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
            
            // Handle other URLs (e.g., opening external links in Safari)
            // if !url.absoluteString.hasPrefix("https://konto.infakt.pl") && !url.absoluteString.hasPrefix("https://front.infakt.pl") {
            //     UIApplication.shared.open(url)
            //     decisionHandler(.cancel)
            //     return
            // }
        }
        decisionHandler(.allow) // Default to allow navigation
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

// MARK: - WKUIDelegate Methods (Handling JavaScript alerts and file selection)
extension MainController: WKUIDelegate  {
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

// MARK: - UNUserNotificationCenterDelegate (Handling notifications in ViewController)
extension MainController: UNUserNotificationCenterDelegate {
    
    // Method called when a notification is received in the foreground (app is active)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Notification received in foreground in ViewController: \(notification.request.content.userInfo)")
        
        // Pass notification data to WebView
        handlePushNotification(userInfo: notification.request.content.userInfo)
        
        // Decide how the notification should be presented (e.g., banner, sound, badge)
        completionHandler([.banner, .sound, .badge])
    }
    
    // Method called when the user interacts with a notification (e.g., taps it)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("User tapped notification in ViewController: \(response.notification.request.content.userInfo)")
        
        // Pass notification data to WebView
        handlePushNotification(userInfo: response.notification.request.content.userInfo)
        
        completionHandler()
    }
}
