//
//  AuthResponse.swift
//  Plans
//
//  Created by Star on 1/28/21.
//

import Foundation
import ObjectMapper

class AuthResponse : BaseModel {
    
    var status: String?
    var message: String?
    var accessToken: String?
    var otp : String?
    var isVerified : Int?
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        status <- map["status"]
        message <- map["message"]
        accessToken <- map["accessToken"]
        otp <- map["otp"]
        isVerified <- map["isVerified"]
    }

}
