//
//  FriendRequestModel.swift
//  Plans
//
//  Created by Top Star on 6/2/21.
//

import Foundation
import ObjectMapper

class FriendRequestModel: BaseData {

    var senderId: String?
    var receiverId: String?
    var friendShip: Int?
    var createAt: Double?
    var senderDetail: UserModel?
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        senderId <- map["senderId"]
        receiverId <- map["receiverId"]
        friendShip <- map["friendShip"]
        createAt <- map["createAt"]
        senderDetail <- map["senderDetail"]
    }
}
