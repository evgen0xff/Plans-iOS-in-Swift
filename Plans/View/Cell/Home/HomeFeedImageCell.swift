//
//  HomeFeedImageCell.swift
//  Plans
//
//  Created by Plans Collective LLC on 5/1/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit
import SDWebImage

class HomeFeedImageCell: BaseTableViewCell {
    
    enum CellType {
        case normal
        case overTop
    }
    
    // MARK: - IBOutlets
    @IBOutlet weak var heightContent: NSLayoutConstraint!
    
    @IBOutlet weak var imgViewEventImage: UIImageView!
    @IBOutlet weak var viewVideoPlayer: PlansVideoPlayerView!
    
    @IBOutlet weak var viewTopBar: UIStackView!
    @IBOutlet weak var topMarginTopBarView: NSLayoutConstraint!
    
    @IBOutlet weak var viewBackBtn: UIView!
    @IBOutlet weak var viewMenuBtn: UIView!
    
    @IBOutlet weak var containerLiveTime: UIView!
    
    @IBOutlet weak var viewLive: UIView!
    @IBOutlet weak var imgviewLive: UIImageView!

    @IBOutlet weak var viewTime: UIView!
    @IBOutlet weak var imgviewClock: UIImageView!
    @IBOutlet weak var lblTime: UILabel!
    
    
    @IBOutlet weak var viewBottomGradient: UIView!
    
    @IBOutlet weak var viewsView: UIView!
    @IBOutlet weak var lblView: UILabel!

    @IBOutlet weak var viewPost: UIView!
    @IBOutlet weak var lblPost: UILabel!

    @IBOutlet weak var viewFriend: UIView!
    @IBOutlet weak var lblFriend: UILabel!
    
    @IBOutlet weak var btnMedia: UIButton!
    
    var event: EventFeedModel?
    var cellType: CellType = .normal
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        viewVideoPlayer.typeUI = .plansEvent
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    // MARK: - Home Cell Data
    
    func configureHomeCell(eventModel: EventFeedModel?, cellType: CellType = .normal) {
        self.event = eventModel
        self.cellType = cellType
        
        configure(cellType: cellType)
        viewBottomGradient.isHidden = true

        // Event Cover Image/Video
        var urlImage: String?
        if event?.mediaType == "video" {
            urlImage = event?.thumbnail
            viewVideoPlayer.isHidden = false
            viewVideoPlayer.setVideo(event?.imageOrVideo, urlImage)
        } else {
            viewVideoPlayer.isHidden = true
            urlImage = event?.imageOrVideo
        }
        imgViewEventImage.setEventImage(urlImage){_ in
            self.viewBottomGradient.isHidden = false
        }

        // Views Count
        viewsView.isHidden = true
        if let viewedCounts = event?.viewedCounts {
            if viewedCounts == 0 {
                viewsView.isHidden = true
            } else if viewedCounts == 1 {
                viewsView.isHidden = false
                lblView.text = "\(viewedCounts) View"
            } else {
                viewsView.isHidden = false
                lblView.text = "\(viewedCounts) Views"
            }
        }
        
        // Posts Count
        viewPost.isHidden = true
        if let postCounts = event?.postCounts {
            if postCounts == 0 {
                viewPost.isHidden = true
            } else if postCounts == 1 {
                viewPost.isHidden = false
                lblPost.text = "\(postCounts) Post"
            } else {
                viewPost.isHidden = false
                lblPost.text = "\(postCounts) Posts"
            }
        }
            
        // Friends Count
        viewFriend.isHidden = true
        if let friendsCount = event?.getFriendsCount() {
            if friendsCount == 0 {
                viewFriend.isHidden = true
            } else if friendsCount == 1 {
                viewFriend.isHidden = false
                lblFriend.text = "\(friendsCount) Friend"
            } else {
                viewFriend.isHidden = false
                lblFriend.text = "\(friendsCount) Friends"
            }
        }
        
        // Time Label
        let status = event?.getEventStatus()
        lblTime.textColor = status?.color
        lblTime.text = status?.title
        imgviewClock.changeColor(status?.color)
        
        // For text color updated issue in iOS 12.0
        APP_CONFIG.defautMainQ.async {
            self.lblTime.textColor = status?.color
        }

        // Live View
        if let isLive = event?.isLive, isLive == 1 {
            viewLive.isHidden = false
        }else {
            viewLive.isHidden = true
        }
        
        imgviewLive.alpha = 1.0
        let options : UIView.AnimationOptions = .repeat
        UIView.animate(withDuration: 1.0, delay:0.0, options:options, animations: {
            self.imgviewLive.alpha = 0.0
        }, completion: nil)
        
    }
    
    private func configure(cellType: CellType = .normal) {
        switch cellType {
        case .overTop :
            heightContent.constant = (MAIN_SCREEN_WIDTH * 2.0 / 3.0) + (UIDevice.current.hasTopNotch ? UIDevice.current.heightTopNotch : 0)
            topMarginTopBarView.constant = UIDevice.current.heightTopNotch
            viewBackBtn.isHidden = false
            viewMenuBtn.isHidden = false
            btnMedia.isHidden = false
            if event?.isEnded == true {
                containerLiveTime.isHidden = true
            }else {
                containerLiveTime.isHidden = false
            }
            break
        default:
            heightContent.constant = MAIN_SCREEN_WIDTH / 1.77
            topMarginTopBarView.constant = 1.0
            viewBackBtn.isHidden = true
            viewMenuBtn.isHidden = true
            btnMedia.isHidden = true
            break
        }
    }
    
    @IBAction func actionBackBtn(_ sender: Any) {
        APP_MANAGER.popViewContorller()
    }
    
    @IBAction func actionMenuBtn(_ sender: Any) {
        OPTIONS_MANAGER.showMenu(data: event, menuType: .eventDetails, delegate: (APP_MANAGER.topVC as? OptionsMenuManagerDelegate) , sender: APP_MANAGER.topVC)
    }
    
    @IBAction func actionMediaBtn(_ sender: Any) {
        if let mediaType = event?.mediaType {
            if mediaType == "image" {
                APP_MANAGER.openImageVC(imgStr: event?.imageOrVideo, title: event?.eventName, activeEvent: event)
            }else if mediaType == "video" {
                APP_MANAGER.playVideo(event?.imageOrVideo)
            }
        }

    }
}

