//
//  UserTableCell.swift
//  Plans
//
//  Created by Star on 5/4/20.
//  Copyright © 2020 Brainmobi. All rights reserved.
//

import UIKit

protocol ItemMoveDelegate {
    func onItemMoveSelected(data: Any?, cell: UITableViewCell?)
}
extension ItemMoveDelegate {
    func onItemMoveSelected(data: Any?, cell: UITableViewCell?){}
}

protocol UserTableCellDelegate : ItemMoveDelegate {
    func tappedProfileImage(user: UserModel?, cell: UITableViewCell?)
    func tappedFriend(user: UserModel?, cell: UITableViewCell?)
    func tappedChat(user: UserModel?, cell: UITableViewCell?)
    func tappedSelection(user: UserModel?, cell: UITableViewCell?)
    func tappedMoreMenu(user: UserModel?, cell: UITableViewCell?)
}

extension UserTableCellDelegate {
    func tappedProfileImage(user: UserModel?, cell: UITableViewCell?){}
    func tappedFriend(user: UserModel?, cell: UITableViewCell?){}
    func tappedChat(user: UserModel?, cell: UITableViewCell?){}
    func tappedSelection(user: UserModel?, cell: UITableViewCell?){}
    func tappedMoreMenu(user: UserModel?, cell: UITableViewCell?){}
}

class UserTableCell: UITableViewCell {
    
    enum CellType {
        case plansUser
        case contact
        case invitedPeople
        case chatSettings
        case liveMoment
    }
    
    @IBOutlet weak var imgviewProfile: UIImageView!
    @IBOutlet weak var btnProfile: UIButton!

    @IBOutlet weak var viewChatBtn: UIView!

    @IBOutlet weak var viewFriendBtn: UIView!
    @IBOutlet weak var imgviewFriend: UIImageView!
    @IBOutlet weak var lblFriend: UILabel!
    
    @IBOutlet weak var viewReoveBtn: UIView!
    
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var lblOrganizerMark: UILabel!
    @IBOutlet weak var viewOrganizerMark: UIView!
    @IBOutlet weak var lblOrganizerUpMark: UILabel!
    @IBOutlet weak var lblAgoTime: UILabel!
    @IBOutlet weak var viewAgoTimeLbl: UIView!
    @IBOutlet weak var viewBottomSeparator: UIView!
    @IBOutlet weak var marginLeftBottomSeparator: NSLayoutConstraint!

    var userModel : UserModel?
    var delegate : UserTableCellDelegate?
    var eventModel: EventFeedModel?
    var chatModel: ChatModel?
    var type = CellType.plansUser
    var canDelete = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func actionProfile(_ sender: Any) {
        delegate?.tappedProfileImage(user: userModel, cell: self)
    }
    @IBAction func actionFriend(_ sender: Any) {
        delegate?.onItemMoveSelected(data: userModel, cell: self)
        delegate?.tappedFriend(user: userModel, cell: self)
    }
    @IBAction func actionChat(_ sender: Any) {
        delegate?.tappedChat(user: userModel, cell: self)
    }
    @IBAction func actionRemove(_ sender: Any) {
        delegate?.tappedMoreMenu(user: userModel, cell: self)
    }
    
    func setupUI (model: UserModel?,
                  delegate: UserTableCellDelegate? = nil,
                  cellType: CellType = .plansUser,
                  canDelete: Bool = false,
                  eventModel: EventFeedModel? = nil,
                  chatModel: ChatModel? = nil,
                  isHiddenSeparator: Bool = false){
        
        self.userModel = model
        self.delegate = delegate
        self.type = cellType
        self.canDelete = canDelete
        self.eventModel = eventModel
        self.chatModel = chatModel
        
        viewBottomSeparator.isHidden = isHiddenSeparator

        setupUI()
    }
    
    func setupUI() {
        // User profile image
        if type == .contact, userModel?.profileImage == nil {
            imgviewProfile.image = UIImage(named: "ic_phone_circle_green")
        }else {
            imgviewProfile.setUserImage(userModel?.profileImage)
        }
        
        // User name
        lblName.text = ""
        if let name = userModel?.name { lblName.text = name }
        if let fullName = userModel?.fullName { lblName.text = fullName }
        if let firstName = userModel?.firstName, let lastName = userModel?.lastName { lblName.text = firstName + " " + lastName}
        
        // Other UIs
        setupOptionsUI()
    }
    
    
    func setupOptionsUI() {
        var userID : String?
        if let _id = userModel?.friendId, _id != "" {
            userID = _id
        }
        if let _id = userModel?.userId, _id != "" {
            userID = _id
        }
        if let _id = userModel?._id, _id != "" {
            userID = _id
        }

        setupFriendBtn(userID: userID)
        showOptionsUI(userID: userID)
    }
    
