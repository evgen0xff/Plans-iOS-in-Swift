//
//  UserLiveMomentsModel.swift
//  Plans
//
//  Created by Plans Collective LLC on 18/02/19.
//  Copyright © 2019 PlansCollective. All rights reserved.
//

import Foundation
import ObjectMapper

class UserLiveMomentsModel: BaseModel {
    
    var userId,
        eventID : String?
    
    var user: UserModel?
    var liveMoments: [LiveMomentModel]?
    
    var timeLatest: Double? {
        return liveMoments?.first?.createdAt
    }
    
    var isAllSeen: Bool {
        return liveMoments?.first?.isViewed ?? false
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)

        userId         <-  map["_id"]
        user           <-  map["user"]
        eventID        <-  map["eventId"]
        liveMoments      <-  map["liveMedia"]
        
        liveMoments?.sort(by:{ (item1, item2) -> Bool in
            if item1.isViewed == false, item2.isViewed == true {
                return true
            }
            return false
        },{ (item1, item2) -> Bool in
            if let createdAt1 = item1.createdAt, let createdAt2 = item2.createdAt, createdAt1 > createdAt2 {
                return true
            }
            return false
        })
        
    }
    
}

