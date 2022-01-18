//
//  RootResponse.swift
//  Plans
//
//  Created by Star on 1/27/21.
//

import Foundation
import ObjectMapper

class RootResponse : BaseModel {
    
    var status: Int?
    var time: Int64?
    var response:Any?
    var error: ErrorModel?
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        status <- map["status"]
        time <- map["time"]
        response <- map["response"]
        error <- map["error"]
    }
}

