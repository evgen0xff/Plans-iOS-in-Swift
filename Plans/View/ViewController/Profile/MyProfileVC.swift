//
//  MyProfileVC.swift
//  Plans
//
//  Created by Star on 2/21/21.
//

import UIKit

class MyProfileVC: DashBoardBaseVC {
    
    // MARK: - IBOutlets
    
    // Top over header
    @IBOutlet weak var viewTopBar: UIView!
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var lblUserLocation: UILabel!

    // Top over Tabs
    @IBOutlet weak var viewTabs: UIView!
    @IBOutlet var collectItemBtns: [UIButton]!
    @IBOutlet var collectItemUnderLines: [UIView]!
    
    // User Profile Table View
    @IBOutlet weak var tblProfile: UITableView!
    
    // No Events View
    @IBOutlet var viewNoEvents: UIView!
    @IBOutlet var lblNoEvents: UILabel!
    
    // Create Event View
    @IBOutlet var viewCreateEvent: UIView!
    @IBOutlet weak var btnCreateEvent: UIButton!
    
    
    // MARK: - Properties
    override var screenName: String? { "MyProfile_Screen" }

    var pageNumber = 1
    var listEvents = [EventFeedModel]()
    var userDetails: UserModel?
    var selectedTab = UserProfileHeaderCell.TabType.organized
    var cellHeights = [IndexPath: CGFloat]()
    

    // MARK: - ViewController Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func initializeData() {
        super.initializeData()
    }
    
    override func setupUI() {
        super.setupUI()
        
        // Top Bar View
        updateTabItems(itemSelected: selectedTab)
        viewTopBar.addShadow()
        
        // Table View
        setupTableView()

        // Create Event View
        btnCreateEvent.layer.borderColor = AppColor.grey_button_border.cgColor
    }
    
    override func hideLoader() {
        super.hideLoader()
        tblProfile.switchRefreshHeader(to: .normal(.success, 0.0))
        tblProfile.switchRefreshFooter(to: .normal)
    }

    override func refreshAll(isShowLoader: Bool = false) {
        super.refreshAll(isShowLoader: isShowLoader)
        
        getProfile(isShowLoader: isShowLoader)
    }

    // MARK: - User Actions
    @IBAction func actionSettings(_ sender: Any) {
        APP_MANAGER.pushSettingsVC(userModel: userDetails, sender: self)
    }
    
    @IBAction func actionTabItems(_ sender: UIButton) {
        let type = UserProfileHeaderCell.TabType(rawValue: sender.tag) ?? .organized
        updateEventType(type: type)
    }
    
    @IBAction func actionCreateEvent(_ sender: Any) {
        APP_MANAGER.pushCreateEventVC(sender: self)
    }
    
    
    // MARK: - Set up view Methods
    private func setupTableView() {
        tblProfile.delegate = self
        tblProfile.dataSource = self
        refreshHeader.isUnderStatusBar = true
        
        tblProfile.configRefreshHeader(with: refreshHeader, container:self) { [weak self] in
            self?.refreshAll()
        }

        tblProfile.configRefreshFooter(with: refreshFooter, container:self) { [weak self] in
            if let this = self, this.listEvents.count % 10 == 0, this.listEvents.count > 0 {
                this.getNextPage()
            }else {
                APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 1) {
                    self?.hideLoader()
                }
            }
        }
        
        tblProfile.registerMultiple(nibs:[ UserProfileHeaderCell.className,
                                           HomeFeedCell.className,
                                           HomeFeedImageCell.className,
                                           PeopleTableCell.className,
                                           DateLocationCell.className,
                                           SearchEventCell.className])
    }
    
    
    private func updateProfile(_ userModel: UserModel) {
        self.userDetails = userModel
        USER_MANAGER.isPrivateAccount = userModel.isPrivateAccount ?? true
        
        // User Name
        lblUserName.text = "\(userModel.firstName ?? "")"
        lblUserName.text! += userModel.lastName != nil ? " \(userModel.lastName ?? "")" : ""
        USER_MANAGER.fullName = lblUserName.text
        
        // User Address
        lblUserLocation.isHidden = (userModel.location == nil || userModel.location == "") ? true : false
        lblUserLocation.text = userModel.location
        
        // User Coin
        APP_MANAGER.updateCoinNumber(new: userModel.coinNumber)
    }
    
    private func updateTabItems(itemSelected: UserProfileHeaderCell.TabType? = nil) {
        
        if let itemSelected = itemSelected {
            collectItemBtns.forEach { (item) in
                let color = item.tag == itemSelected.rawValue ? AppColor.purple_join : .black
                item.setTitleColor(color, for: .normal)
            }
            
            collectItemUnderLines.forEach { (item) in
                item.isHidden = item.tag == itemSelected.rawValue ? false : true
            }

        }
    }
    
    func updateEventType(type: UserProfileHeaderCell.TabType) {
        selectedTab = type
        updateTabItems(itemSelected: selectedTab)
        refreshAll(isShowLoader: true)
    }
    
    func updateData(list: [EventFeedModel]?, pageNumber: Int = 1, numberOfRowsInPage: Int = 10) {
        if pageNumber == 1 { listEvents.removeAll() }

        self.listEvents.replace(arrPage: list, pageNumber: pageNumber, numberOfRowsInPage: numberOfRowsInPage)
        tblProfile.reloadData()
        APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 0.3) {
            self.setupFooterView()
        }
    }
    
    func getNextPage(isShowLoader: Bool = false) {
        pageNumber = listEvents.count / 10 + ((listEvents.count % 10) > 0 ? 1 : 0) + 1
        hitEventListApi(isShow: isShowLoader, pageNumber: pageNumber)
    }
    
    func setupFooterView() {
        var footer : UIView? = nil
        if self.listEvents.count == 0 {
            footer = viewNoEvents
            switch selectedTab {
            case .organized :
                footer = viewCreateEvent
            case .attending :
                self.lblNoEvents.text = "Make Plans.\nJoin Friends."
            case .saved :
                self.lblNoEvents.text = "You have no saved events."
            }
        }
        addFooterView(footer)
    }
    
    // Empty View for organized events.
    func addFooterView(_ footer: UIView? = nil) {
        guard let footer = footer else {
            tblProfile.tableFooterView = nil
            return
        }
        var height = tblProfile.frame.size.height - (cellHeights[IndexPath(row: 0, section: 0)] ?? 400)
        var frame = footer.frame
        if height < 200 {
            height = 200
        }
        frame.size.height = height
        footer.frame = frame
        footer.sizeToFit()
        footer.layoutIfNeeded()
        tblProfile.tableFooterView = footer
    }
    
}


