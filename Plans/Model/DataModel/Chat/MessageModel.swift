//
//  MessageModel.swift
//  Plans
//
//  Created by Star on 1/27/21.
//

import Foundation
import ObjectMapper

class MessageModel : BaseData, NSCoding {
    
    enum MessageType : String {
        case text = "text"
        case image = "image"
        case video = "video"
        case date = "date"
    }
    
    var chatId:     String?
    var userId:     String?
    var message:    String?
    var videoFile:  String?
    var imageUrl:   String?
    var createdAt:  Double?
    var type:       MessageType?
    var user:       UserModel?
    

    var image: UIImage?
    var mediaData: Data?
    var sendingAt: Double?
    var viewModel: MessageViewModel?

    override init() {
        super.init()
    }
    
    init(_id: String?,
         chatId: String?,
         message: String?,
         userId: String?,
         imageUrl: String?,
         videoFile: String?,
         type: String?,
         createdAt: Double?,
         sendingAt: Double?,
         image: UIImage?,
         mediaData: Data?){
        super.init()
        
        self._id = _id
        self.chatId = chatId
        self.message = message
        self.userId = userId
        self.imageUrl = imageUrl
        self.videoFile = videoFile
        self.type = (type != nil) ? MessageType(rawValue: type!) : nil
        self.createdAt = createdAt
        self.sendingAt = sendingAt
        self.image = image
        self.mediaData = mediaData
    }

    required convenience init?(coder: NSCoder) {
        let _id = coder.decodeObject(forKey: "_id") as? String
        let chatId = coder.decodeObject(forKey: "chatId") as? String
        let message = coder.decodeObject(forKey: "message") as? String
        let userId = coder.decodeObject(forKey: "userId") as? String
        let imageUrl = coder.decodeObject(forKey: "imageUrl") as? String
        let videoFile = coder.decodeObject(forKey: "videoFile") as? String
        let type = coder.decodeObject(forKey: "type") as? String
        let createdAt = coder.decodeObject(forKey: "createdAt") as? Double
        let sendingAt = coder.decodeObject(forKey: "sendingAt") as? Double
        let image = coder.decodeObject(forKey: "image") as? UIImage
        let mediaData = coder.decodeObject(forKey: "mediaData") as? Data

        self.init(_id: _id, chatId: chatId,
                  message: message,
                  userId: userId,
                  imageUrl: imageUrl, videoFile: videoFile,
                  type: type,
                  createdAt: createdAt,
                  sendingAt: sendingAt,
                  image: image, mediaData: mediaData)
        
    }
    
    required init?(map: Map) {
        super.init(map: map)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(_id, forKey: "_id")
        coder.encode(chatId, forKey: "chatId")
        coder.encode(message, forKey: "message")
        coder.encode(userId, forKey: "userId")
        coder.encode(imageUrl, forKey: "imageUrl")
        coder.encode(videoFile, forKey: "videoFile")
        coder.encode(type?.rawValue, forKey: "type")
        coder.encode(createdAt, forKey: "createdAt")
        coder.encode(sendingAt, forKey: "sendingAt")
        coder.encode(image, forKey: "image")
        coder.encode(mediaData, forKey: "mediaData")
    }

    override func mapping(map: Map) {
        super.mapping(map: map)
        
        chatId      <- map["chatId"]
        userId      <- map["userId"]
        message     <- map["message"]
        imageUrl    <- map["imageUrl"]
        videoFile   <- map["videoFile"]
        createdAt   <- map["createdAt"]
        user        <- map["user"]

        var tempType : String?
        tempType <- map["type"]
        if tempType != nil {
            type = MessageType.init(rawValue: tempType!)
        }
    }
    
    func toJsonDic() -> [String: Any?] {
        let jsonDic = ["chatId":    chatId,
                      "userId":     userId,
                      "type":       type?.rawValue,
                      "message":    message,
                      "imageUrl":   imageUrl,
                      "videoFile":  videoFile,
                      "createdAt":  sendingAt] as [String : Any?]
        
        return jsonDic
    }
}

