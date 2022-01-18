//
//  EditInvitationVC.swift
//  Plans
//
//  Created by Star on 2/9/21.
//

import UIKit

protocol  EditInvitationVCDelegate {
    func didSelectedUsers (users: [UserModel]?)
}

extension EditInvitationVCDelegate {
    func didSelectedUsers (users: [UserModel]?){}
}

class EditInvitationVC: EventBaseVC {

    enum EditMode {
        case create // For creating a new Event, it returns the selected users to delegate, not call the invitation backend api.
        case edit   // For editing an existing Event, it calls the invitation backend api and returns the selected users to delegate.
    }
    
    // MARK: - IBOutlets
    
    // Search UI
    @IBOutlet weak var txtfSearch: UITextField!
    
    // Tabs UI
    @IBOutlet weak var viewTabBar: UIView!
    @IBOutlet var collecTabBtns: [UIButton]!
    @IBOutlet var collecTabUnderBars: [UIView]!
    
    // Add Container Views
    @IBOutlet weak var viewAddField: UIView!
    @IBOutlet var collecAddViews: [UIView]!
    @IBOutlet var collecPlaceholders: [UILabel]!
    @IBOutlet var collecUnderLines: [UIView]!
    @IBOutlet var collecCheckViews: [UIView]!
    @IBOutlet var collecAddBtns: [UIButton]!

    // Add Phone Number View
    @IBOutlet weak var lblCountryCode: UILabel!
    @IBOutlet weak var txtfAddPhoneNumber: UITextField!
    
    // Add Email View
    @IBOutlet weak var txtfAddEmail: UITextField!
    
    // Share Link View
    @IBOutlet weak var viewLinkTab: UIView!
    @IBOutlet weak var viewShareLink: UIView!
    @IBOutlet weak var lblLinkUrl: UILabel!
    @IBOutlet weak var btnCopy: UIButton!
    @IBOutlet weak var btnShareLink: UIButton!
    
    // List view
    @IBOutlet weak var tblvList: UITableView!
    
    // Invite Button View
    @IBOutlet weak var viewInviteBtn: UIView!
    @IBOutlet weak var btnInvite: UIButton!
    @IBOutlet weak var lblInviteDescription: UILabel!
    @IBOutlet weak var lblRemovedDescription: UILabel!
    
    // No List and No access View
    @IBOutlet weak var lblNoList: UILabel!
    @IBOutlet weak var viewNoAccessContacts: UIView!
    @IBOutlet weak var btnOpenSettings: UIButton!
    
    
    // MARK: - Properties
    var delegate : EditInvitationVCDelegate?
    var editMode = EditMode.create
    var selectedType = InviteType.friend
    
    // Selected Users who are already invited.
    var selectedUsers : [UserModel]?
    var selectedUsersOrigin = [UserModel]()

    // Searched Users who are shown on List
    var listSearched = [UserModel]()

    // Friends List
    var listFriends = [UserModel]()
    var selectedFriendsAlready = [UserModel]()
    var selectedFriendsNew = [UserModel]()
    
    // Contacts List
    var listContacts = [UserModel]()
    var selectedContactsAlready = [UserModel]()
    var selectedContactsNew = [UserModel]()
    var maxLength = 10
    var minLength = 10
    var strCountryCode = "+1"
    var strISOCode = "US"
    
    // Email List
    var listEmails = [UserModel]()
    var selectedEmailsAlready = [UserModel]()
    var selectedEmailsNew = [UserModel]()
    
    var listItems = [UserModel]()
    var userSelected: UserModel? = nil
    var positionSelected: Int? = nil
    var isAnimating = false

    override var screenName: String? { "EventInvitations_Screen" }

    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    // MARK: - User Action Handlers
    
