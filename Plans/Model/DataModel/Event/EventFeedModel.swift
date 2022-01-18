//
//  EventFeedModel.swift
//  Plans
//
//  Created by Plans Collective LLC on 6/21/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import Foundation
import ObjectMapper

class EventFeedModel : BaseData {
    
    enum EventStatus {
        case waiting
        case runningLate
        case lived
        case ended
        case expired
        case cancelled
    }
    
    var address,
        detail,
        mediaType,
        height,
        width,
        thumbnail,
        caption,
        userId,
        eventName,
        imageOrVideo,
        chatId,
        locationName,
        checkInRange : String?
    
    var createdAt, startDate, startTime, endDate, endTime, startedTime, endedTime, liveTime, long, lat : Double?
    var eventCreatedBy : UserModel?
    var invitationDetails : [InvitationModel]?
    var invitedPeople: [UserModel]?
    var post : [PostModel]?
    var isActive, invitesOnly, isPublic, isJoin, isEnded, isPosting, isSaved, turnOffNoti, isHide, isCancel, isExpired, isViewed, isChatEnd : Bool?
    var postCounts, invitationCount, viewedCounts, isLive, isHostLive, isInvite, didLeave, joinStatus, liveMommentsCount, isGroupChatOn : Int?
    var liveMoments: [UserLiveMomentsModel]?
    var liveEventsData : [UserModel]?
    var chatInfo: ChatModel?
    var eventLink: EventLink?
    
    var eventStatus: EventStatus {
        var status: EventStatus = .waiting
        let now = Date().timeIntervalSince1970
        if isActive == false || isCancel == true {
            status = .cancelled
        }else if isEnded == true {
            status = .ended
        }else if isLive == 1 {
            status = .lived
        }else if isExpired == true ||
                    (endTime != nil && endTime! < now && (startedTime == nil || startedTime == 0)) {
            status = .expired
        }else if startTime != nil, startTime! < (now - 60) {
            status = .runningLate
        }else {
            status = .waiting
        }
        return status
    }
    
    var urlCoverImage: String? {
        return mediaType == "video" ? thumbnail : imageOrVideo
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        address             <- map["address"]
        height              <- map["height"]
        detail              <- map["details"]
        width               <- map["width"]
        endDate             <- map["endDate"]
        endTime             <- map["endTime"]
        eventCreatedBy      <- map["eventCreatedBy"]
        eventName           <- map["eventsName"]
        eventName           <- map["eventName"]
        imageOrVideo        <- map["imageOrVideo"]
        invitationDetails   <- map["invitations"]
        invitesOnly         <- map["invitesOnly"]
        isGroupChatOn       <- map["isGroupChatOn"]
        isPublic            <- map["isPublic"]
        userId              <- map["userId"]
        createdAt           <- map["createdAt"]
        startDate           <- map["startDate"]
        startTime           <- map["startTime"]
        lat                 <- map["lat"]
        long                <- map["long"]
        isLive              <- map["isLive"]
        isHostLive          <- map["isHostLive"]
        isInvite            <- map["isInvite"]
        didLeave            <- map["didLeave"]
        isEnded             <- map["isEnded"]
        isPosting           <- map["isPosting"]
        turnOffNoti         <- map["turnOffNoti"]
        isSaved             <- map["isSaved"]
        joinStatus          <- map["joinStatus"]
        isJoin              <- map["isJoin"]
        caption             <- map["caption"]
        mediaType           <- map["mediaType"]
        thumbnail           <- map["thumbnail"]
        postCounts          <- map["postCounts"]
        invitationCount     <- map["invitationCount"]
        viewedCounts        <- map["viewedCounts"]
        post                <- map["posts"]
        liveEventsData      <- map["liveEventsData"]
        liveMommentsCount   <- map["liveMommentsCount"]
        chatId              <- map["chatId"]
        locationName        <- map["locationName"]
        checkInRange        <- map["checkInRange"]
        isChatEnd           <- map["isChatEnd"]
        endedTime           <- map["isEndedTime"]
        isHide              <- map["isHide"]
        isCancel            <- map["isCancel"]
        liveTime            <- map["liveTime"]
        startedTime         <- map["startedTime"]
        isActive            <- map["isActive"]
        isExpired           <- map["isExpired"]
        invitedPeople       <- map["invitedPeople"]
        chatInfo            <- map["chats"]
        eventLink           <- map["eventLink"]
        isViewed            <- map["isViewed"]
        liveMoments         <- map["liveMomments"]
        
        // Extra process for Live
        if isHostLive == 1, let time = liveTime {
            let updatedTime = Date(timeIntervalSince1970: time)
            var hrs : Double = 3
            if isLive == 1, startedTime != nil, endTime != nil {
                if (endTime! - startedTime!) > (3600 * 24) {
                    hrs = 7
                }
            }
            let timeout = Date().addingTimeInterval(-3600 * hrs)
            if updatedTime.compare(timeout) == .orderedAscending {
                isHostLive = 0
            }
        }
        
        invitationDetails?.forEach({ (invitModel) in
            if invitModel.isLive == 1, let time = invitModel.locationArrivedTime {
                let updatedTime = Date(timeIntervalSince1970: time)
                var hrs : Double = 3
                if isLive == 1, startedTime != nil, endTime != nil {
                    if (endTime! - startedTime!) > (3600 * 24) {
                        hrs = 7
                    }
                }
                let timeout = Date().addingTimeInterval(-3600 * hrs)
                if updatedTime.compare(timeout) == .orderedAscending {
                    invitModel.isLive = 0
                }
            }
        })
        
        if isLive == 0 {
            isHostLive = 0
            invitationDetails?.forEach({ (model) in
                model.isLive = 0
            })
        }
        
        invitationDetails?.sort(by: { (item1, item2) -> Bool in
            return (item1.isLive ?? 0) > (item2.isLive ?? 0)
        })
        
        liveMoments?.sort(by: { (item1, item2) -> Bool in
            if item1.user?._id == USER_MANAGER.userId,
               item2.user?._id != USER_MANAGER.userId {
                return true
            }
            return false
        },{ (item1, item2) -> Bool in
            if item1.isAllSeen == false, item2.isAllSeen == true{
                return true
            }
            return false
        },{ (item1, item2) -> Bool in
            if let time1 = item1.timeLatest, let time2 = item2.timeLatest,
               time1 > time2 {
                return true
            }
            return false
        })
    }
    
