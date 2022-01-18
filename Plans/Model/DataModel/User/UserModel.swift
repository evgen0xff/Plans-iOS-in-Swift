//
//  UserModel.swift
//  Plans
//
//  Created by Plans Collective LLC on 6/13/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import Foundation
import ObjectMapper
import Contacts

enum InviteType : Int {
    case friend = 0     // User who is friended with me on Plans
    case contact = 1    // User who is added from Phone Contacts
    case email = 2      // User who is added through the app by email
    case link = 3       // User who is invited by Share Link
    case mobile = 4     // User who is added through the app by mobile number
    case plansUser = 5  // User who is an user on Plans
}

class UserModel : BaseData {
    
    var userId, email, mobile, mobileNumber, name, firstName, lastName, fullName, birthday, key, mainKey, title, friendId, password, socialId, deviceToken, fcmId, communicationType, otp, accessToken, bio, imageType, loginType, profileImage, oldEmail, oldMobile, facebookImage, isCreateAccount, eventId, limit, friendRequestSender, message, location, userLocation, imageUrl, videoUrl, blockedBy : String?
    var isPrivateAccount, isBlock, isFriend : Bool?
    var lat, long, dob, size : Double?
    var status, isActive, pageNumber, isFriends, friendsCount, eventCount : Int?
    var friendShipStatus : Int? // 0 = friend request, 1 = friend, 2 = reject a request, 3 = cancelled a request, 4 = unFriend, 5 = blocked by users, 10 = entry is not in friends table, but its used for if noy any relation between 2 users.    
    var userDetails: UserModel? // Like user for post model
    var userProfile: UserModel? // OtherUserProfile
    var userDetail: [UserModel]? // Notification API
    var imageData: Data?
    var coinNumber: Int?
    var invitedTime: Double?
    var createdAt: Double?
    var invitedType: Int?
    var lastViewTimeForNotify: Double?
    
    var inviteType: InviteType? {
        didSet {
            invitedType = inviteType?.rawValue
        }
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)

        userId                  <- map["userId"]
        key                     <- map["key"]
        mainKey                 <- map["mainKey"]
        title                   <- map["title"]
        firstName               <- map["firstName"]
        lastName                <- map["lastName"]
        fullName                <- map["fullName"]
        name                    <- map["name"]
        email                   <- map["email"]
        status                  <- map["status"]
        lat                     <- map["lat"]
        long                    <- map["long"]
        location                <- map["location"]
        userLocation            <- map["userLocation"]
        bio                     <- map["bio"]
        password                <- map["password"]
        friendId                <- map["friendId"]
        socialId                <- map["socialId"]
        deviceToken             <- map["deviceToken"]
        fcmId                   <- map["fcmId"]
        dob                     <- map["dob"]
        mobile                  <- map["mobile"]
        mobileNumber            <- map["mobileNumber"]
        communicationType       <- map["communicationType"]
        friendShipStatus        <- map["friendShipStatus"]
        otp                     <- map["otp"]
        accessToken             <- map["accessToken"]
        friendsCount            <- map["friendsCount"]
        eventCount              <- map["eventCount"]
        loginType               <- map["loginType"]
        isFriends               <- map["isFriends"]
        profileImage            <- map["profileImage"]
        facebookImage           <- map["facebookImage"]
        isCreateAccount         <- map["isCreateAccount"]
        friendRequestSender     <- map["friendRequestSender"]
        eventId                 <- map["eventId"]
        pageNumber              <- map["pageNo"]
        limit                   <- map["limit"]
        message                 <- map["message"]
        userDetails             <- map["userDetails"]
        userDetail              <- map["userDetail"]
        oldEmail                <- map["oldEmail"]
        oldMobile               <- map["oldMobile"]
        coinNumber              <- map["coinNumber"]
        isPrivateAccount        <- map["isPrivateAccount"]
        isBlock                 <- map["isBlock"]
        imageUrl                <- map["imageUrl"]
        videoUrl                <- map["videoUrl"]
        size                    <- map["size"]
        blockedBy               <- map["blockedBy"]
        isActive                <- map["isActive"]
        isFriend                <- map["isFriend"]
        invitedTime             <- map["invitedTime"]
        createdAt               <- map["created"]
        invitedType             <- map["invitedType"]
        lastViewTimeForNotify   <- map["lastViewTimeForNotify"]

        if _id == nil || userId == nil {
            _id = userId ?? _id
            userId = _id ?? userId
        }
        
        inviteType = InviteType(rawValue: invitedType ?? InviteType.plansUser.rawValue)

        if mobile != nil, mobile != "" {
            mobileNumber = mobile
        }

        if mobileNumber != nil, mobileNumber != "" {
            mobile = mobileNumber
        }
        
