//
//  ChatMessageVC.swift
//  Plans
//
//  Created by Star on 2/3/21.
//

import UIKit
import GrowingTextView
import ObjectMapper


class ChatMessageVC: EventBaseVC {

    // MARK: - IBOutlets
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblNumberOfPeople: UILabel!
    @IBOutlet weak var viewDate: UIView!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var tblvMessages: UITableView!
    @IBOutlet weak var btnScrollDown: UIButton!
    
    @IBOutlet weak var viewMessageUI: UIView!
    @IBOutlet weak var viewAccessStatus: UIView!
    @IBOutlet weak var lblAccessStatus: UILabel!
    @IBOutlet weak var txtvMessage: GrowingTextView!
    @IBOutlet weak var imgvUserProfile: UIImageView!
    @IBOutlet weak var imgvSend: UIImageView!
    @IBOutlet weak var btnSend: UIButton!
    
    @IBOutlet weak var bottomMarginContent: NSLayoutConstraint!

    
    
    // MARK: - Properties
    var userId = USER_MANAGER.userId
    var chatModel: ChatModel?
    var typingData = TypingModel()
    var listMessages = [MessageModel]()
    var listItems = [MessageModel]()
    var listBlockedUsers = [UserModel]()
    var isScrollToBottom = false
    var isRefreshAll = false

    var uploadVideoUrl: URL?
    var previewImage: UIImage!
    var cellHeights = [IndexPath: CGFloat]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        isScrollToBottom = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NOTIFICATION_CENTER.addObserver(self, selector: #selector(updateMessages), name:NSNotification.Name(rawValue: kMessageUpdated),  object: nil)

        NOTIFICATION_CENTER.addObserver(self, selector: #selector(updateSomeoneIsTyping), name:NSNotification.Name(rawValue: kSomeoneIsTyping),  object: nil)
        
        tblvMessages.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        SOCKET_MANAGER.joinChat(chatId: chatModel?._id, isJoin: false)
        SOCKET_MANAGER.closeOutputList()

        NOTIFICATION_CENTER.removeObserver(self)
        
        isScrollToBottom = false
    }
    
    override func initializeData() {
        super.initializeData()
        
        SOCKET_MANAGER.updateShowStatus(chatId: chatModel?._id, isHidden: false)
    }
    
    override func setupUI() {
        super.setupUI()
        
        // Title
        lblTitle.text = chatModel?.titleChat
        lblNumberOfPeople.isHidden = true
        
        // Date View
        viewDate.addShadow()
        updateDateView(isHidden: true)

        // Scroll Down Button
        btnScrollDown.isHidden = true
        
        // Messageing UI
        imgvUserProfile.setUserImage(USER_MANAGER.profileUrl)
        txtvMessage.delegate = self
        viewAccessStatus.isHidden = true
        viewMessageUI.addShadow(shadowOffset: CGSize(width: 0, height: -3.0))
        updateMessagingUI()

        // Message Table View
        setupTableView()
        
    }
    
    override func refreshAll(isShowLoader: Bool = false) {
        super.refreshAll(isShowLoader: isShowLoader)
        isRefreshAll = true

        if isShowLoader == true {
            showLoader()
        }
        getBlockedUsers{
            self.getEventDetails(self.activeEvent?._id){ _,_  in
                self.hideLoader()
                self.updateAccessUI()
                self.getMessages()
            }
        }
    }
    
    override func willShowKeyboard(frame: CGRect) {
        bottomMarginContent.constant = frame.height - UIDevice.current.heightBottomNotch
        view.updateConstraintsIfNeeded()
        APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 0.3) {
            self.tblvMessages.scrollToBottom(animation: true)
        }
    }
    
    override func willHideKeyboard() {
        bottomMarginContent.constant = 0
        view.updateConstraintsIfNeeded()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let obj = object as? UITableView, obj == tblvMessages,
           keyPath == "contentSize" {
            var top = tblvMessages.bounds.height - tblvMessages.contentSize.height - 10
            top = top < 0 ? 0 : top
            if refreshHeader.status == .idle {
                tblvMessages.contentInset = UIEdgeInsets(top: top, left: 0.0, bottom: 10, right: 0.0)
            }
        }
    }


