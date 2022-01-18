//
//  BlockedUserVC.swift
//  Plans
//
//  Created by Star on 2/23/21.
//

import UIKit
import PromiseKit

class BlockedUserVC: UserBaseVC {

    // MARK: - All IBOutlet
    
    @IBOutlet weak var blockedUserTblVw: UITableView!
    @IBOutlet weak var noBlockLbl: UILabel!

    // MARK: - All Propertise
    var cellHeights = [IndexPath: CGFloat]()
    var blockList = [UserModel]()
    var pageNumber = 1
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func setupUI() {
        super.setupUI()
        
        blockedUserTblVw.delegate = self
        blockedUserTblVw.dataSource = self
        blockedUserTblVw.register(nib: UserTableCell.className)

        blockedUserTblVw.configRefreshHeader(with: refreshHeader, container:self) { [weak self] in
            self?.refreshAll()
        }
        
        blockedUserTblVw.configRefreshFooter(with: refreshFooter, container:self) { [weak self] in
            if let this = self, this.blockList.count % 10 == 0, this.blockList.count > 0 {
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
        hitBlockApiMehtod(isShowLoader: isShowLoader, pageNumber: 1, numberOfRows: self.pageNumber * 10)
    }

    override func hideLoader() {
        super.hideLoader()
        blockedUserTblVw.switchRefreshHeader(to: .normal(.success, 0.0))
        blockedUserTblVw.switchRefreshFooter(to: .normal)
    }

    // MARK: - User Actions
    @IBAction func actionBackBtn(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Private Methods
    func getNextPage() {
        pageNumber = blockList.count / 10 + ((blockList.count % 10) > 0 ? 1 : 0) + 1
        hitBlockApiMehtod(pageNumber: pageNumber)
    }
    
    func updateData(list: [UserModel]?, pageNumber: Int = 1, numberOfRows: Int = 10) {
        guard let list = list else { return }
        
        if pageNumber == 1 { blockList.removeAll() }

        blockList.replace(arrPage: list, pageNumber: pageNumber, numberOfRowsInPage: numberOfRows)
        blockedUserTblVw.reloadData()
        
        noBlockLbl.isHidden = blockList.count != 0
    }

}

// MARK: - Api Methods

extension BlockedUserVC {
    
    // MARK: - Block user request
    internal func hitBlockApiMehtod(isShowLoader: Bool = false, pageNumber : Int = 1, numberOfRows: Int = 10) {
        let dict = ["pageNo": pageNumber,
                    "count": numberOfRows]
        if isShowLoader {
            self.showLoader()
        }
        FRIENDS_SERVICE.listBlockRequestApi(dict).done { (response) -> Void in
            self.hideLoader()
            self.updateData(list: response, pageNumber: pageNumber, numberOfRows: numberOfRows)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }

}

// MARK: - UITableViewDataSource

extension BlockedUserVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return getBlockedUserCell(indexPath, tableView: tableView)
    }
    
    func getBlockedUserCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UserTableCell.className, for: indexPath) as? UserTableCell else {
            fatalError("Unexpected index path")
        }
        cell.setupUI(model: blockList[indexPath.row], delegate: self, cellType: .plansUser)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension BlockedUserVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 61
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        APP_MANAGER.pushUserProfileVC(userId: blockList[indexPath.row]._id, sender: self)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? UITableView.automaticDimension
    }

}

// MARK: - UserTableCellDelegate

extension BlockedUserVC : UserTableCellDelegate {
    func tappedFriend(user: UserModel?, cell: UITableViewCell?) {
        if let friendShipStatus = user?.friendShipStatus {
            if friendShipStatus == 5 {
                unblockUser(user)
            }
        }
    }
}

