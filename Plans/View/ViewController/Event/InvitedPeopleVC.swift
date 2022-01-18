//
//  InvitedPeopleVC.swift
//  Plans
//
//  Created by Star on 7/10/20.
//  Copyright © 2020 Plans Collective. All rights reserved.
//

import UIKit

// Event invitation Type
enum JoinType: Int {
    case Invited    =   1
    case Going      =   2
    case Maybe      =   3
    case NextTime   =   4
    case Live       =   5
    case Attended   =   6 // Attended user = Host + Going + Maybe
    
    var title : String {
        switch self {
        case .Invited:
            return "Invited"
        case .Going:
            return "Going"
        case .Maybe:
            return "Maybe"
        case .NextTime:
            return "Next Time"
        case .Live:
            return "Live"
        case .Attended:
            return "Attended"
        }
    }
}


class InvitedPeopleVC: EventBaseVC {
    // MARK: - IBOutlets
    @IBOutlet weak var txtSearch: UITextField!
    @IBOutlet weak var viewSearch: UIView!
    @IBOutlet weak var colviewUserTypes: UICollectionView!
    @IBOutlet weak var tblUserList: UITableView!
    @IBOutlet weak var lblNoUserFound: UILabel!
    @IBOutlet weak var viewDescription: UIView!
    @IBOutlet weak var lblDescription: UILabel!
    
    // MARK: - Properties
    override var screenName: String? { "GuestList_Screen" }

    var userTypes: [JoinType] = [.Live, .Invited, .Going, .Maybe, .NextTime]
    var selectedType = JoinType.Invited
    var pageNumber = 1
    var invitedPeople = InvitedPeopleModel()
    var cellHeights = [IndexPath: CGFloat]()

    var listItems = [UserModel]()
    var userSelected: UserModel? = nil
    var positionSelected: Int? = nil
    var isAnimating = false

    
    // MARK: - ViewController Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    // MARK: - User Actions
    @IBAction func actionBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionSearchChanged(_ sender: UITextField) {
        self.refreshAll()
    }
    
    override func hideLoader() {
        super.hideLoader()
        tblUserList.switchRefreshHeader(to: .normal(.success, 0.0))
        tblUserList.switchRefreshFooter(to: .normal)
    }
    
    override func initialize() {
        setupUI()
        initializeData()
    }

    override func initializeData() {
        super.initializeData()

        if let eventModel = activeEvent {
            updateByEvent(eventModel: eventModel)
        }else {
            showLoader()
            getEventDetails(eventID) { (sucess, eventModel) in
                self.hideLoader()
                self.updateByEvent(eventModel: eventModel)
                self.refreshAll(isShowLoader: true)
            }
        }
    }

    override func setupUI() {
        super.setupUI()
        setupSearchView()
        setupUserTypesView()
        setupUserListView()
    }

    override func refreshAll(isShowLoader: Bool = false) {
        getPeopleList(isShowLoader: isShowLoader, pageNumber: 1, numberOfRows: pageNumber * 20)
    }
    
    // MARK: - Private Methods
    
    func updateByEvent(eventModel: EventFeedModel?) {
        guard let event = eventModel else { return }
        if event.isExistLiveGuest() == true {
            self.selectedType = .Live
        }else if event.isExistAcceptGuest() == true {
            self.selectedType = .Going
        }else {
            self.selectedType = .Invited
        }
        self.updateUserTypesView()
    }
    
    func setupSearchView() {
        txtSearch.attributedPlaceholder = NSAttributedString(string: "Search",
                                                               attributes: [NSAttributedString.Key.foregroundColor: AppColor.whiteOpacity60])
        txtSearch.delegate = self
    }
    
    func setupUserTypesView() {
        colviewUserTypes.register(UINib(nibName: TabItemCell.className, bundle: nil), forCellWithReuseIdentifier: TabItemCell.className)
        colviewUserTypes.dataSource = self
        colviewUserTypes.delegate = self
    }
    
    func updateUserTypesView() {
        if let index = userTypes.firstIndex(of: selectedType) {
            let indexpath = IndexPath(item: index, section: 0)
            colviewUserTypes.scrollToItem(at: indexpath, at: .centeredHorizontally, animated: true)
        }
        colviewUserTypes.reloadData()
    }
    