    // MARK: - User Actions
    @IBAction func actionBackBtn(_ sender: Any) {
        view.endEditing(true)

        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionInfoBtn(_ sender: Any) {
        view.endEditing(true)
        APP_MANAGER.pushChatSettings(chat: chatModel, sender: self)
    }
    
    @IBAction func actionScrollDown(_ sender: Any) {
        tblvMessages.scrollToBottom(animation: true)
    }
    
    @IBAction func actionAttach(_ sender: Any) {
        view.endEditing(true)
        MEDIA_PICKER.showCameraGalleryActionSheet(sender: self,
                                                  delegate: self,
                                                  action: .postMedia)
    }
    
    @IBAction func actionSend(_ sender: Any) {
        let text = txtvMessage.text
        txtvMessage.text = ""
        sendMessage(text)
        SOCKET_MANAGER.isTyping(chatId: chatModel?._id, isTyping: false)
    }
    
    // MARK: - Private Methods
    private func setupTableView() {
        tblvMessages.registerMultiple(nibs: [MyMessageTextCell.className,
                                             MyMessageMediaCell.className,
                                             OthersMessageTextCell.className,
                                             OthersMessageMediaCell.className,
                                             DateMessageCell.className,
                                             SomeoneTypingCell.className])

        tblvMessages.delegate = self
        tblvMessages.dataSource = self
        if #available(iOS 15.0, *) {
            tblvMessages.sectionHeaderTopPadding = 0.0
        }
    }
    
    private func updateAccessUI () {
        if let event = activeEvent, event.isChatEnd == true, event.userId != USER_MANAGER.userId {
            view.endEditing(true)
            viewAccessStatus.isHidden = false
            
            if event.isActive == false {
                lblAccessStatus.text = "This event is cancelled."
            }else if event.isCancel == true {
                lblAccessStatus.text = "This event is cancelled."
            }else if event.isEnded == true {
                lblAccessStatus.text = "This event has ended."
            }else if event.isExpired == true {
                lblAccessStatus.text = "This event has expired."
            }else {
                lblAccessStatus.text = "This event isn't available for you."
            }
        }else {
            viewAccessStatus.isHidden = true
            lblAccessStatus.text = ""
        }
    }

    
    private func updateUI() {
        updateTitleUI()
        tblvMessages.reloadData()
        updateMessagingUI()
        
        if isScrollToBottom {
            APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 0.3) {
                self.tblvMessages.scrollToBottom(animation: true)
                self.isScrollToBottom = false
            }
        }
    }
    
    private func updateTitleUI() {
        lblTitle.text = chatModel?.titleChat
        
        lblNumberOfPeople.isHidden = !(chatModel?.isGroup ?? false)
        let count = chatModel?.people?.count ?? 0
        lblNumberOfPeople.text = "\(count) \(count > 1 ? "people" : "person")"
    }
    
    private func updateMessagingUI() {
        let text = txtvMessage.text?.trimmingCharacters(in: .whitespaces)
        if text != nil, text != "" {
            imgvSend.isHighlighted = true
            btnSend.isEnabled = true
        }else {
            imgvSend.isHighlighted = false
            btnSend.isEnabled = false
        }
    }

    private func updateDateView(isHidden: Bool? = nil, numDate: Double? = nil, text: String? = nil) {
        if let isHidden = isHidden {
            viewDate.isHidden = isHidden
        }
        
        if let text = text {
            lblDate.text = text
        }
        
        if let numDate = numDate {
            let date =  Date(timeIntervalSince1970: numDate).stringDate()
            lblDate.text = date
        }
    }
    
    @objc func updateMessages(_ notification: Notification) {
        hideLoader()
        guard let data = notification.object as? ChatModel else { return }

        chatModel = data
        updateTitleUI()
        updateAccessUI()
        updateData(list: chatModel?.allMessages)
    }
    
    // Check If Someone is Typing
    @objc func updateSomeoneIsTyping(_ notification: Notification) {
        guard let typingModel = notification.object as? TypingUserModel else { return }

        if typingData.updateTyping(typingNew: typingModel, listBlockedUsers: listBlockedUsers) == true {
            isScrollToBottom = true
            updateUI()
        }
    }
    
    private func updateData(list: [MessageModel]?) {
        guard let list = list else {
            isRefreshAll = false
            return
        }

        SOCKET_MANAGER.updateUnsendMessages(chatId: chatModel?._id, messagesSent: list)
        let newMsgs = list.filter({ newMsg in !listBlockedUsers.contains(where: { $0._id == newMsg.userId}) })
 
        if isRefreshAll == true {
            listMessages.removeAll()
            isRefreshAll = false
        }
        
        // Update Messages Data
        newMsgs.forEach { (newMsg) in
            if listMessages.contains(where: {$0._id == newMsg._id}) == false {
                listMessages.append(newMsg)
            }
        }

        // ****** Update Items List
        // 1. Add Date separator item
        var textDate = ""
        listItems.removeAll()
        listMessages.forEach { (msg) in
            if let ceatedAt = msg.createdAt {
                let strDate = Date(timeIntervalSince1970: ceatedAt).stringDate()
                if strDate != textDate {
                    textDate = strDate
                    let msgDate = MessageModel()
                    msgDate.type = .date
                    msgDate.createdAt = ceatedAt
                    msgDate.message = textDate
                    listItems.append(msgDate)
                }
            }
            listItems.append(msg)
        }
        
        // 2. Add Unsent Messages
        if let chatId = chatModel?._id,
           let unSent =  SOCKET_MANAGER.chatMessagesUnsent[chatId], unSent.count > 0 {
            listItems.append(contentsOf: unSent)
        }
        
        // 3. Update Message View Model for each item.
        listItems.enumerated().forEach { (index, item) in
            let viewModel = MessageViewModel()
            // Owner Type
            if item.userId == USER_MANAGER.userId {
                viewModel.ownerType = .mine
            }else if item.type == .date {
                viewModel.ownerType = .date
            }else {
                viewModel.ownerType = .other
            }
            
            // Position Type
            let preIndex = index - 1
            var isExistPreItem = false
            var isExistNextItem = false
            if preIndex >= 0,
               preIndex < listItems.count,
               listItems[preIndex].type != .date,
               listItems[preIndex].userId == item.userId {
                isExistPreItem = true
            }

            let nextIndex = index + 1
            if nextIndex >= 0,
               nextIndex < listItems.count,
               listItems[nextIndex].type != .date,
               listItems[nextIndex].userId == item.userId {
                isExistNextItem = true
            }
            
            if isExistPreItem == true, isExistNextItem == true {
                viewModel.positionType = .medium
            }else if isExistPreItem == true {
                viewModel.positionType = .end
            }else if isExistNextItem == true {
                viewModel.positionType = .start
            }else {
                viewModel.positionType = .normal
            }

            item.viewModel = viewModel
        }

        SOCKET_MANAGER.readAllMessage(chatId: chatModel?._id, userId: USER_MANAGER.userId)
        
        updateUI()
    }

}

