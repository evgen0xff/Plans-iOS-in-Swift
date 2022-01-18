//
//  HiddenEventsVC.swift
//  Plans
//
//  Created by Star on 3/22/21.
//

import UIKit

class HiddenEventsVC: PlansContentBaseVC {

    // MARK: - IBOutlets
    @IBOutlet weak var tblvEventList: UITableView!
    
    // MARK: - Properties
    var cellHeights = [IndexPath: CGFloat]()
    var arrEventList = [EventFeedModel]()
    var pageNumber = 1

    // MARK: - ViewController Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func hideLoader() {
        super.hideLoader()
        tblvEventList.switchRefreshFooter(to: .normal)
    }

    override func setupUI() {
        super.setupUI()
        
        // Table view
        tblvEventList.registerMultiple(nibs: [HomeFeedCell.className,
                                        HomeFeedImageCell.className,
                                        PeopleTableCell.className,
                                        DateLocationCell.className,
                                        HiddenEventsCell.className])

        tblvEventList.delegate = self
        tblvEventList.dataSource = self
        
        tblvEventList.configRefreshFooter(with: refreshFooter, container:self) { [weak self] in
            if let this = self, this.arrEventList.count % 10 == 0, this.arrEventList.count > 0 {
                this.getNextPage()
            }else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self?.hideLoader()
                }
            }
        }

    }
    
    override func refreshAll(isShowLoader: Bool = false) {
        super.refreshAll(isShowLoader: isShowLoader)
        hitHiddenEventListApi(isShowLoader: isShowLoader, pageNumber: 1, numberOfRows: pageNumber * 10)

    }
    
    // MARK: - User Action Handlers
    @IBAction func actionBackBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Private Methods
    
    func updateData(list: [EventFeedModel]?, pageNumber: Int = 1, numberOfRows: Int = 10) {
        
        guard let list = list else { return }
        
        if pageNumber == 1 { arrEventList.removeAll() }

        arrEventList.replace(arrPage: list, pageNumber: pageNumber, numberOfRowsInPage: numberOfRows)

        tblvEventList.reloadData()
    }

    
    func getNextPage() {
        pageNumber = arrEventList.count / 10 + ((arrEventList.count % 10) > 0 ? 1 : 0) + 1
        hitHiddenEventListApi(pageNumber: pageNumber)
    }

    // MARK: - Backend APIs
    func hitHiddenEventListApi(isShowLoader: Bool = false, pageNumber : Int = 1, numberOfRows: Int = 10) {

        if isShowLoader {
            self.showLoader()
        }
        
        let dictParam = ["pageNo" : pageNumber,
                         "count" : numberOfRows,
                         "keyword" : "",
                         "type" : "hidden"] as [String : Any]
        
        EVENT_SERVICE.getEventListApi(dictParam).done { (userResponse) -> Void in
            self.hideLoader()
            self.updateData(list: userResponse, pageNumber: pageNumber, numberOfRows: numberOfRows)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
    
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension HiddenEventsVC : UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return arrEventList.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = arrEventList[section].invitationDetails?.count, count > 0 {
            return 4
        }else {
            return 3
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        APP_MANAGER.pushEventDetailsVC(eventId: arrEventList[indexPath.section]._id, sender: self)
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

// MARK: - HomeFeedCellDelegate

extension HiddenEventsVC : HomeFeedCellDelegate {
    func didTappedJoin(isJoin: Bool, sender: HomeFeedCell, eventModel: EventFeedModel?) {
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

extension HiddenEventsVC: OptionsMenuManagerDelegate {
    func didSelectedMenuItem(titleItem: String?, data: Any?) {
        guard let event = (data as? EventFeedModel), let titleAction = titleItem else { return }
        if processEventMenuAction(titleAction: titleAction, event: event) == false {
            print("Not handled Menu Action : ", titleAction)
        }
    }
}
