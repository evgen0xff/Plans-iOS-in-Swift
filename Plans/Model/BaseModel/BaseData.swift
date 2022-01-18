//
//  BaseData.swift
//  Plans
//
//  Created by Star on 1/27/21.
//

import Foundation
import ObjectMapper

class BaseData : BaseModel {
    
    var _id: String?

    override init(){
        super.init()
    }
    
    required init?(map: Map) {
        super.init(map: map)
    }
    

    override func mapping(map: Map) {
        super.mapping(map: map)
        
        _id <- map["_id"]
    }
}