        isFriend = isFriend ?? (isFriends == 1 ? true : false)
        isFriends = isFriends ?? (isFriend == true ? 1 : 0)
    }

    convenience init(contact: CNContact){
        self.init()
        
        fullName = CNContactFormatter.string(from: contact, style: .fullName)
        name = fullName
        imageData  = contact.imageDataAvailable == true ? contact.imageData : nil

        var countryCode = "US"
        var mobNumVar: String?
        if contact.phoneNumbers.count > 0 {
            if let mobNum = contact.phoneNumbers.first?.value {
                if let code = mobNum.value(forKey: "countryCode") as? String {
                    countryCode = code
                }
                countryCode = countryCode.getCountryPhoneCodeFromISO()
                mobNumVar = (mobNum.value(forKey: "digits") as? String)?.getDigitalPhoneNum()
            }
        }

        mobileNumber = mobNumVar
        mobile = mobNumVar != nil ? (countryCode + mobNumVar!) : nil
        inviteType = .contact
    }

    convenience init(fbUser: FBUser) {
        self.init()
        
        email = fbUser.email
        socialId = fbUser.fbId
        facebookImage = fbUser.profileImage
        profileImage = fbUser.profileImage
        birthday = fbUser.birthday
        if let birth = birthday {
            dob = birth.dateFromString(dateFormat: DateFormat.fbApiDate)?.timeIntervalSince1970
        }
        firstName = fbUser.first_name
        lastName = fbUser.last_name
    }
    
    convenience init(invitationModel: InvitationModel){
        self.init()

        _id = invitationModel.userId ?? invitationModel._id
        userId = invitationModel.userId ?? invitationModel._id
        email = invitationModel.email
        mobile = invitationModel.mobile
        mobileNumber = invitationModel.mobile
        name = invitationModel.fullName
        fullName = invitationModel.fullName
        firstName = invitationModel.firstName
        lastName = invitationModel.lastName
        friendShipStatus = invitationModel.frndShipStatus
        isFriend = invitationModel.isFriend
        profileImage = invitationModel.profileImage
        inviteType = invitationModel.invitedType ?? .friend
        invitedType = inviteType?.rawValue
        
        if friendShipStatus == nil {
            friendShipStatus = isFriend == true ? 1 : nil
        }
    }

    convenience init(userModel: UserModel){
        self.init()

        _id = userModel._id
        userId = userModel.userId
        email = userModel.email
        mobile = userModel.mobile
        mobileNumber = userModel.mobileNumber
        name = userModel.name
        fullName = userModel.fullName
        firstName = userModel.firstName
        lastName = userModel.lastName
        friendShipStatus = userModel.friendShipStatus
        isFriend = userModel.isFriend
        profileImage = userModel.profileImage
        imageData = userModel.imageData
        invitedType = userModel.invitedType
        inviteType = userModel.inviteType
    }

    convenience init(userId: String?){
        self.init()
        self._id = userId
        self.userId = userId
    }

    convenience init(mobile: String){
        self.init()
        self.mobile = mobile
        self.mobileNumber = mobile
        self.inviteType = .mobile
        invitedType = inviteType?.rawValue

    }

    convenience init(email: String){
        self.init()
        self.email = email
        self.inviteType = .email
        invitedType = inviteType?.rawValue
    }
    
    func getCountLiveEvents() -> String? {

        guard let coin = coinNumber, coin > 0 else { return nil }

        var count = 0

        switch coin {
        case 1: count = 1
        case 2: count = 10
        case 3: count = 25
        case 4: count = 100
        case 5: count = 200
        case 6: count = 300
        case 7: count = 400
        case 8: count = 500
        case 9: count = 600
        case 10: count = 700
        case 11: count = 800
        case 12: count = 900
        case 13: count = 1000
        case 14: count = 1250
        case 15: count = 1500
        case 16: count = 2000
        case 17: count = 2500
        case 18: count = 3000
        default:
            break
        }
        
        return "\(count)+";
    }
    
    func getAccessForMe() -> (isAccess: Bool, isBlock: Bool, isPrivate: Bool){
        let isPrivate = isPrivateAccount ?? true
        let isFriends = friendShipStatus == 1 ? true : false
        var isBlockedByMe = false
        
        if isBlock == true {
            isBlockedByMe = true
        }else if let blockedBy = blockedBy, blockedBy == USER_MANAGER.userId {
            isBlockedByMe = true
        }else {
            isBlockedByMe = false
        }

        var isAccess = true
        if isBlockedByMe == true {
            isAccess = false
        }else if isPrivate == true {
            if isFriends == true {
                isAccess = true
            }else {
                isAccess = false
            }
        }
        
        return (isAccess, isBlockedByMe, isPrivate)
    }

}

