//
//  UserImageCell.swift
//  Plans
//
//  Created by Plans Collective LLC on 6/7/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit

class UserImageCell: UICollectionViewCell {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var imgvUser: UIImageView!
    @IBOutlet weak var imgvLing: UIImageView!
    
    var invitationModel: InvitationModel?
    var userModel: UserModel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    // MARK - Public Methods
    
    func setupUI (invitationModel: InvitationModel?, eventModel: EventFeedModel? = nil) {
        self.invitationModel = invitationModel
        guard let invitationModel = invitationModel else { return }
        
        imgvUser.isHidden = false
        imgvUser.contentMode = .scaleAspectFill
        imgvUser.setUserImage(invitationModel.profileImage)

        if invitationModel.isLive == 1, (eventModel?.isEnded ?? false) == false {
            imgvLing.isHidden = false
        } else {
            imgvLing.isHidden = true
        }
    }

    func setupUI (userModel: UserModel?) {
        self.userModel = userModel
        guard let userModel = userModel else { return }

        imgvUser.isHidden = false
        imgvUser.contentMode = .scaleAspectFill
        imgvUser.setUserImage(userModel.profileImage)

        imgvLing.isHidden = true
    }
    
    func setupUILikeImage(isFull: Bool = false) {
        imgvLing.isHidden = true
        imgvUser.isHidden = false
        imgvUser.contentMode = .center

        if isFull == true {
            imgvUser.image = UIImage(named: "ic_heart_filled_green")
        } else {
            imgvUser.image = UIImage(named: "ic_heart_outline_grey")
        }
    }

}
