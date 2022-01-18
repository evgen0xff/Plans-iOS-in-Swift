//
//  NotificationCell.swift
//  Plans
//
//  Created by Plans Collective LLC on 5/24/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit

protocol NotificationCellDelegate {
    func didLongPressed(cellView: UITableViewCell, notification: NotificationActivityModel?)
    func didClickedPhoto(cellView: UITableViewCell, notification: NotificationActivityModel?)
}

extension NotificationCellDelegate {
    func didLongPressed(cellView: UITableViewCell, notification: NotificationActivityModel?) {}
    func didClickedPhoto(cellView: UITableViewCell, notification: NotificationActivityModel?) {}
}

class NotificationCell: BaseTableViewCell {

    @IBOutlet weak var viewBottomSeparator: UIView!
    
    @IBOutlet weak var containerProfiles: UIView!
    @IBOutlet var viewsProfiles: [UIView]!
    @IBOutlet var imgvsProfiles: [UIImageView]!
    
    @IBOutlet weak var viewLiveImage: UIView!
    @IBOutlet weak var lblMessage: UILabel!
    
    @IBOutlet weak var viewPhotoImage: UIView!
    @IBOutlet weak var imgvPhotoImage: UIImageView!
    
    @IBOutlet weak var viewGuides: UIView!
    @IBOutlet weak var imvTapHoldNotification: UIImageView!
    @IBOutlet weak var imvTapViewEvent: UIImageView!
    @IBOutlet weak var constHeightGuideContainer: NSLayoutConstraint!
    
    var notificationModel : NotificationActivityModel?
    var delegate : NotificationCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(actionLongPress))
        self.addGestureRecognizer(longGesture)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func actionPhoto(_ sender: Any) {
        delegate?.didClickedPhoto(cellView: self, notification: notificationModel)
    }
    
    @IBAction func actionGuideTapViewEvent(_ sender: Any) {
        actionPhoto(self)
    }
    
    func configureCell(notificationModel: NotificationActivityModel?,
                       delegate: NotificationCellDelegate? = nil,
                       dicUIConfig: [String: Bool]? = nil
    ) {
        self.notificationModel = notificationModel
        self.delegate = delegate
        
        var widthMax = MAIN_SCREEN_WIDTH - (13 + 15)
        
        viewBottomSeparator.isHidden = dicUIConfig?["isLast"] ?? false
        
        // Profile Images
        let mainProfile = notificationModel?.userImage ?? notificationModel?.profileImage
        viewsProfiles.first(where: {$0.tag == 0})?.isHidden = mainProfile == nil
        imgvsProfiles.first(where: {$0.tag == 0})?.setUserImage(mainProfile)
        if (mainProfile != nil) {
            widthMax -= (44 + 6)
        }

        viewsProfiles.first(where: {$0.tag == 1})?.isHidden = notificationModel?.userImage2 == nil
        imgvsProfiles.first(where: {$0.tag == 1})?.setUserImage(notificationModel?.userImage2)
        if (notificationModel?.userImage2 != nil) {
            widthMax -= 24
        }

        // Image
        viewPhotoImage.isHidden = notificationModel?.image == nil || notificationModel?.image == ""
        imgvPhotoImage.setEventImage(notificationModel?.image)
        if (viewPhotoImage.isHidden == false) {
            widthMax -= (40 + 6)
        }

        // Live Mark view
        viewLiveImage.isHidden = notificationModel?.isLive != 1

        // Message
        lblMessage.attributedText = notificationModel?.getMessageText(widthMax: widthMax, label: lblMessage)
        
        // Guide Views
        imvTapHoldNotification.isHidden = !(dicUIConfig?["isFirstNotify"] ?? false) || USER_MANAGER.isSeenGuideTapHoldNotification
        imvTapViewEvent.isHidden = !((dicUIConfig?["isFirstEventImage"] ?? false) && !USER_MANAGER.isSeenGuideTapViewEvent && !viewPhotoImage.isHidden)
        viewGuides.isHidden = imvTapViewEvent.isHidden && imvTapHoldNotification.isHidden
        constHeightGuideContainer.constant = imvTapHoldNotification.isHidden == false ? 63.0 : (imvTapViewEvent.isHidden == false ? 50.0 : 0.0)

    }
    
    @objc func actionLongPress(_ sender:UILongPressGestureRecognizer!)  {
        switch sender.state {
        case .began:
            delegate?.didLongPressed(cellView: self, notification: notificationModel)
            break
        default:
            break
        }
    }
    
}
