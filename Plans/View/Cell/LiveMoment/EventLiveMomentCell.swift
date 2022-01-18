//
//  EventLiveMomentCell.swift
//  Plans
//
//  Created by Star on 2/12/21.
//

import UIKit

class EventLiveMomentCell: UICollectionViewCell {

    @IBOutlet weak var imgvBackground: UIImageView!
    @IBOutlet weak var imgviewLiveMoment: UIImageView!
    @IBOutlet weak var imgviewUserProfile: UIImageView!
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var lblTime: UILabel!

    var liveMoment: UserLiveMomentsModel?
    var lastMedia: LiveMomentModel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        imgviewUserProfile.layer.cornerRadius = imgviewUserProfile.bounds.size.width / 2.0
    }
    
    func setupUI(liveMoment: UserLiveMomentsModel?) {
        self.liveMoment = liveMoment
        lastMedia = liveMoment?.liveMoments?.first
        
        // Live Moment Image
        var urlString: String?
        if lastMedia?.mediaType == "image" {
            urlString = lastMedia?.imageOrVideo
        }else {
            urlString = lastMedia?.liveThumbnail
        }
        imgviewLiveMoment.setEventImage(urlString)
        
        // User Profile Image
        imgviewUserProfile.setUserImage(liveMoment?.user?.profileImage)
        
        // User Name
        if liveMoment?.user?._id == USER_MANAGER.userId {
            lblUserName.text = "Your\nLive Moments"
            lblUserName.font = AppFont.bold.size(13.0)
        }else {
            lblUserName.text = liveMoment?.user?.fullName
            lblUserName.font = AppFont.regular.size(13.0)
        }
        imgvBackground.isHidden = liveMoment?.isAllSeen ?? false


        // Time
        if let timeAgo = liveMoment?.timeLatest, timeAgo > 0 {
            lblTime.text = Date(timeIntervalSince1970: timeAgo).timeAgoSince()
        }else {
            lblTime.text = ""
        }
    }

}
