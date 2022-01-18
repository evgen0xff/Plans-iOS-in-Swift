//
//  LikesVC.swift
//  Plans
//
//  Created by Star on 3/25/21.
//

import UIKit

class LikesVC: PostCommentBaseVC {

    @IBOutlet weak var tblvUsers: UITableView!
    @IBOutlet weak var txtfSearch: UITextField!

    
    // MARK: - Properties
    var arrLikes = [UserModel]()
    var searchedLikes = [UserModel]()
    var cellHeights = [IndexPath: CGFloat]()
    
    // MARK: - ViewController Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    override func setupUI() {
        super.setupUI()
        
        txtfSearch.attributedPlaceholder = NSAttributedString(string: "Search",
                                                               attributes: [NSAttributedString.Key.foregroundColor: AppColor.whiteOpacity60])
        txtfSearch.delegate = self
        txtfSearch.addTarget(self, action: #selector(searchUser(_ :)), for: .editingChanged)

        // Users Table
        tblvUsers.delegate = self
        tblvUsers.dataSource = self
        tblvUsers.registerMultiple(nibs:[UserTableCell.className])
        
        updateData(likes: arrLikes)
    }

    override func refreshAll(isShowLoader: Bool = false) {
        super.refreshAll(isShowLoader: isShowLoader)
        getPostData(isShowLoader: isShowLoader)
    }
    
    
    // MARK: - User Actions
    @IBAction func actionBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func searchUser(_ textfield:UITextField) {
        searchedLikes.removeAll()
        if let text = textfield.text?.lowercased(), text.count > 0 {
            searchedLikes = arrLikes.filter({ (user) -> Bool in
                let name = (user.name ?? user.fullName ?? "\(user.firstName ?? "") \(user.lastName ?? "")").lowercased()
                return name.contains(text)
            })
        }else {
            searchedLikes.append(contentsOf: arrLikes)
        }
        
        tblvUsers.reloadData()
    }

    

    private func updateData(likes: [UserModel]?) {
        guard let likes = likes else { return }
        // sort plans users by friendShipStatus
        arrLikes = likes.sorted { (item1, item2) -> Bool in
            if let status1 = item1.friendShipStatus, let status2 = item2.friendShipStatus {
                if status1 != 10, status2 != 10 {
                    if status1 > status2 {
                        return true
                    }else if status1 == status2 {
                        if item1.friendRequestSender != USER_MANAGER.userId {
                            return true
                        }
                    }
                }else if status1 != 10, status2 == 10 {
                   return true
                }else if status1 == 10, status2 == 10 {
                    if item1._id != USER_MANAGER.userId {
                        return true
                    }
                }
            }
            return false
        }
        
        searchUser(txtfSearch)
    }
    
    
    // MARK: - Backend APIs
    
    func getPostData(isShowLoader: Bool = true) {
        if isShowLoader == true {
            showLoader()
        }
        POSTS_SERVICE.hitPostDetail(eventId: activeEvent?._id, postId: postID, pageNumber: 1)
        .done { (response) -> Void in
            self.hideLoader()
            self.updateData(likes: response.likes)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }

}

// MARK: - UITextFieldDelegate
extension LikesVC : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}


// MARK: - UITableViewDelegate, UITableViewDataSource

extension LikesVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchedLikes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UserTableCell.className, for: indexPath) as? UserTableCell else {
            return UITableViewCell()
        }
        
        cell.setupUI(model: searchedLikes[indexPath.row], delegate: self, cellType: .plansUser)

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 61
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        APP_MANAGER.pushUserProfileVC(userModel: searchedLikes[indexPath.row], sender: self)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? UITableView.automaticDimension
    }


    
}

// MARK: - UserTableCellDelegate

extension LikesVC : UserTableCellDelegate {
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

}


