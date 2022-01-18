//
//  SocketIOManager.swift
//  Plans
//
//  Created by Admin on 17/04/19.
//  Copyright © 2019 PlansCollective. All rights reserved.
//

import Foundation
import SocketIO
import ObjectMapper
import PromiseKit

protocol SocketIOManagerDelegate {
    func didConnect ()
}

extension SocketIOManagerDelegate {
    func didConnect (){}
}


let SOCKET_MANAGER = SocketIOManager.share

class SocketIOManager : BaseService {
    static let share = SocketIOManager()

    var delegate : SocketIOManagerDelegate?
    var manager:SocketManager
    var socket:SocketIOClient
    var resetAck:SocketAckEmitter?
    var messagesSending = [MessageModel]()
    var dateLastTyping : Date?
    var chatMessagesUnsent = USER_MANAGER.chatMessagesUnsent
    var activeChatId: String? = nil


    // MARK: - Initialize
    override init() {
        manager = SocketManager(socketURL: URL(string: APP_CONFIG.urlChatSocket)!, config: [.log(true), .compress])
        socket = manager.defaultSocket
    }

    // MARK: - Initialize
    func initialize() {
        connectSocket()
    }

    // For Logout
    func initializeForLogout() {
        chatMessagesUnsent = [String: [MessageModel]]()
        closeChatList()
        closeConnection()
    }

    // MARK: - Socket Connect
    func connectSocket() {
        socket.on(clientEvent: .connect) {data, ack in
            self.delegate?.didConnect()
            self.sendUnsentMessages()
        }
        socket.connect()
    }
    
    // MARK: - Close Socket Connection
    func closeConnection() {
        socket.disconnect()
    }
    
    

