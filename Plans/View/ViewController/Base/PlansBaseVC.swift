//
//  PlansBaseVC.swift
//  Plans
//
//  Created by Star on 2/8/21.
//

import UIKit
import ActiveLabel

// Most based viewcontroller for Plans actions
// PlansBaseVC -> BaseViewController -> UIViewController
// Menu actions

class PlansBaseVC: BaseViewController {

    // MARK: - ViewController Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NOTIFICATION_CENTER.addObserver(self, selector: #selector(didAppBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NOTIFICATION_CENTER.addObserver(self, selector: #selector(refreshAll), name: Notification.Name(rawValue: kRefreshAll), object: nil)
        
        refreshAll(isShowLoader: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NOTIFICATION_CENTER.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NOTIFICATION_CENTER.removeObserver(self, name: Notification.Name(rawValue: kRefreshAll), object: nil)
    }

    // MARK: - Notification Handler
    @objc func refreshAll(isShowLoader: Bool = false) {
    }
    
    @objc func didAppBecomeActive() {
    }
    
    func logOut() {
        let _ = showPlansAlertYesNo(message: ConstantTexts.logout.localizedString, titleYes: "Log Out", titleNo: "Cancel", actionYes: {
            self.showLoader()
            let dict = [:] as? [String: String]
            USER_SERVICE.logoutUserApi(dict!).done { (response) -> Void in
                self.hideLoader()
                if let _ = response._id {
                    ANALYTICS_MANAGER.logEvent(.logout, itemID: USER_MANAGER.userId)
                    APP_MANAGER.gotoLandingVC()
                }
            }.catch { (error) in
                self.hideLoader()
                POPUP_MANAGER.handleError(error)
            }
        }, blurEnabled: true)

    }

}

// MARK: - Option Menu
extension PlansBaseVC {
    func processEventMenuAction(titleAction: String?, event: EventFeedModel?) -> Bool {
        var result = false
        guard let event = event else { return result }
        
        result = true

        switch titleAction {
        case "Edit Event", "Update Event":
            updateEvent(model: event)
            break
        case "Turn On Posting":
            turnOnOffPosting(model: event, isOn: true)
            break
        case "Turn Off Posting":
            turnOnOffPosting(model: event, isOn: false)
            break
        case "Mute Notifications":
            turnOnOffNotification(model: event, isOn: true)
            break
        case "Unmute Notifications":
            turnOnOffNotification(model: event, isOn: false)
            break
        case "Share Event":
            shareEvent(model: event)
            break
        case "Duplicate Event":
            duplicateEvent(model: event)
            break
        case "Cancel Event":
            cancelEvent(model: event)
            break
        case "Delete Event":
            deleteEvent(model: event)
            break
        case "End Event":
            endEvent(model: event)
            break
        case "Unsave Event":
            saveUnsaveEvent(model: event, isSave: false)
            break
        case "Save Event":
            saveUnsaveEvent(model: event, isSave: true)
            break
        case "Unhide Event":
            hideUnhideEvent(model: event, isHide: false)
            break
        case "Hide Event":
            hideUnhideEvent(model: event, isHide: true)
            break
        case "Leave Event":
            leaveEvent(model: event)
            break
        case "Report":
            reportEvent(model: event)
            break
        case "Join":
            joinEvent(model: event)
            break
        case "Unjoin":
            unjoinEvent(model: event)
            break
        case "Going":
            goingMaybeNextTime(model: event, status: 2)
            break
        case "Maybe":
            goingMaybeNextTime(model: event, status: 3)
            break
        case "Next Time":
            goingMaybeNextTime(model: event, status: 4)
            break

        case "Add to Calendar":
            gotoAddEventToCalendar(event: event)
            break

        default:
            result = false
            break
        }

        return result
    }
    
    func processChatMenu(titleAction: String?, chat: ChatModel?) -> Bool {
        var result = false
        guard let chat = chat else { return result }
        
        result = true

        switch titleAction {
        case "Mute Notifications":
            muteChatNotification(chat._id)
            break
        case "Unmute Notifications":
            muteChatNotification(chat._id, isMute: false)
            break
        case "Invite People":
            APP_MANAGER.pushEditInvitationVC(editMode: .edit, selectedUsers: chat.event?.getInvitedPeople(), sender: self)
            break
        case "Add People":
            APP_MANAGER.pushFriendsSelectionVC(typeSelect: .addPeopleInChat,
                                               delegate: self as? FriendsSelectionVCDelegate,
                                               selectedUsers:chat.people,
                                               sender: self)
            break
        case "Cancel Event":
            cancelEvent(model: chat.event)
            break
        case "End Event":
            endEvent(model: chat.event)
            break
        case "Leave Event":
            leaveEvent(model: chat.event)
            break
        case "Delete Chat", "Hide Chat":
            updateShowStatus(chat._id, isHidden: true)
            break
        case "Leave Chat":
            let user = chat.members?.first(where: {$0._id == USER_MANAGER.userId})
            if user?._id == chat.organizer?._id, chat.isEventChat == false, chat.isGroup == true {
                assignAdminAndRemoveUserInChat(chatId: chat._id)
            }else {
                removeUserInChat(chatId: chat._id, user: user )
            }
            break
        default :
            result = false
        }
        
        return result
    }
}


