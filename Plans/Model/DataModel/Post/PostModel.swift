//
//  PostModel.swift
//  Plans
//
//  Created by Star on 1/27/21.
//

import Foundation
import ObjectMapper

class PostModel : BaseData {
    
    var postType,
        postThumbnail,
        postText,
        postMedia,
        
        commentType,
        commentThumbnail,
        commentText,
        commentMedia,
        message : String?
    
    var createdAt: Double?
    var likes : [UserModel]?
    var user: UserModel?
    var comments: [PostModel]?
    var likesCounts, commentsCounts: Int?
    var isLike: Bool?
    var width, height: Int?
    
    var type : String? {
        return postType ?? commentType
    }

    var text: String? {
        return postText ?? commentText
    }

    var isMediaType: Bool {
        return (type == "image" || type == "video")
    }

    var urlMedia: String? {
        return postMedia ?? commentMedia
    }

    var urlThumbnail: String? {
        return postThumbnail ?? commentThumbnail
    }

    var isComment: Bool {
        var result = false
        if postText != nil || (postType != nil && postMedia != nil) {
            result = false
        }else if commentText != nil || (commentType != nil && commentMedia != nil) {
            result = true
        }
        return result
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        postThumbnail       <- map["postThumbnail"]
        postText            <- map["postText"]
        postType            <- map["postType"]
        postMedia           <- map["postMedia"]
        width               <- map["width"]
        height              <- map["height"]
        commentType         <- map["commentType"]
        commentThumbnail    <- map["commentThumbnail"]
        commentText         <- map["commentText"]
        commentMedia        <- map["commentMedia"]
        user                <- map["userId"]
        createdAt           <- map["createdAt"]
        user                <- map["userId"]
        likes               <- map["likes"]
        isLike              <- map["isLike"]
        comments            <- map["comments"]
        likesCounts         <- map["likesCounts"]
        commentsCounts      <- map["commentsCounts"]
        message             <- map["message"]
        
        likes?.sort(by: { (item1, item2) -> Bool in
            if let time1 = item1.createdAt, let time2 = item2.createdAt, time1 > time2 {
                return true
            }
            return false
        })
    }
    
}