    // MARK: - Fetch all chat list
    func getChatList()
    {
        socket.on("getChatList"){ dataArray, ack in
            if let chatData = dataArray[0] as? [String : Any] {
                if let userId = chatData["userId"] as? String,
                    userId == USER_MANAGER.userId,
                    let dicChats = chatData["listChats"] as? [[String:Any]] {
                    
                    let chatList = Mapper<ChatModel>().mapArray(JSONArray: dicChats)
                    NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kChatListChanged), object: chatList)
                }
            }
        }
        socket.emit("getChatList", ["userId": USER_MANAGER.userId])
    }
    
    
    //MARK: - Close GetChatList Event on Socket
    func closeChatList(){
        socket.off("getChatList")
    }
    
    //MARK: - Close GetChatMessages Event on Socket
    func closeOutputList()
    {
        socket.off("output")
        socket.off("typing")
    }

    //MARK: - Create Chat on Socket
    func updateChat(chat: ChatModel? = nil, chatId: String? = nil) {
        guard let chat = chat ?? (chatId != nil ? ChatModel(id: chatId) : nil) else { return }
        
        getChatMessages()
        checkSomeoneIsTyping()

        socket.emit("getMessages", chat.toJsonDic())
    }
       
    //MARK: - Fetch all chat messages
    func getChatMessages()
    {
        socket.on("output") { dataArray, ack in
            if dataArray.count > 0,
               let chatData = dataArray[0] as? [String : Any],
               let chat = Mapper<ChatModel>().map(JSON: chatData) {
                if self.activeChatId == nil || chat._id == self.activeChatId {
                    NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kMessageUpdated), object: chat)
                }
            }
        }
    }
    
    //MARK: - Check if other user is typing
    func checkSomeoneIsTyping(){
        socket.on("typing") { dataArray , ack in
            if dataArray.count > 0,
               let data = dataArray[0] as? [String: Any],
               let typingModel = Mapper<TypingUserModel>().map(JSON: data) {
                if self.activeChatId == nil || typingModel.chatId == self.activeChatId {
                    NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kSomeoneIsTyping), object: typingModel)
                }
            }
        }
    }
    
    //MARK: - Read Count To Zero
    var isPosting = false
    func readAllMessage(chatId: String?, userId: String?) {
        guard let chatId = chatId, let userId = userId else { return }
        let myJson = ["chatId": chatId, "userId": userId] as [String: Any]
        guard isPosting == false else { return }

        isPosting = true
        socket.emit("viewerId", myJson){
            self.isPosting = false
        }
    }

    func joinChat(chatId: String? = nil, isJoin: Bool = true) {
        isPosting = false
        let joinedChatId = chatId ?? activeChatId
        if chatId != nil, chatId! != "" {
            if isJoin == true {
                activeChatId = chatId
            }else {
                activeChatId = nil
            }
        }
        guard let chatId = joinedChatId, let userId = USER_MANAGER.userId else { return }
        let myJson = ["chatId": chatId, "userId": userId, "isJoin": isJoin] as [String: Any]
        socket.emit("joinChat", myJson)
    }

    
    //MARK: - Send Message
    func sendMessage(model: MessageModel, isAddUnsent: Bool = true, completion: (() -> ())? = nil) {
        if isAddUnsent == true {
            addUnsentMessage(chatModel: model)
        }
        socket.emit("input", model.toJsonDic()){
            model.createdAt = model.sendingAt
            self.updateUnsendMessages(chatId: model.chatId, messagesSent: [model])
            ANALYTICS_MANAGER.logEvent(.chat_message)
            completion?()
        }
    }
    
    //MARK: - Check if other user is typing
    func isTyping(chatId: String?, isTyping: Bool = false) {
        
        guard let chatId = chatId,
            let userName = USER_MANAGER.fullName,
            let userId = USER_MANAGER.userId
        else { return }
        
        let profileImage = USER_MANAGER.profileUrl
        let typing = TypingUserModel(userName: userName, chatId: chatId, userId: userId, profileImage: profileImage, isTyping: isTyping)

        self.socket.emit("typing", typing.toJSON())

        if isTyping == true {
            dateLastTyping = Date()
            APP_CONFIG.backgrountQ.asyncAfter(deadline: .now() + 5.0) {
                guard let last = self.dateLastTyping, last.compare(Date().addingTimeInterval(-5.0)) == .orderedAscending else { return }
                self.isTyping(chatId: chatId, isTyping: false)
            }
        }
    }
    
    //MARK: - Mute Notifications on Chat
    func muteNotification(chatId: String?, status: Int = 1, complete: (()->())? = nil) {
        guard let chatId = chatId, let userId = USER_MANAGER.userId else { return }
        socket.emit("muteNotification", ["chatId": chatId, "userId": userId, "status": status]){
            NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
            complete?()
        }
    }
    
    //MARK: - Delete Chat
    func updateShowStatus(chatId: String?, isHidden: Bool = true, complete: (()->())? = nil) {
        guard let id = chatId, id != "" else { return }
        socket.emit("updateShowStatus", ["chatId": id, "userId": USER_MANAGER.userId, "isHidden": isHidden] as [String: Any?]){
            NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
            complete?()
        }
    }

    //MARK: - Chat Upload media (video / image)
    func uploadMedia(model : MessageModel, isAddUnsent: Bool = true, complete : ((_ success: Bool, _ errMsg: String? ) -> Void)? = nil) {

        guard let fileType =  model.type else {
            complete?(false, "Invalid parameters")
            return
        }
        APP_CONFIG.backgrountQ.async {
            if isAddUnsent == true {
                self.addUnsentMessage(chatModel: model)
            }
            let dict = ["userId": USER_MANAGER.userId ?? "",
                        "mediaType": fileType.rawValue] as [String : Any]
            
            if fileType == .video, let mediaUrl = model.videoFile {
                complete?(true, nil)
                CHAT_SERVICE.sendMediaVideo(dict, media: model.image, videoUrl : URL(string: mediaUrl), mediaData: model.mediaData)
                .done { (response) -> Void in
                    model.imageUrl = response.imageUrl
                    model.videoFile = response.videoUrl
                    self.sendMessage(model: model, isAddUnsent: false)
                }.catch { (error) in
                    complete?(false, self.handleError(error))
                }

            }else if fileType == .image {
                 complete?(true, nil)
                CHAT_SERVICE.sendMediaImg(dict,media: model.image)
                 .done { (response) -> Void in
                    model.imageUrl = response.imageUrl
                    model.videoFile = response.videoUrl
                    self.sendMessage(model: model, isAddUnsent: false)
                 }.catch { (error) in
                    complete?(false, self.handleError(error))
                 }
            }else {
                complete?(false, "Invalid parameters")
            }

        }
        
    }
    
    func addUnsentMessage(chatModel: MessageModel){
        guard let chatId = chatModel.chatId else { return }

        var unsentMessages = chatMessagesUnsent
        if var messages = unsentMessages[chatId] {

            if messages.contains(where: { (unSent) -> Bool in
                if unSent.chatId == chatModel.chatId,
                    unSent.userId == chatModel.userId,
                    unSent.type == chatModel.type,
                    unSent.sendingAt == chatModel.sendingAt {
                    return true
                }else {
                    return false
                }
            }) == false {
                messages.append(chatModel)
                unsentMessages[chatId] = messages
            }
        }else {
            unsentMessages[chatId] = [chatModel]
        }
        chatMessagesUnsent = unsentMessages
    }
    
    func updateUnsendMessages(chatId: String?, messagesSent: [MessageModel]?){
        guard let chatId = chatId, let messagesSent = messagesSent else { return }

        var totalList = chatMessagesUnsent
        guard var unsentMessages = totalList[chatId], unsentMessages.count > 0 else { return }
        messagesSent.forEach { (sent) in
            if let index = unsentMessages.firstIndex(where: { (unSent) -> Bool in
                if unSent.chatId == sent.chatId,
                    unSent.userId == sent.userId,
                    unSent.type == sent.type,
                    unSent.sendingAt == sent.createdAt {
                    return true
                }else {
                    return false
                }
            }) {
                unsentMessages.remove(at: index)
            }
        }
        totalList[chatId] = unsentMessages
        chatMessagesUnsent = totalList
    }

    
    // Resend unsent messages
    func sendUnsentMessages(){
        let messages = chatMessagesUnsent
        messages.forEach { (key, value) in
            value.forEach { (message) in
                if let type = message.type {
                    switch type {
                    case .text:
                        sendMessage(model: message, isAddUnsent: false)
                    case .image, .video:
                        uploadMedia(model: message, isAddUnsent: false)
                    default:
                        break
                    }
                }
            }
            updateChat(chatId: key)
        }
    }
    
    func appDidEnterBackground() {
        isTyping(chatId: activeChatId, isTyping: false)
        joinChat(chatId: activeChatId, isJoin: false)
    }
    
    func appDidBecomeActive() {
        joinChat(chatId: activeChatId, isJoin: true)
    }
    
    func appWillTerminate() {
        USER_MANAGER.chatMessagesUnsent = chatMessagesUnsent
        isTyping(chatId: activeChatId, isTyping: false)
        joinChat(chatId: activeChatId, isJoin: false)
        closeConnection()
    }
    
    
}



