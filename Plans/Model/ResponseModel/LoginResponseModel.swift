//
//  LoginResponseModel.swift
//  Plans
//
//  Created by Star on 1/27/21.
//

import Foundation
import ObjectMapper

class LoginResponseModel : BaseModel {
    
    var accessToken : String?
    var userProfile : UserModel?
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        accessToken             <- map["accessToken"]
        userProfile             <- map["userProfile"]
    }
}
