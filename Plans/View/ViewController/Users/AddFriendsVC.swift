//
//  AddFriendsVC.swift
//  Plans
//
//  Created by Star on 3/26/21.
//

import UIKit

class AddFriendsVC: UserBaseVC {

    enum TabType: Int {
        case plansUsers = 0
        case contacts = 1
    }
    
    // MARK: - IBOutlets
    // Search Bar
    @IBOutlet weak var txtSearch: UITextField!

    // Tab Bar
    @IBOutlet var collecTabUnderLine: [UIView]!
    
    // Table View
    @IBOutlet weak var tblFriends: UITableView!

    // No Access Contacts
    @IBOutlet weak var viewNoAccessContact: UIView!
    @IBOutlet weak var btnOpenSettings: UIButton!
    
    // Search Result View
    @IBOutlet weak var viewSearchResult: UIView!
    @IBOutlet weak var imgvSearch: UIImageView!
    @IBOutlet weak var lblSearchResult: UILabel!

    // MARK: - Properties
    override var screenName: String? { "FindFriends_Screen" }

    var selectedTab = TabType.plansUsers
    var usersPlans = [UserModel]()
    var contactsInvite = [UserModel]()
    var pageNumber = 1
    var numberOfRowsOnPage = 20
    var cellHeights = [IndexPath: CGFloat]()
    var timestampLoading = Date()

    var listUsers = [UserModel]()
    var listContacts = [UserModel]()
    var userSelected: UserModel? = nil
    var indexPathSelected: IndexPath? = nil
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
    
    override func setupUI() {
        super.setupUI()

        // Search TextField
        txtSearch.attributedPlaceholder = NSAttributedString(string: "Search",
                                                               attributes: [NSAttributedString.Key.foregroundColor: AppColor.whiteOpacity60])
        txtSearch.delegate = self
        txtSearch.addTarget(self, action: #selector(refreshAll), for: .editingChanged)


        // Open Settings button in No acccess contacts view
        btnOpenSettings.layer.borderColor = AppColor.grey_button_border.cgColor
        

        setupTableView()
        updateUI()
    }
    
    override func refreshAll(isShowLoader: Bool = false) {
        super.refreshAll(isShowLoader: isShowLoader)
        
        contactsInvite.removeAll()
        switch selectedTab {
        case .plansUsers:
            getAllPlansUserList(isShowLoader: isShowLoader, pageNumber: 1, numberOfRows: pageNumber * numberOfRowsOnPage)
        case .contacts:
            fetchContacts(isShowLoader: isShowLoader)
        }
    }

    
    // MARK: - User Actions
    @IBAction func actionBackBtn(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionPlansUsers(_ sender: UIButton) {
        selectedTab = .plansUsers
        updateUI()
        pageNumber = 1
        refreshAll(isShowLoader: true)
    }
    
    @IBAction func actionContacts(_ sender: UIButton) {
        selectedTab = .contacts
        updateUI()
        pageNumber = 1
        refreshAll(isShowLoader: true)
    }
    
    @IBAction func actionOpenSettings(_ sender: Any) {
        self.openUrl(urlString: UIApplication.openSettingsURLString)
    }

    // MARK: - Private Methods
    
    private func setupTableView() {
        tblFriends.registerMultiple(nibs: [UserTableCell.className, SectionHeaderCell.className])
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
        
        if #available(iOS 15.0, *) {
            tblFriends.sectionHeaderTopPadding = 0.0
        }
    }

    func updateUI() {
        view.endEditing(true)
        txtSearch.text = ""
        
        collecTabUnderLine.forEach({$0.isHidden = $0.tag != selectedTab.rawValue})
    }
    
    func updateUIForNoData(isAccessContacts: Bool = true) {
        viewSearchResult.isHidden = true
        lblSearchResult.isHidden = false
        imgvSearch.isHidden = false
        viewNoAccessContact.isHidden = true

        if usersPlans.count == 0 {
            switch selectedTab {
            case .plansUsers:
                viewSearchResult.isHidden = false
                if let search = txtSearch.text, search != "" {
                    lblSearchResult.text = "Sorry! No Users Found."
                }else {
                    lblSearchResult.text = "Find Friends"
                }
            case .contacts:
                if contactsInvite.count == 0 {
                    if isAccessContacts == true {
                        viewSearchResult.isHidden = false
                        if let search = txtSearch.text, search != "" {
                            lblSearchResult.text = "Sorry! No contacts found."
                        }else {
                            lblSearchResult.text = "No contacts yet."
                        }
                    }else {
                        viewNoAccessContact.isHidden = false
                    }
                }
            }
        }
        
    }
    
    func updateData(list: [UserModel]?, pageNumber: Int = 1, numberOfRowsInPage: Int = 20) {
        if pageNumber == 1 { usersPlans.removeAll() }

        self.usersPlans.replace(arrPage: list, pageNumber: pageNumber, numberOfRowsInPage: numberOfRowsInPage)
        
        if userSelected != nil, indexPathSelected != nil {
            moveSelectedItem()
        }else {
            updateAll()
        }
    }
    
    func updateAll() {
        userSelected = nil
        indexPathSelected = nil
        isAnimating = false
        
        listUsers.removeAll()
        listUsers.append(contentsOf: usersPlans)

        listContacts.removeAll()
        listContacts.append(contentsOf: contactsInvite)

        tblFriends.reloadData()
        updateUIForNoData()
    }

    func moveSelectedItem() {
        var toPosition: IndexPath? = nil
        var newItem: UserModel? = nil
        if let toIndexForUsers = usersPlans.firstIndex(where: { ($0._id ?? $0.userId) == (userSelected?._id ?? userSelected?.userId)}) {
            toPosition = IndexPath(row: toIndexForUsers, section: 0)
            newItem = usersPlans[toIndexForUsers]
        }else if let toIndexForContacts = contactsInvite.firstIndex(where: { $0.mobile == userSelected?.mobile}) {
            toPosition = IndexPath(row: toIndexForContacts, section: 1)
            newItem = contactsInvite[toIndexForContacts]
        }
        
        if !isAnimating,
           let newItem = newItem,
           let toPosition = toPosition,
           let fromPosition = indexPathSelected,
           toPosition != fromPosition {
            isAnimating = true
            switch fromPosition.section {
            case 0:
                listUsers[fromPosition.row] = newItem
                break
            case 1:
                listContacts[fromPosition.row] = newItem
                break
            default:
                break
            }
            tblFriends.reloadRows(at: [fromPosition], with: .none)
            
            APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 0.3) {
                if self.isAnimating {
                    switch fromPosition.section {
                    case 0:
                        self.listUsers.remove(at: fromPosition.row)
                        break
                    case 1:
                        self.listContacts.remove(at: fromPosition.row)
                        break
                    default:
                        break
                    }
                    
                    switch toPosition.section {
                    case 0:
                        let newPosition = min(self.listUsers.count, toPosition.row)
                        self.listUsers.insert(newItem, at: newPosition)
                        break
                    case 1:
                        let newPosition = min(self.listContacts.count, toPosition.row)
                        self.listContacts.insert(newItem, at: newPosition)
                        break
                    default:
                        break
                    }
                    
                    self.tblFriends.beginUpdates()
                    self.tblFriends.moveRow(at: fromPosition, to: toPosition)
                    self.tblFriends.endUpdates()
                    
                    self.indexPathSelected = nil
                    self.userSelected = nil
                    self.isAnimating = false
                }
            }
            
        }else {
            updateAll()
        }
    }

    
    func getNextPage(isShowLoader: Bool = false) {
        pageNumber = usersPlans.count / numberOfRowsOnPage + ((usersPlans.count % numberOfRowsOnPage) > 0 ? 1 : 0) + 1
        refreshAll()
    }
    
