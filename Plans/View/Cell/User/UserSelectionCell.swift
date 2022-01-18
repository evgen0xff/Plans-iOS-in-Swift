//
//  UserSelectionCell.swift
//  Plans
//
//  Created by Star on 3/5/21.
//

import UIKit

class UserSelectionCell: BaseTableViewCell {

    @IBOutlet weak var imgvUserImage: UIImageView!
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var btnSelected: UIButton!
    
    var userModel: UserModel?
    var actionUserSelected: ((_ user: UserModel?) -> ())? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func actionSelectedBtn(_ sender: Any) {
        btnSelected.isSelected = !btnSelected.isSelected
        actionUserSelected?(userModel)
    }
    
    func setupUI(user: UserModel?, isSelected: Bool = false, actionUserSelected: ((_ user: UserModel?) -> ())? = nil) {
        userModel = user
        self.actionUserSelected = actionUserSelected
        
        // User Image
        imgvUserImage.setUserImage(user?.profileImage)
        
        // User Name
        lblUserName.text = user?.fullName ?? user?.name ?? "\(user?.firstName ?? "") \(user?.lastName ?? "")"
        
        // Selected Status
        btnSelected.isSelected = isSelected
    }
}
