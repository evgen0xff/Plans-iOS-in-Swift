//
//  NotificationListVC.swift
//  Plans
//
//  Created by Star on 2/24/21.
//

import UIKit

class NotificationListVC: DashBoardBaseVC {
    enum SectionType {
        case invitation
        case emptySpace
        case headerActivity
        case headerNew
        case listNew
        case listSeen
    }

    // MARK: - IBOutlets
    @IBOutlet weak var tblvNotifications: UITableView!
    @IBOutlet weak var viewNoActivites: UIView!
    
    // MARK: - Properties
    var cellHeights = [IndexPath: CGFloat]()
    var pageNumber = 1
    var sections = [SectionType]()

    // Notifications
    var notiModel: NotificationModel?

    // Activities
    var listActivites = [NotificationActivityModel]()
    var listActivitesNew = [NotificationActivityModel]()
    var listActivitesSeen = [NotificationActivityModel]()
    var indexPathFirstNotify: IndexPath? = nil
    var indexPathFirstEventImage: IndexPath? = nil
    
    override var screenName: String? { "Notifications_Screen" }

    
    // MARK: - ViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NOTIFICATION_CENTER.addObserver(self, selector: #selector(pushNotification(notification:)), name: Notification.Name(kPushNotification_Show), object: nil)

        APPLICATION.applicationIconBadgeNumber = 0
        USER_MANAGER.countUnviewedNotify = 0
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NOTIFICATION_CENTER.removeObserver(self, name: Notification.Name(kPushNotification_Show), object: nil)
 
