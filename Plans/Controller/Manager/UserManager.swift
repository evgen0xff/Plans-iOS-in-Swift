//
//  UserManager.swift
//  Plans
//
//  Created by Star on 2/21/20.
//  Copyright © 2020 Brainmobi. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation
import FirebaseCrashlytics

let USER_MANAGER = UserManager.shared

class UserManager: NSObject {

    static let shared = UserManager()

    var deviceToken: String? {
        get {
            return USER_DEFAULTS.value(forKey: kDeviceToken) as? String
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kDeviceToken)
        }
    }
    
    var latitude : Double {
        get {
            return USER_DEFAULTS.object(forKey: kLatitude) as? Double ?? 0
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kLatitude)
        }
    }

    var longitude : Double {
        get {
            return USER_DEFAULTS.object(forKey: kLongitude) as? Double ?? 0
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kLongitude)
        }
    }
    
    var countryOwn: String? {
        get {
            return USER_DEFAULTS.object(forKey: kCountryOwn) as? String
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kCountryOwn)
        }
    }

    var myLocation: CLLocation {
        return CLLocation(latitude: latitude, longitude: longitude)
    }

    var isPrivateAccount : Bool {
        get {
            return USER_DEFAULTS.object(forKey: kIsPrivateAccount) as? Bool ?? true
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kIsPrivateAccount)
        }
    }

    var isLogined : Bool {
        get {
            return USER_DEFAULTS.object(forKey: kLoggedIn) as? Bool ?? false
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kLoggedIn)
        }
    }
    
    var isSeenYouLiveAt : Bool {
        get {
            return USER_DEFAULTS.object(forKey: kIsSeenYouLiveAt) as? Bool ?? false
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kIsSeenYouLiveAt)
        }
    }
    
    var isSeenGuideGuestList : Bool {
        get {
            return USER_DEFAULTS.object(forKey: kIsSeenGuideGuestList) as? Bool ?? false
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kIsSeenGuideGuestList)
        }
    }

    var isSeenGuideChatWithEventGuest : Bool {
        get {
            return USER_DEFAULTS.object(forKey: kIsSeenGuideChatWithEventGuest) as? Bool ?? false
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kIsSeenGuideChatWithEventGuest)
        }
    }

    var isSeenGuideAddEventPosts : Bool {
        get {
            return USER_DEFAULTS.object(forKey: kIsSeenGuideAddEventPosts) as? Bool ?? false
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kIsSeenGuideAddEventPosts)
        }
    }

    var isSeenGuideTapHoldNotification : Bool {
        get {
            return USER_DEFAULTS.object(forKey: kIsSeenGuideTapHoldNotification) as? Bool ?? false
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kIsSeenGuideTapHoldNotification)
        }
    }

    var isSeenGuideTapHoldChat : Bool {
        get {
            return USER_DEFAULTS.object(forKey: kIsSeenGuideTapHoldChat) as? Bool ?? false
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kIsSeenGuideTapHoldChat)
        }
    }

    var isSeenGuideTapViewEvent : Bool {
        get {
            return USER_DEFAULTS.object(forKey: kIsSeenGuideTapViewEvent) as? Bool ?? false
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kIsSeenGuideTapViewEvent)
        }
    }

    var isSeenGuideLocationDiscovery : Bool {
        get {
            return USER_DEFAULTS.object(forKey: kIsSeenGuideLocationDiscovery) as? Bool ?? false
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kIsSeenGuideLocationDiscovery)
        }
    }

    var eventTutorial : Int? {
        get {
            return USER_DEFAULTS.value(forKey: kEventTutorial) as? Int
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kEventTutorial)
        }
    }
    
    var isShownPostTutorial : Bool {
        get {
            return USER_DEFAULTS.value(forKey: kIsShownPostTutorial) as? Bool ?? false
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kIsShownPostTutorial)
        }
    }

    var isShownTutorialFriends : Bool {
        get {
            return USER_DEFAULTS.value(forKey: kIsShownTutorialFriends) as? Bool ?? false
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kIsShownTutorialFriends)
        }
    }

    var userId : String? {
        get {
            return USER_DEFAULTS.value(forKey: kUserId) as? String
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kUserId)
        }
    }

    var mobile : String? {
        get {
            return USER_DEFAULTS.value(forKey: kMobile) as? String
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kMobile)
        }
    }
    
    var accessToken : String? {
        get {
            return USER_DEFAULTS.value(forKey: kAccessToken) as? String
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kAccessToken)
        }
    }

    var email : String? {
        get {
            return USER_DEFAULTS.value(forKey: kEmail) as? String
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kEmail)
        }
    }
    
    var firstName : String? {
        get {
            return USER_DEFAULTS.value(forKey: kFirstName) as? String
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kFirstName)
        }
    }
    
    var lastName : String? {
        get {
            return USER_DEFAULTS.value(forKey: kLastName) as? String
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kLastName)
        }
    }

    var fullName : String? {
        get {
            var name = USER_DEFAULTS.value(forKey: kFullName) as? String
            if name == nil {
                if firstName != nil {
                    name = firstName!
                }
                if lastName != nil {
                    if name != nil {
                        name! += " \(lastName!)"
                    }else {
                        name = lastName
                    }
                }
            }
            return name
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kFullName)
        }
    }

    var userName : String? {
        get {
            return USER_DEFAULTS.value(forKey: kUserName) as? String
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kUserName)
        }
    }

    var profileUrl : String? {
        get {
            return USER_DEFAULTS.value(forKey: kProile) as? String
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kProile)
        }
    }

    var countUnviewedNotify : Int {
        get {
            return USER_DEFAULTS.value(forKey: kCountUnviewedNotify) as? Int ?? 0
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kCountUnviewedNotify)
        }
    }
    
    var countUnviewedChatMsg: Int {
        get {
            return USER_DEFAULTS.value(forKey: kCountUnviewedChatMsg) as? Int ?? 0
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kCountUnviewedChatMsg)
        }
    }
    
    var lastViewTimeForNotify : Double {
        get {
            return USER_DEFAULTS.value(forKey: kLastViewTimeForNotify) as? Double ?? 0
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kLastViewTimeForNotify)
        }
    }

    var coinNumber : Int {
        get {
            var number : Int = 0
            let coinDic = USER_DEFAULTS.value(forKey: kCoinNumber) as? [String: Int]
            let userId = USER_MANAGER.userId ?? ""
            if coinDic?.keys.contains(userId) == true {
                number = coinDic?[userId] ?? 0
            }
            return number
        }
        set {
            guard let userId = USER_MANAGER.userId else { return }
            var coinDic = (USER_DEFAULTS.value(forKey: kCoinNumber) as? [String: Int]) ?? [String:Int]()
            coinDic[userId] = newValue
            USER_DEFAULTS.set(coinDic, forKey: kCoinNumber)
        }
    }
   
    var chatMessagesUnsent : [String:[MessageModel]] {
        get {
            guard let decoded  = USER_DEFAULTS.data(forKey: kChatMessagesUnsent) else { return [String : [MessageModel]]()}
            return try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(decoded) as? [String : [MessageModel]] ?? [String : [MessageModel]]()
        }
        set {
            guard let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: false) else { return }
            USER_DEFAULTS.set(encodedData, forKey: kChatMessagesUnsent)
        }
    }
    
    var isFirstWatchMoment: Bool {
        get {
            return USER_DEFAULTS.value(forKey: kIsFirstWatchMoment) as? Bool ?? true
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kIsFirstWatchMoment)
        }
    }
    
    var emailList: [String] {
        get {
            return USER_DEFAULTS.value(forKey: kEmailList) as? [String] ?? [String]()
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kEmailList)
        }
    }
    
    var mobileList: [String] {
        get {
            return USER_DEFAULTS.value(forKey: kMobileList) as? [String] ?? [String]()
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kMobileList)
        }
    }
    
    var listShareContents: [[String: String]] {
        get {
            return USER_DEFAULTS.value(forKey: kShareContentList) as? [[String: String]] ?? [[String: String]]()
        }
        set {
            USER_DEFAULTS.set(newValue, forKey: kShareContentList)
        }
    }
    
    var listMonitorRegions: [CLCircularRegion] {
        get {
            guard let decoded  = USER_DEFAULTS.data(forKey: kMonitorRegionList) else { return [CLCircularRegion]()}
            return try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(decoded) as? [CLCircularRegion] ?? [CLCircularRegion]()
        }
        set {
            guard let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: true) else { return }
            USER_DEFAULTS.set(encodedData, forKey: kMonitorRegionList)
        }
    }
    
    var isClickedByAppLink : Bool {
        return containsShareContents(["type": "app_share"]) != nil
    }


    func initializeForLaunch () {
        isSeenYouLiveAt = false
        ANALYTICS_MANAGER.setUserID(userId)
        ANALYTICS_MANAGER.logEvent(.app_open)
    }
    
    func initForLogin(userModel: UserModel?, token: String?) {
        isLogined = true
        accessToken = token
        updateUserInfo(userModel: userModel)
    }

    func updateUserInfo (userModel: UserModel?) {
        userId = userModel?._id
        mobile = userModel?.mobile
        email =  userModel?.email
        userName = userModel?.firstName
        firstName = userModel?.firstName
        lastName = userModel?.lastName
        fullName = userModel?.name ?? userModel?.fullName
        profileUrl = userModel?.profileImage
        lastViewTimeForNotify = userModel?.lastViewTimeForNotify ?? 0
        ANALYTICS_MANAGER.setUserID(userModel?._id)
    }
    
    func updateUserInfoFromEditProfile(newUser: UserModel?) {
        guard let newUser = newUser?.userDetails else { return }
        if newUser.profileImage != nil {
            profileUrl = newUser.profileImage
        }
        if newUser.firstName != nil {
            firstName = newUser.firstName
        }
        if newUser.lastName != nil {
            lastName = newUser.lastName
        }
    }

    
    func initializeUserInfo () {
        isLogined = false
        isSeenYouLiveAt = false
        isFirstWatchMoment = true
        accessToken = nil
        eventTutorial = nil
        isShownPostTutorial = false
        isShownTutorialFriends = false
        updateUserInfo(userModel: nil)
        chatMessagesUnsent = [String: [MessageModel]]()
        listShareContents = [[String: String]]()
    }
    
    func addShareContent(_ url: URL?) -> [String: String]? {
        var result : [String: String]? = nil
        
        guard let url = url, let dicQuery = url.queryParameters else { return result }
        
        var dicContents: [String: String]? = nil
        
        if dicQuery.keys.contains("type") == true {
            dicContents = dicQuery
        }else if dicQuery.keys.contains("deep_link_id") == true {
            if let link = dicQuery["deep_link_id"], let linkDeep = URL(string: link) {
                dicContents = linkDeep.queryParameters
            }
        }
        
        guard let sharedContents = dicContents else { return result }
        
        var list = listShareContents
        
        if list.contains(where: { (item) -> Bool in
            var isEqual = true
            for (key, value) in sharedContents {
                if item[key] != value {
                    isEqual = false
                    break
                }
            }
            return isEqual
        }) == false {
            list.append(sharedContents)
            listShareContents = list
            result = sharedContents
        }
        
        return result
    }
    
    func removeShareContent(_ content: [String: String]) {
        var list = listShareContents
        if let index = containsShareContents(content) {
            list.remove(at: index)
            listShareContents = list
        }
    }
    
    func containsShareContents(_ content: [String: String]) -> Int? {
        return listShareContents.firstIndex(where: { (item) -> Bool in
            var isEqual = true
            for (key, value) in content {
                if item[key] != value {
                    isEqual = false
                    break
                }
            }
            return isEqual
        })
    }
          
    func addUnsentMessage(chatModel: MessageModel){
        guard let chatId = chatModel.chatId else { return }
        var unsentMessages = chatMessagesUnsent

        if var messages = unsentMessages[chatId] {

            if messages.contains(where: { (unSent) -> Bool in
                if unSent.chatId == chatModel.chatId,
                    unSent.userId == chatModel.userId,
                    unSent.type == chatModel.type,
                    unSent.sendingAt == chatModel.sendingAt {
                    return true
                }else {
                    return false
                }
            }) == false {
                messages.append(chatModel)
                unsentMessages[chatId] = messages
            }
        }else {
            unsentMessages[chatId] = [chatModel]
        }
        chatMessagesUnsent = unsentMessages
    }
    
    func updateUnsendMessages(chatId: String?, messagesSent: [MessageModel]?){
        guard let chatId = chatId, let messagesSent = messagesSent else { return }
        var totalList = chatMessagesUnsent

        guard var unsentMessages = totalList[chatId], unsentMessages.count > 0 else { return }
        messagesSent.forEach { (sent) in
            if let index = unsentMessages.firstIndex(where: { (unSent) -> Bool in
                if unSent.chatId == sent.chatId,
                    unSent.userId == sent.userId,
                    unSent.type == sent.type,
                    unSent.sendingAt == sent.createdAt {
                    return true
                }else {
                    return false
                }
            }) {
                unsentMessages.remove(at: index)
            }
        }
        totalList[chatId] = unsentMessages
        chatMessagesUnsent = totalList
    }
    
}
