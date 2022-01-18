//
//  PostLikedCell.swift
//  Plans
//
//  Created by Star on 2/23/21.
//

import UIKit

class PostLikedCell: BaseTableViewCell {
    
    // MARK: - IBOutlets
    @IBOutlet weak var imgvProfile: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblSubTitle: UILabel!
    @IBOutlet weak var imgvHeart: UIImageView!
    
    @IBOutlet weak var viewPostText: UIView!
    @IBOutlet weak var postText: UILabel!
    
    @IBOutlet weak var viewMedia: UIView!
    @IBOutlet weak var imgviewMedia: UIImageView!
    @IBOutlet weak var viewVideoPlayer: PlansVideoPlayerView!
    @IBOutlet weak var heightMediaView: NSLayoutConstraint!
    @IBOutlet weak var viewBottomSeparator: UIView!
    
    var postModel: LikedPostModel?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        viewVideoPlayer?.typeUI = .postComment
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func actionLikeHeartBtn(_ sender: Any) {
        APP_MANAGER.likeUnlikePost(postId: postModel?._id, eventId: postModel?.eventId, isLike: false)
    }
    @IBAction func actionEventBtn(_ sender: Any) {
        APP_MANAGER.pushEventDetailsVC(eventId: postModel?.eventId)
    }
    
    public func setupUI(postModel: LikedPostModel?, isHiddenSeparator: Bool = false){
        self.postModel = postModel

        viewBottomSeparator.isHidden = isHiddenSeparator
        // Profile Image
        imgvProfile.setEventImage(postModel?.eventImageUrl)

        // Title
        lblTitle.text = postModel?.eventName

        // SubTitl
        lblSubTitle.text = "Organized by "
        lblSubTitle.text! += "\(postModel?.firstName ?? "") "
        lblSubTitle.text! += "\(postModel?.lastName ?? "")"

        // Like heart
        imgvHeart.isHighlighted = true
        
        // Post Text
        viewPostText.isHidden = postModel?.postText == "" || postModel?.postText == nil
        postText.text = postModel?.postText
        
        // Media View
        viewMedia.isHidden = postModel?.postType == "" || postModel?.postType == "text" || postModel?.postType == nil
        if viewMedia.isHidden == false {
            imgviewMedia.setEventImage(postModel?.postImageUrl)
            if postModel?.postType == "video" {
                viewVideoPlayer.isHidden = false
                viewVideoPlayer.setVideo(postModel?.postMedia)
            } else {
                viewVideoPlayer.isHidden = true
            }
            
            // Posted Image/Video View size
            if let width = postModel?.width, let height = postModel?.height, width != 0, height != 0 {
                let widthImageView = MAIN_SCREEN_WIDTH
                let temp = (CGFloat(height) / CGFloat(width)) * widthImageView
                let max = widthImageView
                if temp > max {
                    heightMediaView.constant = max
                }else {
                    heightMediaView.constant = temp
                }
            }else {
                heightMediaView.constant = 200
            }
        }
    }
    
}
