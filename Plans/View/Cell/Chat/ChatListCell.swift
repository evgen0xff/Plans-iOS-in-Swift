//
//  ChatListCell.swift
//  Plans
//
//  Created by Plans Collective LLC on 5/27/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit

protocol ChatListCellDelegate {
    func didLongPressed(chatModel: ChatModel?)
}

extension ChatListCellDelegate {
    func didLongPressed(chatModel: ChatModel?){}
}

class ChatListCell: BaseTableViewCell {

    // MARK: - IBOutlets
    @IBOutlet var viewsProfiles: [UIView]!
    @IBOutlet var imgvsProfiles: [UIImageView]!

    @IBOutlet weak var stackHeaderView: UIStackView!
    @IBOutlet weak var lblLive: UILabel!
    @IBOutlet weak var lblUnreadCount: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblDot: UILabel!
    @IBOutlet weak var imgViewLive: UIImageView!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var lblLastmessage: UILabel!
    @IBOutlet weak var viewPhoto: UIView!
    @IBOutlet weak var viewVideo: UIView!
    @IBOutlet weak var imgviewMute: UIImageView!

    @IBOutlet weak var widthNameLbl: NSLayoutConstraint!
    @IBOutlet weak var widthChatTime: NSLayoutConstraint!
    @IBOutlet weak var widthLiveTimeLbl: NSLayoutConstraint!
    @IBOutlet weak var widthUnreadCount: NSLayoutConstraint!

    @IBOutlet weak var viewBottomSeparator: UIView!
    @IBOutlet weak var viewGuide: UIView!
    
