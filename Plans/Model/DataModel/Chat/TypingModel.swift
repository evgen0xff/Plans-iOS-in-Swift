//
//  TypingUserModel.swift
//  Plans
//
//  Created by Star on 1/27/21.
//

import Foundation
import ObjectMapper

class TypingUserModel: BaseModel {
    
    var userName,
        chatId,
        userId,
        profileImage: String?
    
    var isTyping: Bool = false

    override init(){
        super.init()
    }

    required init?(map: Map) {
        super.init(map: map)
    }
    
    init(userName: String?,
         chatId: String?,
         userId: String?,
         profileImage: String?,
         isTyping: Bool = false) {
        super.init()
    
        self.userName = userName
        self.chatId = chatId
        self.userId = userId
        self.profileImage = profileImage
        self.isTyping = isTyping
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        userName <- map["userName"]
        chatId  <- map["chatId"]
        userId  <- map["userId"]
        profileImage <- map["profileImage"]
        isTyping <- map["isTyping"]
    }
    
}

class TypingModel: BaseModel {
    
    var chatId: String?
    var typingUsers = [TypingUserModel]()
    var lastTypingUser: TypingUserModel? {
        return typingUsers.last
    }

    var isTyping: Bool {
        return typingUsers.contains(where: {$0.isTyping == true})
    }
    
    var textTyping: String {
        var result: String = ""
        switch typingUsers.count {
        case 0:
            break
        case 1:
            result = "\(typingUsers[0].userName ?? "") is typing..."
        case 2:
            result = "\(typingUsers[0].userName ?? "") and \(typingUsers[1].userName ?? "") are typing..."
        case 3:
            result = "\(typingUsers[0].userName ?? ""), \(typingUsers[1].userName ?? "") and \(typingUsers[2].userName ?? "") are typing..."
        default:
            result = "Several people are typing..."
        }
        
        return result
    }
    
    func updateTyping(typingNew: TypingUserModel?, listBlockedUsers: [UserModel]) -> Bool {
        
        var isChanged = false
        
        guard let new = typingNew, new.userId != USER_MANAGER.userId, !listBlockedUsers.contains(where: { $0._id == new.userId}) else {
            return isChanged
        }
        
        typingUsers.removeAll(where: { user in listBlockedUsers.contains(where: { $0._id == user.userId}) })
        
        chatId = new.chatId
        if let index = typingUsers.firstIndex(where: {$0.userId == new.userId}) {
            if new.isTyping == false {
                typingUsers.remove(at: index)
                isChanged = true
            }
        }else {
            if new.isTyping == true {
                typingUsers.append(new)
                isChanged = true
            }
        }
        
        return isChanged
    }
    
    
}
