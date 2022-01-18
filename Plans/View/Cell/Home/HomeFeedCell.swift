//
//  HomeFeedCell.swift
//  Plans
//
//  Created by Plans Collective LLC on 4/27/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit

protocol HomeFeedCellDelegate {
    func didTappedJoin(isJoin: Bool, eventModel: EventFeedModel?)
    func didTappedMore(eventModel: EventFeedModel?)
    func didTappedProfile(eventModel: EventFeedModel?)
    func didTappedCaption(eventModel: EventFeedModel?)
}

extension HomeFeedCellDelegate {
    func didTappedJoin(isJoin: Bool, eventModel: EventFeedModel?) {}
    func didTappedMore(eventModel: EventFeedModel?) {}
    func didTappedProfile(eventModel: EventFeedModel?) {}
    func didTappedCaption(eventModel: EventFeedModel?) {}
}

class HomeFeedCell: BaseTableViewCell {
    
    enum CellType {
        case homeFeed
        case eventDetails
    }
    
    // MARK: - IBOutlets
    @IBOutlet weak var viewContainer: UIView!

    @IBOutlet weak var imgViewProfile: UIImageView!
    @IBOutlet weak var liveImage: UIImageView!
    @IBOutlet weak var btnProfile: UIButton!

    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var imvPublicPrivate: UIImageView!
    @IBOutlet weak var lblCreatedAt: UILabel!
    
    @IBOutlet weak var viewJoin: UIView!
    @IBOutlet weak var viewUnjoin: UIView!
    
    @IBOutlet weak var viewMore: UIView!
    @IBOutlet weak var btnMore: UIButton!

    @IBOutlet weak var lblEventName: UILabel!
    
    @IBOutlet weak var viewCaption: UIView!
    @IBOutlet weak var lblCaption: ExpandableLabel!
    
    var delegate : HomeFeedCellDelegate?
    var eventModel : EventFeedModel?
    var cellType: CellType = .homeFeed
    
    class func instantiateFromNib() -> HomeFeedCell{
        return Bundle.main.loadNibNamed(HomeFeedCell.className, owner: self, options: nil)! [0] as! HomeFeedCell
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        lblCaption.delegateExpandable = self
        lblCaption.collapsedAttributedLink = "See more".colored(color: AppColor.grey_text, font: AppFont.regular.size(15.0))
        layoutIfNeeded()

        lblCaption.textReplacementType = .character
        lblCaption.numberOfLines = 3
        lblCaption.collapsed = true
        APP_MANAGER.topVC?.setupActiveLabel(label: lblCaption)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    // MARK: - Home Cell Data
    
    func setupUI(eventModel: EventFeedModel?, delegate: HomeFeedCellDelegate? = nil, cellType: CellType = .homeFeed) {
        layoutIfNeeded()

        self.eventModel = eventModel
        self.delegate = delegate
        self.cellType = cellType
        
        guard let event = eventModel else { return }
        
        // Event name
        lblEventName.text = event.eventName
        
        // Public/Private mark
        imvPublicPrivate.image = UIImage(named: event.isPublic == true ? "ic_public_green" : "ic_private_green")

        // Created At Time
        lblCreatedAt.text = Date(timeIntervalSince1970: event.createdAt ?? 0).timeAgoSince()

        // User profile image
        imgViewProfile.setUserImage(event.eventCreatedBy?.profileImage)
        
        // Live profile around image
        liveImage.isHidden = event.isHostLive == 1 ? false : true
        
        // User name
        lblUserName.text = ""
        if let fname = event.eventCreatedBy?.firstName {
            lblUserName.text = fname
        }
        if let lname = event.eventCreatedBy?.lastName{
            if lblUserName.text == "" {
                lblUserName.text = lname
            }else {
                lblUserName.text! += " " + lname
            }
        }
        
        // Cell type
        switch cellType {
        case .homeFeed:
            // Event Name
            lblEventName.numberOfLines = 2
            
            // More Option
            viewMore.isHidden = false

            // Join button/label
            var titleJoin : String?
            if let userId = USER_MANAGER.userId, userId == event.eventCreatedBy?.userId { // Host is me
                titleJoin = nil
            }else if event.isPublic == true {  // Public event
                if event.isInvite == 1 {       ////// Invited event
                    titleJoin = nil
                } else if event.didLeave == 1, event.isLive == 1 {
                    titleJoin = "Join"
                }else if event.isJoin == true, event.isLive == 0 {
                    titleJoin = "Unjoin"
                } else if event.isJoin == false{
                    titleJoin = "Join"
                }
            }
            viewJoin.isHidden = titleJoin == nil || titleJoin == "Unjoin"
            viewUnjoin.isHidden = titleJoin == nil || titleJoin == "Join"

            // Event Caption
            if let caption = event.caption, caption.count > 0 {
                viewCaption.isHidden = false
                lblCaption.text = caption
            }else {
                lblCaption.text = ""
                viewCaption.isHidden = true
            }

            break
        case .eventDetails:
            // Event Name
            lblEventName.numberOfLines = 0
            viewJoin.isHidden = true
            viewUnjoin.isHidden = true
            viewMore.isHidden = true
            viewCaption.isHidden = true
            break
        }
    }
    
    @IBAction func actionMore(_ sender: Any) {
        delegate?.didTappedMore(eventModel: eventModel)
    }
    @IBAction func actionUnjoin(_ sender: Any) {
        delegate?.didTappedJoin(isJoin: false, eventModel: eventModel)
    }
    @IBAction func actionJoin(_ sender: UIButton) {
        delegate?.didTappedJoin(isJoin: true, eventModel: eventModel)
    }
    @IBAction func actionProfile(_ sender: Any) {
        delegate?.didTappedProfile(eventModel: eventModel)
    }
    @IBAction func actionCaption(_ sender: Any) {
        delegate?.didTappedCaption(eventModel: eventModel)
    }
    
}

extension HomeFeedCell : ExpandableLabelDelegate {
    func didTapAttributedLink(_ label: ExpandableLabel) {
        APP_MANAGER.pushDetailsOfEventVC(event: eventModel)
    }
    
    func didTapText(_ label: ExpandableLabel) {
        APP_MANAGER.pushEventDetailsVC(event: eventModel)
    }
}
