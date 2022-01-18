//
//  ErrorModel.swift
//  Plans
//
//  Created by Star on 1/28/21.
//

import Foundation
import ObjectMapper

class ErrorModel : BaseModel {
    
    var errorCode: Int?
    var message:String?
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        errorCode <- map["errorCode"]
        message <- map["message"]
    }
}
