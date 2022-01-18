//
//  AssignAdminForGroupChatVC.swift
//  Plans
//
//  Created by Top Star on 10/29/21.
//

import UIKit

class AssignAdminForGroupChatVC: UserBaseVC {
    
    // MARK: - IBOutlets
    // Search Bar
    @IBOutlet weak var txtSearch: UITextField!

    // Table View
    @IBOutlet weak var tblFriends: UITableView!

    // Done View
    @IBOutlet weak var viewDone: UIView!
    @IBOutlet weak var btnDone: UIButton!

    // No Friends View
    @IBOutlet weak var viewNoFriends: UIView!
    
    // Search Result View
    @IBOutlet weak var viewSearchResult: UIView!


    // MARK: - Properties
    var chatId: String? = nil
    var chatDetails: ChatModel? = nil
    var listMembers = [UserModel]()
    var userSelected: UserModel? = nil
    
    var cellHeights = [IndexPath: CGFloat]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeData() {
        super.initializeData()
        userID = USER_MANAGER.userId
    }
    
    override func hideLoader() {
        super.hideLoader()
        tblFriends.switchRefreshFooter(to: .normal)
    }

    
    override func setupUI() {
        super.setupUI()

        // Search TextField
        txtSearch.attributedPlaceholder = NSAttributedString(string: "Search",
                                                               attributes: [NSAttributedString.Key.foregroundColor: AppColor.whiteOpacity60])
        txtSearch.delegate = self
        txtSearch.addTarget(self, action: #selector(refreshAll), for: .editingChanged)


        // Table View
        setupTableView()
        
        // Done view
        btnDone.addShadow(shadowOffset: CGSize.zero)
    }
    
    override func refreshAll(isShowLoader: Bool = false) {
        super.refreshAll(isShowLoader: isShowLoader)
        getChatDetails(isShowLoader: isShowLoader)
    }
    
    // MARK: - User Actions
    @IBAction func actionBackBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func actionDone(_ sender: Any) {
        guard let chatId = chatId, let adminId = userSelected?._id ?? userSelected?.userId else { return }
        
        showLoader()
        CHAT_SERVICE.assignAdminForGroupChat(chatId: chatId, adminId: adminId).done { chat in
            if chat != nil {
                CHAT_SERVICE.removeUserInChat(USER_MANAGER.userId, chatId: chatId).done { chat in
                    self.hideLoader()
                    if chat != nil {
                        if let vcChatList = self.navigationController?.viewControllers.last(where: { $0.isKind(of: ChatListVC.self)})  {
                            self.navigationController?.popToViewController(vcChatList, animated: true)
                        }
                    }
                }.catch { (error) in
                    self.hideLoader()
                    POPUP_MANAGER.handleError(error)
                }
            }else {
                self.hideLoader()
            }
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
        
    }
    
    // MARK: - Private Methods

    private func setupTableView() {
        tblFriends.registerMultiple(nibs: [UserSelectionCell.className])
        tblFriends.delegate = self
        tblFriends.dataSource = self
        
        tblFriends.configRefreshFooter(with: refreshFooter, container:self) { [weak self] in
            if let this = self, this.listMembers.count % 20 == 0, this.listMembers.count > 0 {
                this.getNextPage()
            }else {
                APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 1) {
                    self?.hideLoader()
                }
            }
        }
        
        tblFriends.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 90, right: 0)
    }
    
    func updateData(chat: ChatModel?) {
        chatDetails = chat
        
        listMembers.removeAll()
        
        guard let list = chatDetails?.members?.filter({ ($0._id ?? $0.userId) != USER_MANAGER.userId}) else {
            updateUI()
            return
        }
        
        let search = txtSearch.text?.trimmingCharacters(in: .whitespaces).lowercased() ?? ""
        
        if search.isEmpty == true {
            listMembers.append(contentsOf: list)
        }else {
            listMembers = list.filter({ ($0.fullName ?? $0.name ?? "\($0.firstName ?? "") \($0.lastName ?? "")").lowercased().contains(search) })
        }
        
        updateUI()
    }
    
    func getNextPage(isShowLoader: Bool = false) {
        getChatDetails(isShowLoader: false)
    }

    func updateUI () {
        viewDone.isHidden = userSelected == nil
        tblFriends.reloadData()
        updateUIForNoData()
    }
    
    func updateUIForNoData() {
        viewSearchResult.isHidden = true
        viewNoFriends.isHidden = true

        if listMembers.count == 0 {
            if let search = txtSearch.text, search != "" {
                viewSearchResult.isHidden = false
            }else {
                viewNoFriends.isHidden = false
            }
        }
    }
    
}


// MARK: - Backend Api Methods

extension AssignAdminForGroupChatVC {
    
    // Get user's friends list
    func getChatDetails(isShowLoader: Bool = true) {
        if isShowLoader == true {
            showLoader()
        }

        CHAT_SERVICE.getChatDetails(chatId).done{(response) in
            self.hideLoader()
            self.updateData(chat: response)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
}

// MARK: - UITableViewDataSource
extension AssignAdminForGroupChatVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listMembers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return getUserCell(indexPath, tableView: tableView)
    }
    
    private func getUserCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UserSelectionCell.className, for: indexPath) as? UserSelectionCell
            else { return UITableViewCell() }
        let userModel = listMembers[indexPath.row]
        let isSelected = (userSelected?._id ?? userSelected?.userId) == (userModel._id ?? userModel.userId)
        cell.setupUI(user: userModel, isSelected: isSelected, actionUserSelected: actionSelectedUser(_:))
        return cell
    }
    
    func actionSelectedUser(_ user: UserModel?) {
        if (userSelected?._id ?? userSelected?.userId) == (user?._id ?? user?.userId) {
            userSelected = nil
        }else {
            userSelected = user
        }
        updateUI()
    }
    
}

// MARK: - UITableViewDelegate

extension AssignAdminForGroupChatVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        APP_MANAGER.pushUserProfileVC(userModel: listMembers[indexPath.row], sender: self)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? UITableView.automaticDimension
    }

}


// MARK: - UITextFieldDelegate

extension AssignAdminForGroupChatVC : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == txtSearch {
            self.refreshAll(isShowLoader: true)
        }
        return true
    }
}

