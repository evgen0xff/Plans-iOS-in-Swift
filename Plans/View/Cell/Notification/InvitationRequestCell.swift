//
//  InvitationRequestCell.swift
//  Plans
//
//  Created by Star on 2/25/21.
//

import UIKit

class InvitationRequestCell: BaseTableViewCell {
    
    
    @IBOutlet weak var containerRequest: UIView!
    @IBOutlet weak var lblTitleRequest: UILabel!
    @IBOutlet var viewImages: [UIView]!
    @IBOutlet var imgvImages: [UIImageView]!
    @IBOutlet weak var lblDescription: UILabel!
    
    @IBOutlet weak var containerEvent_Friend: UIView!
    
    @IBOutlet weak var imgvEventInvite: UIImageView!
    @IBOutlet weak var lblCountEventInvite: UILabel!
    
    @IBOutlet weak var imgvFriendRequest: UIImageView!
    @IBOutlet weak var lblCountFriendRequest: UILabel!
    
    
    var notification: NotificationModel?
    
    var listEventList: [EventFeedModel] = []
    var usersInvited: [UserModel] = []
    var usersInvitedLast3: [UserModel] = []
    var listFriendRequest: [FriendRequestModel] = []
    var listFriendRequestLast3: [FriendRequestModel] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: - User Actions
    @IBAction func actionRequestBtn(_ sender: Any) {
        if usersInvited.count > 0 {
            actionEventInvite(self)
        }else {
            actionFriendRequest(self)
        }
    }
    
    @IBAction func actionEventInvite(_ sender: Any) {
        APP_MANAGER.pushEventInvitationsVC()
    }
    
    @IBAction func actionFriendRequest(_ sender: Any) {
        APP_MANAGER.pushFriendRequestsVC()
    }
    
    
    
    // MARK: - Public Methods
    
    func setupUI(notificationModel: NotificationModel?){
        notification = notificationModel
        updateData()
        updateUI()
    }
    
    
    // MARK: - Private Methods
    func updateData() {
        // Event Invitation
        listEventList.removeAll()
        usersInvited.removeAll()
        usersInvitedLast3.removeAll()
        
        if let list = notification?.eventInvitationList, list.count > 0 {
            listEventList.append(contentsOf: list)
        }
        
        listEventList.forEach { (event) in
            if let host = event.eventCreatedBy,
               usersInvited.contains(where:{$0.userId == host.userId}) == false {
                usersInvited.append(host)
            }
        }
        
        usersInvited.sort { (item1, item2) -> Bool in
            let event1 = listEventList.first { (item) -> Bool in
                if item.eventCreatedBy?.userId == item1.userId {
                    return true
                }
                return false
            }
            let event2 = listEventList.first { (item) -> Bool in
                if item.eventCreatedBy?.userId == item2.userId {
                    return true
                }
                return false
            }
            let invite1 = event1?.invitationDetails?.first(where: { (invite) -> Bool in
                if invite.userId == USER_MANAGER.userId {
                    return true
                }
                return false
            })
            let invite2 = event2?.invitationDetails?.first(where: { (invite) -> Bool in
                if invite.userId == USER_MANAGER.userId {
                    return true
                }
                return false
            })
            if let time1 = invite1?.invitationTime, let time2 = invite2?.invitationTime, time1 < time2 {
                return true
            }
            return false
        }
        
        usersInvitedLast3 = usersInvited.suffix(3)
        
        // Friend Requests
        listFriendRequest.removeAll()
        listFriendRequestLast3.removeAll()
        if let response = notification?.friendRequestList, response.count > 0 {
            listFriendRequest.append(contentsOf: response)
            listFriendRequestLast3 = listFriendRequest.suffix(3)
        }

    }
    
    func updateUI() {
        containerRequest.isHidden = true
        containerEvent_Friend.isHidden = true

        if usersInvited.count > 0 && listFriendRequest.count > 0 {
            containerEvent_Friend.isHidden = false
            updateEvent_FriendUI()
        }else {
            containerRequest.isHidden = false
            updateRequestUI()
        }
    }
    
    func updateEvent_FriendUI() {
        imgvEventInvite.setUserImage(usersInvited.last?.profileImage)
        lblCountEventInvite.text = "\(notification?.eventInvitationCount ?? 0)"
        
        imgvFriendRequest.setUserImage(listFriendRequest.last?.senderDetail?.profileImage)
        lblCountFriendRequest.text = "\(notification?.friendRequestCount ?? 0)"
    }
    
    func updateRequestUI(){
        lblDescription.text = ""
        var addmorestr = ""
        if usersInvitedLast3.count > 0 {
            lblTitleRequest.text = "Event Invitations"
            var txt: [String] = []
            for (index, item) in usersInvitedLast3.enumerated() {
                var fullName = "\(item.firstName ?? "")"
                fullName += item.lastName != nil ? " \(item.lastName!)" : ""
                txt.append(fullName)
                imgvImages.first(where: {$0.tag == index})?.setUserImage(item.profileImage)
            }
            viewImages.forEach({$0.isHidden = $0.tag >= usersInvitedLast3.count})
            
            if usersInvited.count > 3{
                addmorestr = "<bold>" + txt[2] + ",</bold> <bold>" + txt[1] + "</bold> and <bold>\(self.usersInvited.count - 2) others</bold> sent you an event invitation."
            }
            else if usersInvited.count == 3 {
                addmorestr = "<bold>" + txt[2] + ",</bold> <bold>" + txt[1] + "</bold> and <bold>1 other</bold> sent you an event invitation."
            }
            else if usersInvited.count == 2 {
                addmorestr = "<bold>" + txt[1] + "</bold> and <bold>" + txt[0] + "</bold> sent you an event invitation."
            } else {
                addmorestr = "<bold>" + txt[0] + "</bold> sent you an event invitation."
            }
        }else if listFriendRequestLast3.count > 0 {
            lblTitleRequest.text = "Friend Requests"
            var txt: [String] = []
            for (index, item) in listFriendRequestLast3.enumerated() {
                var fullName = "\(item.senderDetail?.firstName ?? "")"
                fullName += item.senderDetail?.lastName != nil ? " \(item.senderDetail!.lastName!)" : ""
                txt.append(fullName)
                imgvImages.first(where: {$0.tag == index})?.setUserImage(item.senderDetail?.profileImage)
            }
            viewImages.forEach({$0.isHidden = $0.tag >= listFriendRequestLast3.count})

            if listFriendRequest.count > 3 {
                addmorestr = "<bold>" + txt[2] + ",</bold> <bold>" + txt[1] + "</bold> and <bold>\(listFriendRequest.count - 2) others</bold>" + " sent you a friend request."
            } else if listFriendRequest.count == 3 {
                addmorestr = "<bold>" + txt[2] + ",</bold> <bold>" + txt[1] + "</bold> and <bold>1 other</bold> sent you a friend request."
            }
            else if listFriendRequest.count == 2 {
                addmorestr = "<bold>" + txt[1] + "</bold> and <bold>" + txt[0] + "</bold> sent you a friend request."
            } else {
                addmorestr = "<bold>" + txt[0] + "</bold> sent you a friend request."
            }
        }
        lblDescription.attributedText = addmorestr.set(style: AppLabelStyleGroup.notification)
    }
    
}