    // MARK: - Fetch Contacts
    
    private func fetchContacts(isShowLoader: Bool = true) {
        usersPlans.removeAll()
        contactsInvite.removeAll()
        
        CONTACT_MANAGER.fetchContactList{ (success, contacts) in
            if success == true{
                if let contacts = contacts, contacts.count > 0  {
                    self.contactsInvite.append(contentsOf: contacts)
                    self.getUsersWithMobiles(isShowLoader: isShowLoader)
                }else {
                    self.tblFriends.reloadData()
                    self.updateUIForNoData()
                }
            }else {
                self.tblFriends.reloadData()
                self.updateUIForNoData(isAccessContacts: false)
            }
        }
    }

    private func filterContactsInvite (_ response : [UserModel]) {
        // Filter non friends
        let list = response.filter({$0.friendShipStatus != 1 && $0.mobile != USER_MANAGER.mobile })

        // remove contants who have a plan account from contactsInvite
        usersPlans.removeAll()
        var newContactsInvite = [UserModel]()
        list.forEach { (user) in
            if user._id != nil {
                usersPlans.append(user)
            }else {
                for contact in contactsInvite {
                    if contact.mobile == user.mobile {
                        contact.invitedTime = user.invitedTime
                        newContactsInvite.append(contact)
                        break
                    }
                }
            }
        }
        
        contactsInvite = newContactsInvite
        
        // filter plans users and contacts with search text
        if let str = txtSearch.text?.lowercased(), str != "" {
            
            let filterList1 = usersPlans.filter { (contact) -> Bool in
                if let fullName = contact.fullName?.lowercased(), fullName.contains(str) == true {
                    return true
                }
                if let mobile = contact.mobile?.lowercased(), mobile.contains(str) == true {
                    return true
                }
                return false
            }
            usersPlans = filterList1

            let filterList2 = contactsInvite.filter { (contact) -> Bool in
                if let fullName = contact.fullName?.lowercased(), fullName.contains(str) == true {
                    return true
                }
                if let mobile = contact.mobile?.lowercased(), mobile.contains(str) == true {
                    return true
                }
                return false
            }
            contactsInvite = filterList2
        }
        
        // sort plans users by friendShipStatus
        usersPlans.sort { (item1, item2) -> Bool in
            if let friendShip1 = item1.friendShipStatus,
                let friendShip2 = item2.friendShipStatus {
                
                if friendShip1 <= friendShip2 {
                    if friendShip1 == friendShip2, friendShip1 == 0 {
                        if let sender1 = item1.friendRequestSender,
                            let sender2 = item2.friendRequestSender {
                            if sender1 == USER_MANAGER.userId {
                                return false
                            }
                            if sender2 == USER_MANAGER.userId {
                                return true
                            }
                            return true
                        }else {
                            return true
                        }
                    }
                    return true
                }else {
                    return false
                }
            }else {
                return true
            }
        }
        
        // sort contacts by invitedTime
        contactsInvite.sort { (contact1, contact2) -> Bool in
            return (contact1.invitedTime ?? 0) > (contact2.invitedTime ?? 0)
        }

        if userSelected != nil, indexPathSelected != nil {
            moveSelectedItem()
        }else {
            updateAll()
        }
    }
    
    
}

