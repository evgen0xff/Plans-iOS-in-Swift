//
//  ChatModel.swift
//  Plans
//
//  Created by Star on 3/5/21.
//

import UIKit
import ObjectMapper


class ChatModel: BaseData {
    
    var nameGroup:              String?
    var lastMessageTime:        Double?
    var members:                [ChatUserModel]?
    var organizer:              ChatUserModel?
    var lastMessageId:          String?
    var eventId:                String?
    var unreadMessages:         [MessageModel]?
    var allMessages:            [MessageModel]?
    var peopleEvent:            [UserModel]?
    var countUnreadMessages:    Int?

    var event:           EventFeedModel?
    var lastMessage:     MessageModel?

    var isGroup: Bool {
        return isEventChat == true ? true : ((members?.count ?? 0) > 2)
    }

    var isMuteNotification: Bool {
        return members?.first(where: {$0._id == USER_MANAGER.userId})?.isMuteNotification ?? false
    }
    
    var isEventChat: Bool {
        return eventId != nil || event?._id != nil
    }
    
    var lastUser: ChatUserModel? {
        return members?.first
    }

    var nextUser: ChatUserModel? {
        return (members?.count ?? 0) > 1 ? members?[1] : nil
    }

    var profileUser: ChatUserModel? {
        return isGroup == true ? lastUser : members?.first(where: {$0._id != USER_MANAGER.userId})
    }
    
    var profileImage: String? {
        return isEventChat == true ? event?.urlCoverImage : profileUser?.profileImage
    }

    var profileNextUser: ChatUserModel? {
        return isEventChat == false && isGroup == true ? nextUser : nil
    }

    var people: [UserModel]? {
        var list = isEventChat == true ? peopleEvent : members
        if isGroup == false {
            list = list?.filter({$0._id != USER_MANAGER.userId})
        }
        return list
    }
    
    var titleChat: String? {
        var title: String?
        if isEventChat == true {
            title = event?.eventName
        }else if isGroup == false {
            title = "\(profileUser?.firstName ?? "") \(profileUser?.lastName ?? "")"
        }else if isGroup == true {
            if let name = nameGroup {
                title = name
            }else {
                guard let listFirstNames = people?.filter({ ($0._id ?? $0.userId) != USER_MANAGER.userId }).map({ $0.firstName ?? "" }) else { return title }
                if listFirstNames.count < 3 {
                    title = listFirstNames.joined(separator: ", ")
                }else {
                    title = listFirstNames[...1].joined(separator: ", ") + " and \(listFirstNames.count - 2) more"
                }
            }
        }
        
        return title
    }
    
    convenience init?(id:      String? = nil,
                      eventId: String? = nil,
                      event:   EventFeedModel? = nil,
                      members: [UserModel]? = nil) {

        guard id != nil || event?.chatId != nil || members != nil else { return nil}

        self.init()
        
        self._id = id ?? event?.chatId
        self.eventId = eventId ?? event?._id
        self.event = event
        if let members = members {
            self.members = members.map({ChatUserModel(user: $0)})
        }
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        nameGroup       <- map["nameGroup"]
        organizer       <- map["organizer"]
        members         <- map["members"]
        lastMessageTime <- map["lastMessageTime"]
        unreadMessages  <- map["unreadMessages"]
        lastMessageId   <- map["lastMessageId"]
        eventId         <- map["eventId"]
        lastMessage     <- map["lastMessage"]
        event           <- map["event"]
        allMessages     <- map["allMessages"]
        peopleEvent     <- map["peopleEvent"]
        countUnreadMessages <- map["unreadCount"]
        
        eventId = eventId ?? event?._id
        lastMessageId = lastMessageId ?? lastMessage?._id
        countUnreadMessages = countUnreadMessages ?? unreadMessages?.count ?? 0
    }
    
    func toJsonDic() -> [String: Any?] {
        var dic = [String: Any?]()
        
        dic["chatId"] = _id
        dic["userId"] = USER_MANAGER.userId
        dic["eventId"] = eventId
        dic["memberIds"] = members?.map({$0._id ?? $0.userId})

        return dic
    }
    
    func getOptionList() -> [String] {
        var list = [String]()

        if isMuteNotification == true {
            list.append("Unmute Notifications")
        }else {
            list.append("Mute Notifications")
        }
        
        let isOrganizer = organizer?._id == USER_MANAGER.userId

        // Add People / Leave Chat
        var titleAddPeople: String? = "Add People"
        var titleLeaveChat: String? = isGroup == true ? "Leave Chat" : nil
        
        if isEventChat == true {
            if isOrganizer == false {
                titleLeaveChat = event?.isLive == 1 ? "Leave Event" : nil
                titleAddPeople = nil
            }else if event?.isCancel == true ||
                     event?.isActive == false ||
                     event?.isEnded == true {
                titleAddPeople = nil
                titleLeaveChat = nil
            }else if event?.isLive == 1 {
                titleLeaveChat = "End Event"
                titleAddPeople = "Invite People"
            }else if event?.isExpired == true {
                titleLeaveChat = "Cancel Event"
                titleAddPeople = nil
            }else {
                titleLeaveChat = "Cancel Event"
                titleAddPeople = "Invite People"
            }
        }
        
        if let title = titleAddPeople {
            list.append(title)
        }
        
        list.append("Delete Chat")
        
        if let title = titleLeaveChat {
            list.append(title)
        }
        
        return list

    }
    
    
    
}
