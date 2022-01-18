//
//  FriendRequestsVC.swift
//  Plans
//
//  Created by Star on 2/27/21.
//

import UIKit

class FriendRequestsVC: PlansContentBaseVC {
    
    // MARK: - IBOutlets
    @IBOutlet weak var tblFriendRequest: UITableView!
    @IBOutlet weak var lblNoRequests: UILabel!
    
    // MARK: - Property
    var pageNumber = 1
    var listRequests = [UserModel]()
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
        friendListApiMethod(isShowLoader: isShowLoader, pageNumber: 1, numberOfRows: pageNumber * 10)
    }
    
    override func hideLoader() {
        super.hideLoader()
        tblFriendRequest.switchRefreshHeader(to: .normal(.success, 0.0))
        tblFriendRequest.switchRefreshFooter(to: .normal)
    }

    // MARK: - User Actions
    @IBAction func actionBackBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Private Methods
    private func setupTableView() {
        
        tblFriendRequest.delegate = self
        tblFriendRequest.dataSource = self
        tblFriendRequest.registerMultiple(nibs: [FriendRequestCell.className])
        
        tblFriendRequest.configRefreshHeader(with: refreshHeader, container:self) { [weak self] in
            self?.refreshAll()
        }
        
        tblFriendRequest.configRefreshFooter(with: refreshFooter, container:self) { [weak self] in
            if let this = self, this.listRequests.count % 10 == 0, this.listRequests.count > 0 {
                this.getNextPage()
            }else {
                APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 1) {
                    self?.hideLoader()
                }
            }
        }

    }
    
    func getNextPage() {
        pageNumber = listRequests.count / 10 + ((listRequests.count % 10) > 0 ? 1 : 0) + 1
        friendListApiMethod(pageNumber: pageNumber)
    }

    func updateData(list: [UserModel]?, pageNumber: Int = 1, numberOfRows: Int = 10) {
        guard let list = list else { return }
        
        if pageNumber == 1 { listRequests.removeAll() }

        listRequests.replace(arrPage: list, pageNumber: pageNumber, numberOfRowsInPage: numberOfRows)
        tblFriendRequest.reloadData()
        
        lblNoRequests.isHidden = listRequests.count > 0
    }
    
}

// MARK: - BackEnd API Methods
extension FriendRequestsVC {
    // MARK: - Friends list
    func friendListApiMethod(isShowLoader: Bool = false, pageNumber : Int = 1, numberOfRows: Int = 10) {
        
        let dict = ["pageNo": pageNumber,
                    "count": numberOfRows]

        if isShowLoader == true {
            self.showLoader()
        }
        
        FRIENDS_SERVICE.hitFriendRequestToMeApi(dict).done { (response) -> Void in
            self.hideLoader()
            self.updateData(list: response, pageNumber: pageNumber, numberOfRows: numberOfRows)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
}

// MARK: - UITableViewDataSource
extension FriendRequestsVC: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listRequests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FriendRequestCell.className, for: indexPath) as? FriendRequestCell
        cell?.configureCell(frndModel: listRequests[indexPath.row])
        return cell ?? UITableViewCell()
    }
}

// MARK: - UITableViewDelegate
extension FriendRequestsVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        APP_MANAGER.pushUserProfileVC(userId: listRequests[indexPath.row].friendId, sender: self)
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