// MARK: - Event Actions
extension PlansBaseVC {
    
    // Join/Unjoin Event
    func joinEvent(model: EventFeedModel?) {
        guard let eventId = model?._id, let mobileNumber = USER_MANAGER.mobile else { return }
        
        let dict = ["eventId": eventId,
                    "mobile": mobileNumber]
        
        showLoader()
        EVENT_SERVICE.getJoinEvent(dict).done { (userResponse) -> Void in
            self.makeToast(ConstantTexts.joinedEvent.localizedString)
            NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
            LOCATION_MANAGER.updateLocation()
            self.logJoinEvent(model: model)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
    
    func unjoinEvent(model: EventFeedModel?) {
        guard let eventId = model?._id, let mobileNumber = USER_MANAGER.mobile else { return }
        
        let dict = ["eventId": eventId,
                    "mobile": mobileNumber,
                    "type": 0] as [String : Any]

        showLoader()
        EVENT_SERVICE.getUnjoinEvent(dict).done { (userResponse) -> Void in
            self.makeToast(ConstantTexts.leftEvent.localizedString)
            NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
    
    // respond to event request
    func goingMaybeNextTime(model: EventFeedModel?, status: Int) {
        guard let eventId = model?._id, let mobileNumber = USER_MANAGER.mobile else { return }
        let dict = ["eventId": eventId,
                    "mobile": mobileNumber,
                    "status": status] as [String : Any]
        showLoader()
        EVENT_SERVICE.going_Maybe_NextTime(dict).done { (response) -> Void in
            self.hideLoader()
            if let msg = response.message, msg != "" {
                self.makeToast(ConstantTexts.youRespondedToEvent.localizedString)
                NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
                LOCATION_MANAGER.updateLocation()
                self.logJoinEvent(model: model, status: status)
            }
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
    
    func logJoinEvent(model: EventFeedModel?, status: Int? = nil) {
        guard let eventId = model?._id else { return }

        if status == nil || status == 2 || status == 3 {
            ANALYTICS_MANAGER.logEvent(model?.isPublic == true ? .join_event_public : .join_event_private, itemID: eventId)
            
            let invitedType = model?.getAttendee(userId: USER_MANAGER.userId, mobile: USER_MANAGER.mobile, email: USER_MANAGER.email)?.invitedType
            
            var eventType: AnalyticsManager.EventType? = nil
            
            switch invitedType {
            case .contact, .mobile:
                eventType = .invitations_sms
                break
            case .email:
                eventType = .invitations_email
                break
            case .link:
                eventType = .invitations_link
                break
            default:
                break
            }

            ANALYTICS_MANAGER.logEvent(eventType, itemID: eventId)
        }
    }
    
    func updateEvent(model: EventFeedModel?) {
        APP_MANAGER.pushEditEventVC(event: model, isDuplicate: false, sender: self)
    }
    
    func duplicateEvent(model: EventFeedModel?) {
        APP_MANAGER.pushEditEventVC(event: model, isDuplicate: true, sender: self)
    }
    
    func gotoAddEventToCalendar(event: EventFeedModel?) {
        EVENT_MANAGER.addEvent(event: event, senderVC: self)
    }

    
    func turnOnOffPosting(model: EventFeedModel?, isOn: Bool = true) {
        guard let eventId = model?._id else { return }
        let isPosting = isOn == true ? "true" : "false"
        let info = ["eventId": eventId,
                    "isPosting": isPosting] as [String : Any]
        showLoader()
        EVENT_SERVICE.hitTurnOffPosting(info).done { (response) -> Void in
            self.hideLoader()
            if let msg = response.message,
                msg != "" {
                NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
                POPUP_MANAGER.makeToast(msg)
            }
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
    
    // Turn on notifications
    func turnOnOffNotification(model: EventFeedModel?, isOn: Bool = true) {
        guard let eventId = model?._id, let mobileNo = USER_MANAGER.mobile else { return }
        
        let dict = ["eventId": eventId,
                    "turnedOffNotification": isOn,
                    "mobileNo": mobileNo ] as [String : Any]
        
        showLoader()
        EVENT_SERVICE.hitTurnOffNotification(dict).done { (response) -> Void in
            self.hideLoader()
            if let msg = response.message,
                msg != "" {
                NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
                POPUP_MANAGER.makeToast(msg)
            }
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
    
    func shareEvent(model: EventFeedModel?) {
        APP_MANAGER.shareEvent(event: model, sender: self)
    }
    
    func cancelEvent(model: EventFeedModel?, complete: ((_ success: Bool) -> ())? = nil) {
        guard let eventId = model?._id else {
            complete?(false)
            return }
        let _ = showPlansAlertYesNo(message: ConstantTexts.cancelEvent.localizedString) {
            let dict = ["eventId": eventId,
                        "isCancel": "true"] as [String : Any]
            self.showLoader()
            EVENT_SERVICE.hitCancelEvent(dict).done { (response) -> Void in
                self.hideLoader()
                if let msg = response.message,
                    msg != "" {
                    NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
                    POPUP_MANAGER.makeToast(msg)
                    complete?(true)
                }else {
                    complete?(false)
                }
            }.catch { (error) in
                self.hideLoader()
                POPUP_MANAGER.handleError(error)
                complete?(false)
            }
        }
    }
    
    // Delete event
    func deleteEvent(model: EventFeedModel?) {
        guard let eventId = model?._id else { return }
        let _ = showPlansAlertYesNo(message: ConstantTexts.deleteEvent.localizedString) {
            let dict = ["eventId": eventId,
                        "isActive": "false" ] as [String : Any]
            self.showLoader()
            EVENT_SERVICE.hitDeleteEvent(dict).done { (response) -> Void in
                self.hideLoader()
                if let msg = response.message,
                    msg != "" {
                    NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
                    POPUP_MANAGER.makeToast(msg)
                }
            }.catch { (error) in
                self.hideLoader()
                POPUP_MANAGER.handleError(error)
            }
        }
    }
    
    func endEvent(model: EventFeedModel?, complete: ((_ success: Bool) -> ())? = nil) {
        guard let eventId = model?._id else {
            complete?(false)
            return
        }
        let _ = showPlansAlertYesNo(message: ConstantTexts.endEvent.localizedString) {
            let dict = ["eventId": eventId,
                        "isEnded": "1" ] as [String : Any]
            self.showLoader()
            EVENT_SERVICE.hitEndEvent(dict).done { (response) -> Void in
                self.hideLoader()
                if let msg = response.message,
                    msg != "" {
                    NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
                    POPUP_MANAGER.makeToast(msg)
                    complete?(true)
                }else {
                    complete?(false)
                }
            }.catch { (error) in
                self.hideLoader()
                POPUP_MANAGER.handleError(error)
                complete?(false)
            }
        }
    }
    
    // Save event
    private func saveUnsaveEvent(model: EventFeedModel?, isSave: Bool = true) {
        guard let eventId = model?._id else { return }
        let dict = ["eventId": eventId,
                    "saveEvent": "\(isSave)" ] as [String : Any]

        self.showLoader()
        EVENT_SERVICE.hitSaveEvent(dict).done { (response) -> Void in
            self.hideLoader()
            if let msg = response.message,
                msg != "" {
                NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
                POPUP_MANAGER.makeToast(msg)
            }
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
    
    func hideUnhideEvent(model: EventFeedModel?, isHide: Bool = true) {
        guard let eventId = model?._id, let mobileNumber = USER_MANAGER.mobile else { return }

        let dict = ["eventId": eventId,
                    "mobileNo": mobileNumber ] as [String : Any]

        self.showLoader()
        if isHide == true {
            EVENT_SERVICE.hitHideEvent(dict).done { (response) -> Void in
                self.hideLoader()
                if let msg = response.message,
                    msg != "" {
                    NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
                    POPUP_MANAGER.makeToast(msg)
                }
            }.catch { (error) in
                self.hideLoader()
                POPUP_MANAGER.handleError(error)
            }
        }else {
            EVENT_SERVICE.hitUnhideEvent(dict).done { (response) -> Void in
                self.hideLoader()
                if let msg = response.message,
                    msg != "" {
                    NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
                    POPUP_MANAGER.makeToast(msg)
                }
            }.catch { (error) in
                self.hideLoader()
                POPUP_MANAGER.handleError(error)
            }
        }
    }
    
    func leaveEvent(model: EventFeedModel?, complete: ((_ success: Bool) -> ())? = nil) {
        guard let eventId = model?._id, let mobileNumber = USER_MANAGER.mobile else {
            complete?(false)
            return }
        let _ = showPlansAlertYesNo(message: ConstantTexts.leaveEvent.localizedString) {
            let dict = ["eventId": eventId,
                        "mobile": mobileNumber] as [String : Any]
            self.showLoader()
            EVENT_SERVICE.hitLeaveEvent(dict).done { (response) -> Void in
                self.hideLoader()
                if let msg = response.message,
                    msg != "" {
                    NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
                    POPUP_MANAGER.makeToast(msg)
                    complete?(true)
                }else {
                    complete?(false)
                }
            }.catch { (error) in
                self.hideLoader()
                POPUP_MANAGER.handleError(error)
                complete?(false)
            }
        }
    }

    func reportEvent(model: EventFeedModel?) {
        guard let eventId = model?._id else { return }
        let _ = showPlansAlertYesNo(message: ConstantTexts.reportEvent.localizedString) {
            self.reportEntity(id: eventId, type: "event")
        }
    }

}


// MARK: - Report Contents
extension PlansBaseVC {
    // Report entity
    func reportEntity(id: String?, type: String?) {
        guard let id = id, let type = type else { return }
        let dict = ["entity_id": id, "entity_type": type]
        self.showLoader()
        POSTS_SERVICE.reportPost(dict).done { (response) -> Void in
            self.hideLoader()
            if let msg = response.message,
                msg != "" {
                POPUP_MANAGER.makeToast(msg)
            }
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
}

// MARK: - SMS Invitation
extension PlansBaseVC {
    func sendInviteSMS(_ mobile: String) {
        let dict = ["mobile": mobile,
                    "type": "inviteToPlans",
                    ] as [String: Any]

        showLoader()
        USER_SERVICE.hitSendSMSApi(dict).done { (response) -> Void in
            self.hideLoader()
            NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }

}

// MARK: - Chat Actions
extension PlansBaseVC {
    func muteChatNotification(_ chatId: String?, isMute: Bool = true, complete: (() -> ())? = nil){
        SOCKET_MANAGER.muteNotification(chatId: chatId, status: isMute == true ? 1 : 0, complete: complete)
    }
    
    func updateShowStatus(_ chatId: String?, isHidden: Bool = true, complete: (() -> ())? = nil) {
        let _ = showPlansAlertYesNo(message: "Are you sure you want to delete this chat?", actionYes: {
            self.showLoader()
            SOCKET_MANAGER.updateShowStatus(chatId: chatId, isHidden: isHidden){
                self.hideLoader()
                complete?()
            }
        }, blurEnabled: true)
    }
    
    func createChat(members: [UserModel]?, complete: ((_ chatModel: ChatModel?) -> ())? = nil) {
        guard let list = members, list.count > 0 else {
            complete?(nil)
            return
        }
        
        let groupModel = ChatModel()
        groupModel.organizer = ChatUserModel(userId: USER_MANAGER.userId)
        groupModel.members = list.map({ChatUserModel(user: $0)})
        
        showLoader()
        CHAT_SERVICE.createChatGroup(groupModel.toJSON()).done { (response) -> Void in
            self.hideLoader()
            complete?(response)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
            complete?(nil)
        }
        
    }

    func updateChat(chatId: String?, members: [UserModel]?, complete: ((_ chatModel: ChatModel?) -> ())? = nil) {
        guard let chatId = chatId, let list = members, list.count > 0 else {
            complete?(nil)
            return
        }
        
        let groupModel = ChatModel(id: chatId)
        groupModel?.organizer = ChatUserModel(userId: USER_MANAGER.userId)
        groupModel?.members = list.filter({$0._id != USER_MANAGER.userId}).map({ChatUserModel(user: $0)})
        
        showLoader()
        CHAT_SERVICE.updateChatGroup(groupModel?.toJSON()).done { (response) -> Void in
            self.hideLoader()
            complete?(response)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
            complete?(nil)
        }
    }
    
    func removeUserInChat(chatId: String?, user: UserModel?, isShowLoader: Bool = true, complete: ((_ chatModel: ChatModel?) -> ())? = nil) {
        guard let chatId = chatId, let userId = user?._id else {
            complete?(nil)
            return
        }
        var fullName = user?.fullName ?? user?.name ?? "\(user?.firstName ?? "") \(user?.lastName ?? "")"
        
        var prefix = "Are you sure you want to remove "
        if userId == USER_MANAGER.userId {
            prefix = "Are you suer you want to leave this chat"
            fullName = ""
        }
        
        let _ = showPlansAlertYesNo(message: "\(prefix)\(fullName)?", actionYes: {
            if isShowLoader == true {
                self.showLoader()
            }
            CHAT_SERVICE.removeUserInChat(userId, chatId: chatId).done { (chatModel) -> Void in
                self.hideLoader()
                NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
                complete?(chatModel)
            }.catch { (error) in
                self.hideLoader()
                POPUP_MANAGER.handleError(error)
                complete?(nil)
            }
        }, blurEnabled: true)

        
    }
    
    func assignAdminAndRemoveUserInChat(chatId: String?) {
        guard let chatId = chatId else { return }
        let msg = "Are you sure you want to leave this chat?\nYou will be required to assign another admin"
        let _ = showPlansAlertYesNo(message: msg, actionYes: {
            APP_MANAGER.pushAssignAdminForGroupChat(chatId: chatId, sender: self)
        }, blurEnabled: true)
    }

}
