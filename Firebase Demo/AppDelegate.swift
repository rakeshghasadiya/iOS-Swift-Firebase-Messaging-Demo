//
//  AppDelegate.swift
//  Firebase Demo
//
//  Created by Rakesh Ghasadiya on 06/03/17.
//  Copyright © 2017 Rakesh Ghasadiya. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications
import FirebaseInstanceID
import FirebaseMessaging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
let gcmMessageIDKey = "gcm.message_id"

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
    
    // Register for remote notifications. This shows a permission dialog on first run, to
    // show the dialog at a more appropriate time move this registration accordingly.
    // [START register_for_notifications]
    if #available(iOS 10.0, *) {
      // For iOS 10 display notification (sent via APNS)
      UNUserNotificationCenter.current().delegate = self
      
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: {_, _ in })
      
      // For iOS 10 data message (sent via FCM)
      FIRMessaging.messaging().remoteMessageDelegate = self
      
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    application.registerForRemoteNotifications()
    
    // [END register_for_notifications]
    FIRApp.configure()
    
    // [START add_token_refresh_observer]
    // Add observer for InstanceID token refresh callback.
    NotificationCenter.default.addObserver(self,selector: #selector(self.tokenRefreshNotification(_:)),name: .firInstanceIDTokenRefresh,object: nil)
    // [END add_token_refresh_observer]
    
    
    return true
  }

  
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    // Print message ID.
    if let messageID = userInfo[gcmMessageIDKey] {
      print("Message ID: \(messageID)")
    }
    
    // Print full message.
    print(userInfo)
  }
  
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
     print("Unable to register for remote notifications: \(error.localizedDescription)")
  }
  
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
            print("APNs token retrieved: \(deviceToken)")
  }
  
 
  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    FIRMessaging.messaging().disconnect()
    print("Disconnected from FCM.")

  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    connectToFcm()

  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }

  
  func tokenRefreshNotification(_ notification: Notification) {
    if let refreshedToken = FIRInstanceID.instanceID().token() {
      print("InstanceID token: \(refreshedToken)")
    }
    
    // Connect to FCM since connection may have failed when attempted before having a token.
    connectToFcm()
  }
  // [END refresh_token]
  // [START connect_to_fcm]
  func connectToFcm() {
    // Won't connect since there is no token
    guard FIRInstanceID.instanceID().token() != nil else {
      return;
    }
    
    // Disconnect previous FCM connection if it exists.
    FIRMessaging.messaging().disconnect()
    
    FIRMessaging.messaging().connect { (error) in
      if error != nil {
        print("Unable to connect with FCM. \(error)")
      } else {
        print("Connected to FCM.")
      }
    }
  }
  // [END connect_to_fcm]

}


// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
  
  // Receive displayed notifications for iOS 10 devices.
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    // Print message ID.
    if let messageID = userInfo[gcmMessageIDKey] {
      print("Message ID: \(messageID)")
    }
    
    // Print full message.
    print(userInfo)
    
    // Change this to your preferred presentation option
    completionHandler([])
  }
  
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    // Print message ID.
    if let messageID = userInfo[gcmMessageIDKey] {
      print("Message ID: \(messageID)")
    }
    
    // Print full message.
    print(userInfo)
    
    completionHandler()
  }
}
// [END ios_10_message_handling]


extension AppDelegate : FIRMessagingDelegate {
  // Receive data message on iOS 10 devices while app is in the foreground.
  func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
    print("Message = \(remoteMessage.appData.values)")
    
    let notificationData : [String : Any] = remoteMessage.appData["notification"] as! [String : Any]
    let message : String = notificationData["body"] as! String
    print(message)
    
  }
}