        APPLICATION.applicationIconBadgeNumber = 0
        USER_MANAGER.countUnviewedNotify = 0
    }

    
    override func setupUI() {
        tblvNotifications.delegate = self
        tblvNotifications.dataSource = self
        tblvNotifications.registerMultiple(nibs: [InvitationRequestCell.className,
                                                  SectionHeaderCell.className,
                                                  NotificationCell.className])
        tblvNotifications.configRefreshHeader(with: refreshHeader, container:self) { [weak self] in
            self?.refreshAll()
        }
        
        tblvNotifications.configRefreshFooter(with: refreshFooter, container:self) { [weak self] in
            if let this = self, this.listActivites.count % 10 == 0, this.listActivites.count > 0 {
                this.getNextPage()
            }else {
                APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 1) {
                    self?.hideLoader()
                }
            }
        }

    }
    
    override func refreshAll(isShowLoader: Bool = false) {
        super.refreshAll(isShowLoader: isShowLoader)
        hitNotificaitonApi(isShowLoader: isShowLoader, pageNumber: 1, numberOfRows: self.pageNumber * 10)
    }
    
    override func hideLoader() {
        super.hideLoader()
        tblvNotifications.switchRefreshHeader(to: .normal(.success, 0.0))
        tblvNotifications.switchRefreshFooter(to: .normal)
    }

    // MARK: - Public Meothods
    @objc func pushNotification(notification: Notification?) {
        guard let userInfo = notification?.userInfo else { return }
        let pushNotify = NotificationActivityModel(dic: userInfo)
        
        if pushNotify.notificationType != "Private Message" && pushNotify.notificationType != "Event Chat" {
            pushNotification(pushNotify)
        }
    }

    public func pushNotification(_ notification: NotificationActivityModel?) {
        guard let notification = notification else { return }
        switch notification.notificationType {
        case "Update Event","Live", "End Event", "Invitation Sent", "Event Reminder":
            pushEventDetail(notification.eventId)
        case "Watch Live Moments":
            pushNotificationLiveMoment(notification)
        case "Comment", "Like", "Comment Like", "Post":
            pushPostDetail(notification.eventId, notification.postId)
        case "Friend Request":
            pushNotificationFriendsActivity()
        case "Friend Request Accepted":
            pushNotificationAcceptFriendActivity(notification.uid)
        case "Invitation Accepted", "Event Joined":
            pushNotificationAcceptEventIniviationActivity(notification.eventId)
        case "Coin":
            pushCoinVC()
        case "Event Deleted", "Event Cancelled", "Event Expired":
            if let uid = notification.uid, uid == USER_MANAGER.userId {
                pushEventDetail(notification.eventId)
            }
        default:
            pushEventDetail(notification.eventId)
            break
        }
    }

    
    // MARK: - Private Methods
    private func getNextPage() {
        pageNumber = listActivites.count / 10 + ((listActivites.count % 10) > 0 ? 1 : 0) + 1
        hitNotificaitonApi(pageNumber: pageNumber)
    }

    private func updateData(data: NotificationModel?, pageNumber: Int = 1, numberOfRows: Int = 10) {
        guard let data = data else { return }

        notiModel = data
        sections.removeAll()
        
        // Invitation Section
        if (data.eventInvitationCount ?? 0) + (data.friendRequestCount ?? 0) > 0 {
            sections.append(.invitation)
            sections.append(.emptySpace)
        }
        
        // Activity section
        listActivites.removeAll()
        if let list = data.listActivities, list.count > 0 {
            sections.append(.headerActivity)
            listActivites.append(contentsOf: list)
        }

        // New Section
        indexPathFirstNotify = nil
        indexPathFirstEventImage = nil
        listActivitesNew = listActivites.filter({$0.isNew == true})
        if listActivitesNew.count > 0 {
            sections.append(.headerNew)
            sections.append(.listNew)
            indexPathFirstNotify = IndexPath(row: 0, section: sections.count - 1)
            if let index = listActivitesNew.firstIndex(where: {$0.image != nil && !$0.image!.isEmpty}) {
                indexPathFirstEventImage = IndexPath(row: index, section: sections.count - 1)
            }
            sections.append(.emptySpace)
        }
        
        // Old Section
        listActivitesSeen = listActivites.filter({$0.isNew == false })
        if listActivitesSeen.count > 0 {
            sections.append(.listSeen)
            if indexPathFirstNotify == nil {
                indexPathFirstNotify = IndexPath(row: 0, section: sections.count - 1)
            }
            if indexPathFirstEventImage == nil, let index = listActivitesSeen.firstIndex(where: {$0.image != nil && !$0.image!.isEmpty}) {
                indexPathFirstEventImage = IndexPath(row: index, section: sections.count - 1)
            }
        }

        tblvNotifications.reloadData()
        updateNoActivities()
        updateLastViewTimeForNotify()
    }
    
    private func updateLastViewTimeForNotify(indexPath: IndexPath? = nil) {
        let time = Date().timeIntervalSince1970
        var isUpdate = false
        if let indexPath = indexPath {
            let section = getSectionInfo(indexSection: indexPath.section).section
            if section == .listSeen, indexPath.row == 0 {
                isUpdate = true
            }
        }else {
            USER_MANAGER.lastViewTimeForNotify = time
            if listActivitesSeen.isEmpty {
                isUpdate = true
            }
        }
        
        if isUpdate {
            USER_SERVICE.hitUpdateLastViewTimeForNotify(time).done { (user) in
                USER_MANAGER.lastViewTimeForNotify = time
            }.catch { _ in }
        }
    }
    
    private func updateNoActivities() {
        let count = listActivites.count + (notiModel?.eventInvitationCount ?? 0) + (notiModel?.friendRequestCount ?? 0)
        viewNoActivites.isHidden = count > 0
    }
    
    private func updateGuideViews(isNotifyGuide: Bool = false, isEventImageGuide: Bool = false) {
        
        if isNotifyGuide == true,
           let indexPath = indexPathFirstNotify,
           USER_MANAGER.isSeenGuideTapHoldNotification == false {
            USER_MANAGER.isSeenGuideTapHoldNotification = true
            tblvNotifications.reloadRows(at: [indexPath], with: .none)
        }
        
        if isEventImageGuide == true,
           let indexPath = indexPathFirstEventImage,
           USER_MANAGER.isSeenGuideTapViewEvent == false {
            USER_MANAGER.isSeenGuideTapViewEvent = true
            tblvNotifications.reloadRows(at: [indexPath], with: .none)
        }

    }
    
    private func getSectionInfo(indexSection: Int) -> (section: SectionType?, countRows: Int) {
        let section = indexSection < sections.count ? sections[indexSection] : nil
        
        var countRows = 0
        
        switch section {
        case .invitation,
             .emptySpace,
             .headerActivity,
             .headerNew:
            countRows = 1
        case .listNew:
            countRows = listActivitesNew.count
        case .listSeen:
            countRows = listActivitesSeen.count
        default:
            countRows = 0
        }
        
        return (section, countRows)
    }
    
    private func pushEventDetail(_ eventId: String?) -> Void {
        APP_MANAGER.pushEventDetailsVC(eventId: eventId, sender: self)
    }
    
    private func pushCoinVC() {
        APP_MANAGER.pushUserCoinVC(userId: USER_MANAGER.userId, sender: self)
    }
    
    private func pushPostDetail(_ eventId: String?, _ postId: String?) -> Void {
        APP_MANAGER.pushEventAndPostVC(eventId: eventId, postId: postId, sender: self)
    }
    
    private func pushNotificationFriendsActivity() -> Void {
        APP_MANAGER.pushFriendRequestsVC(self)
    }
    
    private func pushNotificationAcceptFriendActivity(_ userId: String?) -> Void {
        APP_MANAGER.pushUserProfileVC(userId: userId, sender: self)
    }
    
    private func pushNotificationEventsActivity() -> Void {
        APP_MANAGER.pushEventInvitationsVC(self)
    }
    
    private func pushNotificationAcceptEventIniviationActivity(_ eventId: String?) -> Void {
        APP_MANAGER.pushInvitedPeopleVC(eventId: eventId,
                                        sender: self)
    }
    
    private func pushNotificationLiveMoment(_ notify: NotificationActivityModel?) -> Void {
        if let eventId = notify?.eventId, let liveMomentId = notify?.liveMomentId {
            APP_MANAGER.pushWatchLiveMomentsVC(eventId: eventId,
                                               liveMomentId: liveMomentId,
                                               sender: self)
        }else if let eventId = notify?.eventId {
            APP_MANAGER.pushLiveMomentsVC(eventId: eventId, sender: self)
        }
    }
}