// MARK: - BackEnd APIs

extension MyProfileVC {
    func getProfile(isShowLoader: Bool = false) {
        guard let userID = USER_MANAGER.userId else {return}
        let dict = ["userId" : userID]
        if isShowLoader == true {
            showLoader()
        }
        USER_SERVICE.getUserProfileApi(dict).done { (response) -> Void in
            self.hideLoader()
            self.updateProfile(response)
            self.hitEventListApi(isShow: isShowLoader, pageNumber: 1, numberOfRows: self.pageNumber * 10)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
    
    func hitEventListApi(isShow: Bool = false,
                         pageNumber: Int = 1,
                         numberOfRows: Int = 10) {
        if isShow {
            self.showLoader()
        }
        
        let dictParam = ["pageNo" : pageNumber,
                         "count" : numberOfRows,
                         "keyword" : "",
                         "type" : selectedTab.keyValue] as [String : Any]
        EVENT_SERVICE.getEventListApi(dictParam).done { (userResponse) -> Void in
            self.hideLoader()
            self.updateData(list: userResponse, pageNumber: pageNumber, numberOfRowsInPage: numberOfRows)
            }.catch { (error) in
                self.hideLoader()
                POPUP_MANAGER.handleError(error)
        }
    }
    
}

// MARK: - UITableViewDataSource
extension MyProfileVC: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return listEvents.count + 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        switch section {
        case 0 :
            count = 1
            break
        default:
            if selectedTab == .saved {
                count = 1
            }else {
                if let number = listEvents[section - 1].invitationDetails?.count, number > 0 {
                    count = 4
                }else {
                    count = 3
                }
            }
            break
        }
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0 : return getUserProfileHeaderCell(indexPath, tableView: tableView)
        default:
            if selectedTab == .saved {
                return getSavedEventsCell(indexPath, tableView: tableView)
            } else {
                switch indexPath.row {
                    case 0: return homeFeedCell(indexPath, tableView: tableView)
                    case 1: return homeFeedImageCell(indexPath, tableView: tableView)
                    case 2:
                        if let count = listEvents[indexPath.section - 1].invitationDetails?.count, count > 0 {
                            return getPeopleCell(indexPath, tableView: tableView)
                        }else {
                            return getDateLocationCell(indexPath, tableView: tableView)
                        }
                    case 3: return getDateLocationCell(indexPath, tableView: tableView)
                    default:return UITableViewCell()
                }
            }
        }

    }
    
    private func getUserProfileHeaderCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UserProfileHeaderCell.className, for: indexPath) as? UserProfileHeaderCell else {
            return UITableViewCell()
        }
        cell.setupUI(user: userDetails, delegate: self, typeCell: .myProfile, selectedTab: selectedTab)
        return cell

    }
    
    private func homeFeedCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: HomeFeedCell.className, for: indexPath) as? HomeFeedCell else {
            return UITableViewCell()
        }
        cell.setupUI(eventModel: listEvents[indexPath.section - 1], delegate: self)
        return cell
    }
    
    private func homeFeedImageCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: HomeFeedImageCell.className, for: indexPath) as?  HomeFeedImageCell else {
            return UITableViewCell()
        }
        cell.configureHomeCell(eventModel: listEvents[indexPath.section - 1])
        return cell
    }
    
    private func getPeopleCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PeopleTableCell.className, for: indexPath) as? PeopleTableCell
            else {
                return UITableViewCell()
        }
        cell.setupUI(model: listEvents[indexPath.section - 1], delegate: nil, cellType: .homeFeed)
        return cell
    }
    
    private func getDateLocationCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DateLocationCell.className, for: indexPath) as? DateLocationCell else {
            return UITableViewCell()
        }
        cell.setupUI(eventModel: listEvents[indexPath.section - 1], cellType: .homeFeed)
        return cell
    }

    private func getSavedEventsCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchEventCell.className, for: indexPath) as? SearchEventCell else { return UITableViewCell() }
        cell.configureEventCell(eventFeed: listEvents[indexPath.section - 1], cellType: .saved)
        return cell
    }
}


