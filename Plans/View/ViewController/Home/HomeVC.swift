//
//  HomeVC.swift
//  Plans
//
//  Created by Plans Collective LLC on 4/27/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit

class HomeVC: DashBoardBaseVC {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var tblHome: UITableView!
    @IBOutlet weak var viewEmptyFeed: UIView!
    @IBOutlet weak var viewEmptyFeedTwo: UIView!
    @IBOutlet weak var btnFindFriends: UIButton!
    @IBOutlet weak var lblChatBadge: UILabel!
    @IBOutlet weak var contWidthChatBadge: NSLayoutConstraint!
    @IBOutlet weak var constMarginRightChatBtn: NSLayoutConstraint!
    
    // MARK: - Properties
    
    var arrEventList = [EventFeedModel]()
    var arrHiddenEvents = [EventFeedModel]()
    var isUpdatedLocation = false
    var pageNumber = 1
    var cellHeights = [IndexPath: CGFloat]()
    override var screenName: String? { "Home_Screen" }

    // MARK: - View Life Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NOTIFICATION_CENTER.addObserver(self, selector: #selector(pushNotification(notification:)), name: Notification.Name(kPushNotification_Show), object: nil)
        NOTIFICATION_CENTER.addObserver(self, selector: #selector(updateChats), name: Notification.Name(kRefreshBadges), object: nil)

        APP_MANAGER.updateBadges()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NOTIFICATION_CENTER.removeObserver(self, name: Notification.Name(kPushNotification_Show), object: nil)
        NOTIFICATION_CENTER.removeObserver(self, name: Notification.Name(kRefreshBadges), object: nil)
    }

    
    // MARK: - Overrided Methods for BaseViewController
    override func initializeData() {
        super.initializeData()

        isUpdatedLocation = false
        showLoader()
        LOCATION_MANAGER.startUpdatingLocation { (success) in
            self.isUpdatedLocation = true
            self.refreshAll()
        }
    }
    