// MARK: - Backend APIs
extension ChatMessageVC {
    
    func getMessages() {
        SOCKET_MANAGER.updateChat(chat: self.chatModel)
        SOCKET_MANAGER.joinChat(chatId: self.chatModel?._id)
    }
    
    func sendMessage(_ message: String?) {
        guard let msg = message, let model = prepareMessage(msg) else { return }

        SOCKET_MANAGER.sendMessage(model: model)
        isScrollToBottom = true
        updateData(list: [MessageModel](listMessages))
    }
    
    func getBlockedUsers(complete: (() -> Void)? = nil) {
        let dict = ["pageNo": 1,
                    "count": 1000,
                    "isByMe": false] as [String : Any]

        FRIENDS_SERVICE.listBlockRequestApi(dict).done { (response) -> Void in
            self.listBlockedUsers.removeAll()
            self.listBlockedUsers.append(contentsOf: response)
            complete?()
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
            complete?()
        }
    }

    func uploadMedia(_ image: UIImage?, mediaType: MessageModel.MessageType = .image) {
        
        guard let model = prepareMessage(image: image, mediaType: mediaType) else { return }
        
        SOCKET_MANAGER.uploadMedia(model: model) { (success, errMsg) in
            APP_CONFIG.defautMainQ.async {
                self.isScrollToBottom = true
                self.updateData(list: [MessageModel](self.listMessages))
                if success == false, let msg = errMsg {
                    POPUP_MANAGER.makeToast(msg){ didTap in
                        if msg == ConstantTexts.loginAgain.localizedString  {
                            APP_MANAGER.gotoLandingVC()
                        }
                    }
                }
            }
        }
    }
    