    func isLiveUser (_ userId : String?) -> Bool {
        var live = false
        if self.userId == userId {
            live = self.isHostLive == 0 ? false : true
        } else if let user = self.invitationDetails?.first(where: { (invitModel) -> Bool in
            if invitModel.userId == userId {
                return true
            }else {
                return false
            }
        }) {
            live = user.isLive == 0 ? false : true
        }
        return live
    }

    func isTurnOffNoti (_ userId : String?) -> Bool {
        var result = false
        if self.userId == userId {
            result = self.turnOffNoti ?? false
        } else if let user = self.invitationDetails?.first(where: { (invitModel) -> Bool in
            if invitModel.userId == userId {
                return true
            }else {
                return false
            }
        }) {
            result = user.turnOffNoti ?? false
        }
        return result
    }
    
    func setTurnOffNoti (_ userId: String?, isTurnOff: Bool) {
        if self.userId == userId {
            self.turnOffNoti = isTurnOff
        } else if let user = self.invitationDetails?.first(where: { (invitModel) -> Bool in
            if invitModel.userId == userId {
                return true
            }else {
                return false
            }
        }) {
            user.turnOffNoti = isTurnOff
        }
    }
    
    func getFriendsCount () -> Int {
        var count = 0
        if eventCreatedBy?.isFriend == true {
            count += 1
        }
        
        invitationDetails?.forEach({ (user) in
            if user.isFriend == true, (user.status == 2 || user.status == 3){
                count += 1
            }
        })
        
        return count
    }
    
    func textStartEndTime() -> String? {
        var text, textStart, textEnd, textDate : String?
        if let time = startTime  {
            let dateTime = Date(timeIntervalSince1970: time)
            textDate = dateTime.dateStringWith(strFormat: "E, MMM d, yyyy")
            if dateTime.year != Date().year {
                textStart = textDate
            }else {
                textStart = dateTime.dateStringWith(strFormat: "E, MMM d")
            }
            textStart! += " at " + dateTime.dateStringWith(strFormat: "h:mm a")
        }
        if let time = endTime  {
            let dateTime = Date(timeIntervalSince1970: time)
            textEnd = dateTime.dateStringWith(strFormat: "E, MMM d, yyyy")
            if textEnd == textDate {
                textEnd = dateTime.dateStringWith(strFormat: "h:mm a")
            }else {
                if dateTime.year == Date().year {
                    textEnd = dateTime.dateStringWith(strFormat: "E, MMM d")
                }
                textEnd! += " at " + dateTime.dateStringWith(strFormat: "h:mm a")
            }
        }
        
        text = "\(textStart ?? "") - \(textEnd ?? "")"

        return text
    }
    
    func isOwnEvent(_ userId: String?) -> Bool {
        return userId == (eventCreatedBy?.userId ?? self.userId)
    }
    
    func getInvitedUserCounts () -> (friends: Int, contacts: Int, emails: Int) {
        let countFriends = invitationDetails?.count ?? 0
        let countContacts = invitedPeople?.filter({people in people.inviteType == .mobile && !(invitationDetails?.contains(where: {$0.mobile == people.mobile}) ?? false) }).count ?? 0
        let countEmails = invitedPeople?.filter({people in people.inviteType == .email && !(invitationDetails?.contains(where: {$0.email == people.email}) ?? false)}).count ?? 0
        
        return (countFriends, countContacts, countEmails)
    }
    
