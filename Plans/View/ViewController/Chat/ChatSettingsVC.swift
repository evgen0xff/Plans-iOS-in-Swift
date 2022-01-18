//
//  ChatSettingsVC.swift
//  Plans
//
//  Created by Star on 3/10/21.
//

import UIKit
import MaterialComponents

class ChatSettingsVC: EventBaseVC {

    // MARK: - IBOutlets
    @IBOutlet weak var tblvSettings: UITableView!
    @IBOutlet weak var viewHeader: UIView!
    @IBOutlet weak var stackHeader: UIStackView!
    @IBOutlet weak var viewGroupName: UIView!
    @IBOutlet weak var txtfGroupName: MDCTextField!
    @IBOutlet weak var switchMuteNotification: UISwitch!
    
    @IBOutlet weak var viewAddPeople: UIView!
    @IBOutlet weak var btnAddPeople: UIButton!
    
    @IBOutlet weak var viewDeleteChat: UIView!
    @IBOutlet weak var btnDeleteChat: UIButton!
    
    @IBOutlet weak var viewLeaveChat: UIView!
    @IBOutlet weak var btnLeaveChat: UIButton!
    
    // MARK: - Properties
    var chatModel: ChatModel?
    var allTextFieldControllers = [MDCTextInputControllerUnderline]()
    var cellHeights = [IndexPath: CGFloat]()
    var listPeople = [UserModel]()

    var userSelected: UserModel? = nil
    var positionSelected: Int? = nil
    var isAnimating = false

    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func setupUI() {
        super.setupUI()
        setupGroupNameUI()
        setupTableView()
        updateData(chat: chatModel)
    }
    
    override func refreshAll(isShowLoader: Bool = false) {
        super.refreshAll(isShowLoader: isShowLoader)
        getChatDetails(isShowLoader: isShowLoader){
            if self.chatModel?.isEventChat == true {
                self.getEventDetails(self.chatModel?.event?._id)
            }
        }
    }

    // MARK: - User Actions
    @IBAction func actionBackbtn(_ sender: Any) {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }
    
    @objc func actionSaveGroupNameBtn(_ sender: UIButton) {
        view.endEditing(true)
        let nameGroup = txtfGroupName.text?.trimmingCharacters(in: .whitespaces)
        chatModel?.nameGroup = nameGroup
        updateGroupNameUI(nameGroup)
        updateGroupChatName(nameGroup)
    }
    
    @IBAction func actionGroupNameChanged(_ sender: MDCTextField) {
        updateGroupNameUI(sender.text)
    }
    
    @IBAction func actionMuteNotificationsChanged(_ sender: UISwitch) {
        muteChatNotification(chatModel?._id, isMute: sender.isOn)
    }
    
    @IBAction func actionAddPeople(_ sender: UIButton) {
        view.endEditing(true)
        if chatModel?.isEventChat == true {
            APP_MANAGER.pushEditInvitationVC(editMode: .edit, selectedUsers: activeEvent?.getInvitedPeople(), sender: self)
        }else {
            APP_MANAGER.pushFriendsSelectionVC(typeSelect: .addPeopleInChat,
                                               delegate: self,
                                               selectedUsers:chatModel?.people,
                                               sender: self)
        }
    }
    
