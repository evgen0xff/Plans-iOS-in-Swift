//
//  BaseModel.swift
//  Plans
//
//  Created by Star on 1/27/21.
//

import Foundation
import ObjectMapper

class BaseModel : Mappable {
    
    required init?(map: Map) {
    }
    
    init(){
    }
    
    func mapping(map: Map) {
    }
}