    func showOptionsUI(userID: String?) {

        viewReoveBtn.isHidden = true
        viewFriendBtn.isHidden = true
        viewChatBtn.isHidden = true
        btnProfile.isHidden = true
        lblDescription.isHidden = true
        viewAgoTimeLbl.isHidden = true
        
        if userID != USER_MANAGER.userId {
            switch type {
            case .plansUser:
                viewFriendBtn.isHidden = false
            case .contact:
                viewFriendBtn.isHidden = false
                lblDescription.isHidden = false
                lblDescription.text = userModel?.mobile?.getFormattedPhoneNumber()
            case .invitedPeople:
                viewReoveBtn.isHidden = !canDelete
                if userModel?.friendShipStatus == 1 {
                    viewChatBtn.isHidden = false
                }else {
                    viewFriendBtn.isHidden = false
                }
            case .chatSettings:
                viewFriendBtn.isHidden = false
                if chatModel?.isGroup == true, chatModel?.organizer?._id == USER_MANAGER.userId {
                    viewReoveBtn.isHidden = false
                }
            case .liveMoment:
                if userModel?.friendShipStatus == 1 {
                    viewChatBtn.isHidden = false
                }
            }
        }

        var isHiddenOrganizerMark = true
        var textOrganizer = "Organizer"
        switch type {
        case .liveMoment, .invitedPeople:
            isHiddenOrganizerMark = !(userID == eventModel?.userId)
        case .chatSettings:
            marginLeftBottomSeparator.constant = 15.0
            isHiddenOrganizerMark = chatModel?.organizer?._id != userID
            if chatModel?.isEventChat != true {
                textOrganizer = "Admin"
            }
            break
        default:
            break
        }

        updateOrganizerMarkView(isHidden: isHiddenOrganizerMark, textOrganizer: textOrganizer)
    }
    
    func updateOrganizerMarkView(isHidden: Bool = true, textOrganizer: String? = "Organizer") {
        viewOrganizerMark.isHidden = true
        lblOrganizerUpMark.isHidden = true
        
        let widthNameText = lblName.text?.width(withConstraintedHeight: 18, font: AppFont.bold.size(15.0)) ?? 0.0
        let widthFriend = (lblFriend.text?.width(withConstraintedHeight: 28, font: AppFont.regular.size(17.0)) ?? 0.0) + 28.0 + 4
        let widthOrganizer = (textOrganizer?.width(withConstraintedHeight: 18, font: AppFont.bold.size(13.0)) ?? 0.0) + 9.0
        let width = 30.0 + 40.0 + 8.0 + widthNameText + 4.0 + widthOrganizer + 10.0 + 30 + 5.0 + (viewChatBtn.isHidden == false ? 68 : 0 ) + (viewFriendBtn.isHidden == false ? widthFriend : 0) + (viewReoveBtn.isHidden == false ? 44.0 : 0.0)
        
        var markView: UIView?
        if width > MAIN_SCREEN_WIDTH {
            markView = lblOrganizerUpMark
        }else {
            markView = viewOrganizerMark
        }
        
        markView?.isHidden = isHidden

        lblOrganizerUpMark.text = lblOrganizerUpMark.isHidden == true ? "" : textOrganizer
        lblOrganizerMark.text = textOrganizer
    }


    func setupFriendBtn(userID: String?) {
        guard userID != USER_MANAGER.userId else { return }
        
        var title: String?
        var image: String?
        var color = AppColor.purple_join
        
        if userID != nil {
            if userModel?.friendShipStatus == 0 {
                if userModel?.friendRequestSender == USER_MANAGER.userId {
                // "Requested"
                    title = "Requested"
                    image = "ic_clock_grey"
                    color = AppColor.grey_button
                }else {
                // "Confirm Request"
                    title = "Confirm Request"
                    image = "ic_check_purple"
                }
            }else if userModel?.friendShipStatus == 1 {
                // "Friends"
                title = "Friends"
                image = "ic_users_purple"
            }else if userModel?.friendShipStatus == 5 {
                // "Unblock"
                title = "Unblock"
                image = "ic_unlock_black"
                color = .black
            }else {
                // "Add Friend"
                title = "Add Friend"
                image = "ic_plus_purple"
            }
        }else {
            if let invitedTime = userModel?.invitedTime,
               Date(timeIntervalSince1970: invitedTime) > Date().addingTimeInterval(-3600*24*2) {
                // "Invited"
                title = "Invited"
                image = "ic_check_circle_purple"
            }else {
                // "Invite"
                title = "Invite"
                image = "ic_enter_black"
                color = .black
            }
        }

        lblFriend.text = title
        lblFriend.textColor = color
        imgviewFriend.image = image != nil ? UIImage(named: image!) : nil
    }
    
    func setupAgoTime(liveMoment: UserLiveMomentsModel?) {
        viewAgoTimeLbl.isHidden = false
        lblAgoTime.text = ""

        if let timeAgo = liveMoment?.timeLatest, timeAgo > 0 {
            lblAgoTime.text = Date(timeIntervalSince1970: timeAgo).timeAgoSince()
        }
    }
    
}