    @IBAction func actionDeleteChat(_ sender: UIButton) {
        view.endEditing(true)
        updateShowStatus(chatModel?._id, isHidden: true){
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    @IBAction func actionLeaveChat(_ sender: UIButton) {
        view.endEditing(true)
        if chatModel?.isEventChat == true {
            let action = sender.title(for: .normal)
            if action == "Cancel Event" {
                cancelEvent(model: activeEvent){
                    success in
                    if success == true {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
            }else if action == "End Event" {
                endEvent(model: activeEvent){
                    success in
                    if success == true {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
            }else if action == "Leave Event" {
                leaveEvent(model: activeEvent){
                    success in
                    if success == true {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
            }
        }else {
            let user = chatModel?.members?.first(where: {$0._id == USER_MANAGER.userId})
            if user?._id == chatModel?.organizer?._id, chatModel?.isEventChat == false, chatModel?.isGroup == true {
                assignAdminAndRemoveUserInChat(chatId: chatModel?._id)
            }else {
                removeUserInChat(chatId: chatModel?._id, user: user ){
                    chatModel in
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
    
    
    // MARK: - Private methods
    private func setupGroupNameUI() {
        txtfGroupName.delegate = self
        txtfGroupName.addTrailingView(titleAction: "Save", colorActionTitle: AppColor.purple_join, taget: self, action: #selector(actionSaveGroupNameBtn(_:)))
        txtfGroupName.trailingViewMode = .never
        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: txtfGroupName))
        
        allTextFieldControllers.forEach { (item) in
            item.textInput?.textColor = AppColor.grey_text
            item.textInputFont = AppFont.regular.size(17.0)
            item.applyTheme(withScheme: AppScheme.purpleTextField)
            item.floatingPlaceholderNormalColor = .black
            item.floatingPlaceholderScale = 0.9
            
        }
        txtfGroupName.text = chatModel?.titleChat
    }
    
    private func setupTableView() {
        tblvSettings.delegate = self
        tblvSettings.dataSource = self
        tblvSettings.register(nib: UserTableCell.className)
    }
    
    private func updateData(chat: ChatModel?){
        guard let chat = chat else { return }
        chatModel = chat
        updateUI()
        
        if userSelected != nil, positionSelected != nil {
            moveSelectedItem()
        }else {
            updateAll()
        }

    }
    
    func moveSelectedItem() {
        if !isAnimating, let toPosition = chatModel?.people?.firstIndex(where: { ($0._id ?? $0.userId) == (userSelected?._id ?? userSelected?.userId)}) {
            if let positionSelected = positionSelected,
               let newItem = chatModel?.people?[toPosition],
               toPosition != positionSelected {
                
                isAnimating = true
                listPeople[positionSelected] = newItem
                tblvSettings.reloadRows(at: [IndexPath(row: positionSelected, section: 0)], with: .none)
                
                APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 0.3) {
                    if self.isAnimating {
                        self.listPeople.remove(at: positionSelected)
                        let newPosition = min(self.listPeople.count, toPosition)
                        self.listPeople.insert(newItem, at: newPosition)
                        
                        self.tblvSettings.beginUpdates()
                        self.tblvSettings.moveRow(at: IndexPath(row: positionSelected, section: 0),
                                                to: IndexPath(row: newPosition, section: 0))
                        self.tblvSettings.endUpdates()
                        
                        self.positionSelected = nil
                        self.userSelected = nil
                        self.isAnimating = false
                    }
                }
            }else {
                updateAll()
            }
        }else {
            updateAll()
        }
    }

    
    func updateAll() {
        userSelected = nil
        positionSelected = nil
        isAnimating = false
        
        listPeople.removeAll()
        if let people = chatModel?.people {
            listPeople.append(contentsOf: people)
        }

        tblvSettings.reloadData()
    }

    
    private func updateUI() {
        // Group Name View
        updateGroupNameUI(txtfGroupName.text)
        
        // Mute Notifications
        switchMuteNotification.isOn = chatModel?.isMuteNotification ?? false

        // Add People
        let optionList = chatModel?.getOptionList()
        if let titleAddPeople = optionList?.first(where: {$0 == "Add People" || $0 == "Invite People"}){
            viewAddPeople.isHidden = false
            btnAddPeople.setTitle(titleAddPeople, for: .normal)
        }else {
            viewAddPeople.isHidden = true
        }
        
        // Leave Chat
        if let titleLeaveChat = optionList?.first(where: {$0 == "Leave Chat" ||
                                                          $0 == "Leave Event" ||
                                                          $0 == "End Event" ||
                                                          $0 == "Cancel Event"}){
            viewLeaveChat.isHidden = false
            btnLeaveChat.setTitle(titleLeaveChat, for: .normal)
        }else {
            viewLeaveChat.isHidden = true
        }
        
        // Header View Height
        viewHeader.bounds.size.height = 286 - (viewGroupName.isHidden == true ? 65.0 : 0) - (viewAddPeople.isHidden == true ? 44.0 : 0) - (viewLeaveChat.isHidden == true ? 44.0 : 0)
        viewHeader.sizeToFit()
        
        stackHeader.arrangedSubviews.forEach({$0.viewWithTag(1)?.isHidden = false})
        stackHeader.arrangedSubviews.last(where: {$0.isHidden == false &&  $0.viewWithTag(1) != nil})?.viewWithTag(1)?.isHidden = true
        
    }
    
    func updateGroupNameUI(_ text: String? = nil) {
        let isEventChat = chatModel?.isEventChat ?? false
        viewGroupName.isHidden = isEventChat == true || chatModel?.isGroup == false
        
        var groupName = chatModel?.titleChat
        if viewGroupName.isHidden == false, viewGroupName.isUserInteractionEnabled == true {
            if let newGroupName = text, newGroupName != chatModel?.titleChat {
                groupName = newGroupName
                txtfGroupName.trailingViewMode = newGroupName.count > 0 ? .always : .never
            }else {
                txtfGroupName.trailingViewMode = .never
            }
        }
        
        txtfGroupName.text = groupName
    }

}

// MARK: - BackEnd APIs
extension ChatSettingsVC {
    func getChatDetails(isShowLoader: Bool = false, complete: (() -> ())? = nil) {
        if isShowLoader {
            self.showLoader()
        }
        CHAT_SERVICE.getChatDetails(chatModel?._id).done{(response) in
            self.hideLoader()
            self.updateData(chat: response)
            complete?()
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
            complete?()
        }
    }
    
    func updateGroupChatName(_ nameGroup: String?, isShowLoader: Bool = true) {
        guard let chatId = chatModel?._id, let nameGroup = nameGroup else { return }
        if isShowLoader {
            self.showLoader()
        }
        CHAT_SERVICE.updateGroupChatName(nameGroup, chatId: chatId).done{(response) in
            self.hideLoader()
            self.updateData(chat: response)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }

}

// MARK: - UITextFieldDelegate
extension ChatSettingsVC : UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.textColor = .black
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.textColor = AppColor.grey_text
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}


// MARK: - UITableViewDataSource

extension ChatSettingsVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listPeople.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return getUserCell(indexPath, tableView: tableView)
    }
    
    func getUserCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UserTableCell.className, for: indexPath) as? UserTableCell else {
            fatalError("Unexpected index path")
        }
        cell.setupUI(model: listPeople[indexPath.row],
                     delegate: self,
                     cellType: .chatSettings,
                     chatModel: chatModel,
                     isHiddenSeparator: indexPath.row == (listPeople.count - 1))
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ChatSettingsVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 61
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        APP_MANAGER.pushUserProfileVC(userId: listPeople[indexPath.row]._id, sender: self)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? UITableView.automaticDimension
    }

}

// MARK: - UserTableCellDelegate
extension ChatSettingsVC : UserTableCellDelegate {
    func tappedFriend(user: UserModel?, cell: UITableViewCell?) {
        var mobile = ""
        if let number = user?.mobileNumber { mobile = number }
        if let number = user?.mobile { mobile = number }

        if let friendId = user?._id, let friendShipStatus = user?.friendShipStatus {
            if friendShipStatus == 0 {
                if user?.friendRequestSender == USER_MANAGER.userId {
                    cancelFriendRequestMethod(friendId)
                }else {
                    acceptRequestMethod(user: user)
                }
            }else if friendShipStatus == 1 {
                unFriendMethod(user)
            }else if friendShipStatus == 5 {
                unblockUser(user)
            }else {
                sendFriendRequest(mobile)
            }
        }else if let invitedTime = user?.invitedTime {
            let limitDate = Date().addingTimeInterval(-3600*24*2)
            if Date(timeIntervalSince1970: invitedTime) < limitDate {
                sendInviteSMS(mobile)
            }
        }else {
            sendInviteSMS(mobile)
        }
    }
    
    func tappedMoreMenu(user: UserModel?, cell: UITableViewCell?) {
        let list = chatModel?.isEventChat == true ? ["Remove Guest"] : ["Remove User"]
        
        OPTIONS_MANAGER.showMenu(list: list, data: user, delegate: self, sender: self)
    }
    
    func onItemMoveSelected(data: Any?, cell: UITableViewCell?) {
        userSelected = data as? UserModel
        positionSelected = listPeople.firstIndex(where: { ($0._id ?? $0.userId) == (userSelected?._id ?? userSelected?.userId)})
    }


}

// MARK: - OptionsMenuManagerDelegate
extension ChatSettingsVC : OptionsMenuManagerDelegate {
    func didSelectedMenuItem(titleItem: String?, data: Any?) {
        switch titleItem {
        case "Remove Guest":
            removeGuestFromEvent(user: data as? UserModel)
        case "Remove User":
            removeUserInChat(chatId: chatModel?._id, user: data as? UserModel){
                chatModel in
                self.txtfGroupName.text = chatModel?.titleChat
            }
            break
        default:
            break
        }
    }
}

extension ChatSettingsVC: FriendsSelectionVCDelegate {
    func didSelectFriends(list: [UserModel]?, sender: FriendsSelectionVC?) {
        sender?.showLoader()
        updateChat(chatId: chatModel?._id, members: list){
            chatModel in
            sender?.hideLoader()
            self.txtfGroupName.text = chatModel?.titleChat
            sender?.navigationController?.popViewController(animated: true)
        }
    }
}
