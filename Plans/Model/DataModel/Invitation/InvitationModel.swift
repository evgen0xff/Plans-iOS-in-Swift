//
//  InvitationModel.swift
//  Plans
//
//  Created by Star on 1/27/21.
//

import Foundation
import ObjectMapper

class InvitationModel : BaseData {
    var mobile, profileImage, userId, firstName, lastName, fullName, name, email : String?
    var userDetails : [UserModel]?
    var imageData: Data?
    var eventCreatedBy : [UserModel]?
    var isLive: Int?
    var status: Int?   // 1 -> Invited, 2 -> Going, 3 -> Maybe, 4 -> Next Time
    var frndShipStatus: Int? // 0 = friend request, 1 = friend, 2 = reject a request, 3 = cancelled a request, 4 = unFriend, 5 = blocked by users, 10 = entry is not in friends table, but its used for if noy any relation between 2 users.
    var locationArrivedTime : Double?
    var invitationTime: Double?
    var turnOffNoti, isFriend: Bool?
    var invitedType: InviteType?
    
    override func mapping(map: Map) {
        super.mapping(map: map)

        userId          <- map["userId"]
        mobile          <- map["mobile"]
        email           <- map["email"]
        name            <- map["name"]
        firstName       <- map["firstName"]
        lastName        <- map["lastName"]
        fullName        <- map["fullName"]
        isLive          <- map["isLive"]
        status          <- map["status"]
        userDetails     <- map["userDetails"]
        eventCreatedBy  <- map["eventCreatedBy"]
        profileImage    <- map["profileImage"]
        frndShipStatus    <- map["friendShipStatus"]
        locationArrivedTime  <- map["locationArrivedTime"]
        invitationTime <- map["invitationTime"]
        turnOffNoti     <- map["turnOffNoti"]
        isFriend        <- map["isFriend"]

        var invitedType : Int?
        invitedType <- map["invitedType"]
        if let type = invitedType {
            self.invitedType = InviteType(rawValue: type)
        }
        
        // Extra code
        if invitationTime != nil, Date() < Date(timeIntervalSince1970: invitationTime!) {
            invitationTime! = invitationTime! / 1000.0
        }
    }
    
    convenience init(user: UserModel){
        self.init()

        _id = user._id ?? user.userId
        userId = user._id ?? user.userId
        mobile = user.mobile
        email = user.email
        name = user.name
        fullName = user.fullName
        firstName = user.firstName
        lastName = user.lastName
        profileImage = user.profileImage
        frndShipStatus = user.friendShipStatus
        isFriend = user.isFriend
        invitationTime = user.invitedTime
        imageData = user.imageData
        invitedType = user.inviteType
    }

}
