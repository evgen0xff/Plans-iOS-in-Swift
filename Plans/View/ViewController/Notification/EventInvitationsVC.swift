//
//  EventInvitationsVC.swift
//  Plans
//
//  Created by Star on 2/27/21.
//

import UIKit

class EventInvitationsVC: PlansContentBaseVC {

    // MARK: - IBOutlets
    
    @IBOutlet weak var tblEventInvitation: UITableView!
    @IBOutlet weak var lblNoInvite: UILabel!
    
    // MARK: - Properties
    
    var listInvites = [EventFeedModel]()
    var pageNumber = 1
    var cellHeights = [IndexPath: CGFloat]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func setupUI() {
        super.setupUI()
        setupTableView()
    }
    
    override func refreshAll(isShowLoader: Bool = false) {
        super.refreshAll(isShowLoader: isShowLoader)
        getInvitationList(isShowLoader: isShowLoader, pageNumber: 1, numberOfRows: pageNumber * 10)
    }
    
    override func hideLoader() {
        super.hideLoader()
        tblEventInvitation.switchRefreshHeader(to: .normal(.success, 0.0))
        tblEventInvitation.switchRefreshFooter(to: .normal)
    }
    
    // MARK: - User Actions

    @IBAction func actionBackBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Private Methods
    
    private func setupTableView() {
        tblEventInvitation.delegate = self
        tblEventInvitation.dataSource = self
        tblEventInvitation.registerMultiple(nibs: [EventInvitationCell.className])

        tblEventInvitation.configRefreshHeader(with: refreshHeader, container:self) { [weak self] in
            self?.refreshAll()
        }
        
        tblEventInvitation.configRefreshFooter(with: refreshFooter, container:self) { [weak self] in
            if let this = self, this.listInvites.count % 10 == 0, this.listInvites.count > 0 {
                this.getNextPage()
            }else {
                APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 1) {
                    self?.hideLoader()
                }
            }
        }
    }
    
    func getNextPage() {
        pageNumber = listInvites.count / 10 + ((listInvites.count % 10) > 0 ? 1 : 0) + 1
        getInvitationList(pageNumber: pageNumber)
    }

    func updateData(list: [EventFeedModel]?, pageNumber: Int = 1, numberOfRows: Int = 10) {
        guard let list = list else { return }
        
        if pageNumber == 1 { listInvites.removeAll() }

        listInvites.replace(arrPage: list, pageNumber: pageNumber, numberOfRowsInPage: numberOfRows)
        tblEventInvitation.reloadData()
        
        lblNoInvite.isHidden = listInvites.count > 0
    }

    
}

// MARK: - Hit api method

extension EventInvitationsVC {
    
    // Get event Invitation List
    func getInvitationList(isShowLoader: Bool = false, pageNumber : Int = 1, numberOfRows: Int = 10) {
        
        let dictParam = ["pageNo" : pageNumber,
                         "count" : numberOfRows,
                         "lat" : "",
                         "long" : "",
                         "keyword" : "",
                         "type" : "invitation"] as [String : Any]
        
        if isShowLoader == true {
            showLoader()
        }

        EVENT_SERVICE.getEventListApi(dictParam).done { (response) -> Void in
            self.hideLoader()
            self.updateData(list: response, pageNumber: pageNumber, numberOfRows: numberOfRows)
            }.catch { (error) in
                self.hideLoader()
                POPUP_MANAGER.handleError(error)
        }
    }
    
}


extension EventInvitationsVC: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listInvites.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: EventInvitationCell.className, for: indexPath) as? EventInvitationCell
        cell?.configureCell(feedModel: listInvites[indexPath.row], delegate: self)
        return cell ?? UITableViewCell()
    }
}

extension EventInvitationsVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        APP_MANAGER.pushEventDetailsVC(event: listInvites[indexPath.row], sender: self)
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

// MARK: - EventTableCellDelegate
extension EventInvitationsVC : EventTableCellDelegate {
    func didTapHostProfile(sender: UITableViewCell, eventModel: EventFeedModel?) {
        APP_MANAGER.pushUserProfileVC(userId: eventModel?.eventCreatedBy?.userId, sender: self)
    }
    
    func didTapEventDetail(sender: UITableViewCell, eventModel: EventFeedModel?) {
        APP_MANAGER.pushEventDetailsVC(event: eventModel, sender: self)
    }
    
    func didTapGoingMaybeNextTime(sender: UITableViewCell, eventModel: EventFeedModel?, status: JoinType) {
        goingMaybeNextTime(model: eventModel, status: status.rawValue)
    }
    
    func didTapHide(sender: UITableViewCell, eventModel: EventFeedModel?) {
        
    }
}