    func getRemovedUserCounts(friensNew: [InvitationModel]?, peopleNew: [UserModel]?) -> (friends: Int, contacts: Int, emails: Int) {
        let countFriends = invitationDetails?.filter({ (old) -> Bool in
                if friensNew == nil || friensNew?.contains(where: {$0.userId == old.userId}) == true {
                    return false
                }
                return true
            }).count ?? 0

        let countContacts = invitedPeople?.filter({ people in people.inviteType == .mobile && !(invitationDetails?.contains(where: {$0.mobile == people.mobile}) ?? false)}).filter({ (old) -> Bool in
                if peopleNew == nil || peopleNew?.contains(where: {$0.mobile == old.mobile}) == true {
                    return false
                }
                return true
            }).count ?? 0

        let countEmails = invitedPeople?.filter({ people in people.inviteType == .email && !(invitationDetails?.contains(where: {$0.email == people.email}) ?? false)}).filter({ (old) -> Bool in
                if peopleNew == nil || peopleNew?.contains(where: {$0.email == old.email}) == true {
                    return false
                }
                return true
            }).count ?? 0

        return (countFriends, countContacts, countEmails)
    }
    
    func isExistLiveGuest() -> Bool {
        var result = false
        result = invitationDetails?.contains(where: {$0.isLive == 1}) ?? false
        return result
    }
    
    func isExistAcceptGuest() -> Bool {
        var result = false
        result = invitationDetails?.contains(where: {($0.status ?? 0) > 1}) ?? false
        return result
    }
    
    func isEnableAddLiveMoment() -> Bool {
        var result = false
        if isPostingForMe() == true,
           isLiveUser(USER_MANAGER.userId) == true,
           (isEnded ?? false) == false {
            result = true
        }
        return result
    }
    
    func isPostingForMe() -> Bool {
        var result = false
        if isOwnEvent(USER_MANAGER.userId) == true || (isPosting == true && (joinStatus == 2 || joinStatus == 3)) {
            result = true
        }
        return result
    }
    
    func getEventStatus() -> (title: String?, color: UIColor?) {
        var title: String?
        var color: UIColor?
        
        switch eventStatus {
        case .waiting:
            title = Date(timeIntervalSince1970: startTime ?? 0).getStartedString(isStarted: false)
            color = AppColor.blue_text
        case .runningLate:
            title = "Running Late"
            color = AppColor.pink_running
        case .lived:
            if let startedTime = startedTime, startedTime != 0 {
                title = Date(timeIntervalSince1970: startedTime).getStartedString(isStarted: true)
                color = AppColor.blue_text
            }
        case .ended:
            title = "Ended"
            color = AppColor.purple_join
        case .cancelled:
            title = "Cancelled"
            color = AppColor.brown_cancelled
        case .expired:
            title = "Expired"
            color = AppColor.orange_expired
        }
        
        return (title, color)
    }
    
    static func getEventStatusColor(from status: String?) -> UIColor? {
        guard let status = status else { return nil}
        
        var color: UIColor?
        switch status {
        case "Running Late" :
            color = AppColor.pink_running
        case "Ended":
            color = AppColor.purple_join
        case "Cancelled":
            color = AppColor.brown_cancelled
        case "Expired":
            color = AppColor.orange_expired
        default :
            color = AppColor.blue_text
        }

        return color
    }
    
    func getInvitedPeople() -> [UserModel] {
        var result = [UserModel]()
        invitationDetails?.forEach({ result.append(UserModel(invitationModel: $0)) })
        invitedPeople?.forEach({ result.append($0) })
        
        return result
    }
    
    func isEnableToShow(userId: String?) -> Bool {
        var result = true

        if (isActive == false) {
            result = false
        }else if (!isOwnEvent(userId)) {
            if (isPublic == false && !isAttended(userId: userId)) {
                result = false
            }
        }

        return result
    }
    
    func isAttended(userId: String?) -> Bool {
        var result = false
        if (isOwnEvent(userId)) {
          result = true
        } else {
            result = invitationDetails?.contains(where: { $0.userId != nil && $0.userId == userId}) ?? false
        }

        return result
    }
    
    func getAttendee(userId: String? = nil, mobile: String? = nil, email: String? = nil) -> InvitationModel? {
        let attendee = invitationDetails?.first(where: { item in
            var result = false
            if mobile != nil, !mobile!.isEmpty {
                result = item.mobile == mobile
            }
            if result == false, email != nil, !email!.isEmpty {
                result = item.email == email
            }
            if result == false, userId != nil, !userId!.isEmpty {
                result = (item._id ?? item.userId) == userId
            }
            return result
        })
        
        return attendee
    }



}

