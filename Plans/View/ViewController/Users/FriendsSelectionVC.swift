//
//  FriendsSelectionVC.swift
//  Plans
//
//  Created by Star on 3/5/21.
//

import UIKit

protocol FriendsSelectionVCDelegate {
    func didSelectFriends(list: [UserModel]?, sender: FriendsSelectionVC?)
}

extension FriendsSelectionVCDelegate {
    func didSelectFriends(list: [UserModel]?, sender: FriendsSelectionVC?) {}
}

class FriendsSelectionVC: UserBaseVC {
    
    enum SelectType {
        case startChat
        case addPeopleInChat
    }
    
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
    var listFriends = [UserModel]()
    var listAvailables = [UserModel]()
    var listSelectedAlready = [UserModel]()
    var listSelected = [UserModel]()

    
    var typeSelect : SelectType = .startChat
    var delegate: FriendsSelectionVCDelegate?
    var pageNumber = 1
    var numberOfRowsOnPage = 20
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
        
        switch typeSelect {
        case .startChat:
            btnDone.setTitle("Start Chat", for: .normal)
        case .addPeopleInChat:
            btnDone.setTitle("Add", for: .normal)
        }
        
    }
    
    override func refreshAll(isShowLoader: Bool = false) {
        super.refreshAll(isShowLoader: isShowLoader)
        friendListApiMethod(isShowLoader: isShowLoader, pageNumber: 1, numberOfRows: pageNumber * numberOfRowsOnPage)
    }
    
    // MARK: - User Actions
    @IBAction func actionBackBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func actionDone(_ sender: Any) {
        var list = [UserModel]()
        list.append(contentsOf: listSelectedAlready)
        list.append(contentsOf: listSelected)
        delegate?.didSelectFriends(list: list, sender: self)
    }
    
    // MARK: - Private Methods

    private func setupTableView() {
        tblFriends.registerMultiple(nibs: [UserSelectionCell.className])
        tblFriends.delegate = self
        tblFriends.dataSource = self
        
        tblFriends.configRefreshFooter(with: refreshFooter, container:self) { [weak self] in
            if let this = self, this.listFriends.count % this.numberOfRowsOnPage == 0, this.listFriends.count > 0 {
                this.getNextPage()
            }else {
                APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 1) {
                    self?.hideLoader()
                }
            }
        }
        
        tblFriends.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 90, right: 0)
    }
    
    func updateData(list: [UserModel]?, pageNumber: Int = 1, numberOfRowsInPage: Int = 20) {
        if pageNumber == 1 {
            listFriends.removeAll()
        }
        
        listFriends.replace(arrPage: list, pageNumber: pageNumber, numberOfRowsInPage: numberOfRowsInPage)

        listAvailables = listFriends.filter({ (friend) -> Bool in
            return !listSelectedAlready.contains(where: {($0._id ?? $0.userId ?? $0.friendId) == (friend._id ?? friend.userId ?? friend.friendId)})
        })

        listSelected = listAvailables.filter { (item) -> Bool in
            return listSelected.contains(where: {($0._id ?? $0.userId ?? $0.friendId) == (item._id ?? item.userId ?? item.friendId)})
        }
        
        updateUI()
    }
    
    func getNextPage(isShowLoader: Bool = false) {
        pageNumber = listFriends.count / numberOfRowsOnPage + ((listFriends.count % numberOfRowsOnPage) > 0 ? 1 : 0) + 1
        friendListApiMethod(isShowLoader: false, pageNumber: pageNumber)
    }

    func updateUI () {
        viewDone.isHidden = listSelected.count == 0
        tblFriends.reloadData()
        updateUIForNoData()
    }
    
    func updateUIForNoData() {
        viewSearchResult.isHidden = true
        viewNoFriends.isHidden = true

        if listFriends.count == 0 {
            if let search = txtSearch.text, search != "" {
                viewSearchResult.isHidden = false
            }else {
                viewNoFriends.isHidden = false
            }
        }else if listAvailables.count == 0 {
            viewSearchResult.isHidden = false
        }
    }
    
}


// MARK: - Backend Api Methods

extension FriendsSelectionVC {
    
    // Get user's friends list
    func friendListApiMethod(isShowLoader: Bool = true, pageNumber: Int = 1, numberOfRows: Int = 20) {
        guard let userID = userID else { return }
        let dict = ["pageNo": pageNumber,
                    "count": numberOfRows,
                    "userId": userID,
                    "keyword": self.txtSearch.text ?? "" ] as [String: Any]
        
        if isShowLoader == true {
            showLoader()
        }
        FRIENDS_SERVICE.hitFriendListApi(dict).done { (response) -> Void in
            self.hideLoader()
            self.updateData(list: response, pageNumber: pageNumber, numberOfRowsInPage: numberOfRows)
            }.catch { (error) in
                self.hideLoader()
                POPUP_MANAGER.handleError(error)
        }
    }
}

// MARK: - UITableViewDataSource
extension FriendsSelectionVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listAvailables.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return getUserCell(indexPath, tableView: tableView)
    }
    
    private func getUserCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UserSelectionCell.className, for: indexPath) as? UserSelectionCell
            else { return UITableViewCell() }
        let userModel = listAvailables[indexPath.row]
        let isSelected = listSelected.contains(where: {$0._id == userModel._id})
        cell.setupUI(user: userModel, isSelected: isSelected, actionUserSelected: actionSelectedUser(_:))
        return cell
    }
    
    func actionSelectedUser(_ user: UserModel?) {
        guard let user = user else { return }
        if listSelected.contains(where: {$0._id == user._id}) {
            listSelected.removeAll(where: {$0._id == user._id})
        }else {
            listSelected.append(user)
        }
        updateUI()
    }
    
}

// MARK: - UITableViewDelegate

extension FriendsSelectionVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        APP_MANAGER.pushUserProfileVC(userModel: listAvailables[indexPath.row], sender: self)
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

extension FriendsSelectionVC : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == txtSearch {
            self.refreshAll(isShowLoader: true)
        }
        return true
    }
}

