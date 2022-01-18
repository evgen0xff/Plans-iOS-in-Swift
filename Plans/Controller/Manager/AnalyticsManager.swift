//
//  AnalyticsManager.swift
//  Plans
//
//  Created by Top Star on 1/9/22.
//

import UIKit
import Firebase

let ANALYTICS_MANAGER = AnalyticsManager.shared

class AnalyticsManager: NSObject {
    static let shared = AnalyticsManager()
    
    enum EventType: String {
        case app_open = "app_open"
        case sign_up = "sign_up"
        case login = "login"
        case logout = "logout"
        case create_event = "create_event"
        case join_event_public = "join_event_public"
        case join_event_private = "join_event_private"
        case invitations_email = "invitations_email"
        case invitations_sms = "invitations_sms"
        case invitations_link = "invitations_link"
        case live_user = "live_user"
        case chat_message = "chat_message"
        case friend_add = "friend_add"
        case friend_request = "friend_request"
        case story_add = "story_add"
        case post_add = "post_add"
        case invite_link = "invite_link"
        case screen_view = "screen_view"
    }
    
    func setUserID(_ userId: String?) {
        let userId = (userId != nil && !userId!.isEmpty) ? userId : UIDevice.uuidString

        Analytics.setUserID(userId)

        if userId != nil {
            Crashlytics.crashlytics().setUserID(userId!)
        }
    }
    
    func logEvent(_ typeEvent: EventType? = nil,
                  itemID: String? = nil,
                  itemName: String? = nil,
                  content: String? = nil
    ) {
        guard let type = typeEvent else { return }
        
        var params = [String: Any]()
        
        if let itemID = itemID {
            params[AnalyticsParameterItemID] = itemID
        }
        
        if let itemName = itemName {
            params[AnalyticsParameterItemName] = itemName
        }
        
        if let content = content {
            params[AnalyticsParameterContent] = content
        }

        Analytics.logEvent(type.rawValue, parameters: params)
    }

    func logScreenView(_ screenName: String? = nil, className: String? = nil) {
        guard let screenName = screenName, !screenName.isEmpty else { return }
        
        var params = [String: Any]()
        params[AnalyticsParameterScreenName] = screenName
        
        if let className = className, !className.isEmpty {
            params[AnalyticsParameterScreenClass] = className
        }
        
        Analytics.logEvent(AnalyticsEventScreenView, parameters: params)
    }

    
    
}
	