// MARK: - BackEnd APIs
extension NotificationListVC  {
    func hitNotificaitonApi(isShowLoader: Bool = false, pageNumber : Int = 1, numberOfRows: Int = 10) {
        let dict = ["pageNo": 1,
                    "count": pageNumber * numberOfRows]
        if isShowLoader == true {
            self.showLoader()
        }
        NOTIFI_SERVICE.notificationApi(dict).done { (response) -> Void in
            self.hideLoader()
            self.updateData(data: response, pageNumber: pageNumber, numberOfRows: numberOfRows)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }

    func deleteNotfication (notificaton: NotificationActivityModel?) {
        guard let model = notificaton, let _id = model._id else { return }
        
        let dict : [String: Any] = ["notificationId": _id]
        self.showLoader()
        
        NOTIFI_SERVICE.deleteApi(dict).done { (response) -> Void in
            self.hideLoader()
            self.refreshAll(isShowLoader: true)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }

}

// MARK: - UITableViewDataSource
extension NotificationListVC : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getSectionInfo(indexSection: section).countRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        let section = getSectionInfo(indexSection: indexPath.section).section
        switch section {
        case .invitation:
            cell = getInvitationRequestCell(tableView, cellForRowAt: indexPath)
        case .emptySpace:
            cell = getEmptyCell(tableView, cellForRowAt: indexPath)
        case .headerActivity:
            cell = getActivityHeaderCell(tableView, cellForRowAt: indexPath)
        case .headerNew:
            cell = getNewHeaderCell(tableView, cellForRowAt: indexPath)
        case .listNew, .listSeen:
            cell = getActivitiesCell(tableView, cellForRowAt: indexPath, typeSection: section)
        default:
            break
        }
        return cell ?? UITableViewCell()
    }
    
