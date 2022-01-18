//
//  UserInvitationCell.swift
//  Plans
//
//  Created by Star on 8/20/20.
//  Copyright © 2020 Brainmobi. All rights reserved.
//

import UIKit

protocol UserInvitationCellDelegate: ItemMoveDelegate {
    func didTapProfileImage(userModel: UserModel?, cell: UITableViewCell)
    func didTapUnselectedMark(userModel: UserModel?, cell: UITableViewCell)
    func didTapSelectedMark(userModel: UserModel?, cell: UITableViewCell)
    func didTapCrossMark(userModel: UserModel?, cell: UITableViewCell)
    func didTapTrashMark(userModel: UserModel?, cell: UITableViewCell)
}

extension UserInvitationCellDelegate {
    func didTapProfileImage(userModel: UserModel?, cell: UITableViewCell){}
    func didTapUnselectedMark(userModel: UserModel?, cell: UITableViewCell){}
    func didTapSelectedMark(userModel: UserModel?, cell: UITableViewCell){}
    func didTapCrossMark(userModel: UserModel?, cell: UITableViewCell){}
    func didTapTrashMark(userModel: UserModel?, cell: UITableViewCell){}
}

class UserInvitationCell: UITableViewCell {
    
    struct UserStatus {
        var isSelected : Bool? = nil
        var isCrossed = false
        var isGrayed = false
        var isTrash = false
    }
    
    @IBOutlet weak var imgvProfile: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var viewUnselected: UIView!
    @IBOutlet weak var viewSelected: UIView!
    @IBOutlet weak var viewCrossMark: UIView!
    @IBOutlet weak var viewTrashMark: UIView!
    
    var delegate: UserInvitationCellDelegate?
    var userModel: UserModel?
    var status: UserStatus?
    var itemType = InviteType.friend

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func actionProfileBtn(_ sender: Any) {
        delegate?.didTapProfileImage(userModel: userModel, cell: self)
    }
    @IBAction func actionUnselectedMark(_ sender: Any) {
        delegate?.onItemMoveSelected(data: userModel, cell: self)
        delegate?.didTapUnselectedMark(userModel: userModel, cell: self)
    }
    @IBAction func actionSelectedMark(_ sender: Any) {
        delegate?.onItemMoveSelected(data: userModel, cell: self)
        delegate?.didTapSelectedMark(userModel: userModel, cell: self)
    }
    @IBAction func actionCrossMark(_ sender: Any) {
        delegate?.onItemMoveSelected(data: userModel, cell: self)
        delegate?.didTapCrossMark(userModel: userModel, cell: self)
    }
    @IBAction func actionTrashMark(_ sender: Any) {
        delegate?.didTapTrashMark(userModel: userModel, cell: self)
    }
    
    func setupUI(userModel: UserModel?, itemType: InviteType = .friend, status: UserStatus? = nil, delegate: UserInvitationCellDelegate? = nil) {
        
        self.userModel = userModel
        self.itemType = itemType
        self.status = status
        self.delegate = delegate
        
        // User profile image
        imgvProfile.setUserImage(userModel?.profileImage)
        
        // User name
        lblTitle.text = ""
        if let name = userModel?.name { lblTitle.text = name }
        if let fullName = userModel?.fullName { lblTitle.text = fullName }
        if let firstName = userModel?.firstName, let lastName = userModel?.lastName { lblTitle.text = firstName + " " + lastName}

        // Description
        lblDescription.isHidden = true
        
        // Mark Views
        if let status = status {
            viewUnselected.isHidden = status.isSelected ?? true
            viewSelected.isHidden = !(status.isSelected ?? false)
            viewCrossMark.isHidden = !status.isCrossed
            viewTrashMark.isHidden = !status.isTrash
        }else {
            viewUnselected.isHidden = true
            viewSelected.isHidden = true
            viewCrossMark.isHidden = true
        }
        
        // Type
        switch itemType {
        case .friend:
            break
        case .contact:
            lblDescription.text = userModel?.mobile?.getFormattedPhoneNumber()
            if lblTitle.text == nil || lblTitle.text == "" {
                lblTitle.text = lblDescription.text
                lblDescription.isHidden = true
            }else {
                lblDescription.isHidden = false
            }
            if userModel?.profileImage == nil {
                imgvProfile.image = UIImage(named: "ic_phone_circle_green")
            }
            break
        case .email:
            lblDescription.text = userModel?.email
            if lblTitle.text == nil || lblTitle.text == "" {
                lblTitle.text = lblDescription.text
                lblDescription.isHidden = true
            }else {
                lblDescription.isHidden = false
            }
            if userModel?.profileImage == nil {
                imgvProfile.image = UIImage(named: "ic_atMark_circle_green")
            }
            break
        case .link:
            break
        default :
            break
        }

    }
}