// MARK: - UITableViewDelegate
extension MyProfileVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section != 0 {
            APP_MANAGER.pushEventDetailsVC(eventId: listEvents[indexPath.section - 1]._id, sender: self)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? HomeFeedImageCell {
            cell.viewVideoPlayer.pause()
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? UITableView.automaticDimension
    }

}

// MARK: - UIScroll View Delegate

extension MyProfileVC : UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView){
        let heightOverlay = (cellHeights[IndexPath(row: 0, section: 0)] ?? 320) - (UIDevice.current.heightTopNotch + 62 + viewTabs.bounds.height)
        
        if scrollView.contentOffset.y < 50 {
            viewTopBar.isHidden = true
            viewTabs.isHidden = true
        } else if scrollView.contentOffset.y <= heightOverlay {
            viewTopBar.isHidden = false
            viewTabs.isHidden = true
        } else {
            viewTopBar.isHidden = false
            viewTabs.isHidden = false
        }
    }
}

//MARK: - HomeFeedCellDelegate
extension MyProfileVC : HomeFeedCellDelegate {
    func didTappedJoin(isJoin: Bool, eventModel: EventFeedModel?) {
        if isJoin == true {
            joinEvent(model: eventModel)
        }else {
            unjoinEvent(model: eventModel)
        }
    }

    func didTappedProfile(eventModel: EventFeedModel?) {
        APP_MANAGER.pushUserProfileVC(userId: eventModel?.eventCreatedBy?.userId, sender: self)
    }
    
    func didTappedMore(eventModel: EventFeedModel?) {
        OPTIONS_MANAGER.showMenu(data: eventModel, menuType: .eventFeed, delegate: self, sender: self)
    }
}

// MAKR: UserProfileHeaderCellDelegate
extension MyProfileVC: UserProfileHeaderCellDelegate {
    func didSelect(titleItem: String?, user: UserModel?) {
        switch titleItem {
        case "Organized":
            updateEventType(type: .organized)
            break
        case "Attending":
            updateEventType(type: .attending)
            break
        case "Saved":
            updateEventType(type: .saved)
            break
        default:
            break
        }
    }
}

// MARK: - OptionsMenuManagerDelegate

extension MyProfileVC: OptionsMenuManagerDelegate {
    func didSelectedMenuItem(titleItem: String?, data: Any?) {
        guard let event = (data as? EventFeedModel), let titleAction = titleItem else { return }
        if processEventMenuAction(titleAction: titleAction, event: event) == false {
            print("Not handled Menu Action : ", titleAction)
        }
    }
}

