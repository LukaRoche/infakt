//
//  AppDelegate.swift
//  Infakt
//
//  Created by Łukasz Stoiński on 22/07/2025.
//

import UIKit
import UserNotifications // Import UserNotifications for notification handling

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        // --- Push Notification Configuration ---
        UNUserNotificationCenter.current().delegate = self // Set the notification center delegate
        print("AppDelegate: Attempting to request notification authorization.")

        // Request authorization for notifications from the user
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("AppDelegate: User granted notification permissions.")
                DispatchQueue.main.async {
                    // Register the application for remote notifications
                    print("AppDelegate: Registering for remote notifications...")
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("AppDelegate: Notification authorization denied: \(error?.localizedDescription ?? "unknown error").")
            }
        }
        // --- End Push Notification Configuration ---

        return true
    }

    // MARK: UISceneSession Lifecycle (for projects with SceneDelegate)
    // These methods are essential for SceneDelegate-based apps.

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Remote Notification Registration Callbacks

    // Method called after successful registration with APNs
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("AppDelegate: !!! Device Token received: \(token) !!!") 
        
        // Correct way to access the rootViewController in a SceneDelegate-based app
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController as? MainController {
            rootViewController.handleDeviceToken(token)
        } else {
            print("AppDelegate: Could not find MainController (rootViewController) to pass device token.")
        }
    }

    // Method called in case of an error during APNs registration
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("AppDelegate: !!! FAILED TO REGISTER FOR REMOTE NOTIFICATIONS WITH ERROR: \(error.localizedDescription) !!!") // KLUCZOWY LOG BŁĘDU
        // Ten błąd jest często bardzo pomocny w diagnozowaniu problemów z rejestracją.
    }
}

// MARK: - UNUserNotificationCenterDelegate (Handling background and foreground notifications)
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // Method called when a notification is received in the foreground (app is active)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("AppDelegate: Notification received in foreground (willPresent): \(notification.request.content.userInfo)")
        
        // Pass notification data to WebView
        // Correct way to access the rootViewController in a SceneDelegate-based app
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController as? MainController {
            rootViewController.handlePushNotification(userInfo: notification.request.content.userInfo)
        } else {
            print("AppDelegate: Could not find ViewController (rootViewController) to pass push notification.")
        }
        
        // Decide how the notification should be presented (e.g., banner, sound, badge)
        completionHandler([.banner, .sound, .badge])
    }
    
    // Method called when the user interacts with a notification (e.g., taps it)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("AppDelegate: User tapped notification (didReceive): \(response.notification.request.content.userInfo)")
        
        // Pass notification data to WebView
        // Correct way to access the rootViewController in a SceneDelegate-based app
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController as? MainController {
            rootViewController.handlePushNotification(userInfo: response.notification.request.content.userInfo)
        } else {
            print("AppDelegate: Could not find ViewController (rootViewController) to pass tapped notification.")
        }
        
        completionHandler()
    }
}
