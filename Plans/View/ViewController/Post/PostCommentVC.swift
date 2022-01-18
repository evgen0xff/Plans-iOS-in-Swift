//
//  PostCommentVC.swift
//  Plans
//
//  Created by Star on 2/14/21.
//

import UIKit
import GrowingTextView

class PostCommentVC: PostCommentBaseVC {
    // MARK: - IBOutlets

    // MARK: - Porperties
    @IBOutlet weak var tblvPost: UITableView!
    @IBOutlet weak var viewCommenting: UIView!
    @IBOutlet weak var imgviewUserProfile: UIImageView!
    @IBOutlet weak var txtvMessage: GrowingTextView!
    @IBOutlet weak var imgviewSend: UIImageView!
    @IBOutlet weak var btnSend: UIButton!
    @IBOutlet weak var bottomMarginContent: NSLayoutConstraint!
    
    var postComments = [PostModel]()
    var cellHeights = [IndexPath: CGFloat]()
    var pageNumber = 1

    // MARK: - ViewController Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func setupUI() {
        super.setupUI()
        setupTableView()
        setupCommentingUI()
    }
    
    override func refreshAll(isShowLoader: Bool = false) {
        super.refreshAll(isShowLoader: isShowLoader)
        hitApiMethod(isShowLoader: isShowLoader, pageNumber: 1, numberOfRows: pageNumber * 10)
    }
    
    override func hideLoader() {
        super.hideLoader()
        tblvPost.switchRefreshHeader(to: .normal(.success, 0.0))
        tblvPost.switchRefreshFooter(to: .normal)
    }
    
    override func willShowKeyboard(frame: CGRect) {
        bottomMarginContent.constant = frame.height - UIDevice.current.heightBottomNotch
        view.updateConstraintsIfNeeded()
    }
    
    override func willHideKeyboard() {
        bottomMarginContent.constant = 0
        view.updateConstraintsIfNeeded()
    }

    
    // MARK: - User Actions
    @IBAction func actionBackBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionMenuBtn(_ sender: Any) {
        let dic = ["post": postDetail,
                   "event": activeEvent]
        OPTIONS_MANAGER.showMenu(data: dic, menuType: .post, delegate: self, sender: self)
    }
    
    @IBAction func actionSendBtn(_ sender: Any) {
        view.endEditing(true)
        addComment(comment: txtvMessage.text)
        txtvMessage.text = ""
    }
    
    // MARK: - Private Methods
    private func setupTableView() {
        tblvPost.registerMultiple(nibs: [PostCommentCell.className, PeopleTableCell.className, SectionHeaderCell.className])

        tblvPost.delegate = self
        tblvPost.dataSource = self
        tblvPost.tableFooterView?.isHidden = true

        tblvPost.configRefreshHeader(with: refreshHeader, container:self) { [weak self] in
            self?.refreshAll()
        }
        
        tblvPost.configRefreshFooter(with: refreshFooter, container:self) { [weak self] in
            if let this = self, this.postComments.count % 10 == 0, this.postComments.count != 0 {
                this.getNextPage()
            }else {
                APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 1) {
                    self?.hideLoader()
                }
            }
        }

        if #available(iOS 15.0, *) {
            tblvPost.sectionHeaderTopPadding = 0.0
        }
    }
    
    func setupCommentingUI() {
        viewCommenting.addShadow(shadowOffset: CGSize(width: 0, height: -3.0))
        updateCommentingUI()
        txtvMessage.delegate = self
    }

    func getNextPage(isShowLoader: Bool = false) {
        pageNumber = postComments.count / 10 + ((postComments.count % 10) > 0 ? 1 : 0) + 1
        hitApiMethod(isShowLoader: isShowLoader, pageNumber: pageNumber)
    }
    
    func updateData(post: PostModel?, pageNumber: Int = 1, numberOfRows: Int = 10 ) {
        guard let post = post else { return }
        postDetail = post
        if pageNumber == 1 { postComments.removeAll() }
        
        postComments.replace(arrPage: post.comments, pageNumber: pageNumber, numberOfRowsInPage: numberOfRows)
        updateUI()
    }
    
    func updateUI() {
        tblvPost.reloadData()
        updateCommentingUI()
        updateNoComments()
    }
    
    func updateNoComments() {
        var isHidden = false
        if postComments.count > 0 {
            isHidden = true
        }
        
        APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 0.3) {
            var height: CGFloat = 0.0
            if isHidden == false {
                height = self.tblvPost.bounds.height - self.tblvPost.rect(forSection: 0).height - self.tblvPost.rect(forSection: 1).height
                if height < 200 {
                    height = 200
                }
            }
            self.tblvPost.tableFooterView?.bounds.size.height = height
            self.tblvPost.tableFooterView?.sizeToFit()
            self.tblvPost.tableFooterView?.isHidden = isHidden
            self.tblvPost.reloadData()
        }
    }
    
    func updateCommentingUI() {
        imgviewUserProfile.setUserImage(USER_MANAGER.profileUrl)

        let text = txtvMessage.text?.trimmingCharacters(in: .whitespaces)
        if text != nil, text != "" {
            imgviewSend.isHighlighted = true
            btnSend.isEnabled = true
        }else {
            imgviewSend.isHighlighted = false
            btnSend.isEnabled = false
        }
        
    }
}

