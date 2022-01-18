//
//  SettingsModel.swift
//  Plans
//
//  Created by Star on 2/23/21.
//

import UIKit
import ObjectMapper

class SettingOptionModel: BaseData {
    
    var name: String?
    var details: String?
    var key: String?
    var type: String?
    var status: Bool?

    required init?(map: Map) {
        super.init(map: map)
    }

    init(name: String? = nil, details: String? = nil, status: Bool? = nil) {
        super.init()
        
        self.name = name
        self.details = details
        self.status = status
    }
    
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        name <- map["name"]
        key <- map["key"]
        type <- map["type"]
        status <- map["status"]
        details <- map["details"]
    }

}

class SettingsModel: BaseData {
    
    var userId: String?
    var pushNotifications: [SettingOptionModel]?
    
    override func mapping(map: Map) {
        super.mapping(map: map)

        userId <- map["userId"]
        pushNotifications <- map["pushNotifications"]
    }
}
