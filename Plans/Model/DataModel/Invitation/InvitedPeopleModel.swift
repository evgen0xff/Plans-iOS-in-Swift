//
//  InvitedPeopleModel.swift
//  Plans
//
//  Created by Star on 1/27/21.
//

import Foundation
import ObjectMapper

class InvitedPeopleModel : BaseModel {
    
    var eventData: EventFeedModel?
    var counts = InvitationCountModel()
    var people = [UserModel]()
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        counts                  <- map["count"]
        eventData               <- map["eventData"]
        people                  <- map["people"]
    }
}
