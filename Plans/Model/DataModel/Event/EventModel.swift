//
//  EventModel.swift
//  Plans
//
//  Created by Star on 2/3/21.
//

import Foundation
import ObjectMapper

class EventModel : BaseModel {
    
    var eventID, postText, eventsName, details, userId, friendsContactNumbers, address, isCancel, caption, mediaType, locationName, checkInRange : String?
    var startDate, endDate, startTime, endTime, lat, long : Double?
    var isPublic, isGroupChatOn, invitesOnly: Bool?
    var invitedUsers: [InvitationModel]?
    var imageData: UIImage?
    var videoUrl: URL?
    var invitedPeople: [UserModel]?
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        eventID <- map["eventId"]
        postText <- map["postText"]
        eventsName <- map["eventsName"]
        details <- map["details"]
        startDate <- map["startDate"]
        friendsContactNumbers <- map["friendsContactNumbers"]
        endDate <- map["endDate"]
        startTime <- map["startTime"]
        endTime <- map["endTime"]
        address <- map["address"]
        lat <- map["lat"]
        long <- map["long"]
        isPublic <- map["isPublic"]
        invitesOnly <- map["invitesOnly"]
        isGroupChatOn <- map["isGroupChatOn"]
        userId <- map["userId"]
        caption <- map["caption"]
        mediaType <- map["mediaType"]
        checkInRange <- map["checkInRange"]
        locationName <- map["locationName"]
        isCancel <- map["isCancel"]
        invitedPeople <- map["invitedPeople"]
    }
    
    func getInvitedUserCounts () -> (friends: Int, contacts: Int, emails: Int) {
        let countFriends = invitedUsers?.count ?? 0
        let countContacts = invitedPeople?.filter({people in people.inviteType == .mobile && !(invitedUsers?.contains(where: {$0.mobile == people.mobile}) ?? false) }).count ?? 0
        let countEmails = invitedPeople?.filter({people in people.inviteType == .email && !(invitedUsers?.contains(where: {$0.email == people.email}) ?? false)}).count ?? 0
        
        return (countFriends, countContacts, countEmails)
    }


}

