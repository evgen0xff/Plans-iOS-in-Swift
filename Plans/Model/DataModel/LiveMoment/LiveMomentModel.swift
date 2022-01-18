//
//  LiveMomentModel.swift
//  Plans
//
//  Created by Star on 2/3/21.
//

import Foundation
import ObjectMapper


class LiveMomentModel: BaseModel {
    
    var _id,
        media,
        liveThumbnail,
        mediaType,
        imageOrVideo : String?
    var createdAt: Double?
    var isViewed: Bool?
    
    override func mapping(map: Map) {
        super.mapping(map: map)

        _id            <-   map["liveMommentId"]
        media          <-   map["media"]
        liveThumbnail  <-   map["liveThumbnail"]
        mediaType      <-   map["mediaType"]
        imageOrVideo   <-   map["url"]
        createdAt      <-   map["createdAt"]
        isViewed       <-   map["isViewed"]
    }
}

func == (left: LiveMomentModel?, right: LiveMomentModel?) -> Bool {
    
    if left?.media == right?.media,
        left?.liveThumbnail == right?.liveThumbnail,
        left?.mediaType == right?.mediaType,
        left?.imageOrVideo == right?.imageOrVideo,
        left?.createdAt == right?.createdAt {
        return true
    }else {
        return false
    }
}