    override func setupUI() {
        super.setupUI()
        
        // Table view
        setupTableView()

        // Empty View
        let swipeGesture1 = UISwipeGestureRecognizer(target: self, action: #selector(self.tapEmptyView(_:)))
        let swipeGesture2 = UISwipeGestureRecognizer(target: self, action: #selector(self.tapEmptyView(_:)))
        swipeGesture1.direction = .down
        swipeGesture2.direction = .down
        viewEmptyFeed.addGestureRecognizer(swipeGesture1)
        viewEmptyFeedTwo.addGestureRecognizer(swipeGesture2)
        btnFindFriends.layer.borderWidth = 1.0
        btnFindFriends.layer.borderColor = AppColor.grey_button.cgColor
        
        // Tutorial View
        setUpTutorial(isHidden: true)
    }
    
    override func hideLoader() {
        super.hideLoader()
        
        tblHome.switchRefreshHeader(to: .normal(.success, 0.0))
        tblHome.switchRefreshFooter(to: .normal)
    }
    
    override func refreshAll(isShowLoader: Bool = false) {
        super.refreshAll(isShowLoader: isShowLoader)
        
        guard isUpdatedLocation == true else { return }
        hitHiddenEventListApi(isShowLoader: isShowLoader) {
            self.hitEventListApi(isShowLoader: isShowLoader, pageNumber: 1, numberOfRows: self.pageNumber * 10)
        }
    }
    
    // MARK: - Private Methods
    
    func setUpTutorial (isHidden: Bool = false) {
        if isHidden == true || arrEventList.count > 0  {
            viewEmptyFeed.isHidden = true
            viewEmptyFeedTwo.isHidden = true
        }else if arrEventList.count == 0 {
            if let isFirstTym = USER_MANAGER.eventTutorial {
                if isFirstTym == 1 {
                    self.viewEmptyFeed.isHidden = true
                    self.viewEmptyFeedTwo.isHidden = false
                } else {
                    self.viewEmptyFeed.isHidden = false
                    self.viewEmptyFeedTwo.isHidden = true
                }
            } else {
                self.viewEmptyFeed.isHidden = true
                self.viewEmptyFeedTwo.isHidden = false
            }
        }

    }
    
    func setupTableView(){
        tblHome.registerMultiple(nibs: [HomeFeedCell.className,
                                        HomeFeedImageCell.className,
                                        PeopleTableCell.className,
                                        DateLocationCell.className,
                                        HiddenEventsCell.className])

        tblHome.delegate = self
        tblHome.dataSource = self
        
        tblHome.configRefreshHeader(with: refreshHeader, container:self) { [weak self] in
            self?.refreshAll()
        }
        
        tblHome.configRefreshFooter(with: refreshFooter, container:self) { [weak self] in
            if let this = self, this.arrEventList.count % 10 == 0, this.arrEventList.count > 0 {
                this.getNextPage()
            }else {
                APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 1) {
                    self?.hideLoader()
                }
            }
        }

    }

    func updateData(list: [EventFeedModel]?, pageNumber: Int = 1, numberOfRows: Int = 10) {
        guard let list = list else { return }
        
        if pageNumber == 1 { arrEventList.removeAll() }

        arrEventList.replace(arrPage: list, pageNumber: pageNumber, numberOfRowsInPage: numberOfRows)

        if let firstEvent = arrEventList.first,
            firstEvent.isLive == 1,
            firstEvent.isLiveUser(USER_MANAGER.userId) == true {
            APP_MANAGER.liveEvent = firstEvent
        } else {
            APP_MANAGER.liveEvent = nil
        }

        updateChats()
        tblHome.reloadData()
        setUpTutorial()
    }
    
    @objc
    func updateChats() {
        let count = USER_MANAGER.countUnviewedChatMsg
        
        if count > 0 {
            lblChatBadge.text = "\(count)"
            var width = (lblChatBadge.text?.width(withConstraintedHeight: 16.0, font: AppFont.regular.size(13.0)) ?? 0) + 8.0
            if width < 16.0 {
                width = 16.0
            }
            contWidthChatBadge.constant = width
            constMarginRightChatBtn.constant = 7
            lblChatBadge.isHidden = false
        }else {
            lblChatBadge.text = ""
            lblChatBadge.isHidden = true
            constMarginRightChatBtn.constant = 0
        }
    }
    
    @objc func pushNotification(notification: Notification?) {
        guard let userInfo = notification?.userInfo else { return }
        let pushNotify = NotificationActivityModel(dic: userInfo)
        
        if pushNotify.notificationType == "Private Message" || pushNotify.notificationType == "Event Chat" {
            APP_MANAGER.pushChatListVC(sender: self, notify: pushNotify)
        }
    }


    // MARK: - Notification Handlers
    
    @objc func applicationForeground(notification: Notification) {
        self.tblHome.reloadData()
    }

    // MARK: - User Actions
    
    @IBAction func actionCalenderBtn(_ sender: Any) {
        APP_MANAGER.pushCalendarVC(sender: self)
    }
    
    @IBAction func actionSearchBtn(_ sender: Any) {
        APP_MANAGER.pushSearchEvents(self)
    }
    
    @IBAction func actionChatBadge(_ sender: Any) {
        APP_MANAGER.pushChatListVC(sender: self)
    }
    
    @IBAction func actionFindFriends(_ sender: UIButton) {
        APP_MANAGER.pushAddFriendsVC(userId: USER_MANAGER.userId, sender: self)
    }
    
    @objc func tapEmptyView(_ sender: UISwipeGestureRecognizer) {
        if sender.direction == .down {
            if self.arrEventList.count == 0 {
                refreshAll(isShowLoader: true)
            } else {
                setUpTutorial()
            }
        }
    }
    
    @IBAction func actionHiddenEvents(_ sender: Any) {
        if arrHiddenEvents.count > 0 {
            APP_MANAGER.pushHiddenEvents()
        }
    }
    
}


// MARK: - Backend APIs

extension HomeVC {
    
    func getNextPage() {
        pageNumber = arrEventList.count / 10 + ((arrEventList.count % 10) > 0 ? 1 : 0) + 1
        hitEventListApi(pageNumber: pageNumber)
    }
    