    var chatModel: ChatModel?
    var delegate : ChatListCellDelegate?
    var isFirst = false

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(actionLongPressed))
        addGestureRecognizer(longGesture)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: - User Actions
    @IBAction func actionProfileImage(_ sender: Any) {
        openProfileEvent()
    }

    @objc func actionLongPressed(gesture: UILongPressGestureRecognizer) {
        
        switch gesture.state {
        case .began:
            USER_MANAGER.isSeenGuideTapHoldChat = true
            updateGuideView()
            delegate?.didLongPressed(chatModel: chatModel)
            break
        default:
            break
        }
    }
    
    // MARK: - Private Methods
    private func updateGuideView() {
        viewGuide.isHidden = !(isFirst && !USER_MANAGER.isSeenGuideTapHoldChat)
    }
    
    private func openProfileEvent() {
        if chatModel?.isEventChat == true {
            if let isCancel = chatModel?.event?.isCancel,
               let isActive = chatModel?.event?.isActive {
                var isAccess = false
                if isActive == false {
                    isAccess = false
                }else if chatModel?.organizer?._id == USER_MANAGER.userId {
                    isAccess = true
                }else if isCancel == true {
                    isAccess = false
                }else if chatModel?.event?.isExpired == true  {
                    isAccess = false
                }else {
                    isAccess = true
                }
                
                if isAccess == true {
                    APP_MANAGER.pushEventDetailsVC(eventId: chatModel?.eventId)
                }
            }
        }else {
            APP_MANAGER.pushUserProfileVC(userId: chatModel?.profileUser?._id)
        }
    }

    
    // MARK: - Public Methods
    
    func configure (model: ChatModel?,
                    delegate: ChatListCellDelegate? = nil,
                    isHiddenSeparator: Bool = false,
                    isFirst: Bool = false
    ) {
        
        chatModel = model
        self.delegate = delegate
        self.isFirst = isFirst

        viewBottomSeparator.isHidden = isHiddenSeparator
        
        guard let model = model else { return }
        
        // Profile Images
        imgvsProfiles.first(where: {$0.tag == 0})?.setUserImage(model.profileImage)

        viewsProfiles.first(where: {$0.tag == 1})?.isHidden = model.profileNextUser == nil
        imgvsProfiles.first(where: {$0.tag == 1})?.setUserImage(model.profileNextUser?.profileImage)
        
        var widthUsed: CGFloat = 13.0 + (viewsProfiles.filter({$0.isHidden == false}).count > 1 ? 68.0 : 44.0) + 6.0 + 15.0
        
        // Event Status
        if model.isEventChat == true {
            imgViewLive.isHidden = true
            lblDot.isHidden = false
            lblLive.isHidden = false
            if model.event?.isActive == false ||
                model.event?.isCancel == true {
                lblLive.text = "Cancelled"
            }else if model.event?.isEnded == true {
                lblLive.text = "Ended"
            }else if model.event?.isLive == 1 {
                lblLive.isHidden = true
                imgViewLive.isHidden = false
                lblDot.isHidden = false
            }else if model.event?.isExpired == true {
                lblLive.text = "Expired"
            }else if let startTime = model.event?.startTime{
                lblLive.text = Date(timeIntervalSince1970: startTime).getTodayTomorrowString(isStarted: model.event?.isLive == 1 ? true : false)
            }else {
                lblLive.isHidden = true
                imgViewLive.isHidden = true
                lblDot.isHidden = true
            }
            lblLive.textColor = EventFeedModel.getEventStatusColor(from: lblLive.text)
            widthLiveTimeLbl.constant = lblLive.text?.width(withConstraintedHeight: 21.0, font: AppFont.regular.size(13.0)) ?? 0
        }else {
            lblLive.isHidden = true
            imgViewLive.isHidden = true
            lblDot.isHidden = true
        }

        // Updated Time
        if let createdAt = model.lastMessageTime {
            lblTime.isHidden = false
            lblTime.text = Date(timeIntervalSince1970: createdAt).timeAgoSince()
            widthChatTime.constant = lblTime.text?.width(withConstraintedHeight: 21.0, font: AppFont.regular.size(13.0)) ?? 0
        } else {
            lblTime.isHidden = true
        }
        
        // Calculate the width of chat Name Label
        if lblTime.isHidden == false {
            widthUsed += widthChatTime.constant + 4.0
        }
        
        widthUsed += 4.0 // For empty view width
        
        if lblLive.isHidden == false {
            widthUsed += widthLiveTimeLbl.constant + 4.0
        }

        if imgViewLive.isHidden == false {
            widthUsed += imgViewLive.bounds.width + 4.0
        }

        if lblDot.isHidden == false {
            widthUsed += lblDot.bounds.width + 4.0
        }
        
        // Chat Name
        let widthAvailable = MAIN_SCREEN_WIDTH - widthUsed
        let widthText = model.titleChat?.width(withConstraintedHeight: 21.0, font: AppFont.bold.size(17.0)) ?? 0
        if widthText > widthAvailable {
            widthNameLbl.constant = widthAvailable
            stackHeaderView.spacing = 0.0
        }else {
            widthNameLbl.constant = widthText
            stackHeaderView.spacing = 4.0
        }
        lblName.text = model.titleChat

        // Unread Count
        if let unreadCount = model.unreadMessages?.count, unreadCount != 0 {
            let strUnreadCount = String(unreadCount)
            lblUnreadCount.text = strUnreadCount
            let width = strUnreadCount.width(withConstraintedHeight: 18.0, font: AppFont.regular.size(13.0)) + 10
            widthUnreadCount.constant = width > 18.0 ? width : 18.0
            lblUnreadCount.isHidden = false
        } else {
            lblUnreadCount.isHidden = true
        }
        
        // Mute Notification
        if model.isMuteNotification == true {
            imgviewMute.isHidden = false
        }else {
            imgviewMute.isHidden = true
        }
        
        // Last message/photo/video
        viewVideo.isHidden = true
        viewPhoto.isHidden = true

        let lastMessageAttri = NSMutableAttributedString()
        var userName : String?
        if model.lastMessage?.user?._id == USER_MANAGER.userId {
            userName = "You: "
        }else if model.isGroup == true {
            userName = "\(model.lastMessage?.user?.firstName ?? ""): "
        }
        
        if let name = userName {
            lastMessageAttri.append(name.colored(color: .black, font: AppFont.bold.size(15.0)))
        }

        if model.lastMessage?.type == .text, let text = model.lastMessage?.message {
            lastMessageAttri.append(text.colored(color: .black, font: AppFont.regular.size(15.0)))
        }else if model.lastMessage?.type == .video {
            viewVideo.isHidden = false
        }else if model.lastMessage?.type == .image{
            viewPhoto.isHidden = false
        }
        
        lblLastmessage.text = ""
        lblLastmessage.attributedText = lastMessageAttri
        lblLastmessage.lineBreakMode = .byTruncatingTail
        
        updateGuideView()
    }
    
}

