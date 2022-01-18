//
//  OptionsMenuManager.swift
//  Plans
//
//  Created by Star on 2/6/21.
//

import UIKit

let OPTIONS_MANAGER = OptionsMenuManager.share

protocol OptionsMenuManagerDelegate {
    func didSelectedMenuItem(titleItem: String?, data: Any?)
}

extension OptionsMenuManagerDelegate {
    func didSelectedMenuItem(titleItem: String?, data: Any?){}
}

class OptionsMenuManager: NSObject {
    
    static let share = OptionsMenuManager()
    
    var delegate: OptionsMenuManagerDelegate?
   
    private var data: Any?
    
    enum MenuType {
        case none
        case eventFeed
        case eventDetails
        case eventJoin
        case eventPending
        case eventLeave
        case post
        case comment
        case userProfile
        case chat
    }
    
    // MARK: - Private Meothds
    private func selectedItem(action: UIAlertAction) {
        delegate?.didSelectedMenuItem(titleItem: action.title, data: self.data)
    }

    
    private func getMenuItems(data: Any? = nil, menuType: MenuType = .none) -> [String]? {
        var list: [String]? = nil
        
        switch menuType {
        case .none:
            break
        case .eventFeed, .eventDetails:
            list = getMenuItemsForEvent(event: data as? EventFeedModel, menuType: menuType)
        case .eventJoin:
            list = getMenuItemsForJoinEvent(event: data as? EventFeedModel)
        case .eventPending:
            list = getMenuItemsForPendingEvent(event: data as? EventFeedModel)
        case .eventLeave:
            list = getMenuItemsForLeaveEvent(event: data as? EventFeedModel)
        case .post, .comment:
            list = getMenuItemsForPost(data: data)
        case .userProfile:
            list = getMenuItemsForUserProfile(user: data as? UserModel)
        case .chat:
            list = (data as? ChatModel)?.getOptionList()
        }

        return list
    }
    
    private func getMenuItemsForUserProfile(user: UserModel?) -> [String]? {
        var list: [String]? = nil
        guard let user = user else { return list }
        if let friendShip = user.friendShipStatus, friendShip != 5 {
            list = ["Block User",
                    "Send Message",
                    "Report"]
        } else {
            list = ["Send Message",
                    "Report"]
        }
        return list
   }
    
    private func getMenuItemsForPost(data: Any?) -> [String]? {
        var list: [String]? = nil
        guard let dic = data as? [String: Any?],
              let post = dic["post"] as? PostModel,
              let event = dic["event"] as? EventFeedModel else { return list }
        
        list = ["Share"]
        if post.isMediaType == true {
            list?.append("Download")
        }
        if USER_MANAGER.userId != post.user?._id {
            list?.append("Report")
        }
        if USER_MANAGER.userId == event.userId || USER_MANAGER.userId == post.user?._id {
            list?.append("Delete")
        }

        return list

    }

    private func getMenuItemsForJoinEvent(event: EventFeedModel?) -> [String]? {
        var list: [String]? = nil
        guard let event = event else { return list }
        if event.isJoin == true {
            list = ["Unjoin"]
        }else {
            list = ["Join"]
        }
        return list
    }

    private func getMenuItemsForPendingEvent(event: EventFeedModel?) -> [String]? {
        var list: [String]? = nil
        guard let event = event else { return list }
        
        switch event.joinStatus {
        case 1: // Pending Invite
            list = ["Going", "Maybe", "Next Time"]
            break
        case 2: // Going
            list = ["Maybe", "Next Time"]
            break
        case 3: // Maybe
            list = ["Going", "Next Time"]
            break
        case 4: // Next Time
            list = ["Going", "Maybe"]
            break
        default:
            break
        }

        return list
    }

    private func getMenuItemsForLeaveEvent(event: EventFeedModel?) -> [String]? {
        var list: [String]? = nil
        guard let _ = event else { return list }
        list = ["Leave Event"]
        return list
    }

    private func getMenuItemsForEvent(event: EventFeedModel?, menuType: MenuType = .eventFeed) -> [String]?{
        var list: [String]? = nil
        guard let event = event,
              let userId = USER_MANAGER.userId,
              let ownerId = event.eventCreatedBy?.userId else { return list }
        
        let notiStr = event.isTurnOffNoti(userId) == false ? "Mute Notifications" : "Unmute Notifications"
        
        // My own Event
        if userId == ownerId {
            let postStr = event.isPosting == false ? "Turn On Posting" : "Turn Off Posting"
            if event.isLive == 1 {             // Lived Event
                list = ["Edit Event",
                        postStr,
                        notiStr,
                        "Add to Calendar",
                        "Share Event",
                        "Duplicate Event",
                        "Delete Event",
                        "End Event",
                        ]
            }else if event.isEnded == true {  // Ended Event
                list = [postStr,
                        notiStr,
                        "Share Event",
                        "Duplicate Event",
                        "Delete Event"]
            }else if event.isCancel == true { // Canceled Event
                list = ["Update Event",
                        "Duplicate Event",
                        "Delete Event"]
            }else if event.isExpired == true { // Expired Event
                list = ["Update Event",
                        "Duplicate Event",
                        "Cancel Event",
                        "Delete Event"]
            }else {
                list = ["Edit Event",
                        postStr,
                        notiStr,
                        "Add to Calendar",
                        "Share Event",
                        "Duplicate Event",
                        "Cancel Event",
                        "Delete Event",
                        ]
            }
            
        // Other Event
        }else {
            let saveStr = event.isSaved == true ? "Unsave Event" : "Save Event"
            let hideStr = event.isHide == true ? "Unhide Event" : "Hide Event"
            // Joined Event
            if event.isJoin == true {
                if event.isLive == 1 {
                    list = [saveStr,
                            hideStr]
                    if menuType == .eventFeed {
                        list?.append("Leave Event")
                    }
                    list?.append(contentsOf: [
                        notiStr,
                        "Add to Calendar",
                        "Share Event",
                        "Report",
                    ])
                }else if event.isCancel == true || event.isExpired == true {
                    list = [saveStr,
                            hideStr,
                            "Report"]
                }else {
                    list = [saveStr,
                            hideStr,
                            notiStr]
                    
                    if event.isEnded != true {
                        list?.append("Add to Calendar")
                    }
                    
                    list?.append(contentsOf: ["Share Event", "Report"])
                }
            // Unjoined Event
            }else if event.isCancel == true || event.isExpired == true {
                list = [saveStr,
                        hideStr,
                        "Report"]
            }else {
                list = [saveStr,
                        hideStr]
                
                if event.isEnded != true {
                    list?.append("Add to Calendar")
                }
                
                list?.append(contentsOf: ["Share Event", "Report"])
            }
        }

        return list
    }
    
    
    
}

// MARK: - Public Methods
extension OptionsMenuManager {

    func showMenu(data: Any? = nil,
                  menuType: MenuType = .none,
                  delegate:OptionsMenuManagerDelegate? = nil,
                  sender: UIViewController? = nil) {
        
        guard let list = getMenuItems(data:data, menuType: menuType), list.count > 0 else{ return }
        self.data = data
        self.delegate = delegate
        POPUP_MANAGER.showPlansMenu(items: list, sender: sender, action: self.selectedItem)
    }
    
    func showMenu(list: [String]?,
                  data: Any? = nil,
                  delegate:OptionsMenuManagerDelegate? = nil,
                  sender: UIViewController? = nil) {
        
        guard let list = list, list.count > 0 else{ return }
        self.data = data
        self.delegate = delegate
        POPUP_MANAGER.showPlansMenu(items: list, sender: sender, action: self.selectedItem)
    }


}
