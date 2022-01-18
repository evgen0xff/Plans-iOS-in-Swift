//
//  PostsLikedVC.swift
//  Plans
//
//  Created by Star on 2/23/21.
//

import UIKit

class PostsLikedVC: UserBaseVC {
    
    // MARK: - All IBOutlet
    
    @IBOutlet weak var likeTblVw: UITableView!
    @IBOutlet weak var emptyLbl: UILabel!
    
    // MARK: - All Propertise
    
    internal var likedArray = [LikedPostModel]()
    internal var pageNumber = 1
    var cellHeights = [IndexPath: CGFloat]()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func setupUI() {
        super.setupUI()
        
        setupTableView()
    }
    
    override func refreshAll(isShowLoader: Bool = false) {
        super.refreshAll(isShowLoader: isShowLoader)
        likedPostMethod(isShowLoader: isShowLoader, pageNumber: 1, numberOfRows: pageNumber * 10)
    }

    override func hideLoader() {
        super.hideLoader()
        likeTblVw.switchRefreshFooter(to: .normal)
    }
    
    // MARK: - User Action Handlers
    @IBAction func actionBackBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Additional Helper Function

    private func setupTableView() {
        likeTblVw.delegate = self
        likeTblVw.dataSource = self
        likeTblVw.register(nib: PostLikedCell.className)

        likeTblVw.configRefreshFooter(with: refreshFooter, container:self) { [weak self] in
            if let this = self, this.likedArray.count % 10 == 0, this.likedArray.count > 0 {
                this.getNextPage()
            }else {
                APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 1) {
                    self?.hideLoader()
                }
            }
        }
    }
    
    func updateData(list: [LikedPostModel]?, pageNumber: Int = 1, numberOfRowsInPage: Int = 10) {
        if pageNumber == 1 { likedArray.removeAll() }
        self.likedArray.replace(arrPage: list, pageNumber: pageNumber, numberOfRowsInPage: numberOfRowsInPage)
        
        if self.likedArray.count > 0 {
            self.emptyLbl.isHidden = true
        } else {
            self.emptyLbl.isHidden = false
        }
        
        self.likeTblVw.reloadData()
    }
    
    func getNextPage(isShowLoader: Bool = false) {
        pageNumber = likedArray.count / 10 + ((likedArray.count % 10) > 0 ? 1 : 0) + 1
        likedPostMethod(isShowLoader: isShowLoader, pageNumber: pageNumber)
    }
    
}

// MARK: - Liked Post Api method

extension PostsLikedVC {
    func likedPostMethod(isShowLoader: Bool = true, pageNumber: Int = 1, numberOfRows: Int = 10) {
        let dict = ["pageNo": pageNumber,
                    "count": numberOfRows] as [String: Any]
        if isShowLoader == true {
            self.showLoader()
        }
        POSTS_SERVICE.getLikedPost(dict).done { (response) -> Void in
            self.hideLoader()
            self.updateData(list: response, pageNumber: pageNumber, numberOfRowsInPage: numberOfRows)
            }.catch { (error) in
                self.hideLoader()
                POPUP_MANAGER.handleError(error)
        }
    }
    
}

// MARK: - UITableViewDataSource
extension PostsLikedVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return likedArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostLikedCell.className, for: indexPath) as? PostLikedCell
        let isLast = indexPath.row == (likedArray.count - 1)
        cell?.setupUI(postModel: likedArray[indexPath.row], isHiddenSeparator: isLast)
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        APP_MANAGER.pushPostCommentVC(eventId: likedArray[indexPath.row].eventId, postId: likedArray[indexPath.row]._id, sender: self)
    }
    
}

// MARK: - UITableViewDelegate
extension PostsLikedVC: UITableViewDelegate {
    
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
