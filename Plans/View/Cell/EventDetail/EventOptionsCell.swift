//
//  EventOptionsCell.swift
//  Plans
//
//  Created by Plans Collective LLC on 5/17/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit

protocol EventOptionsCellDelegate {
    func eventOptions(didEdit event: EventFeedModel?)
    func eventOptions(didInvite event: EventFeedModel?)
    func eventOptions(didDetails event: EventFeedModel?)
    func eventOptions(didChat event: EventFeedModel?)
    func eventOptions(didGuestAction actionName: String?, event: EventFeedModel?)
}

extension EventOptionsCellDelegate {
    func eventOptions(didEdit event: EventFeedModel?){}
    func eventOptions(didInvite event: EventFeedModel?){}
    func eventOptions(didDetails event: EventFeedModel?){}
    func eventOptions(didChat event: EventFeedModel?){}
    func eventOptions(didGuestAction actionName: String?, event: EventFeedModel?){}
}

class EventOptionsCell: BaseTableViewCell {
    
    // MARK: - IBOutlets
    
    // You're Here / Not Here
    @IBOutlet weak var viewHere: UIView!
    @IBOutlet weak var imgviewHere: UIImageView!
    @IBOutlet weak var lblHere: UILabel!
    @IBOutlet weak var btnHere: UIButton!
    @IBOutlet weak var viewArrowDownHere: UIView!
    @IBOutlet weak var imgvArrowDownHere: UIImageView!
    
    // Edit/Update for the host
    @IBOutlet weak var viewEdit: UIView!
    @IBOutlet weak var lblEdit: UILabel!
    @IBOutlet weak var imageEdit: UIImageView!
    @IBOutlet weak var btnEdit: UIButton!
    
    // Guest Actions for Join/Unjoin, Pending Invite, Going, Maybe, Next Time
    @IBOutlet weak var viewGuestAction: UIView!
    @IBOutlet weak var imgviewGuestAction: UIImageView!
    @IBOutlet weak var lblGuestAction: UILabel!
    @IBOutlet weak var btnGuestAction: UIButton!
    @IBOutlet weak var viewDownArrow: UIView!
    @IBOutlet weak var imgviewDownArrow: UIImageView!
    
    // Invite the friends of the host
    @IBOutlet weak var inviteView: UIView!
    @IBOutlet weak var lblInvite: UILabel!
    @IBOutlet weak var imageInvite: UIImageView!
    @IBOutlet weak var btnInvite: UIButton!
    
    // Details
    @IBOutlet weak var viewDetails: UIView!
    @IBOutlet weak var btnDetails: UIButton!
    
    // Chat
    @IBOutlet weak var chatView: UIView!
    @IBOutlet weak var lblUnreadMsgCount: UILabel!
    @IBOutlet weak var widthUnreadMsgCount: NSLayoutConstraint!
    @IBOutlet weak var btnChat: UIButton!
    
    // Guide View
    @IBOutlet weak var viewGuide: UIView!
    

    
    // MARK: - Properties
    var eventModel: EventFeedModel?
    var delegate: EventOptionsCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        NOTIFICATION_CENTER.addObserver(self, selector: #selector(getChatList(_:)), name: NSNotification.Name(rawValue: kChatListChanged), object: nil)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    deinit {
        NOTIFICATION_CENTER.removeObserver(self)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.updateConstraintsIfNeeded()
    }
    
    @objc func getChatList(_ notification: Notification)
    {
        lblUnreadMsgCount?.isHidden = true
        guard let chatList = notification.object as? [ChatModel] else { return }
        guard let chatId = eventModel?.chatId else { return }
        guard let chat = chatList.first(where: {$0._id == chatId}) else { return }

        updateUnreadMsgCount(count: chat.unreadMessages?.count ?? 0)
    }
    
    func updateUnreadMsgCount(count: Int?) {
        guard let count = count, count > 0 else {
            lblUnreadMsgCount?.isHidden = true
            return
        }
        let strCount = "\(count)"
        lblUnreadMsgCount?.text = strCount
        let width = strCount.width(withConstraintedHeight: 18.0, font: AppFont.regular.size(12.0)) + 10
        if width > 18.0 {
            widthUnreadMsgCount.constant = width
        }else {
            widthUnreadMsgCount.constant = 18.0
        }
        lblUnreadMsgCount?.isHidden = false
    }

    
    func setupUI(event: EventFeedModel?, delegate: EventOptionsCellDelegate? = nil) {
        guard let event = event else { return }
        
        eventModel = event
        self.delegate = delegate

        updateUnreadMsgCount(count: event.chatInfo?.countUnreadMessages)

        if event.userId == USER_MANAGER.userId {
            setupUIForHost()
        }else {
            setupUIForGuest()
        }
        
        updateGuideView()
        
        layoutIfNeeded()
        setNeedsDisplay()
    }
    
