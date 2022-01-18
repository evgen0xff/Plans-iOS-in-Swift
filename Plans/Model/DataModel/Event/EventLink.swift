//
//  EventLink.swift
//  Plans
//
//  Created by Star on 1/27/21.
//

import Foundation
import ObjectMapper

class EventLink : BaseModel {
    
    var invitation: String?
    var share: String?
    
    override func mapping(map: Map) {
        super.mapping(map: map)

        invitation     <- map["invitation"]
        share          <- map["share"]
    }
    
}
