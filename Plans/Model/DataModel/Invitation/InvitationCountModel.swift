//
//  InvitationCountModel.swift
//  Plans
//
//  Created by Star on 1/27/21.
//

import Foundation
import ObjectMapper

class InvitationCountModel : BaseModel {
    var liveCnt: Int = 0, invitedCnt: Int = 0, goingCnt: Int = 0, maybeCnt: Int = 0, nextTimeCnt: Int = 0
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        liveCnt          <- map["liveCnt"]
        invitedCnt       <- map["invitedCnt"]
        goingCnt         <- map["goingCnt"]
        maybeCnt         <- map["maybeCnt"]
        nextTimeCnt      <- map["nextTimeCnt"]
    }
}