// MARK: - UITableViewDataSource
extension PostCommentVC: UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
            case 0: return 1
            case 1: return 1
            case 2: return postComments.count
            default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell : UITableViewCell?
        
        switch indexPath.section {
            case 0, 2:
                cell = getPostCommentCell(indexPath, tableView: tableView)
                break
            case 1:
                cell = getLikesCell(indexPath, tableView: tableView)
                break
            default:
                break
        }
        
        return cell ?? UITableViewCell()
    }
    
    private func getPostCommentCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PostCommentCell.className, for: indexPath) as? PostCommentCell
            else {
            return UITableViewCell()
        }
        var post: PostModel?
        var cellType = PostCommentCell.CellType.postDetails
        var isHiddenSeparator = false
        switch indexPath.section {
            case 0:
                post = postDetail
                cellType = .postDetails
                break
            case 2:
                post = postComments[indexPath.row]
                cellType = .postComment
                isHiddenSeparator = indexPath.row == (postComments.count - 1)
                break
            default:
                break
        }
        cell.setupUI(post: post, event: activeEvent, cellType: cellType, isHiddenSeparator: isHiddenSeparator)
        return cell
    }
    
    private func getLikesCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PeopleTableCell.className, for: indexPath) as? PeopleTableCell
            else {
                return UITableViewCell()
        }
        cell.setupUI(model: postDetail, delegate: self, cellType: .postLike)
        return cell
    }
    
    private func getHeaderView(_ section: Int, tableView: UITableView) -> UIView? {
        var header: UIView?
        switch section {
            case 2:
                if postComments.count > 0, let cell = tableView.dequeueReusableCell(withIdentifier: SectionHeaderCell.className) as? SectionHeaderCell {
                    var title: String?
                    if postComments.count == 1 {
                        title = "1 Comment"
                    } else {
                        title = "\(postComments.count) Comments"
                    }
                    cell.setupUI(title: title, cellType: .postComment)
                    header = cell
                }
                break
            default:
                break
        }
        return header
    }


}

// MARK: - UITableViewDelegate
extension PostCommentVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 2: return postComments.count > 0 ? 26.0 : 0.0
        default: return 0.0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return getHeaderView(section, tableView: tableView)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? UITableView.automaticDimension
    }
}


// MARK: - Hit Api Method

extension PostCommentVC {
    
    // Get all information (Post and comments)
    func hitApiMethod(isShowLoader: Bool = false,
                      pageNumber: Int = 1,
                      numberOfRows: Int = 10) {
        
        if isShowLoader {
            self.showLoader()
        }
        
        POSTS_SERVICE.hitPostDetail(eventId: eventID ?? "", postId: postID, pageNumber: pageNumber, numberOfRows: numberOfRows)
            .done { (response) -> Void in
                self.hideLoader()
                self.updateData(post: response, pageNumber: pageNumber, numberOfRows: numberOfRows)
        }.catch { (error) in
            self.hideLoader()
            self.actionBackBtn(self)
        }
    }
    
}

// MARK: - UITextViewDelegate

extension PostCommentVC : UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateCommentingUI()
    }
}

// MARK: - PeopleTableCellDelegate

extension PostCommentVC: PeopleTableCellDelegate {
    func likeUnlinkPost(postModel: PostModel?) {
        let isLike = postModel?.likes?.contains(where: { $0._id == USER_MANAGER.userId }) ?? false
        likeUnlikePost(postId: postModel?._id, eventId: eventID, isLike: !isLike)
    }
}


// MARK: - OptionsMenuManagerDelegate

extension PostCommentVC: OptionsMenuManagerDelegate {
    func didSelectedMenuItem(titleItem: String?, data: Any?) {
        guard let post =  (data as? [String: Any?])?["post"] as? PostModel,
              let titleAction = titleItem else { return }
        if processPostMenuAction(titleAction: titleAction, post: post) == false {
            print("Not handled Menu Action : ", titleAction)
        }
    }
}


