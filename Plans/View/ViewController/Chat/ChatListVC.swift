//
//  ChatListVC.swift
//  Plans
//
//  Created by Star on 2/24/21.
//

import UIKit
import PromiseKit
import ObjectMapper
import SocketIO

class ChatListVC: PlansContentBaseVC {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var txtSearch: UITextField!
    @IBOutlet weak var tblChatList: UITableView!
    @IBOutlet weak var viewEmpty: UIView!
    
    // MARK: - Properties

    var arrChatList = [ChatModel]()
    var listSearched = [ChatModel]()
    var selectedChat: ChatModel?
    
    override var screenName: String? { "Chats_Screen" }

    
    // MARK: - ViewController Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NOTIFICATION_CENTER.addObserver(self, selector: #selector(getChatList(_:)), name: NSNotification.Name(rawValue: kChatListChanged), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NOTIFICATION_CENTER.removeObserver(self)
    }
    
    override func setupUI() {
        super.setupUI()
        
        // Search TextField
        txtSearch.attributedPlaceholder = NSAttributedString(string: "Search",
                                                               attributes: [NSAttributedString.Key.foregroundColor: AppColor.whiteOpacity60])
        txtSearch.delegate = self
        txtSearch.addTarget(self, action: #selector(searchChats), for: .editingChanged)


        tblChatList.delegate = self
        tblChatList.dataSource = self
        tblChatList.registerMultiple(nibs: [ChatListCell.className])

        tblChatList.configRefreshHeader(with: refreshHeader, container:self) { [weak self] in
            SOCKET_MANAGER.getChatList()
            APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 0.5) {
                self?.hideLoader()
            }
        }
        
        tblChatList.configRefreshFooter(with: refreshFooter, container:self) { [weak self] in
            SOCKET_MANAGER.getChatList()
            APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 0.5) {
                self?.hideLoader()
            }
        }
        
        viewEmpty.isHidden = true
    }
    
    override func hideLoader() {
        super.hideLoader()
        tblChatList.switchRefreshHeader(to: .normal(.success, 0.0))
        tblChatList.switchRefreshFooter(to: .normal)
    }
    
    override func refreshAll(isShowLoader: Bool = false) {
        super.refreshAll(isShowLoader: isShowLoader)
        CHAT_SERVICE.getChatList(USER_MANAGER.userId).done { (list) in
            self.reloadChatList(list: list)
        }.catch { error in
        }
    }

    // MARK: - IBAction Methods
    @IBAction func actionBackBtn(_ sender: Any) {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionNewChat(_ sender: Any) {
        view.endEditing(true)
        selectedChat = nil
        APP_MANAGER.pushFriendsSelectionVC(typeSelect: .startChat,
                                           delegate: self,
                                           sender: self)
    }
    
    
    // MARK: - Public Methods

    func pushNotification(_ notification: NotificationActivityModel?) {
        guard let notify = notification, let chatId = notify.chatId else { return }
        APP_MANAGER.pushChatMessageVC(chatId: chatId, sender: self)
    }
    
    
    // MARK: - Private Methods
    @objc func getChatList(_ notification: Notification)
    {
        guard let chatList = notification.object as? [ChatModel] else { return }
        
        reloadChatList(list: chatList)
    }
    
    func reloadChatList(list: [ChatModel]?){
        guard let chatList = list else { return }
        
        arrChatList.removeAll()
        if chatList.count > 0 {
            arrChatList.append(contentsOf: chatList)
        }
        
        searchChats()
    }
    
    @objc func searchChats() {
        listSearched.removeAll()
        if let keyword = txtSearch?.text?.trimmingCharacters(in: .whitespaces).lowercased(), !keyword.isEmpty {
            listSearched = arrChatList.filter { $0.titleChat?.lowercased().contains(keyword) == true}
        }else {
            listSearched.append(contentsOf: arrChatList)
        }
        
        tblChatList.reloadData()
        viewEmpty.isHidden = arrChatList.count > 0
    }
    
    private func updateGuideViews() {
        if listSearched.count > 0 {
            tblChatList.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        }
    }
    
}

// MARK: - UITableViewDataSource

extension ChatListVC: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listSearched.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatListCell.className, for: indexPath) as? ChatListCell
        
        cell?.configure(model: listSearched[indexPath.row],
                        delegate: self,
                        isHiddenSeparator: indexPath.row == (listSearched.count - 1),
                        isFirst: indexPath.row == 0 )
        
        return cell ?? UITableViewCell()
    }
}

// MARK: - UITableViewDelegate

extension ChatListVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = listSearched[indexPath.row]
        APP_MANAGER.pushChatMessageVC(chatModel: model, sender: self)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - ChatListCellDelegate
extension ChatListVC: ChatListCellDelegate {
    func didLongPressed(chatModel: ChatModel?) {
        updateGuideViews()
        selectedChat = chatModel
        OPTIONS_MANAGER.showMenu(data: chatModel,
                                 menuType: .chat,
                                 delegate: self,
                                 sender: self)
    }
}

// MARK: - OptionsMenuManagerDelegate
extension ChatListVC : OptionsMenuManagerDelegate {
    func didSelectedMenuItem(titleItem: String?, data: Any?) {
        if processChatMenu(titleAction: titleItem, chat: data as? ChatModel) == true {
        }
    }
}

// MARK: - FriendsSelectionVCDelegate
extension ChatListVC: FriendsSelectionVCDelegate {
    func didSelectFriends(list: [UserModel]?, sender: FriendsSelectionVC?) {
        sender?.showLoader()
        
        if let chatId = selectedChat?._id, !chatId.isEmpty {
            updateChat(chatId: chatId, members: list){ chatModel in
                sender?.hideLoader()
                sender?.navigationController?.popViewController(animated: true)
            }
        }else {
            createChat(members: list){ groupModel in
                sender?.hideLoader()
                guard let group = groupModel else { return }
                
                sender?.navigationController?.viewControllers.removeLast()
                APP_MANAGER.pushChatMessageVC(chatModel: group)
            }
        }
    }

}

// MARK: - UITextFieldDelegate

extension ChatListVC : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        if textField == txtSearch {
            self.refreshAll(isShowLoader: true)
        }
        return true
    }
}








