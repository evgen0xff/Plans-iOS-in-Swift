//
//  FriendRequestCell.swift
//  Plans
//
//  Created by Plans Collective LLC on 5/27/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit
import CoreLocation

class FriendRequestCell: BaseTableViewCell {

    // MARK: - IBOutlets
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var addressLbl: UILabel!
    
    var request: UserModel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

    @IBAction func actionAccept(_ sender: Any) {
        (APP_MANAGER.topVC as? PlansContentBaseVC)?.acceptRequestMethod(user: request)
    }
    
    @IBAction func actionReject(_ sender: Any) {
        (APP_MANAGER.topVC as? PlansContentBaseVC)?.rejectRequestMethod(request?.friendId)
    }
    
    public func configureCell(frndModel: UserModel?) {
        request = frndModel
        profileImg.setUserImage(frndModel?.profileImage)
        nameLbl.text = frndModel?.name
        addressLbl.isHidden = frndModel?.userLocation == nil || frndModel?.userLocation == ""
        addressLbl.text =  frndModel?.userLocation
    }
}