    func setupUserListView() {
        tblUserList.register(nib: UserTableCell.className)
        tblUserList.dataSource = self
        tblUserList.delegate = self
        tblUserList.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)

        
        tblUserList.configRefreshHeader(with: refreshHeader, container:self) { [weak self] in
            self?.refreshAll()
        }
        
        tblUserList.configRefreshFooter(with: refreshFooter, container:self) { [weak self] in
            if let this = self, this.invitedPeople.people.count % 10 == 0, this.invitedPeople.people.count > 0 {
                this.getNextPage()
            }else {
                APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 1) {
                    self?.hideLoader()
                }
            }
        }

    }
    
    func updateData(data: InvitedPeopleModel, pageNumber: Int = 1, numberOfRowsInPage: Int = 20) {
        invitedPeople.counts = data.counts
        invitedPeople.eventData = data.eventData

        if pageNumber == 1 { invitedPeople.people.removeAll() }
        invitedPeople.people.replace(arrPage: data.people, pageNumber: pageNumber, numberOfRowsInPage: numberOfRowsInPage)

        colviewUserTypes.reloadData()
        
        if userSelected != nil, positionSelected != nil {
            moveSelectedItem()
        }else {
            updateAll()
        }

    }
    
    func moveSelectedItem() {
        if !isAnimating, let toPosition = invitedPeople.people.firstIndex(where: { ($0._id ?? $0.userId) == (userSelected?._id ?? userSelected?.userId)}) {
            if let positionSelected = positionSelected, toPosition != positionSelected {
                
                isAnimating = true
                let newItem = invitedPeople.people[toPosition]
                listItems[positionSelected] = newItem
                tblUserList.reloadRows(at: [IndexPath(row: positionSelected, section: 0)], with: .none)
                
                APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 0.3) {
                    if self.isAnimating {
                        self.listItems.remove(at: positionSelected)
                        let newPosition = min(self.listItems.count, toPosition)
                        self.listItems.insert(newItem, at: newPosition)
                        
                        self.tblUserList.beginUpdates()
                        self.tblUserList.moveRow(at: IndexPath(row: positionSelected, section: 0),
                                                to: IndexPath(row: newPosition, section: 0))
                        self.tblUserList.endUpdates()
                        
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
        
        listItems.removeAll()
        listItems.append(contentsOf: invitedPeople.people)

        tblUserList.reloadData()
        updateDescriptionUI()
        updateNoUserFound()
    }

    
    func getNextPage(isShowLoader: Bool = false) {
        pageNumber = invitedPeople.people.count / 10 + ((invitedPeople.people.count % 10) > 0 ? 1 : 0) + 1
        getPeopleList(isShowLoader: isShowLoader, pageNumber: pageNumber)
    }
    
    func getCountFor(type: JoinType) -> Int {
        var count : Int = 0
        switch type  {
        case .Invited :
            count = invitedPeople.counts.invitedCnt
        case .Going :
            count = invitedPeople.counts.goingCnt
        case .Maybe :
            count = invitedPeople.counts.maybeCnt
        case .NextTime :
            count = invitedPeople.counts.nextTimeCnt
        case .Live :
            count = invitedPeople.counts.liveCnt
        default :
            break
        }
        return count
    }
    
    
    func updateNoUserFound() {
        if invitedPeople.people.count == 0 {
            lblNoUserFound.isHidden = false
            switch selectedType {
            case .Live :
                lblNoUserFound.text = "No live friends"
                break
            case .Invited :
                lblNoUserFound.text = "No invited friends"
                break
            case .Going :
                lblNoUserFound.text = "No friends responded"
                break
            case .Maybe :
                lblNoUserFound.text = "No friends responded"
                break
            case .NextTime :
                lblNoUserFound.text = "No friends responded"
                break
            default :
                break
            }
        }else {
            lblNoUserFound.isHidden = true
        }
    }
    
    func updateDescriptionUI() {
        if invitedPeople.eventData?.userId == USER_MANAGER.userId {
            var invitedMobiles = invitedPeople.eventData?.invitedPeople?.filter({$0.inviteType == .mobile})
            var invitedEmails = invitedPeople.eventData?.invitedPeople?.filter({$0.inviteType == .email})
            let countLinksInvited = invitedPeople.eventData?.invitationDetails?.filter({$0.invitedType == .link}).count ?? 0
            invitedPeople.eventData?.invitationDetails?.forEach({ (user) in
                invitedMobiles?.removeAll(where: {$0.mobile == user.mobile})
                invitedEmails?.removeAll(where: {$0.email?.lowercased() == user.email?.lowercased()})
            })
            
            if let attrStr = getAttriString(emails: invitedEmails?.count ?? 0, mobiles: invitedMobiles?.count ?? 0, links: countLinksInvited) {
                lblDescription.attributedText = attrStr
                viewDescription.isHidden = false
            }else {
                viewDescription.isHidden = true
            }
            
        }else {
            viewDescription.isHidden = true
        }
    }
    
    // MARK: - Backend APIs
    func getPeopleList(isShowLoader: Bool = true, pageNumber: Int = 1, numberOfRows: Int = 20) {
        guard let eventId = activeEvent?._id else { return }

        let dictParam = ["pageNo": pageNumber,
                         "count": numberOfRows,
                         "status": selectedType.rawValue,
                         "keyword": txtSearch.text ?? "",
                         "eventId": eventId] as [String: Any]
        
        if isShowLoader == true { showLoader() }
        EVENT_SERVICE.getInvitationListApi(dictParam).done { (response) -> Void in
            self.hideLoader()
            self.updateData(data: response, pageNumber: pageNumber, numberOfRowsInPage: numberOfRows)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
    
    
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension InvitedPeopleVC : UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userTypes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TabItemCell.className, for: indexPath) as? TabItemCell else { return UICollectionViewCell() }
        
        let type = userTypes[indexPath.row]
        let count = getCountFor(type: type)
        cell.eventTypeName.text = type.title
        if count > 0 {
            cell.eventTypeName.text! += " (\(count))"
        }
        if type == selectedType {
            cell.colorLbl.backgroundColor = UIColor.white
        }else{
            cell.colorLbl.backgroundColor = UIColor.clear
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize{
        let type = userTypes[indexPath.row]
        let count = getCountFor(type: type)
        var title = type.title
        if count > 0 {
            title += " (\(count))"
        }
        let width = title.width(withConstraintedHeight: 50, font: AppFont.regular.size(17))
        return CGSize(width: width + 40, height: 38)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let type = userTypes[indexPath.row]
        if selectedType != type {
            selectedType = type
            pageNumber = 1
            collectionView.reloadData()
            self.refreshAll(isShowLoader: true)
        }
    }
    
}

// MARK: - UITextFieldDelegate
extension InvitedPeopleVC : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        self.refreshAll(isShowLoader: true)
        return true
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension InvitedPeopleVC : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UserTableCell.className, for: indexPath) as? UserTableCell else { return UITableViewCell() }
        let canDelete = invitedPeople.eventData?.userId == USER_MANAGER.userId
        cell.setupUI(model: listItems[indexPath.row], delegate: self, cellType: .invitedPeople, canDelete: canDelete, eventModel: activeEvent)

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 61
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        APP_MANAGER.pushUserProfileVC(userId: listItems[indexPath.row]._id, sender: self)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? UITableView.automaticDimension
    }
    
}

// MARK: - UserTableCellDelegate
extension InvitedPeopleVC : UserTableCellDelegate {
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
    
    func tappedChat(user: UserModel?, cell: UITableViewCell?) {
        APP_MANAGER.pushChatMessageVC(otherUser: user,
                                      sender: self)

    }
    
    func tappedMoreMenu(user: UserModel?, cell: UITableViewCell?) {
        let list = ["Remove Guest"]
        OPTIONS_MANAGER.showMenu(list: list, data: user, delegate: self, sender: self)
    }
    
    func onItemMoveSelected(data: Any?, cell: UITableViewCell?) {
        userSelected = data as? UserModel
        positionSelected = listItems.firstIndex(where: { ($0._id ?? $0.userId) == (userSelected?._id ?? userSelected?.userId)})
    }

    
}

extension InvitedPeopleVC : OptionsMenuManagerDelegate {
    func didSelectedMenuItem(titleItem: String?, data: Any?) {
        switch titleItem {
        case "Remove Guest":
            self.removeGuestFromEvent(user: data as? UserModel)
            break
        default:
            break
        }
    }
}