    @IBAction func actionBack(_ sender: Any) {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionTapBackground(_ sender: Any) {
        view.endEditing(true)
    }
    
    
    @IBAction func actionTabBtns(_ sender: UIButton) {
        view.endEditing(true)
        txtfSearch.text = ""
        selectedType = InviteType(rawValue: sender.tag) ?? .friend
        updateUI(selectedType)
    }
    
    @IBAction func actionAdd(_ sender: Any) {
        view.endEditing(true)
        
        guard isValidForAdd() == true else { return }

        switch selectedType {
        case .contact :
            addPhoneNumber()
            break
        case .email :
            addEmail()
            break
        default :
            break
        }
    }
    
    @IBAction func actionInvite(_ sender: Any) {
        view.endEditing(true)
        let selectedUsers = getSelectedUsers()
        switch editMode {
        case .create :
            actionBack(self)
            delegate?.didSelectedUsers(users: selectedUsers)
            break
        case .edit :
            updateInvitationWithPeople(users: selectedUsers)
            break
        }
    }
    
    @IBAction func actionCopyBtn(_ sender: Any) {
        UIPasteboard.general.string = lblLinkUrl.text
        POPUP_MANAGER.makeToast("Link copied")
    }
    
    @IBAction func actionShareLinkBtn(_ sender: Any) {
        APP_MANAGER.shareEvent(event: activeEvent, isInviting: true, sender: self)
    }
    
    @IBAction func actionOpenSettings(_ sender: Any) {
        view.endEditing(true)
        self.openUrl(urlString: UIApplication.openSettingsURLString)
    }
    
    @IBAction func actionCountryCode(_ sender: Any) {
        view.endEditing(true)
        APP_MANAGER.pushPinCodeVC(delegate: self, sender: self)
    }

    @IBAction func actionEditChangedSearch(_ sender: UITextField) {
        filterListBy(text: sender.text)
    }

    @IBAction func actionChangedAddText(_ sender: UITextField) {
        updateAddUI(isEditing: true)
    }

    // MARK: - Initialization Methods
    override func initializeData() {
        super.initializeData()
        
        selectedUsersOrigin.removeAll()
        if let origin = selectedUsers, origin.count > 0 {
            selectedUsersOrigin.append(contentsOf: origin)
        }
        
        // Selected Friends
        selectedFriendsAlready = selectedUsers?.filter({$0.isFriend == true}) ?? [UserModel]()
        selectedContactsAlready = selectedUsers?.filter({$0.inviteType == .mobile || $0.inviteType == .contact}) ?? [UserModel]()
        selectedEmailsAlready = selectedUsers?.filter({$0.inviteType == .email}) ?? [UserModel]()
        
        // Sync UserDefault Data - Mobile and Email List
        var mobileList = USER_MANAGER.mobileList
        selectedContactsAlready.forEach { (item) in
            mobileList.removeAll(where: {$0 == item.mobile})
            mobileList.append(item.mobile ?? "")
        }
        USER_MANAGER.mobileList = mobileList

        var emailList = USER_MANAGER.emailList
        selectedEmailsAlready.forEach { (item) in
            emailList.removeAll(where: {$0.lowercased() == item.email?.lowercased()})
            emailList.append(item.email ?? "")
        }
        USER_MANAGER.emailList = emailList
    }
    
    override func setupUI() {
        super.setupUI()
        
        // Search TextField
        txtfSearch.attributedPlaceholder = NSAttributedString(string: "Search",
                                                                   attributes: [NSAttributedString.Key.foregroundColor: AppColor.whiteOpacity60])
        txtfSearch.delegate = self
        
        // Tabs View
        viewLinkTab.isHidden = activeEvent?.eventLink?.invitation != nil ? false : true
        
        // Phone Number
        txtfAddPhoneNumber.delegate = self

        // Email
        txtfAddEmail.delegate = self

        // Share Link View
        lblLinkUrl.text = activeEvent?.eventLink?.invitation
        btnShareLink.addShadow(3.0, shadowOpacity: 0.3, shadowOffset: CGSize.zero)
        viewShareLink.isHidden = true
        
        // TableView
        tblvList.delegate = self
        tblvList.dataSource = self
        tblvList.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 150, right: 0)
        tblvList.registerMultiple(nibs: [UserInvitationCell.className])
        
        // No List UI
        lblNoList.isHidden = true
        viewNoAccessContacts.isHidden = true
        btnOpenSettings.layer.borderColor = AppColor.grey_button_border.cgColor
        
        // Invite View
        btnInvite.addShadow(3.0, shadowOpacity: 0.3, shadowOffset: CGSize.zero)
        if editMode == .create {
            btnInvite.setTitle("Done", for: .normal)
        }

        hitFriendListAPI(isUpdateUI: false) {
            self.fetchContacts(isUpdateUI: false) {
                self.fetchEmailList(isUpdateUI: false) {
                    self.updateUI(self.selectedType)
                }
            }
        }
    }
    
    // MARK: - Update UI Methods
    
    func updateUI(_ type: InviteType) {
        updateTabBar(type)
        updateAddView(type)
        updateList(type)
    }
    
    func updateTabBar(_ type: InviteType) {
        collecTabBtns.forEach { (tabBtn) in
            if tabBtn.tag == selectedType.rawValue {
                tabBtn.setTitleColor(.white, for: .normal)
            }else {
                tabBtn.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .normal)
            }
        }
        
