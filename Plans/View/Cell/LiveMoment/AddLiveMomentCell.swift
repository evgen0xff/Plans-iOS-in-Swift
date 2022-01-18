//
//  AddLiveMomentCell.swift
//  Plans
//
//  Created by Star on 2/12/21.
//

import UIKit

class AddLiveMomentCell: UICollectionViewCell {

    @IBOutlet weak var viewContent: UIView!
    @IBOutlet weak var imgviewUserProfile: UIImageView!
    @IBOutlet weak var lblAddLiveMoment: UILabel!
    @IBOutlet weak var viewTapToPost: UIView!
    @IBOutlet weak var btnTapToPost: UIButton!
    
    var eventModel: EventFeedModel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        layer.zPosition = 1
        viewContent.layer.borderWidth = 1.0
        viewContent.layer.borderColor = AppColor.grey_button_border.cgColor
        imgviewUserProfile.setUserImage(USER_MANAGER.profileUrl)
    }
    
    func setupUI(event: EventFeedModel?) {
        layer.zPosition = 1
        eventModel = event
        viewTapToPost.isHidden = USER_MANAGER.isShownPostTutorial
    }
    
    @IBAction func actionTapToPost(_ sender: Any) {
        APP_MANAGER.pushLiveMomentCameraVC(event: eventModel)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.contains(point) || (viewTapToPost.isHidden == false && viewTapToPost.frame.contains(point))
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        var result = super.hitTest(point, with: event)
        if viewTapToPost.isHidden == false,
           viewTapToPost.frame.contains(point) == true {
            result = btnTapToPost
        }
        return result
    }

    
}
