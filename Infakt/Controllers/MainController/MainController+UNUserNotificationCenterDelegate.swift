//
//  MainController+UNUserNotificationCenterDelegate.swift
//  Infakt
//
//  Created by Łukasz Stoiński on 28/07/2025.
//

import UIKit
import UserNotifications // Import UserNotifications for push notification handling

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
