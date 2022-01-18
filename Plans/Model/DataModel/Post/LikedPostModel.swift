//
//  LikedPostModel.swift
//  Plans
//
//  Created by Star on 2/6/21.
//

import Foundation
import ObjectMapper

class LikedPostModel : BaseData {
    var postMedia,
        postType,
        postText,
        eventId,
        userId,
        eventName,
        eventType,
        firstName,
        lastName,
        postImageUrl,
        message,
        eventImageUrl: String?
    
    var width, height : Float?
    
    override func mapping(map: Map) {
        super.mapping(map:map)
        
        postMedia               <- map["postMedia"]
        eventId                 <- map["eventId"]
        postText                <- map["postText"]
        postType                <- map["postType"]
        userId                  <- map["userId"]
        eventName               <- map["eventName"]
        eventType               <- map["eventType"]
        firstName               <- map["firstName"]
        lastName                <- map["lastName"]
        postImageUrl            <- map["postImageUrl"]
        eventImageUrl           <- map["eventImageUrl"]
        message                 <- map["message"]
        width                   <- map["width"]
        height                  <- map["height"]
    }
}

