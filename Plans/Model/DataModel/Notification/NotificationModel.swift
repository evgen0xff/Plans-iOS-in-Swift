//
//  NotificationModel.swift
//  Plans
//
//  Created by Star on 2/3/21.
//

import Foundation
import ObjectMapper

class NotificationModel: BaseModel {
    var eventInvitationCount,
        friendRequestCount: Int?
    var eventInvitationList: [EventFeedModel]?
    var friendRequestList: [FriendRequestModel]?
    var totalCountActivities: Int?
    var listActivities: [NotificationActivityModel]?

    override func mapping(map: Map) {
        super.mapping(map: map)

        eventInvitationCount        <-  map["eventInvitationCount"]
        friendRequestCount          <-  map["friendRequestCount"]
        eventInvitationList         <-  map["eventInvitationList"]
        friendRequestList           <-  map["friendRequestList"]
        listActivities              <-  map["listActivities"]
        totalCountActivities        <-  map["totalCountActivities"]
    }
}

class UnreadNotifyModel: BaseModel {
    var listNotifyUnviewed: [NotificationActivityModel]?
    var listChatsUnviewed: [ChatModel]?

    
    override func mapping(map: Map) {
        super.mapping(map: map)

        listNotifyUnviewed        <-  map["listNotifyUnviewed"]
        listChatsUnviewed          <-  map["listChatsUnviewed"]
    }

}

