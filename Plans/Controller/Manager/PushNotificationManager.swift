//
//  PushNotificationManager.swift
//  Plans
//
//  Created by Star on 6/9/20.
//  Copyright © 2020 Plans Collective. All rights reserved.
//

import UIKit

let PUSH_MANAGER = PushNotificationManager.share

class PushNotificationManager: NSObject {

    static let share = PushNotificationManager()
    let notificationCenter = UNUserNotificationCenter.current()

    enum ActionType {
        case recevied_not_running       // When the user recevied a Push Notification when the application isn't running.
        case recevied_in_running        // When the user recevied a Push Notification when the application is running.
        case tapped_not_running         // When the user tapped a Push Notification when the application isn't running.
        case tapped_in_running          // When the user tapped a Push Notification when the application is running.
    }
    
    override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    func registerForPushNotifications(application: UIApplication) {
        
        if #available(iOS 10.0, *)
        {
            notificationCenter.requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in
                // Enable or disable features based on authorization.
            }
            application.registerForRemoteNotifications()
        }
        else{ //If user is not on iOS 10 use the old methods we've been using
            let notificationSettings = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
            application.registerUserNotificationSettings(notificationSettings)
        }
    }
    
    func handlePushNotification(_ userInfo: [AnyHashable:Any]?, actionType: ActionType = .recevied_not_running) {
        notificationCenter.getDeliveredNotifications { (list) in
            let listNotify = list.map({NotificationActivityModel(dic: $0.request.content.userInfo)})
            print("notificationCenter.getDeliveredNotifications : ", listNotify)
        }
        
        guard let userInfo = userInfo else { return }

        var isSetBadge = true
        var isGoToNotification = false
        var delay : TimeInterval = 0
        let pushNotify = NotificationActivityModel(dic: userInfo)

        switch actionType {
        case .recevied_not_running:
            isGoToNotification = true
            delay = 1
           break
        case .recevied_in_running:
           break
        case .tapped_in_running:
            isGoToNotification = true
           break
        default:
           break
        }

        APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + delay) {
            let result = self.processByNotifiType(pushNotify)
            isGoToNotification = result.isGoToNotification ?? isGoToNotification
            isSetBadge = result.isSetBadge ?? isSetBadge

            // Refresh All
            APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 1.0) {
                NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
            }

            // Go to Notification
            if isGoToNotification == true, pushNotify.isSilent == false {
                switch pushNotify.notificationType {
                case "Private Message", "Event Chat":
                    APP_MANAGER.gotoTabItemVC(tabType: .home)
                    break
                default:
                    APP_MANAGER.gotoTabItemVC(tabType: .notification)
                    break
                }
                APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 1.0) {
                    NOTIFICATION_CENTER.post(name: NSNotification.Name(rawValue: kPushNotification_Show), object: nil, userInfo: userInfo)
                }
            }
            
            // Update the app badge and main Tab bar notification indicator
            if isSetBadge == true {
                APPLICATION.applicationIconBadgeNumber += 1
                APP_MANAGER.updateBadges()
            }
        }
    }
    
    func processByNotifiType (_ pushNotifi : NotificationActivityModel?) -> (isSetBadge: Bool?, isGoToNotification: Bool?) {
        var isSetBadge: Bool?
        var isGoToNotification: Bool?
        
        switch pushNotifi?.notificationType {
        case "All guests left", "A guest lived":
            isSetBadge = false
            isGoToNotification = false
            APP_MANAGER.getLivedEventsForEnding()
        case "Event Deleted":
            APP_MANAGER.removeAllEventScreens(eventId: pushNotifi?.eventId)
        case "Event Cancelled", "Event Expired":
            APP_MANAGER.forceUserOutsideFromEvent(eventId: pushNotifi?.eventId)
        case "End Event":
            break
        case "Update Location":
            LOCATION_MANAGER.updateLocation()
            break
        case "Blocked User":
            APP_MANAGER.forceUserOutsideFromUser(userId: pushNotifi?.uid)
            break
        default:
            break
        }
        
        if isGoToNotification == nil {
            if APP_MANAGER.hostedEvents.count > 0 {
                isGoToNotification = false
            }
        }
        
        return (isSetBadge: isSetBadge, isGoToNotification: isGoToNotification)
    }
    
}

extension PushNotificationManager : UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        print("-------------- userNotificationCenter willPresent ------------------")
        handlePushNotification(notification.request.content.userInfo, actionType: .recevied_in_running)
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("-------------- userNotificationCenter didReceive response------------------")

        handlePushNotification(response.notification.request.content.userInfo, actionType: .tapped_in_running)
        completionHandler()

    }

}
