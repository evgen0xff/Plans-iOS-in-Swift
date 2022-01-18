//
//  PostCommentCell.swift
//  Plans
//
//  Created by Plans Collective LLC on 5/16/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit
import ActiveLabel

class PostCommentCell: BaseTableViewCell {
    
    enum CellType {
        case eventPost
        case postDetails
        case postComment
    }

    // MARK: - IBOutlets
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var viewOrganizerMark: UIView!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var viewMenu: UIView!
    
    @IBOutlet weak var viewPostText: UIView!
    @IBOutlet weak var postText: ActiveLabel!
    
    @IBOutlet weak var viewMedia: UIView!
    @IBOutlet weak var btnMedia: UIButton!
    @IBOutlet weak var imgviewMedia: UIImageView!
    @IBOutlet weak var viewVideoPlayer: PlansVideoPlayerView!
    @IBOutlet weak var heightMediaView: NSLayoutConstraint!
    
    @IBOutlet weak var viewLikesComments: UIView!
    
    @IBOutlet weak var likeView: UIView!
    @IBOutlet weak var likeImage: UIImageView!
    @IBOutlet weak var likeCount: UILabel!
    @IBOutlet weak var likeBtn: UIButton!
    
    @IBOutlet var viewsUserLiked: [UIView]!
    @IBOutlet var imgviewsUserLiked: [UIImageView]!
    
    @IBOutlet weak var commentView: UIView!
    @IBOutlet weak var commentImgView: UIImageView!
    @IBOutlet weak var commentCount: UILabel!
    
    @IBOutlet weak var viewSeparator: UIView!
    
    var postModel: PostModel?
    var eventModel: EventFeedModel?
    var cellType: CellType = .eventPost
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        APP_MANAGER.topVC?.setupActiveLabel(label: postText)
        viewVideoPlayer.typeUI = .postComment
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setupUI(post: PostModel?,
                 event: EventFeedModel? = nil,
                 cellType: CellType = .eventPost,
                 isHiddenSeparator: Bool = false) {
        
        postModel = post
        eventModel = event
        configureUI(cellType: cellType, isHiddenSeparator: isHiddenSeparator)
        
        // User Profile Image
        profileImage.setUserImage(post?.user?.profileImage)

        // User Name
        if let firstName = post?.user?.firstName ,
            let lastName = post?.user?.lastName {
            name.text = firstName + " " + lastName
        }
        
        // Organizer Mark
        viewOrganizerMark.isHidden = !(post?.user?._id == event?.userId)

        // Time Posted
        if let createdAt = post?.createdAt {
            time.text = Date(timeIntervalSince1970: createdAt).timeAgoSince()
        }

        // Text Post
        if let text = post?.text, text != "" {
            postText.text = text
            viewPostText.isHidden = false
        }else {
            viewPostText.isHidden = true
        }
        
        // Media Post
        if post?.isMediaType == true {
            viewMedia.isHidden = false
            if post?.type == "video" {
                viewVideoPlayer.isHidden = false
                viewVideoPlayer.setVideo(post?.urlMedia, post?.urlThumbnail)
            } else {
                viewVideoPlayer.isHidden = true
                imgviewMedia.setEventImage(post?.urlMedia)
            }
            
            // Posted Image/Video View size
            if let width = post?.width, let height = post?.height, width != 0, height != 0 {
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
        }else {
            viewMedia.isHidden = true
        }

        // Like image
        if let isLike = post?.isLike, isLike == true {
            likeImage.image = UIImage(named: "ic_heart_filled_green")
            likeCount.textColor = AppColor.teal_main
        } else {
            likeImage.image = UIImage(named: "ic_heart_outline_grey")
            likeCount.textColor = .black
        }

        // Like Count label
        if let likesCounts = post?.likesCounts {
            if likesCounts == 0 {
                likeCount.text = ""
                likeCount.isHidden = true
            } else {
                likeCount.isHidden = false
                likeCount.text = "\(likesCounts)"
            }
        }
        
        // Users liked
        viewsUserLiked.forEach { (view) in
            view.isHidden = true
        }
        if let likes = post?.likes {
            for i in 0...2 {
                if i < likes.count {
                    viewsUserLiked.first(where: {$0.tag == i })?.isHidden = false
                    imgviewsUserLiked.first(where: {$0.tag == i })?.setUserImage(likes[i].userDetails?.profileImage)
                }
            }
        }
        
        // Comment Count
        commentView.isHidden = true
        if let commentsCounts = post?.commentsCounts {
            if commentsCounts == 0 {
                commentView.isHidden = true
            } else {
                commentView.isHidden = false
                commentCount.text = "\(commentsCounts)"
            }
        }
    }
    
    private func configureUI(cellType: CellType = .eventPost, isHiddenSeparator: Bool = false) {
        self.cellType = cellType
        viewSeparator.isHidden = isHiddenSeparator

        switch cellType {
        case .eventPost:
            viewMenu.isHidden = true
            viewLikesComments.isHidden = false
            btnMedia.isHidden = true
            postText.isUserInteractionEnabled = false
            break
        case .postDetails:
            viewMenu.isHidden = true
            viewLikesComments.isHidden = true
            btnMedia.isHidden = false
            viewSeparator.isHidden = postModel?.isMediaType ?? isHiddenSeparator
            postText.isUserInteractionEnabled = true
            break
        case .postComment:
            viewMenu.isHidden = false
            viewLikesComments.isHidden = false
            btnMedia.isHidden = false
            postText.isUserInteractionEnabled = true
            break
        }
    }
    
    
    
    @IBAction func actionUserProfileBtn(_ sender: Any) {
        APP_MANAGER.pushUserProfileVC(userId: postModel?.user?._id)
    }
    
    @IBAction func actionLikeBtn(_ sender: Any) {
        APP_MANAGER.likeContent(content: postModel, isLike: !(postModel?.isLike ?? false))
    }
    
    @IBAction func actionMenuBtn(_ sender: Any) {
        let dic = ["post": postModel,
                   "event": eventModel]
        OPTIONS_MANAGER.showMenu(data: dic, menuType: .post, delegate: APP_MANAGER.topVC as? OptionsMenuManagerDelegate)
    }
    
    @IBAction func actionMediaBtn(_ sender: Any) {
        if let type = postModel?.type, type != "" {
            if type == "video" {
                APP_MANAGER.playVideo(postModel?.urlMedia)
            }else if type == "image" {
                APP_MANAGER.openImageVC(imgStr: postModel?.urlMedia, activeEvent: eventModel)
            }
        }
    }
}