// MARK: - Backend Api Methods

extension AddFriendsVC {
    
    private func prepareDictForUsersWithMobiles() -> [String: Any] {
        var mobiles = [String]()
        contactsInvite.forEach { (user) in
            if let mobile = user.mobile {
                mobiles.append(mobile)
            }
        }
        let dict = ["mobiles": mobiles] as [String: Any]
        return dict
    }

    // Get all plans users list
    func getAllPlansUserList(isShowLoader: Bool = true, pageNumber: Int = 1, numberOfRows: Int = 20) {
        guard let search = txtSearch.text, search != "" else {
            self.usersPlans.removeAll()
            self.tblFriends.reloadData()
            self.updateUIForNoData()
            return
        }
        
        let dict = ["pageNo": pageNumber,
                    "count": numberOfRows,
                    "keyword": self.txtSearch.text ?? "" ] as [String: Any]
        
        if isShowLoader == true {
            showLoader()
        }
        
        USER_SERVICE.hitPlansUserListApi(dict).done { (response) -> Void in
                self.hideLoader()
                self.updateData(list: response, pageNumber: pageNumber, numberOfRowsInPage: numberOfRows)
            }.catch { (error) in
                self.hideLoader()
                POPUP_MANAGER.handleError(error)
        }
    }

    // Get plans users with mobiles
    func getUsersWithMobiles(isShowLoader: Bool = true) {
        if isShowLoader == true {
            showLoader()
        }
        USER_SERVICE.hitPlansUsersWithMobilesApi(prepareDictForUsersWithMobiles()).done { (response) -> Void in
            self.hideLoader()
            self.filterContactsInvite(response)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
}

extension AddFriendsVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if listContacts.count > 0 {
            return 2
        }else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 1:
            return listContacts.count
        default:
            return listUsers.count
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 1:
            let header = tableView.dequeueReusableCell(withIdentifier: SectionHeaderCell.className) as? SectionHeaderCell
            header?.setupUI(title: "Invite Contacts", cellType: .inviteContacts)
            return header
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 1:
            return 37
        default:
            return CGFloat.leastNormalMagnitude
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return getUserCell(indexPath, tableView: tableView)
    }
    
    private func getUserCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UserTableCell.className, for: indexPath) as? UserTableCell
            else { return UITableViewCell() }
        
        var userModel : UserModel?
        switch indexPath.section {
        case 1:
            if listContacts.count > indexPath.row {
                userModel = listContacts[indexPath.row]
            }
        default:
            if listUsers.count > indexPath.row {
                userModel = listUsers[indexPath.row]
            }
        }
        
        cell.setupUI(model: userModel, delegate: self, cellType: selectedTab == .contacts ? .contact : .plansUser)
        return cell
    }
    
}

extension AddFriendsVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var userModel : UserModel?
        switch indexPath.section {
        case 1:
            userModel = listContacts[indexPath.row]
        default:
            userModel = listUsers[indexPath.row]
        }
        
        APP_MANAGER.pushUserProfileVC(userModel: userModel, sender: self)
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

extension AddFriendsVC : UITextFieldDelegate {
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

extension AddFriendsVC : UserTableCellDelegate {
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
        if let index = listUsers.firstIndex(where: { ($0._id ?? $0.userId) == (userSelected?._id ?? userSelected?.userId)}) {
            indexPathSelected = IndexPath(row: index, section: 0)
        }else if let index = listContacts.firstIndex(where: { $0.mobile == userSelected?.mobile}) {
            indexPathSelected = IndexPath(row: index, section: 1)
        }
    }
    
}