    func updateGuideView() {
        if chatView.isHidden == false, USER_MANAGER.isSeenGuideChatWithEventGuest == false {
            viewGuide.isHidden = false
        }else {
            viewGuide.isHidden = true
        }
    }
    
    func setupUIForGuest() {
        guard let event = eventModel else { return }
        
        viewHere.isHidden = true
        viewEdit.isHidden = true
        viewGuestAction.isHidden = false
        inviteView.isHidden = true
        viewDetails.isHidden = false
        chatView.isHidden = true
        lblGuestAction.textColor = .black
        viewDownArrow.isHidden = true
        viewArrowDownHere.isHidden = true

        if event.isEnded == true || event.isActive == false || event.isCancel == true || event.isExpired == true {
            ///////////////////////////////////// Event Ended, Delelted, Cancelled, Expired
            viewHere.isHidden = false
            lblHere.textColor = .black
            imgviewHere.image = UIImage(named: "ic_flag_purple")
            if event.isEnded == true {
                lblHere.textColor = AppColor.purple_join
                lblHere.text = "Ended"
                imgviewHere.changeColor(AppColor.purple_join)
            }else if event.isActive == false || event.isCancel == true {
                lblHere.textColor = AppColor.brown_cancelled
                lblHere.text = "Canceled"
                imgviewHere.changeColor(AppColor.brown_cancelled)
            }else if event.isExpired == true {
                lblHere.textColor = AppColor.orange_expired
                lblHere.text = "Expired"
                imgviewHere.changeColor(AppColor.orange_expired)
            }
            
            viewGuestAction.isHidden = true
        }else if event.isLive == 1 {
            ///////////////////////////////////// Event Lived
            if event.isJoin == true {
                // Attended by host's invitation or by yourself joined
                if event.joinStatus == 4 {
                    lblGuestAction.text = "Next Time"
                    imgviewGuestAction.image = UIImage(named: "ic_x_circle_black")
                    viewDownArrow.isHidden = false
                    imgviewDownArrow.changeColor(.black)
                }else if event.isLiveUser(USER_MANAGER.userId) == true {
                    lblHere.textColor = AppColor.teal_main
                    lblHere.text = "You're Here"
                    imgviewHere.image = UIImage(named: "ic_check_circle_green")
                    imgvArrowDownHere.changeColor(AppColor.teal_main)
                    viewArrowDownHere.isHidden = false
                    viewGuestAction.isHidden = true
                    viewHere.isHidden = false
                }else {
                    lblHere.textColor = AppColor.red_not_here
                    lblHere.text = "Not Here"
                    imgviewHere.image = UIImage(named: "ic_minus_circle_red")
                    imgvArrowDownHere.changeColor(AppColor.red_not_here)
                    viewArrowDownHere.isHidden = false
                    viewGuestAction.isHidden = true
                    viewHere.isHidden = false
                }
            }else {
                // Not Attended by host's invitation or by yourself joined
                if event.isInvite == 1 {
                    lblGuestAction.textColor = .black
                    lblGuestAction.text = "Pending Invite"
                    imgviewGuestAction.image = UIImage(named: "ic_clock_black")
                    viewDownArrow.isHidden = false
                    imgviewDownArrow.changeColor(.black)
                }else {
                    lblGuestAction.text = "Join"
                    imgviewGuestAction.image = UIImage(named: "ic_plus_black")
                }
            }
        }else {
            ///////////////////////////////////// Before live
            if event.isJoin == true {
                // Attended by host's invitation or by yourself joined
                if event.isInvite == 1 { // By host's invitation
                    if event.joinStatus == 2 {
                        lblGuestAction.textColor = AppColor.teal_main
                        lblGuestAction.text = "Going"
                        imgviewGuestAction.image = UIImage(named: "ic_check_circle_green")
                        viewDownArrow.isHidden = false
                        imgviewDownArrow.changeColor(AppColor.teal_main)
                    }else if event.joinStatus == 3 {
                        lblGuestAction.text = "Maybe"
                        imgviewGuestAction.image = UIImage(named: "ic_clock_black")
                        viewDownArrow.isHidden = false
                        imgviewDownArrow.changeColor(.black)
                    }else if event.joinStatus == 4 {
                        lblGuestAction.text = "Next Time"
                        imgviewGuestAction.image = UIImage(named: "ic_x_circle_black")
                        viewDownArrow.isHidden = false
                        imgviewDownArrow.changeColor(.black)
                    }
                }else { // By yourself joined
                    lblGuestAction.textColor = AppColor.teal_main
                    lblGuestAction.text = "Joined"
                    imgviewGuestAction.image = UIImage(named: "ic_user_check_green")
                }
            }else {
                // Not Attended by host's invitation or by yourself joined
                if event.isInvite == 1 { // By host's invitation
                    lblGuestAction.textColor = .black
                    lblGuestAction.text = "Pending Invite"
                    imgviewGuestAction.image = UIImage(named: "ic_clock_black")
                    viewDownArrow.isHidden = false
                    imgviewDownArrow.changeColor(.black)
                }else { // By yourself joined
                    lblGuestAction.text = "Join"
                    imgviewGuestAction.image = UIImage(named: "ic_plus_black")
                }
            }
        }
        
        // Chat view
        if (event.joinStatus == 2 || event.joinStatus == 3), event.isGroupChatOn == 1 {
            chatView.isHidden = false
        }
    }
    
