//
//  ChatUserModel.swift
//  Plans
//
//  Created by Star on 3/7/21.
//

import UIKit
import ObjectMapper

class ChatUserModel: UserModel {
    
    var shownStatus:        Int?            // 1 -> Shown, 2 -> Hidden, 3 -> Deleted
    var isMuteNotification: Bool?           // Push Notify On/Off
    var isJoin:             Bool?
    var lastAccessTime:     Double?
    var deletedTime:        Double?
    var isHostChat:         Bool?           // Check if the user is the host or not.
    var lastMessageId:      String?
    var lastMessage:        MessageModel?

    override func mapping(map: Map) {
        super.mapping(map: map)

        shownStatus         <- map["shownStatus"]
        isMuteNotification  <- map["isMuteNotification"]
        isJoin              <- map["isJoin"]
        lastAccessTime      <- map["lastAccessTime"]
        deletedTime         <- map["deletedTime"]
        isHostChat          <- map["isHostChat"]
        lastMessageId       <- map["lastMessageId"]
        lastMessage         <- map["lastMessage"]
    }
    
    convenience init(user: UserModel?) {
        self.init()
        _id =           user?._id
        userId =        user?.userId
        firstName =     user?.firstName
        lastName =      user?.lastName
        email =         user?.email
        mobile =        user?.mobile
        profileImage =  user?.profileImage
    }

    convenience init(userId: String?) {
        self.init()
        self._id = userId
        self.userId = userId
    }

}
