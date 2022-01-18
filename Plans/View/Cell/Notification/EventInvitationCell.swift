//
//  EventInvitationCell.swift
//  Plans
//
//  Created by Plans Collective LLC on 5/27/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit

protocol EventTableCellDelegate {
    func didTapHostProfile(sender: UITableViewCell, eventModel: EventFeedModel?)
    func didTapEventDetail(sender: UITableViewCell, eventModel: EventFeedModel?)
    func didTapGoingMaybeNextTime(sender: UITableViewCell, eventModel: EventFeedModel?, status: JoinType)
    func didTapHide(sender: UITableViewCell, eventModel: EventFeedModel?)
}

extension EventTableCellDelegate {
    func didTapHostProfile(sender: UITableViewCell, eventModel: EventFeedModel?){}
    func didTapEventDetail(sender: UITableViewCell, eventModel: EventFeedModel?){}
    func didTapGoingMaybeNextTime(sender: UITableViewCell, eventModel: EventFeedModel?, status: JoinType){}
    func didTapHide(sender: UITableViewCell, eventModel: EventFeedModel?){}
}


class EventInvitationCell: BaseTableViewCell {

    // MARK: - IBOutlets
    
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var eventName: UILabel!
    @IBOutlet weak var dateTimeLbl: UILabel!
    @IBOutlet weak var lblInvitedTime: UILabel!
    @IBOutlet weak var heightDateTimeLbl: NSLayoutConstraint!
    @IBOutlet weak var widthInvitedTimeLbl: NSLayoutConstraint!
    
    var delegate : EventTableCellDelegate?
    var eventModel: EventFeedModel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func configureCell(feedModel: EventFeedModel, delegate: EventTableCellDelegate? = nil) {
        
        self.delegate = delegate
        self.eventModel = feedModel
        
        profileImg.setUserImage(feedModel.eventCreatedBy?.profileImage)
        if let fname = feedModel.eventCreatedBy?.firstName,
            let lname = feedModel.eventCreatedBy?.lastName {
            userName.text = "Organized by " + fname + " " + lname
        }
        if let invitModel = feedModel.invitationDetails?.filter({ (model) -> Bool in
            if model.userId == USER_MANAGER.userId {
                return true
            }else {
                return false
            }
        }).first {
            if let invitedTime = invitModel.invitationTime {
                lblInvitedTime.text = Date(timeIntervalSince1970: invitedTime).timeAgoSince()
                widthInvitedTimeLbl.constant = lblInvitedTime.text?.width(withConstraintedHeight: 18.0, font: AppFont.regular.size(13.0)) ?? 30
            }
        }
        
        if let eventN = feedModel.eventName {
            eventName.text = eventN
        }
        
        dateTimeLbl.text = feedModel.textStartEndTime()
        let height = dateTimeLbl.text?.height(withConstrainedWidth: MAIN_SCREEN_WIDTH - 30 - 40 - 8 - 16 - 4, font: AppFont.regular.size(15.0)) ?? 18.0
        heightDateTimeLbl.constant = height < 18.0 ? 18.0 : height
    }
    
    @IBAction func actionEventDetails(_ sender: Any) {
        delegate?.didTapEventDetail(sender: self, eventModel: eventModel)
    }
    
    @IBAction func actionProfile(_ sender: Any) {
        delegate?.didTapHostProfile(sender: self, eventModel: eventModel)
    }
    @IBAction func actionYes(_ sender: Any) {
        delegate?.didTapGoingMaybeNextTime(sender: self, eventModel: eventModel, status: .Going)
    }
    @IBAction func actionMaybe(_ sender: Any) {
        delegate?.didTapGoingMaybeNextTime(sender: self, eventModel: eventModel, status: .Maybe)
    }
    @IBAction func actionNextTime(_ sender: Any) {
        delegate?.didTapGoingMaybeNextTime(sender: self, eventModel: eventModel, status: .NextTime)
    }
    @IBAction func actionHide(_ sender: Any) {
        delegate?.didTapHide(sender: self, eventModel: eventModel)
    }
}