    func setupUIForHost() {
        guard let event = eventModel else { return }

        viewHere.isHidden = true
        viewEdit.isHidden = false
        viewGuestAction.isHidden = true
        inviteView.isHidden = false
        viewDetails.isHidden = false
        chatView.isHidden = true
        viewArrowDownHere.isHidden = true
        
        // Other Views
        if event.isEnded == true {
            ///////////////////////////////////// Event Ended
            viewHere.isHidden = false
            lblHere.textColor = AppColor.purple_join
            lblHere.text = "Ended"
            imgviewHere.image = UIImage(named: "ic_flag_purple")

            viewEdit.isHidden = true
            inviteView.isHidden = true
        }else if event.isActive == false || event.isCancel == true || event.isExpired == true {
            ///////////////////////////////////// Event Delelted, Cancelled, Expired
            inviteView.isHidden = true
            lblEdit.textColor = .black
            lblEdit.text = "Update"
            imageEdit.image = UIImage(named: "ic_pencil_black")
        }else if event.isLive == 1 {
            ///////////////////////////////////// Event Lived
            viewHere.isHidden = false
            viewEdit.isHidden = true
            if event.isHostLive == 1 {
                lblHere.textColor = AppColor.teal_main
                lblHere.text = "You're Here"
                imgviewHere.image = UIImage(named: "ic_check_circle_green")
            }else {
                lblHere.textColor = AppColor.red_not_here
                lblHere.text = "Not Here"
                imgviewHere.image = UIImage(named: "ic_minus_circle_red")
            }
        }else {
            ///////////////////////////////////// Before live
            lblEdit.textColor = .black
            lblEdit.text = "Edit"
            imageEdit.image = UIImage(named: "ic_pencil_black")
        }
        
        // Chat View
        if event.isGroupChatOn == 1 {
            chatView.isHidden = false
        }
        
    }
    
    // MARK: - User Actions
    
    @IBAction func actionHere(_ sender: Any) {
        if eventModel?.userId != USER_MANAGER.userId, eventModel?.isLive == 1 {
            delegate?.eventOptions(didGuestAction: lblHere.text, event: eventModel)
        }
    }

    @IBAction func actionEdit(_ sender: Any) {
        delegate?.eventOptions(didEdit: eventModel)
    }
    
    @IBAction func actionInvite(_ sender: Any) {
        delegate?.eventOptions(didInvite: eventModel)
    }
    
    @IBAction func actionDetails(_ sender: Any) {
        delegate?.eventOptions(didDetails: eventModel)
    }
    
    @IBAction func actionChat(_ sender: Any) {
        USER_MANAGER.isSeenGuideChatWithEventGuest = true
        delegate?.eventOptions(didChat: eventModel)
    }
    
    @IBAction func actionGuideChatWithGuests(_ sender: Any) {
        actionChat(self)
    }
    
    @IBAction func actionGuestActions(_ sender: Any) {
        delegate?.eventOptions(didGuestAction: lblGuestAction.text, event: eventModel)
    }
    
}