        collecTabUnderBars.forEach { (underBar) in
            if underBar.tag == selectedType.rawValue {
                underBar.isHidden = false
            }else {
                underBar.isHidden = true
            }
        }

    }
    
    func updateAddView(_ type: InviteType) {
        viewAddField.isHidden = false
        viewShareLink.isHidden = true

        switch type {
        case .friend:
            viewAddField.isHidden = true
            break
        case .contact, .email:
            collecAddViews.forEach { (view) in
                if view.tag == type.rawValue {
                    view.isHidden = false
                }else {
                    view.isHidden = true
                }
            }
            updateAddUI()
            break
        case .link:
            viewAddField.isHidden = true
            viewShareLink.isHidden = false
            break
        default:
            break
        }
        
    }
    
    func updateAddUI(isEditing: Bool = false){
        
        let btnAdd = collecAddBtns.filter({$0.tag == selectedType.rawValue}).first
        let viewCheck = collecCheckViews.filter({$0.tag == selectedType.rawValue}).first
        let lblPlaceholder = collecPlaceholders.filter({$0.tag == selectedType.rawValue}).first
        let viewUnderLine = collecUnderLines.filter({$0.tag == selectedType.rawValue}).first
        
        lblPlaceholder?.textColor = isEditing ? AppColor.purple_join : .black
        viewUnderLine?.backgroundColor = isEditing ? AppColor.purple_join : AppColor.grey_text

        if selectedType == .contact {
            txtfAddPhoneNumber.textColor = isEditing ? .black : AppColor.grey_text
            txtfAddPhoneNumber.text = txtfAddPhoneNumber.text?.formatPhoneNumber(maxLength: maxLength)
            lblCountryCode.text = "\(strISOCode) \(strCountryCode)"
        }else if selectedType == .email {
            txtfAddEmail.textColor = isEditing ? .black : AppColor.grey_text
            lblPlaceholder?.isHidden = !(isEditing || (txtfAddEmail.text ?? "").count > 0)
            txtfAddEmail.placeholder = isEditing ? nil : "Add Email Address"
        }
        
        if isValidForAdd() == true {
            viewCheck?.isHidden = false
            btnAdd?.setTitleColor(AppColor.purple_join, for: .normal)
            btnAdd?.isEnabled = true
        }else {
            viewCheck?.isHidden = true
            btnAdd?.setTitleColor(AppColor.grey_text, for: .normal)
            btnAdd?.isEnabled = false
        }
    }


    func updateList(_ type: InviteType) {
        listSearched.removeAll()

        switch type {
        case .friend:
            hitFriendListAPI(isShowLoader: true)
            break
        case .contact:
            fetchContacts()
            break
        case .email:
            fetchEmailList()
            break
        case .link:
            updateTableView()
            break
        default :
            break
        }
    }
    
    func updateInviteView() {

        // Selected Counts
        let selected = getSelectedCounts()
        let removed = getSelectedCounts(isRemoved: true)

        let attriSelected = getAttriString(friends: selected.0, contacts: selected.1, emails: selected.2, isSelected: true)
        let attriRemoved = getAttriString(friends: removed.0, contacts: removed.1, emails: removed.2, isSelected: false)

        viewInviteBtn.isHidden = true
        lblInviteDescription.text = ""
        lblRemovedDescription.text = ""
        lblInviteDescription.isHidden = true
        lblRemovedDescription.isHidden = true
        btnInvite.backgroundColor = AppColor.grey_button
        btnInvite.isEnabled = false
        var titleDone: String? = nil
        
        if attriRemoved != nil {
            lblRemovedDescription.attributedText = attriRemoved
            lblRemovedDescription.isHidden = false
            titleDone = "Done"
        }

        if attriSelected != nil {
            lblInviteDescription.attributedText = attriSelected
            lblInviteDescription.isHidden = false
            titleDone = "Invite"
        }
        
        if attriRemoved != nil || attriSelected != nil || (editMode == .create && selectedUsersOrigin.count > 0){
            btnInvite.backgroundColor = AppColor.purple_join
            btnInvite.isEnabled = true
            if editMode == .create {
                titleDone = "Done"
            }
            if let title = titleDone {
                btnInvite.setTitle(title, for: .normal)
            }
            viewInviteBtn.isHidden = false
        }
        
    }
    
    func updateTableView(noAccessContacts: Bool = false) {
        lblNoList.isHidden = true
        viewNoAccessContacts.isHidden = true
        
        switch selectedType {
        case .friend :
            if listFriends.count == 0 {
                lblNoList.text = "No friends yet."
                lblNoList.isHidden = false
            }
            break
        case .contact :
            if noAccessContacts == true {
                viewNoAccessContacts.isHidden = false
            }else if listContacts.count == 0 {
                lblNoList.text = "No contacts yet."
                lblNoList.isHidden = false
            }
            break
        case .email :
            if listEmails.count == 0 {
                lblNoList.text = "No emails yet."
                lblNoList.isHidden = false
            }
            break
        case .link :
            break
        default :
            break
        }
        
        // Reload List TableView
        if userSelected != nil, positionSelected != nil {
            moveSelectedItem()
        }else {
            updateAllUsers()
        }

    }
    
    func moveSelectedItem() {
        if !isAnimating, let toPosition = listSearched.firstIndex(where: {
            var result = false
            switch selectedType {
            case .friend:
                result = ($0._id ?? $0.userId) == (userSelected?._id ?? userSelected?.userId)
                break
            case .contact:
                result = $0.mobile == userSelected?.mobile
                break
            case .email:
                result = $0.email == userSelected?.email
                break
            default:
                break
            }
            return result
        }) {
            if let positionSelected = positionSelected, toPosition != positionSelected {
                
                isAnimating = true
                let newItem = listSearched[toPosition]
                listItems[positionSelected] = newItem
                tblvList.reloadRows(at: [IndexPath(row: positionSelected, section: 0)], with: .none)
                
                APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 0.3) {
                    if self.isAnimating {
                        self.listItems.remove(at: positionSelected)
                        let newPosition = min(self.listItems.count, toPosition)
                        self.listItems.insert(newItem, at: newPosition)
                        
                        self.tblvList.beginUpdates()
                        self.tblvList.moveRow(at: IndexPath(row: positionSelected, section: 0),
                                                to: IndexPath(row: newPosition, section: 0))
                        self.tblvList.endUpdates()
                        
                        self.positionSelected = nil
                        self.userSelected = nil
                        self.isAnimating = false
                    }
                }
            }else {
                updateAllUsers()
            }
        }else {
            updateAllUsers()
        }
    }

    func updateAllUsers() {
        userSelected = nil
        positionSelected = nil
        isAnimating = false
        
        listItems.removeAll()
        listItems.append(contentsOf: listSearched)

        tblvList.reloadData()
    }

    
    // MARK: - Interal Methods
    
    func isValidForAdd() -> Bool {
        var result = false
 
        switch selectedType {
        case .friend:
            break
        case .contact:
            let text = txtfAddPhoneNumber.text?.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "-", with: "") ?? ""
            result = (text.count >= minLength) && (text.count <= maxLength)
            break
        case .email:
            result = txtfAddEmail.text?.trimmingCharacters(in: .whitespaces).isValidEmail() ?? false
            break
        case .link:
            break
        default:
            break
        }
        
        return result
    }
    
    func filterListBy(text: String?) {
        switch selectedType {
        case .friend:
            filterFriendsBy(text: text)
            break
        case .contact:
            filterContactsBy(text: text)
            break
        case .email:
            filterEmailListBy(text: text)
            break
        default:
            break
        }

        // Reload List TableView
        updateTableView()
    }
    
    func gotoUser(userModel: UserModel?) {
        switch selectedType {
        case .friend :
            break
        case .contact :
            break
        case .email :
            break
        case .link :
            break
        default :
            break

        }
    }
    
    func selectUser(userModel: UserModel?) {
        guard let user = userModel else { return }
        
        if user.friendShipStatus == 1, selectedFriendsNew.contains(where: { $0._id == user._id }) == false {
            selectedFriendsNew.append(user)
        }

        switch selectedType {
        case .friend :
            reloadFriendList()
            break
        case .contact :
            selectedContactsNew.append(user)
            reloadContacts()
            break
        case .email :
            selectedEmailsNew.append(user)
            reloadEmailList()
            break
        case .link :
            break
        default :
            break
        }
        
    }
    
    func unselectUser(userModel: UserModel?) {
        guard let user = userModel else { return }
        
        if user.friendShipStatus == 1 {
            selectedFriendsAlready.removeAll(where: {$0._id == user._id})
            selectedFriendsNew.removeAll(where: {$0._id == user._id})

            selectedContactsAlready.removeAll(where: {$0.mobile == user.mobile})
            selectedContactsNew.removeAll(where: {$0.mobile == user.mobile})

            selectedEmailsAlready.removeAll(where: {$0.email?.lowercased() == user.email?.lowercased()})
            selectedEmailsNew.removeAll(where: {$0.email?.lowercased() == user.email?.lowercased()})
        }

        switch selectedType {
        case .friend :
            selectedFriendsAlready.removeAll(where: {$0._id == user._id})
            selectedFriendsNew.removeAll(where: {$0._id == user._id})
            reloadFriendList()
            break
        case .contact :
            selectedContactsAlready.removeAll(where: {$0.mobile == user.mobile})
            selectedContactsNew.removeAll(where: {$0.mobile == user.mobile})
            reloadContacts()
            break
        case .email :
            selectedEmailsAlready.removeAll(where: {$0.email?.lowercased() == user.email?.lowercased()})
            selectedEmailsNew.removeAll(where: {$0.email?.lowercased() == user.email?.lowercased()})
            reloadEmailList()
            break
        case .link :
            break
        default :
            break
        }
        
    }
    
    func cancelUser(userModel: UserModel?) {
        guard let user = userModel else { return }

        if user.friendShipStatus == 1 {
            selectedFriendsAlready.removeAll(where: {$0._id == user._id})
            selectedFriendsNew.removeAll(where: {$0._id == user._id})

            selectedContactsAlready.removeAll(where: {$0.mobile == user.mobile})
            selectedContactsNew.removeAll(where: {$0.mobile == user.mobile})

            selectedEmailsAlready.removeAll(where: {$0.email?.lowercased() == user.email?.lowercased()})
            selectedEmailsNew.removeAll(where: {$0.email?.lowercased() == user.email?.lowercased()})
        }

        switch selectedType {
        case .friend :
            selectedUsers?.removeAll(where: {$0._id == user._id})
            selectedFriendsAlready.removeAll(where: {$0._id == user._id})
            selectedFriendsNew.removeAll(where: {$0._id == user._id})
            reloadFriendList()
            break
        case .contact :
            selectedUsers?.removeAll(where: {$0.mobile == user.mobile})
            selectedContactsAlready.removeAll(where: {$0.mobile == user.mobile})
            selectedContactsNew.removeAll(where: {$0.mobile == user.mobile})
            reloadContacts()
            break
        case .email :
            selectedUsers?.removeAll(where: {$0.email?.lowercased() == user.email?.lowercased()})
            selectedEmailsAlready.removeAll(where: {$0.email?.lowercased() == user.email?.lowercased()})
            selectedEmailsNew.removeAll(where: {$0.email?.lowercased() == user.email?.lowercased()})
            reloadEmailList()
            break
        case .link :
            break
        default :
            break
        }
        

    }
    
    func deleteUser(userModel: UserModel?) {
        guard let user = userModel else { return }
        var list: [String]?
        switch selectedType {
        case .friend :
            break
        case .contact :
            list = ["Delete Contact"]
            break
        case .email :
            list = ["Delete Email"]
            break
        case .link :
            break
        default :
            break
        }
        
        if let list = list, list.count > 0 {
            OPTIONS_MANAGER.showMenu(list: list, data: user, delegate: self, sender: self)
        }
    }
    
    func getSelectedUsers() -> [UserModel] {
        var result = [UserModel]()
        var friends = [UserModel]()
        var people = [UserModel]()

        // Friends
        selectedFriendsAlready.forEach { (user) in
            if let friend = listFriends.first(where: {$0._id == user._id}) {
                friend.inviteType = .friend
                friends.append(friend)
            }
        }
        selectedFriendsNew.forEach { (user) in
            if let friend = listFriends.first(where: {$0._id == user._id}) {
                friend.inviteType = .friend
                friends.append(friend)
            }
        }

        // Contacts
        people.append(contentsOf: selectedContactsAlready.map({ (contant) -> UserModel in
            contant.inviteType = .mobile
            return contant
        }))
        people.append(contentsOf: selectedContactsNew.map({ (contant) -> UserModel in
            contant.inviteType = .mobile
            return contant
        }))
        
        // Emails
        people.append(contentsOf: selectedEmailsAlready.map({ (email) -> UserModel in
            email.inviteType = .email
            return email
        }))
        people.append(contentsOf: selectedEmailsNew.map({ (email) -> UserModel in
            email.inviteType = .email
            return email
        }))
        
        people.forEach { (people) in
            if people.friendShipStatus == 1 {
                if friends.contains(where: {$0.mobile == people.mobile || $0.email?.lowercased() == people.email?.lowercased()}) == false {
                    let friend = UserModel(userModel: people)
                    friend.inviteType = .friend
                    friends.append(friend)
                }
            }
        }
        
        result.append(contentsOf: friends)
        result.append(contentsOf: people)

        return result
    }
    
    func getSelectedCounts(isRemoved: Bool = false) -> (friends: Int, contacts: Int, emails: Int) {

        var friends = [UserModel]()
        friends.append(contentsOf: selectedFriendsNew)
        selectedContactsNew.forEach { (contact) in
            if contact.friendShipStatus == 1, friends.contains(where: {$0._id == contact._id}) == false {
                friends.append(contact)
            }
        }
        
        selectedEmailsNew.forEach { (email) in
            if email.friendShipStatus == 1, friends.contains(where: {$0._id == email._id}) == false {
                friends.append(email)
            }
        }

        var countFriends = friends.count
        var countContacts = selectedContactsNew.filter({$0.friendShipStatus != 1}).count
        var countEmails = selectedEmailsNew.filter({$0.friendShipStatus != 1}).count
        var countRemovedFriends = 0
        var countRemovedContacts = 0
        var countRemovedEmails = 0

        let friendsAlready = listFriends.filter({friend in selectedFriendsAlready.contains(where: {$0._id == friend._id})})
        let contactsAlready = listContacts.filter({contact in selectedContactsAlready.contains(where: {$0.mobile == contact.mobile})})
        let emailsAlready = listEmails.filter({email in selectedEmailsAlready.contains(where: {$0.email == email.email})})


        if editMode == .create {

            friendsAlready.forEach { (friend) in
                if friend.friendShipStatus == 1, friends.contains(where: {$0._id == friend._id}) == false {
                    friends.append(friend)
                }
            }

            contactsAlready.forEach { (contact) in
                if contact.friendShipStatus == 1, friends.contains(where: {$0.mobile == contact.mobile}) == false {
                    friends.append(contact)
                }
            }
            
            emailsAlready.forEach { (email) in
                if email.friendShipStatus == 1, friends.contains(where: {$0.email == email.email}) == false {
                    friends.append(email)
                }
            }
            
            countFriends = friends.count
            countContacts += contactsAlready.filter({$0.friendShipStatus != 1}).count
            countEmails += emailsAlready.filter({$0.friendShipStatus != 1}).count
        }else {
            let oriFriends = listFriends.filter({friend in selectedUsers?.contains(where: { $0.mobile == friend.mobile || $0.email == friend.email }) ?? false })
            let oriContacts = listContacts.filter({contact in contact.friendShipStatus != 1 && (selectedUsers?.contains(where: {$0.mobile == contact.mobile && $0.inviteType == .mobile}) ?? false) })
            let oriEmails = listEmails.filter({friend in friend.friendShipStatus != 1 && (selectedUsers?.contains(where: {$0.email == friend.email && $0.inviteType == .email}) ?? false) })

            countRemovedFriends = oriFriends.count - friendsAlready.count - contactsAlready.filter({$0.friendShipStatus == 1}).count - emailsAlready.filter({$0.friendShipStatus == 1}).count
            countRemovedContacts = oriContacts.count - contactsAlready.filter({$0.friendShipStatus != 1}).count
            countRemovedEmails = oriEmails.count - emailsAlready.filter({$0.friendShipStatus != 1}).count
        }
        
        
        return isRemoved == false ? (countFriends, countContacts, countEmails) : (countRemovedFriends, countRemovedContacts, countRemovedEmails)
    }
    
    func getCellStatus(_ userModel: UserModel?) -> UserInvitationCell.UserStatus {
        var result = UserInvitationCell.UserStatus()
        result.isSelected = getIsSelected(userModel)
        result.isGrayed = false
        result.isCrossed = false
        result.isTrash = false

        switch selectedType {
        case .friend :
            if editMode != .create {
                result.isGrayed = getIsSelected(userModel, isNew: false)
                result.isCrossed = result.isGrayed
                if result.isGrayed == true {
                    result.isSelected = nil
                }
            }
            break
        case .contact :
            result.isTrash = userModel?.inviteType == .mobile ? true : false
            if editMode != .create {
                result.isGrayed = getIsSelected(userModel, isNew: false)
                if result.isGrayed == true {
                    result.isSelected = nil
                    result.isCrossed = true
                    result.isTrash = false
                }
            }
            break
        case .email :
            result.isTrash = true
            if editMode != .create {
                result.isGrayed = getIsSelected(userModel, isNew: false)
                if result.isGrayed == true {
                    result.isSelected = nil
                    result.isCrossed = true
                    result.isTrash = false
                }
            }
            break
        case .link :
            break
        default :
            break

        }

        return result
    }
    
    func getIsSelected(_ userModel: UserModel?, isNew: Bool? = nil) -> Bool {
        var result = false
        switch selectedType {
        case .friend :
            result = getSelectedStatus(userModel, listNew: selectedFriendsNew, listAlready: selectedFriendsAlready, isNew: isNew)
            break
        case .contact :
            result = getSelectedStatus(userModel, listNew: selectedContactsNew, listAlready: selectedContactsAlready, isNew: isNew)
            break
        case .email :
            result = getSelectedStatus(userModel, listNew: selectedEmailsNew, listAlready: selectedEmailsAlready, isNew: isNew, userType: .email)
            break
        case .link :
            break
        default :
            break
        }
        
        return result
    }
    
    func getSelectedStatus(_ userModel: UserModel?, listNew: [UserModel], listAlready: [UserModel], isNew: Bool? = nil, userType: InviteType = .mobile) -> Bool {
        var result = false
        
        let new = listNew.contains { (item) -> Bool in
            switch userType {
            case .friend, .plansUser :
                return item._id == userModel?._id
            case .mobile :
                return item.mobile == userModel?.mobile
            case .email :
                return item.email?.lowercased() == userModel?.email?.lowercased()
            default :
                break
            }
            return false
        }
        
        let already = listAlready.contains { (item) -> Bool in
            switch userType {
            case .friend, .plansUser :
                return item._id == userModel?._id
            case .mobile :
                return item.mobile == userModel?.mobile
            case .email :
                return item.email?.lowercased() == userModel?.email?.lowercased()
            default :
                break
            }
            return false
        }
        
        if let isNew = isNew {
            if isNew == true {
                result = new
            }else {
                result = already
            }
        }else {
            result = new || already
        }
        
        return result
    }
    
    // MARK: - Friend List Methods
    func updateFriendList(list: [UserModel]?, isUpdateUI: Bool = true, complete: (() -> Void)? = nil) {
        guard let list = list else { return }
        listFriends = list
        reloadFriendList(isUpdateUI: isUpdateUI, complete: complete)
    }
    
    func reloadFriendList(isUpdateUI: Bool = true, complete: (() -> Void)? = nil) {
        // Sort Friend List
        sortFriendList()
        
        if isUpdateUI == true {
            // Filter by Search text
            filterFriendsBy(text: txtfSearch.text)
            
            // Update No List UI
            updateTableView()
            
            // Update Invitation View
            updateInviteView()
        }
        
        complete?()
    }
    
    // Sort by name and selected status
    func sortFriendList() {
        listFriends.sort(by: { (friend1, friend2) -> Bool in
            let already1 = selectedFriendsAlready.contains(where: {$0._id == friend1._id})
            let already2 = selectedFriendsAlready.contains(where: {$0._id == friend2._id})
            if already1 == true, already2 == false {
                return true
            }
            return false
        }, { (friend1, friend2) -> Bool in
            let new1 = selectedFriendsNew.contains(where: {$0._id == friend1._id})
            let new2 = selectedFriendsNew.contains(where: {$0._id == friend2._id})
            if new1 == true, new2 == false {
                return true
            }
            return false
        }) { (friend1, friend2) -> Bool in
            let name1 = friend1.name ?? "\(friend1.firstName ?? "") \(friend1.lastName ?? "")"
            let name2 = friend2.name ?? "\(friend2.firstName ?? "") \(friend2.lastName ?? "")"
            if name1 < name2 {
                return true
            }
            return false
        }
    }
    
    func filterFriendsBy (text: String?) {
        if let searchText = text?.trimmingCharacters(in: .whitespaces).lowercased(), searchText != "" {
            listSearched = listFriends.filter({ $0.name?.lowercased().contains(searchText) ?? false })
        }else {
            listSearched = listFriends
        }
    }
    
    // MARK: - Contacts Methods
    
    func fetchContacts(isUpdateUI: Bool = true, complete: (() -> Void)? = nil) {
        listContacts.removeAll()

        let mobileList = USER_MANAGER.mobileList.map({UserModel(mobile: $0)})
        listContacts.append(contentsOf: mobileList)
        
        CONTACT_MANAGER.fetchContactList{ (success, contacts) in
            var updateUI = isUpdateUI
            if success == true {
                contacts?.forEach { (contact) in
                    if contact.mobile != USER_MANAGER.mobile {
                        self.listContacts.removeAll(where: {$0.mobile == contact.mobile})
                        self.listContacts.append(contact)
                    }
                }
            }else {
                if isUpdateUI == true {
                    self.updateTableView(noAccessContacts: true)
                    updateUI = false
                }
            }
            self.getUsersWithMobiles(self.listContacts, isUpdateUI: updateUI, complete: complete)
        }
        
    }
    
    func updateContactsList(_ list: [UserModel]?, isUpdateUI: Bool = true, complete: (() -> Void)? = nil) {
        // Update Contacts list with Plans user info
        list?.forEach({ (user) in
            if let index = listContacts.firstIndex(where: {$0.mobile == user.mobile}) {
                if user._id != nil {
                    user.inviteType = listContacts[index].inviteType
                    listContacts.remove(at: index)
                    listContacts.insert(user, at: index)
                }else {
                    listContacts[index].invitedTime = user.invitedTime
                }
            }
        })
        
        reloadContacts(isUpdateUI: isUpdateUI, complete: complete)
    }
    
    func reloadContacts(isUpdateUI: Bool = true, complete: (() -> Void)? = nil) {
        // Sort Contact List
        sortContactList()
        
        if isUpdateUI == true {
            // Filter by Search text
            filterContactsBy(text: txtfSearch.text)
            
            // Update No List UI
            updateTableView()
            
            // Update Invitation View
            updateInviteView()
        }

        complete?()
    }
    
    // Sort by Selected status and Name according to Edit Mode.
    func sortContactList() {
        
        listContacts.sort(by: { (contact1, contact2) -> Bool in
            let already1 = selectedContactsAlready.contains(where: {$0.mobile == contact1.mobile})
            let already2 = selectedContactsAlready.contains(where: {$0.mobile == contact2.mobile})
            if already1 == true, already2 == false {
                return true
            }
            return false
        }, { (contact1, contact2) -> Bool in
            let new1 = selectedContactsNew.contains(where: {$0.mobile == contact1.mobile})
            let new2 = selectedContactsNew.contains(where: {$0.mobile == contact2.mobile})
            if new1 == true, new2 == false {
                return true
            }
            return false
        }, { (contact1, contact2) -> Bool in
            if contact1.inviteType == .mobile, contact2.inviteType == .contact {
                return true
            }
            return false
        }, { (contact1, contact2) -> Bool in
            if contact1._id != nil, contact2._id == nil {
                return true
            }
            return false
        }, { (contact1, contact2) -> Bool in
            var name1 = contact1.name ?? "\(contact1.firstName ?? "") \(contact1.lastName ?? "")"
            var name2 = contact2.name ?? "\(contact2.firstName ?? "") \(contact2.lastName ?? "")"
            if name1 == "" { name1 = contact1.mobile ?? "" }
            if name2 == "" { name2 = contact2.mobile ?? "" }

            if name1 < name2 {
                return true
            }
            return false
        });

    }
        
    func filterContactsBy (text: String?) {
        if let searchText = text?.trimmingCharacters(in: .whitespaces).lowercased(), searchText != "" {
            listSearched = listContacts.filter({ (contact) -> Bool in
                let name = (contact.name ?? "\(contact.firstName ?? "") \(contact.lastName ?? "")").lowercased()
                let mobile = contact.mobile ?? ""
                return name.contains(searchText) || mobile.contains(searchText)
            })
        }else {
            listSearched = listContacts
        }
    }
    
    func deleteContact(contact: UserModel?) {
        guard let contact = contact, let mobile = contact.mobile else { return }
        var mobileList = USER_MANAGER.mobileList
        mobileList.removeAll(where: {$0 == mobile})
        USER_MANAGER.mobileList = mobileList
        
        self.selectedContactsAlready.removeAll(where: {$0.mobile == mobile})
        self.selectedContactsNew.removeAll(where: {$0.mobile == mobile})
        self.listContacts.removeAll(where: {$0.mobile == mobile})

        self.reloadContacts()
        self.updateInviteView()
    }
    
    func addPhoneNumber() {
        let number = txtfAddPhoneNumber.text?.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "-", with: "") ?? ""
        let mobile = strCountryCode + number
        if mobile == USER_MANAGER.mobile {
            makeToast("This phone number is yours, it can't be added here.")
        }else if listContacts.contains(where: {$0.mobile == mobile}) == true {
            makeToast("This phone number has already been added.")
        }else{
            var mobiles = USER_MANAGER.mobileList
            mobiles.removeAll(where: {$0 == mobile})
            mobiles.append(mobile)
            USER_MANAGER.mobileList = mobiles
            txtfAddPhoneNumber.text = ""
            updateUI(selectedType)
        }
    }
    
    // MARK: - Emails Methods
    
    func fetchEmailList(isUpdateUI: Bool = true, complete: (() -> Void)? = nil) {
        listEmails.removeAll()
        
        let emailList = USER_MANAGER.emailList.map({UserModel(email: $0)})
        listEmails.append(contentsOf: emailList)
        getUsersWithEmails(listEmails, isUpdateUI: isUpdateUI, complete: complete)
    }
    
    func updateEmailList(_ list: [UserModel]?, isUpdateUI: Bool = true, complete: (() -> Void)? = nil) {
        // Update Contacts list with Plans user info
        list?.forEach({ (user) in
            if let index = listEmails.firstIndex(where: {$0.email?.lowercased() == user.email?.lowercased()}) {
                if user._id != nil {
                    user.inviteType = listEmails[index].inviteType
                    listEmails.remove(at: index)
                    listEmails.insert(user, at: index)
                }else {
                    listEmails[index].invitedTime = user.invitedTime
                }
            }
        })
        
        reloadEmailList(isUpdateUI: isUpdateUI, complete: complete)
    }
    
    func reloadEmailList(isUpdateUI: Bool = true, complete: (() -> Void)? = nil) {
        // Sort Contact List
        sortEmailList()
        
        if isUpdateUI == true {
            
            // Filter by Search text
            filterEmailListBy(text: txtfSearch.text)
            
            // Update No List UI
            updateTableView()
            
            // Update Invitation View
            updateInviteView()
        }

        complete?()
    }
    
    // Sort by Selected status and Name according to Edit Mode.
    func sortEmailList() {
        
        listEmails.sort(by: { (item1, item2) -> Bool in
            let already1 = selectedEmailsAlready.contains(where: {$0.email?.lowercased() == item1.email?.lowercased()})
            let already2 = selectedEmailsAlready.contains(where: {$0.email?.lowercased() == item2.email?.lowercased()})
            if already1 == true, already2 == false {
                return true
            }
            return false
        }, { (item1, item2) -> Bool in
            let new1 = selectedEmailsNew.contains(where: {$0.email?.lowercased() == item1.email?.lowercased()})
            let new2 = selectedEmailsNew.contains(where: {$0.email?.lowercased() == item2.email?.lowercased()})
            if new1 == true, new2 == false {
                return true
            }
            return false
        },  { (item1, item2) -> Bool in
            if item1._id != nil, item2._id == nil {
                return true
            }
            return false
        }, { (item1, item2) -> Bool in
            var name1 = item1.name ?? "\(item1.firstName ?? "") \(item1.lastName ?? "")"
            var name2 = item2.name ?? "\(item2.firstName ?? "") \(item2.lastName ?? "")"
            if name1 == "" { name1 = item1.email?.lowercased() ?? "" }
            if name2 == "" { name2 = item2.email?.lowercased() ?? "" }

            if name1 < name2 {
                return true
            }
            return false
        });

    }
        
    func filterEmailListBy (text: String?) {
        if let searchText = text?.trimmingCharacters(in: .whitespaces).lowercased(), searchText != "" {
            listSearched = listEmails.filter({ (user) -> Bool in
                let name = (user.name ?? "\(user.firstName ?? "") \(user.lastName ?? "")").lowercased()
                let email = user.email?.lowercased() ?? ""
                return name.contains(searchText) || email.contains(searchText)
            })
        }else {
            listSearched = listEmails
        }
    }
    
    func deleteEmail(email: UserModel?) {
        guard let email = email?.email?.lowercased() else { return }

        var emailList = USER_MANAGER.emailList
        emailList.removeAll(where: {$0.lowercased() == email})
        USER_MANAGER.emailList = emailList
        
        self.selectedEmailsAlready.removeAll(where: {$0.email?.lowercased() == email})
        self.selectedEmailsNew.removeAll(where: {$0.email?.lowercased() == email})
        self.listEmails.removeAll(where: {$0.email?.lowercased() == email})

        self.reloadEmailList()
        self.updateInviteView()
    }
    
    func addEmail() {
        guard let email = txtfAddEmail.text?.trimmingCharacters(in: .whitespaces), email != "" else { return }
        if email.lowercased() == USER_MANAGER.email?.lowercased() {
            makeToast("This email address is yours, it can't be added here.")
        }else if listEmails.contains(where: {$0.email?.lowercased() == email.lowercased()}) == true {
            makeToast("This email address has already been added.")
        }else{
            var emailList = USER_MANAGER.emailList
            emailList.removeAll(where: {$0.lowercased() == email.lowercased()})
            emailList.append(email)
            USER_MANAGER.emailList = emailList
            txtfAddEmail.text = ""
            updateUI(selectedType)
        }
    }



}