    func prepareMessage(_ message: String? = nil, image: UIImage? = nil, mediaType: MessageModel.MessageType = .text) -> MessageModel? {

        let model = MessageModel()
        model.message = message
        model.image = image
        model.chatId = chatModel?._id
        model.userId = self.userId
        model.type = mediaType
        model.sendingAt = floor(Date().timeIntervalSince1970)

        switch mediaType {
        case .text:
            guard message != nil else{ return nil }
        case .image:
            guard image != nil else{ return nil }
        case .video:
            guard let videoUrl = uploadVideoUrl?.absoluteString,
                  let url = URL(string: videoUrl),
                  FileManager.default.fileExists(atPath:url.path) else{ return nil }
            model.videoFile = videoUrl
            do {
                model.mediaData = try Data(contentsOf: url)
            } catch {
                return nil
            }
        default : return nil
        }
        
        return model
    }

}

// MARK: - UITextViewDelegate
extension ChatMessageVC : UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView == txtvMessage {
            SOCKET_MANAGER.isTyping(chatId: chatModel?._id, isTyping: true)
        }
        updateMessagingUI()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == txtvMessage {
            SOCKET_MANAGER.isTyping(chatId: chatModel?._id, isTyping: false)
        }
    }
    

}

// MARK: - UITableViewDataSource
extension ChatMessageVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return listItems.count
        case 1 : return typingData.isTyping == true ? 1 : 0
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        switch indexPath.section {
        case 0:
            cell = getMessageCell(tableView, cellForRowAt: indexPath)
        case 1:
            cell = getTypingCell(tableView, cellForRowAt: indexPath)
        default:
            break
        }
        return cell ?? UITableViewCell()
    }
    
    func getMessageCell (_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell? {
        
        var cell: UITableViewCell?
        let message = listItems[indexPath.row]
        var cellId: String?
        
        switch message.viewModel?.ownerType {
        case .mine:
            cellId = message.type == .text ? MyMessageTextCell.className : MyMessageMediaCell.className
        case .other:
            cellId = message.type == .text ? OthersMessageTextCell.className : OthersMessageMediaCell.className
        case .date:
            cellId = DateMessageCell.className
        default :
            break
        }
        
        if let cellId = cellId,
           let cellMsg = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? MessageBaseCell {
            cellMsg.setupUI(message: message, chat: chatModel)
            cell = cellMsg
        }
        
        return cell
    }
    
    func getTypingCell (_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell? {
        let cell = tableView.dequeueReusableCell(withIdentifier: SomeoneTypingCell.className, for: indexPath) as? SomeoneTypingCell
        cell?.lblMessage.text = typingData.textTyping
        return cell
    }

}

// MARK: - UITableViewDelegate
extension ChatMessageVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
        if indexPath.row == (listItems.count - 1), indexPath.section == 0 {
            btnScrollDown.isHidden = true
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == (listItems.count - 1), indexPath.section == 0 {
            btnScrollDown.isHidden = false
        }

    }
 
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? UITableView.automaticDimension
    }
}

//MARK: -  UIScrollViewDelegate
extension ChatMessageVC: UIScrollViewDelegate {
    // Hide Section wise date view and arrow button
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateDateView(isHidden: true)
    }
    
    // Show date for section wise grouped messages
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        updateDateView(isHidden: false)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let visibleItems = tblvMessages.indexPathsForVisibleRows?.filter({$0.section == 0}).sorted(by: {$0.row < $1.row})
        if let index = visibleItems?.first?.row,
           let createdAt = listItems[index].createdAt {
            updateDateView(numDate: createdAt)
        }
    }
    
}

// MARK: - MediaPickerDelegate
extension ChatMessageVC : MediaPickerDelegate {
    
    func mediaPicker(_ mediaPicker: MediaPicker?, didTakenImage image: UIImage?) {
        guard let image = image else { return }
        previewImage = image
        uploadMedia(self.previewImage)
    }
    
    func mediaPicker(_ mediaPicker: MediaPicker?, didTakenVideo outputFileURL: URL?, previewImage: UIImage?) {
        guard let image = previewImage, let url = outputFileURL else { return }
        self.uploadVideoUrl = url
        self.previewImage = image
        uploadMedia(self.previewImage, mediaType: .video)
    }
}



