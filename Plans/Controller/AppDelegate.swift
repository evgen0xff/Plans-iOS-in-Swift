//
//  AppDelegate.swift
//  Plans
//
//  Created by Star on 1/23/21.
//

import Foundation
import UIKit
import FBSDKCoreKit
import GooglePlaces
import GoogleMaps
import Firebase
import FirebaseCrashlytics
import SDWebImage
import IQKeyboardManagerSwift


let APP_DELEGATE = APPLICATION.delegate as! AppDelegate

@main
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate {
    
    var window: UIWindow?
    var backgroundTasks = [UIBackgroundTaskIdentifier]()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print("-------------- didFinishLaunchingWithOptions ------------------")
        // Keyboard
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        IQKeyboardManager.shared.disabledDistanceHandlingClasses = [EventDetailsVC.self,
                                                                    PostCommentVC.self,
                                                                    ChatMessageVC.self]

        // FaceBook SDK
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        Settings.shared.isAdvertiserTrackingEnabled = true
        Settings.shared.isAutoLogAppEventsEnabled = true
        Settings.shared.isAdvertiserIDCollectionEnabled = true

        // Google and Firebase configure
        GMSServices.provideAPIKey(APP_CONFIG.googleApiKey)
        GMSPlacesClient.provideAPIKey(APP_CONFIG.googleApiKey)
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        Crashlytics.crashlytics()
        
        // App manager
        APP_MANAGER.initializeForLaunch()
        
        // Push Notification
        PUSH_MANAGER.registerForPushNotifications(application: application)
        PUSH_MANAGER.handlePushNotification(launchOptions?[.remoteNotification] as? [AnyHashable: Any])

        // Location Manager
        if let _ = launchOptions?[.location] {
            let _ = LOCATION_MANAGER
        }

        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        print("-------------- applicationWillResignActive ------------------")

    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("-------------- applicationDidEnterBackground ------------------")

        SOCKET_MANAGER.appDidEnterBackground()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        print("-------------- applicationWillEnterForeground ------------------")
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("-------------- applicationDidBecomeActive ------------------")
        
        SOCKET_MANAGER.appDidBecomeActive()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        print("-------------- applicationWillTerminate ------------------")

        SOCKET_MANAGER.appWillTerminate()
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("-------- application didReceiveRemoteNotification fetchCompletionHandler -------")
        PUSH_MANAGER.handlePushNotification(userInfo, actionType: .recevied_in_running)
        completionHandler(.newData)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        print("-------- application didReceiveRemoteNotification -------")
        PUSH_MANAGER.handlePushNotification(userInfo, actionType: .recevied_in_running)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {

        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        
        return application(app, open: url,
                           sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                           annotation: "")
    }
    
 
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
      if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url) {
        // Handle the deep link. For example, show the deep-linked content or
        // apply a promotional offer to the user's account.
        // ...
        
        print ("application: sourceApplication: ", url.absoluteURL)
        APP_MANAGER.handleIncomingDynamicLink(url)

        return true
      }
      return false
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
      let handled = DynamicLinks.dynamicLinks().handleUniversalLink(userActivity.webpageURL!) { (dynamiclink, error) in
        // ...
        print ("dynamiclink url: ", dynamiclink?.url?.absoluteString ?? "")
        APP_MANAGER.handleIncomingDynamicLink(dynamiclink?.url)
      }

      return handled
    }
    
    func registerBackgroundTask() {
        print("Background task began.")
        let backgroundTask = APPLICATION.beginBackgroundTask { [weak self] in
          self?.endBackgroundTask()
        }
        backgroundTasks.append(backgroundTask)
    }
    
    func endBackgroundTask() {
        print("Background task ended.")
        if backgroundTasks.count > 0, let task = backgroundTasks.first{
            APPLICATION.endBackgroundTask(task)
            backgroundTasks.removeFirst()
        }
    }

    func convertToDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
        return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Messaging.messaging().token { token, error in
          if let _ = error {
          } else if let token = token {
              USER_MANAGER.deviceToken = token
          }
        }
    }

}