// MARK: - BackEnd APIs
extension EditInvitationVC {
    
    // MARK: - Invitation API
    
    func updateInvitationWithPeople(users: [UserModel]?, isShowLoader: Bool = true) {
        guard let eventId = activeEvent?._id else { return }
        
        if isShowLoader == true {
            showLoader()
        }

        let arrayDic = users?.map({$0.toJSON()}) ?? [[String: Any]]()

        let dict = ["people": arrayDic,
                    "eventId":  eventId] as [String : Any]
        
        EVENT_SERVICE.updateInvitationWithPeople(dict).done { (userResponse) -> Void in
            self.hideLoader()
            self.actionBack(self)
            self.delegate?.didSelectedUsers(users: users)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }

    // MARK: - Friends List API
    
    func hitFriendListAPI(isShowLoader: Bool = true, isUpdateUI: Bool = true, complete: (() -> Void)? = nil) {
        let dict = ["pageNo": 1,
                    "count": 100,
                    "keyword": "" ] as [String: Any]
        
        if isShowLoader == true {
            showLoader()
        }
        
        FRIENDS_SERVICE.hitFriendListApi(dict).done { (response) -> Void in
            self.hideLoader()
            self.updateFriendList(list: response, isUpdateUI: isUpdateUI, complete: complete)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
            complete?()
        }
    }
    
    // MARK: - Contacts List API
    
    // Get plans users with mobiles
    func getUsersWithMobiles(_ contacts: [UserModel]?, isUpdateUI: Bool = true, complete: (() -> Void)? = nil) {
        guard let contacts = contacts, contacts.count > 0 else {
            if isUpdateUI == true {
                updateTableView()
            }
            complete?()
            return
        }
        
        let mobiles : [String] = contacts.map ({ $0.mobile ?? ""})
        let dict = ["mobiles": mobiles] as [String: Any]

        showLoader()
        USER_SERVICE.hitPlansUsersWithMobilesApi(dict).done { (response) -> Void in
            self.hideLoader()
            self.updateContactsList(response, isUpdateUI: isUpdateUI, complete: complete)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
            complete?()
        }
    }
    
    // MARK: - Emails List API
    
    // Get plans users with mobiles
    func getUsersWithEmails(_ emails: [UserModel]?, isUpdateUI: Bool = true, complete: (() -> Void)? = nil) {
        guard let emails = emails, emails.count > 0 else {
            if isUpdateUI == true {
                updateTableView()
            }
            complete?()
            return
        }
        
        let list : [String] = emails.map ({ $0.email ?? ""})
        let dict = ["emails": list] as [String: Any]

        showLoader()
        USER_SERVICE.hitPlansUsersWithEmailsApi(dict).done { (response) -> Void in
            self.hideLoader()
            self.updateEmailList(response, isUpdateUI: isUpdateUI, complete: complete)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
            complete?()
        }
    }


}

// MARK: - PinCodeVCDelegate

extension EditInvitationVC: PinCodeVCDelegate {
    func didSelectedPinCode(dicPinCode: [String : Any]?) {
        guard let dict = dicPinCode else { return }
        if dict.count>0 {
            if let strName = dict["ISOCode"] as? String,
                let strCode = dict["CountryCode"] as? String,
                let Max_NSN = dict["Max_NSN"] as? Int,
                let Min_NSN = dict["Min_NSN"] as? Int
            {
                    maxLength = Max_NSN
                    minLength = Min_NSN
                    strISOCode = strName
                    strCountryCode = strCode
                    updateAddUI()
            }
        }

    }
}


// MARK: - UITextFieldDelegate

extension EditInvitationVC : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateAddUI(isEditing: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateAddUI(isEditing: false)
    }
    
    
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension EditInvitationVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UserInvitationCell.className, for: indexPath) as? UserInvitationCell else { return UITableViewCell() }
        let userModel = listItems[indexPath.row]
        cell.setupUI(userModel: userModel, itemType: selectedType, status: getCellStatus(userModel), delegate: self)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 61
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        view.endEditing(true)
        let userModel = listItems[indexPath.row]
        APP_MANAGER.pushUserProfileVC(userId: userModel._id ?? userModel.userId, sender: self)
    }

    
}

