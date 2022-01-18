//
//  NotificationActivityModel.swift
//  Plans
//
//  Created by Star on 2/3/21.
//

import Foundation
import ObjectMapper

class NotificationActivityModel: BaseModel {
    
    var _id,
        userId,                 // Receiver Id
        uid,                    // Sender Id
        eventId,
        postId,
        chatId,
        liveMomentId,
        message,
        attributedMsg,
        profileImage,
        firstName,
        lastName,
        image,
        notificationType,
        eventName,
        createdAt,
        userImage,
        userImage2,
        title,
        body: String?
    
    var isLive,
        isActive : Int?
    
    var createdAtTimestamp: Double?
    var isSilent: Bool?
    var event : EventFeedModel?
    var isNew: Bool {
        return (createdAtTimestamp ?? 0) > USER_MANAGER.lastViewTimeForNotify
    }
    
    required init?(map: Map) {
        super.init(map: map)
    }

    override func mapping(map: Map) {
        super.mapping(map: map)

        _id                         <-  map["_id"]
        message                     <-  map["message"]
        attributedMsg               <-  map["attributedMsg"]
        profileImage                <-  map["profileImage"]
        uid                         <-  map["uid"]
        userId                      <-  map["userId"]
        firstName                   <-  map["firstName"]
        lastName                    <-  map["lastName"]
        image                       <-  map["image"]
        notificationType            <-  map["notificationType"]
        eventName                   <-  map["eventName"]
        isLive                      <-  map["isLive"]
        isActive                    <-  map["isActive"]
        createdAt                   <-  map["createdAt"]
        eventId                     <-  map["eventId"]
        userImage                   <-  map["userImage"]
        userImage2                  <-  map["userImage2"]
        eventId                     <-  map["eventId"]
        postId                      <-  map["postId"]
        liveMomentId                <-  map["liveMomentId"]
        createdAtTimestamp          <-  map["createdAtTimestamp"]
        event                       <-  map["event"]
        isSilent                    <-  map["isSilent"]
    }
    
    init(dic : [AnyHashable: Any]?) {
        super.init()
        
        guard let dic = dic else { return }
 
        notificationType = dic["notificationType"] as? String
        title = dic["title"] as? String
        body = dic["body"] as? String
        
        if let eventId = dic["eventId"] as? String, eventId != "" {
            self.eventId = eventId
        }
        if let postId = dic["postId"] as? String, postId != "" {
            self.postId = postId
        }
        if let liveMomentId = dic["liveMomentId"] as? String, postId != "" {
            self.liveMomentId = liveMomentId
        }
        if let uid = dic["uid"] as? String, uid != "" {
            self.uid = uid
        }
        if let userId = dic["userId"] as? String, userId != "" {
            self.userId = userId
        }
        if let chatId = dic["chatId"] as? String, chatId != "" {
            self.chatId = chatId
        }
        if let temp = dic["isSilent"] as? String {
            if temp == "false" {
                isSilent = false
            }else if temp == "true" {
                isSilent = true
            }
        }

    }
    
    func getAttributedText(msgAttri: String? = nil, msgOrigin: String? = nil, withTimeAgo: Bool = true, breakLine: Bool = false) -> NSMutableAttributedString{
        let arrayAttri = NSMutableAttributedString()
        
        if let attributedMsg = msgAttri ?? attributedMsg {
            var arriText = attributedMsg.set(style: AppLabelStyleGroup.notification)
            if notificationType == "Event Reminder", attributedMsg.contains("tomorrow") {
                if let startTime = event?.startTime {
                    var msg = attributedMsg.dropLast()
                    msg = msg + " at " + Date(timeIntervalSince1970: startTime).dateStringWith(strFormat: "h:mm a") + "."
                    arriText = String(msg).set(style: AppLabelStyleGroup.notification)
                }
            }
            arrayAttri.append(arriText)
        }else if let msg = msgOrigin ?? message {
            arrayAttri.append(msg.colored(color: .black, font: AppFont.regular.size(15.0)))
        }
        
        if withTimeAgo == true, let createdAt = createdAtTimestamp {
            let timeAgo = (breakLine == false ? " " : "\n") + Date(timeIntervalSince1970: createdAt).timeAgoSince()
            arrayAttri.append("\(timeAgo)".colored(color: AppColor.grey_text_0, font: AppFont.regular.size(13.0)))
        }
        
        return arrayAttri
    }
    
    func getMessageText(widthMax: CGFloat?, label: UILabel?) -> NSMutableAttributedString {
        var result = getAttributedText()
        guard var countLines = label?.countLines(textAttri: result, width: widthMax, fontTrail: AppFont.regular.size(13.0)) else { return result }
        switch notificationType {
        case "Comment Like", "Like", "Comment":
            var last = 6
            while countLines > 3 {
                let msgAttri = String(attributedMsg?.dropLast(last) ?? "") + "..."
                let msgOrigin = String(message?.dropLast(last) ?? "") + "..."
                result = getAttributedText(msgAttri: msgAttri, msgOrigin: msgOrigin)
                countLines = label!.countLines(textAttri: result, width: widthMax, fontTrail: AppFont.regular.size(13.0))
                last += 3
            }
            break
        default:
            let resultWithOutTime = getAttributedText(withTimeAgo: false)
            guard let countLinesWithOutTime = label?.countLines(textAttri: resultWithOutTime, width: widthMax) else { return result }

            if countLines != countLinesWithOutTime {
                result = getAttributedText(breakLine: true)
            }
            break
        }
        
        return result
    }
    
    
    
    
}