    func hitEventListApi(isShowLoader: Bool = false, pageNumber : Int = 1, numberOfRows: Int = 10) {

        if isShowLoader {
            self.showLoader()
        }
        
        setUpTutorial(isHidden: true)
        
        let dictParam = ["pageNo" : pageNumber,
                         "count" : numberOfRows,
                         "keyword" : "",
                         "type" : "all"] as [String : Any]
        
        EVENT_SERVICE.getEventListApi(dictParam).done { (userResponse) -> Void in
            self.hideLoader()
            self.updateData(list: userResponse, pageNumber: pageNumber, numberOfRows: numberOfRows)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
    
    func hitHiddenEventListApi(isShowLoader: Bool = false, complete: (() -> Void)? = nil) {

        if isShowLoader {
            self.showLoader()
        }
        
        let dictParam = ["pageNo" : 1,
                         "count" : 1000,
                         "keyword" : "",
                         "type" : "hidden"] as [String : Any]
        
        EVENT_SERVICE.getEventListApi(dictParam).done { (userResponse) -> Void in
            self.hideLoader()
            self.arrHiddenEvents = userResponse
            complete?()
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }

}

// MARK: - UITableView Datasource

extension HomeVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return arrEventList.count + (arrHiddenEvents.count > 0 ? 1 : 0)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < arrEventList.count {
            if let count = arrEventList[section].invitationDetails?.count, count > 0 {
                return 4
            }else {
                return 3
            }
        }else if arrHiddenEvents.count > 0 {
            return 1
        }else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section < arrEventList.count {
            switch indexPath.row {
                case 0: return homeFeedCell(indexPath, tableView: tableView)
                case 1: return homeFeedImageCell(indexPath, tableView: tableView)
                case 2:
                    if let count = arrEventList[indexPath.section].invitationDetails?.count, count > 0 {
                        return getPeopleCell(indexPath, tableView: tableView)
                    }else {
                        return getDateLocationCell(indexPath, tableView: tableView)
                    }
                case 3: return getDateLocationCell(indexPath, tableView: tableView)
                default:return UITableViewCell()
            }
        }else if arrHiddenEvents.count > 0 {
            return hiddenEventCell(indexPath, tableView: tableView)
        }else {
            return UITableViewCell()
        }
    }

    private func hiddenEventCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: HiddenEventsCell.className, for: indexPath) as? HiddenEventsCell else {
            return UITableViewCell()
        }
        cell.setupUI(listHiddenEvents: arrHiddenEvents)
        return cell
    }
    
    private func homeFeedCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: HomeFeedCell.className, for: indexPath) as? HomeFeedCell else {
            return UITableViewCell()
        }
        if indexPath.section < arrEventList.count {
            cell.setupUI(eventModel: arrEventList[indexPath.section], delegate: self)
        }
        return cell
    }
    
    private func homeFeedImageCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: HomeFeedImageCell.className, for: indexPath) as?  HomeFeedImageCell else {
            return UITableViewCell()
        }
        cell.configureHomeCell(eventModel: arrEventList[indexPath.section])
        return cell
    }
    
    private func getPeopleCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PeopleTableCell.className, for: indexPath) as? PeopleTableCell
            else {
                return UITableViewCell()
        }
        cell.setupUI(model: arrEventList[indexPath.section], delegate: nil, cellType: .homeFeed)
        return cell
    }
    
    private func getDateLocationCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DateLocationCell.className, for: indexPath) as? DateLocationCell else {
            return UITableViewCell()
        }
        cell.setupUI(eventModel: arrEventList[indexPath.section], cellType: .homeFeed)
        return cell
    }
}



// MARK: - UITable View Delegate

extension HomeVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section < arrEventList.count {
            APP_MANAGER.pushEventDetailsVC(eventId: arrEventList[indexPath.section]._id, sender: self)
        }else if arrHiddenEvents.count > 0 {
            
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section < arrEventList.count {
            if let cell = tableView.cellForRow(at: indexPath) as? HomeFeedImageCell {
                cell.viewVideoPlayer.pause()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? UITableView.automaticDimension
    }
}


//MARK: - HomeFeedCellDelegate
extension HomeVC : HomeFeedCellDelegate {
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

// MARK: - OptionsMenuManagerDelegate

extension HomeVC: OptionsMenuManagerDelegate {
    func didSelectedMenuItem(titleItem: String?, data: Any?) {
        guard let event = (data as? EventFeedModel), let titleAction = titleItem else { return }
        if processEventMenuAction(titleAction: titleAction, event: event) == false {
            print("Not handled Menu Action : ", titleAction)
        }
    }
}