// MARK: - UserInvitationCellDelegate

extension EditInvitationVC : UserInvitationCellDelegate {
    func didTapProfileImage(userModel: UserModel?, cell: UITableViewCell) {
        gotoUser(userModel: userModel)
    }
    
    func didTapUnselectedMark(userModel: UserModel?, cell: UITableViewCell) {
        selectUser(userModel: userModel)
    }
    
    func didTapSelectedMark(userModel: UserModel?, cell: UITableViewCell) {
        unselectUser(userModel: userModel)
    }
    
    func didTapCrossMark(userModel: UserModel?, cell: UITableViewCell) {
        removeGuestFromEvent(user: userModel, nameAction: "uninvite") { (event) in
            if event != nil {
                self.cancelUser(userModel: userModel)
            }
        }
    }
    
    func didTapTrashMark(userModel: UserModel?, cell: UITableViewCell) {
        deleteUser(userModel: userModel)
    }
    
    func onItemMoveSelected(data: Any?, cell: UITableViewCell?) {
        userSelected = data as? UserModel
        positionSelected = listItems.firstIndex(where: {
            var result = false
            switch selectedType {
            case .friend:
                result = ($0._id ?? $0.userId) == (userSelected?._id ?? userSelected?.userId)
                break
            case .contact:
                result = $0.mobile == userSelected?.mobile
                break
            case .email:
                result = $0.email == userSelected?.email
                break
            default:
                break
            }
            return result
        })

    }
}

extension EditInvitationVC: OptionsMenuManagerDelegate {
    func didSelectedMenuItem(titleItem: String?, data: Any?) {
        switch titleItem {
        case "Delete Contact":
            deleteContact(contact: data as? UserModel)
            break
        case "Delete Email":
            deleteEmail(email: data as? UserModel)
            break
        default:
            break
        }

    }
}


