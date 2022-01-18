//
//  FriendListVC.swift
//  Plans
//
//  Created by Plans Collective LLC on 5/29/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit

class FriendListVC: UserBaseVC {
    
    // MARK: - IBOutlets
    // Search Bar
    @IBOutlet weak var txtSearch: UITextField!
    @IBOutlet weak var viewAddFriend: UIView!

    // Table View
    @IBOutlet weak var tblFriends: UITableView!

    // No Friends View
    @IBOutlet weak var viewNoFriends: UIView!
    
    // Search Result View
    @IBOutlet weak var viewSearchResult: UIView!
    @IBOutlet weak var imgvSearch: UIImageView!
    @IBOutlet weak var lblSearchResult: UILabel!
    
    // MARK: - Properties
    var usersPlans = [UserModel]()
    var listItems = [UserModel]()
    var pageNumber = 1
    var numberOfRowsOnPage = 20
    var cellHeights = [IndexPath: CGFloat]()
    var timestampLoading = Date()
    var userSelected: UserModel? = nil
    var positionSelected: Int? = nil
    var isAnimating = false
    
    // MARK: - ViewController Life Cycel
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func hideLoader() {
        super.hideLoader()
        tblFriends.switchRefreshFooter(to: .normal)
    }
    
    override func initializeData() {
        super.initializeData()
    }
    
    override func setupUI() {
        super.setupUI()

        // Search TextField
        txtSearch.attributedPlaceholder = NSAttributedString(string: "Search",
                                                               attributes: [NSAttributedString.Key.foregroundColor: AppColor.whiteOpacity60])
        txtSearch.delegate = self
        txtSearch.text = ""
        txtSearch.addTarget(self, action: #selector(refreshAll), for: .editingChanged)


        viewAddFriend.isHidden = userID != USER_MANAGER.userId
        
        setupTableView()
    }
    
    override func refreshAll(isShowLoader: Bool = false) {
        super.refreshAll(isShowLoader: isShowLoader)
        friendListApiMethod(isShowLoader: isShowLoader, pageNumber: 1, numberOfRows: pageNumber * numberOfRowsOnPage)
    }

    
    // MARK: - User Actions
    @IBAction func actionBackBtn(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionAddFriend(_ sender: UIButton) {
        APP_MANAGER.pushAddFriendsVC(user: activeUser, sender: self)
    }
    
    // MARK: - Private Methods
    
    private func setupTableView() {
        tblFriends.registerMultiple(nibs: [UserTableCell.className])
        tblFriends.delegate = self
        tblFriends.dataSource = self
        
        tblFriends.configRefreshFooter(with: refreshFooter, container:self) { [weak self] in
            guard let this = self, Date().timeIntervalSince1970 - this.timestampLoading.timeIntervalSince1970 > 0.5  else {
                APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 1) {
                    self?.hideLoader()
                }
                return
            }
            this.timestampLoading = Date()

            if this.usersPlans.count % this.numberOfRowsOnPage == 0, this.usersPlans.count > 0 {
                this.getNextPage()
            }else {
                APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 1) {
                    self?.hideLoader()
                }
            }
        }
        
    }

    func updateUIForNoData(isAccessContacts: Bool = true) {
        viewNoFriends.isHidden = true
        viewSearchResult.isHidden = true
        lblSearchResult.isHidden = false
        imgvSearch.isHidden = false

        if usersPlans.count == 0 {
            if let search = txtSearch.text, search != "" {
                viewSearchResult.isHidden = false
                lblSearchResult.text = "Sorry! No friends found."
            }else if userID == USER_MANAGER.userId {
                viewNoFriends.isHidden = false
            }else {
                viewSearchResult.isHidden = false
                lblSearchResult.text = "No friends yet."
            }
        }
        
    }
    
    func updateData(list: [UserModel]?, pageNumber: Int = 1, numberOfRowsInPage: Int = 20) {
        if pageNumber == 1 { usersPlans.removeAll() }
        self.usersPlans.replace(arrPage: list, pageNumber: pageNumber, numberOfRowsInPage: numberOfRowsInPage)
        
        if userSelected != nil, positionSelected != nil {
            moveSelectedItem()
        }else {
            updateAll()
        }
    }
    
    func getNextPage(isShowLoader: Bool = false) {
        pageNumber = usersPlans.count / numberOfRowsOnPage + ((usersPlans.count % numberOfRowsOnPage) > 0 ? 1 : 0) + 1
        friendListApiMethod(isShowLoader: isShowLoader, pageNumber: pageNumber)
    }
    
    func updateAll() {
        userSelected = nil
        positionSelected = nil
        isAnimating = false
        
        listItems.removeAll()
        listItems.append(contentsOf: usersPlans)

        self.tblFriends.reloadData()
        self.updateUIForNoData()
    }
    
    func moveSelectedItem() {
        if !isAnimating, let toPosition = usersPlans.firstIndex(where: { ($0._id ?? $0.userId) == (userSelected?._id ?? userSelected?.userId)}) {
            if let positionSelected = positionSelected, toPosition != positionSelected {
                
                isAnimating = true
                let newItem = usersPlans[toPosition]
                listItems[positionSelected] = newItem
                tblFriends.reloadRows(at: [IndexPath(row: positionSelected, section: 0)], with: .none)
                
                APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 0.3) {
                    if self.isAnimating {
                        self.listItems.remove(at: positionSelected)
                        let newPosition = min(self.listItems.count, toPosition)
                        self.listItems.insert(newItem, at: newPosition)
                        
                        self.tblFriends.beginUpdates()
                        self.tblFriends.moveRow(at: IndexPath(row: positionSelected, section: 0),
                                                to: IndexPath(row: newPosition, section: 0))
                        self.tblFriends.endUpdates()
                        
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
    
}

// MARK: - Backend Api Methods

extension FriendListVC {

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

extension FriendListVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return getUserCell(indexPath, tableView: tableView)
    }
    
    private func getUserCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UserTableCell.className, for: indexPath) as? UserTableCell
            else { return UITableViewCell() }
        
        cell.setupUI(model: listItems[indexPath.row], delegate: self, cellType: .plansUser)
        return cell
    }
    
}

extension FriendListVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        APP_MANAGER.pushUserProfileVC(userModel: listItems[indexPath.row], sender: self)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 61
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? UITableView.automaticDimension
    }

}

extension FriendListVC : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == txtSearch {
            pageNumber = 1
            self.refreshAll(isShowLoader: true)
        }
        return true
    }
}

// MARK: - UserTableCellDelegate

extension FriendListVC : UserTableCellDelegate {
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
    
    func onItemMoveSelected(data: Any?, cell: UITableViewCell?) {
        userSelected = data as? UserModel
        positionSelected = listItems.firstIndex(where: { ($0._id ?? $0.userId) == (userSelected?._id ?? userSelected?.userId)})
    }
    
}