    func getInvitationRequestCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell? {
        let cell = tableView.dequeueReusableCell(withIdentifier: InvitationRequestCell.className, for: indexPath) as? InvitationRequestCell
        
        cell?.setupUI(notificationModel: notiModel)
        return cell
    }
    
    func getEmptyCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell? {
        let cell = tableView.dequeueReusableCell(withIdentifier: SectionHeaderCell.className, for: indexPath) as? SectionHeaderCell
        cell?.setupUI(cellType: .spaceEmpty)
        return cell
    }
    
    func getActivityHeaderCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell? {
        let cell = tableView.dequeueReusableCell(withIdentifier: SectionHeaderCell.className, for: indexPath) as? SectionHeaderCell
        cell?.setupUI(title: "Activity", cellType: .notiActivityHeader)
        return cell
    }
    
    func getNewHeaderCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell? {
        let cell = tableView.dequeueReusableCell(withIdentifier: SectionHeaderCell.className, for: indexPath) as? SectionHeaderCell
        cell?.setupUI(title: "New", cellType: .notiNewHeader)
        return cell
    }
    
    func getActivitiesCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, typeSection: SectionType?) -> UITableViewCell? {
        var notificationModel: NotificationActivityModel?
        var isLastItem = false
        if typeSection == .listNew {
            notificationModel = listActivitesNew[indexPath.row]
            isLastItem = indexPath.row == listActivitesNew.count - 1
        }else {
            notificationModel = listActivitesSeen[indexPath.row]
            isLastItem = indexPath.row == listActivitesSeen.count - 1
        }
        
        let dicUIConfi = [
            "isLast" : isLastItem,
            "isFirstNotify" : indexPathFirstNotify == indexPath,
            "isFirstEventImage" : indexPathFirstEventImage == indexPath
        ]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: NotificationCell.className, for: indexPath) as? NotificationCell
        cell?.configureCell(notificationModel: notificationModel, delegate: self, dicUIConfig: dicUIConfi)
        return cell
    }


}

// MARK: - UITableViewDelegate

extension NotificationListVC : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
        updateLastViewTimeForNotify(indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var notify: NotificationActivityModel? = nil
        let section = getSectionInfo(indexSection: indexPath.section)
        
        switch section.section {
        case .listNew:
            notify = listActivitesNew[indexPath.row]
            break
        case .listSeen:
            notify = listActivitesSeen[indexPath.row]
            break
        default:
            break
        }
        
        if let notify = notify {
            pushNotification(notify)
        }
    }

}

// MARK: - NotificationCellDelegate

extension NotificationListVC : NotificationCellDelegate {
    func didLongPressed(cellView: UITableViewCell, notification: NotificationActivityModel?) {
        updateGuideViews(isNotifyGuide: true)
        let list = ["Delete"]
        OPTIONS_MANAGER.showMenu(list: list, data: notification, delegate: self, sender: self)
    }
    
    func didClickedPhoto(cellView: UITableViewCell, notification: NotificationActivityModel?) {
        updateGuideViews(isEventImageGuide: true)
        APP_MANAGER.pushEventDetailsVC(eventId: notification?.eventId)
    }
}

extension NotificationListVC: OptionsMenuManagerDelegate {
    
    func didSelectedMenuItem(titleItem: String?, data: Any?) {
        guard let notiModel = data as? NotificationActivityModel else { return }
        
        switch titleItem {
        case "Delete":
            deleteNotfication(notificaton: notiModel)
            break
        default:
            break
        }
    }
}
