//
//  EventCalendarModel.swift
//  Plans
//
//  Created by Star on 2/3/21.
//

import Foundation
import ObjectMapper

class EventCalendarModel : BaseModel {
    
    var _id, locationName, address, eventsName,userId : String?
    var startTime, endTime : Double?
    var isLive : Int?
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        _id <- map["_id"]
        locationName <- map["locationName"]
        address <- map["address"]
        eventsName <- map["eventName"]
        endTime <- map["endTime"]
        isLive <- map["isLive"]
        startTime <- map["startTime"]
        userId <- map["userId"]
  
    }
}
